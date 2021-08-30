#!/usr/bin/ruby

require 'pathname'
require 'fileutils'
require 'cbor'
require 'get_process_mem'

# require File.dirname(__FILE__)+'/VictoriaFreSh/filemessage_pb.rb'

class VictoriaFresh
    attr_accessor :diskFlushSize #累积了这么多的数据就向磁盘写入，以减少内存占用
    attr_accessor :diskFileName #向磁盘写入数据时的文件名或前缀
    attr_accessor :diskMultiFile #向磁盘写入时，是否要写多个文件 
    attr_accessor :diskFlush #要提前磁盘写入文件，以节省内存吗？
    attr_accessor :currentDiskFlushSuffix #当前的文件后缀。也等价于已经写入的文件片段个数
    
    def initialize
        @diskFlush=false #要向磁盘写入文件
        @diskFlushSize=143212 #磁盘分块大小
        @diskFileName='victoriafreshdata.v'  #磁盘文件名
        @diskMultiFile=false #磁盘整个文件，不是多个文件
        @diskWriteFileObject={} #向磁盘写入文件的对象
        @contentString="" #内容字符串
        @contentPartArray=[] #内容片段数组
        @currentDiskFlushSuffix=0 #当前的磁盘文件后缀
        @bufferLength=0 #缓冲区总长度
        @externalDataFile={} #外部数据文件对象
    end
    
    def checkMemoryUsage(lineNumber)
        mem= GetProcessMem.new
        
        puts("#{lineNumber} ,  Memory: #{mem.mb}"); #Debug
        
    end #def checkMemoryUsage
    
    def releaseFiles(victoriaFreshPackagedFileString, contentString) #释放目录树
        packagedFile=CBOR.decode(victoriaFreshPackagedFileString) #解码
        
#         puts packagedFile #Debug
        
        releaseFile('.', packagedFile, contentString) #释放一个文件 
    end #def releaseFiles(victoriaFreshPackagedFile, contentString) #释放目录树
    
    def releaseFilesExternalDataFile(victoriaFreshPackagedFileString, externalDataFileName) #释放目录树
        packagedFile=CBOR.decode(victoriaFreshPackagedFileString) #解码
        
#         puts packagedFile #Debug
        
        @externalDataFile=File.open(externalDataFileName, 'rb') #打开文件
        
        releaseFileExternalDataFile('.', packagedFile) #释放一个文件 
        
        @externalDataFile.close #关闭文件
    end #def releaseFiles(victoriaFreshPackagedFile, contentString) #释放目录树
    
    def writeFileExternalDataFile(pathPrefix, packagedFile) #写入文件
        timeObject=getTimeObject(packagedFile) #构造时间戳对象
        
        @externalDataFile.seek(packagedFile['file_start_index']) #定位到起始位置
        
        victoriaFreshData=@externalDataFile.read(packagedFile['file_length']) #读取内容
        
        #         victoriaFreshData=contentString[packagedFile.file_start_index, packagedFile.file_length] #获取内容
#         victoriaFreshData=contentString[ packagedFile['file_start_index'], packagedFile['file_length'] ] #获取内容
        
        #         pathToMake=pathPrefix + '/' + packagedFile.name #构造文件名
        pathToMake=pathPrefix + '/' + packagedFile['name'] #构造文件名

        begin
          victoriaFreshDataFile=File.new(pathToMake , "wb", packagedFile['permission']) #数据文件。
          victoriaFreshDataFile.syswrite(victoriaFreshData) #写入文件。
          victoriaFreshDataFile.close #关闭文件。

          FileUtils.touch pathToMake, :mtime => timeObject #设置修改时间

          permissionNumber=packagedFile['permission'] #获取权限数字

          if (permissionNumber.nil?) #不带权限字段
          elsif #带权限字段
            File.chmod(permissionNumber, pathToMake) #设置权限
          end #if (permissionNumber.nil?) #不带权限字段


        rescue Errno::ENOENT # File not exist
          puts "Rescued by Errno::ENOENT statement. #{pathToMake}" #报告错误
        rescue Errno::EACCES # File permission error
            puts "Rescued by Errno::EACCES statement. #{pathToMake}" #报告错误
        end
    end #def writeFileExternalDataFile(pathPrefix, packagedFile) #写入文件
    
    def writeFile(pathPrefix, packagedFile, contentString) #写入文件
        
        timeObject=getTimeObject(packagedFile) #构造时间戳对象
        
        #         victoriaFreshData=contentString[packagedFile.file_start_index, packagedFile.file_length] #获取内容
        victoriaFreshData=contentString[ packagedFile['file_start_index'], packagedFile['file_length'] ] #获取内容
        
        #         pathToMake=pathPrefix + '/' + packagedFile.name #构造文件名
        pathToMake=pathPrefix + '/' + packagedFile['name'] #构造文件名
        
        victoriaFreshDataFile=File.new(pathToMake , "wb", packagedFile['permission']) #数据文件。
        victoriaFreshDataFile.syswrite(victoriaFreshData) #写入文件。
        victoriaFreshDataFile.close #关闭文件。
        
        FileUtils.touch pathToMake, :mtime => timeObject #设置修改时间
        
        permissionNumber=packagedFile['permission'] #获取权限数字
        
        if (permissionNumber.nil?) #不带权限字段
        elsif #带权限字段
            File.chmod(permissionNumber, pathToMake) #设置权限
        end #if (permissionNumber.nil?) #不带权限字段
        
    end #writeFile(pathPrefix, packagedFile, contentString) #写入文件
    
    #创建符号链接
    def makeSymlinkExternalDataFile(pathPrefix, packagedFile)
        @externalDataFile.seek(packagedFile['file_start_index']) #定位到起始位置
        
        victoriaFreshData=@externalDataFile.read(packagedFile['file_length']) #读取内容
#         victoriaFreshData=contentString[ packagedFile['file_start_index'], packagedFile['file_length'] ] #获取内容
        
        pathToMake=pathPrefix + '/' + packagedFile['name'] #构造文件名
        
        puts("data: #{victoriaFreshData}, path: #{pathToMake}") #Debug

        begin #创建符号链接
            FileUtils.symlink(victoriaFreshData, pathToMake, force: true) #创建符号链接
        rescue Errno::EACCES => e #权限受限
            puts "Rescued by Errno::EACCES statement. #{pathToMake}" #报告错误
        end #begin #创建符号链接
        
        permissionNumber=packagedFile['permission'] #获取权限数字
        
        if (permissionNumber.nil?) #不带权限字段
        elsif #带权限字段
            #             File.chmod(permissionNumber, pathToMake) #设置权限
            begin #尝试修改链接本身的权限
                File.lchmod(permissionNumber, pathToMake) #设置权限
            rescue NotImplementedError #未实现
                puts 'File.lchmod not implemented' #Debug
            rescue Errno::ENOTSUP => e
                puts "Rescued by Errno::ENOTSUP statement. #{pathToMake}" #报告错误
            end #begin #尝试修改链接本身的权限
        end #if (permissionNumber.nil?) #不带权限字段
    end #def makeSymlinkExternalDataFile(pathPrefix, packagedFile)
    
    #创建符号链接
    def makeSymlink(pathPrefix, packagedFile, contentString) 
        puts("start index: #{packagedFile['file_start_index']}, length: #{packagedFile['file_length']}, content string length: #{contentString.bytesize}") #Debug
        victoriaFreshData=contentString[ packagedFile['file_start_index'], packagedFile['file_length'] ] #获取内容
        
        pathToMake=pathPrefix + '/' + packagedFile['name'] #构造文件名
        
        #         victoriaFreshDataFile=File.new(pathToMake , "wb") #数据文件。
        #         victoriaFreshDataFile.syswrite(victoriaFreshData) #写入文件。
        #         victoriaFreshDataFile.close #关闭文件。
        #         
        #         FileUtils.touch pathToMake, :mtime => timeObject #设置修改时间
        
        puts("data: #{victoriaFreshData}, path: #{pathToMake}") #Debug
        
        FileUtils.symlink(victoriaFreshData, pathToMake, force: true) #创建符号链接
        
        permissionNumber=packagedFile['permission'] #获取权限数字
        
        if (permissionNumber.nil?) #不带权限字段
        elsif #带权限字段
            #             File.chmod(permissionNumber, pathToMake) #设置权限
            begin #尝试修改链接本身的权限
                File.lchmod(permissionNumber, pathToMake) #设置权限
            rescue NotImplementedError #未实现
                puts 'File.lchmod not implemented' #Debug
            end #begin #尝试修改链接本身的权限
        end #if (permissionNumber.nil?) #不带权限字段
    end #def makeSymlink(pathPrefix, packagedFile, contentString) #创建符号链接
    
    def getTimeObject(packagedFile) #构造时间戳对象
        #         seconds=packagedFile.timestamp.seconds #获取秒数
        seconds=packagedFile['timestamp']['seconds'] #获取秒数
        
        #         microSeconds=packagedFile.timestamp.nanos/ 1000.0 #获取毫秒数
        microSeconds=packagedFile['timestamp']['nanos'] / 1000.0 #获取毫秒数
        
        timeObject=Time.at(seconds, microSeconds) #构造时间对象
        
    end #getTimeObject(packagedFile) #构造时间戳对象
    
    def makeDirectory(pathPrefix, packagedFile) #创建目录
        timeObject=getTimeObject(packagedFile) #构造时间戳对象
        
        
        #         puts 'mkdir' #Debug
        pathToMake=File.join(pathPrefix, packagedFile['name'])
        
        #         puts  pathToMake #Debug.
        
        if (Dir.exist?(pathToMake)) #目录已经存在
        else #目录 不存在
            begin
            Dir.mkdir(pathToMake) #=> 0
            rescue Errno::EILSEQ => e # File name invalid
            puts "Rescued by Errno::EILSEQ statement. #{pathToMake}" # 报告错误

            end

        end #if (Dir.exist?(pathToMake)) #目录已经存在

        begin
            FileUtils.touch pathToMake, :mtime => timeObject # 设置修改时间
        rescue Errno::EILSEQ => e # File name invalid
            puts "Rescued by Errno::EILSEQ statement. #{pathToMake}" # 报告错误

        end


        permissionNumber=packagedFile['permission'] #获取权限数字
        
        if (permissionNumber.nil?) #不带权限字段
        elsif #带权限字段


            begin
                File.chmod(permissionNumber, pathToMake) #设置权限
            rescue Errno::ENOENT => e # File not exist
                puts "Rescued by Errno::ENOENT statement. #{pathToMake}" # 报告错误

            end


        end #if (permissionNumber.nil?) #不带权限字段
    end #makeDirectory(pathPrefix, packagedFile) #创建目录
    
    def releaseFileExternalDataFile(pathPrefix, packagedFile) #释放一个文件
        if packagedFile['is_file'] #是文件，则直接写入文件
            writeFileExternalDataFile(pathPrefix, packagedFile) #写入文件
        elsif packagedFile['is_symlink'] #是符号链接，则创建符号链接
            makeSymlinkExternalDataFile(pathPrefix, packagedFile) #创建符号链接
        else #是目录，则创建目录，并递归处理
            makeDirectory(pathPrefix, packagedFile) #创建目录
            
            direcotryPathPrefix=pathPrefix  + '/' + packagedFile['name'] #构造针对该目录的路径前缀
            
            subFiles=packagedFile['sub_files'] #获取子文件列表。
            
            subFiles.each do |currentSubFile| #一个个子文件地释放
                releaseFileExternalDataFile(direcotryPathPrefix, currentSubFile) #释放子文件
            end #subFiles.each do |currentSubFile| #一个个子文件地释放
        end #if packagedFile.is_file #是文件，则直接写入文件
    end #def releaseFileExternalDataFile(pathPrefix, packagedFile) #释放一个文件
    
    def releaseFile( pathPrefix, packagedFile, contentString) #释放一个文件 
        if packagedFile['is_file'] #是文件，则直接写入文件
            writeFile(pathPrefix, packagedFile, contentString) #写入文件
        elsif packagedFile['is_symlink'] #是符号链接，则创建符号链接
            makeSymlink(pathPrefix, packagedFile, contentString) #创建符号链接
        else #是目录，则创建目录，并递归处理
            makeDirectory(pathPrefix, packagedFile) #创建目录
            
            direcotryPathPrefix=pathPrefix  + '/' + packagedFile['name'] #构造针对该目录的路径前缀
            
            subFiles=packagedFile['sub_files'] #获取子文件列表。
            
            subFiles.each do |currentSubFile| #一个个子文件地释放
                releaseFile(direcotryPathPrefix, currentSubFile, contentString) #释放子文件
            end #subFiles.each do |currentSubFile| #一个个子文件地释放
            
        end #if packagedFile.is_file #是文件，则直接写入文件
    end #def releaseFile(packagedFile, contentString) #释放一个文件 
    
    #考虑是否要向磁盘先输出内容
    def assessDiskFlush(layer, isFinalPart=false)
        if (@diskFlush) #要做磁盘写入
            if (@bufferLength>=@diskFlushSize) #缓冲区总长度已经超过需要的文件长度
                @contentString = @contentPartArray.join #重组成整个字符串
                
                    @contentPartArray.clear #清空数组
                    
                    while (@contentString.length >= @diskFlushSize) #还有内容要写入
                        contentToWrite=@contentString[0, @diskFlushSize] #取出开头的一段
                        
                        @contentString=@contentString[@diskFlushSize, @contentString.length-@diskFlushSize] #留下剩余的部分
                        
                            if (@diskMultiFile) #多个磁盘文件
                                @diskWriteFileObject=File.new(@diskFileName+@currentDiskFlushSuffix.to_s, 'wb') #打开文件
                                
                                @currentDiskFlushSuffix=@currentDiskFlushSuffix+1 #增加计数
                                
                                @diskWriteFileObject.syswrite(contentToWrite) #写入内容
                                
                                @diskWriteFileObject.close
                            else #单个磁盘文件
                                
                                @diskWriteFileObject.syswrite(contentToWrite) #写入内容
                                
                                @diskWriteFileObject.flush #写入磁盘
                            end #@currentDiskFlushSuffix
                    end #while (contentString.length >= @diskFlushSize) #还有内容要写入
                    
                    @contentPartArray << @contentString #剩余部分重新加入数组中
                    @bufferLength=@contentString.length #重新记录缓冲区总长度
            end #if (bufferLength>=@diskFlushSize) #缓冲区总长度已经超过需要的文件长度
            
            if (isFinalPart) #是最后一部分
                                @contentString = @contentPartArray.join #重组成整个字符串

                @contentPartArray.clear #清空字符串数组
                @bufferLength=0 #缓冲区长度归零
                
                contentToWrite=@contentString #要写入的内容
                
                @contentString="" #字符串清空
                
                    if (@diskMultiFile) #多个磁盘文件
                        @diskWriteFileObject=File.new(@diskFileName+@currentDiskFlushSuffix.to_s, 'wb') #打开文件
                        
                        @currentDiskFlushSuffix=@currentDiskFlushSuffix+1 #增加计数
                        
                        @diskWriteFileObject.syswrite(contentToWrite) #写入内容
                        
                        @diskWriteFileObject.close
                        
                        
                    else #单个磁盘文件
                        @diskWriteFileObject.syswrite(contentToWrite) #写入内容
                        
                        @diskWriteFileObject.close #关闭文件
                        
                    end #if (@diskMultiFile) #多个磁盘文件
            end #if (isFinalPart) #是最后一部分
        end #if (@diskFlush) #要做磁盘写入
    end #contentString= assessDiskFlush(contentString) #考虑是否要向磁盘先输出内容
    
    def checkOnce(directoryPath, startIndex=0, layer=0) #打包一个目录树。
        if (@diskFlush) #要向磁盘写入文件
            if (layer==0) #最外层
                if (@diskMultiFile) #要写多个文件 
                else #不写多个文件
                    @diskWriteFileObject=File.new(@diskFileName, 'wb') #打开文件
                end #if (@diskMultiFile) #要写多个文件 
            end #if (layer==0) #最外层
        end #if (@diskFlush) #要向磁盘写入文件s
        
        packagedFile={} #创建文件消息对象。
        
        packagedFile['sub_files'] = [] #加入到子文件列表中。
        
        directoryPathName=Pathname.new(directoryPath) #构造路径名字对象。
        
        baseName=directoryPathName.basename.to_s #基本文件名。
        
        packagedFile['name']=baseName #设置文件名。
        
        isFile=directoryPathName.file? #是否是文件。
        isSymLink=directoryPathName.symlink? #是否是符号链接
        
        packagedFile['is_file']=isFile #设置属性，是否是文件。
        packagedFile['file_start_index']=startIndex #记录文件内容的开始位置。
        
        packagedFile['is_symlink']=isSymLink #设置属性，是否是符号链接
        
        puts directoryPath #Dbug.
        
        #记录时间戳：
        begin #读取时间戳
            mtimeStamp=File.mtime(directoryPath) #获取时间戳
            
            packagedFile['timestamp']={} #时间戳
            packagedFile['timestamp']['seconds']=mtimeStamp.tv_sec #设置秒数
            packagedFile['timestamp']['nanos']=mtimeStamp.tv_nsec #设置纳秒数
            
            packagedFile['permission']=(File.stat(directoryPath).mode & 07777 ) #设置权限信息
        rescue Errno::ENOENT
        rescue Errno::EACCES #权限受限
        end #begin #读取时间戳
        
        if isFile #是文件，不用再列出其子文件了。
            packagedFile['file_length']=directoryPathName.size #记录文件的内容长度。
            
            #读取文件内容：
            fileToReadContent=File.new(directoryPath,"rb") #创建文件。
            currentFileContent=fileToReadContent.read #全部读取
            @contentPartArray <<  currentFileContent
            @bufferLength=@bufferLength+ currentFileContent.length #记录缓冲区总长度
            #       @contentString= @contentString +  fileToReadContent.read #全部读取。
            
            assessDiskFlush(layer) #考虑是否要向磁盘先输出内容
        elsif (isSymLink) #是符号链接
            linkTarget=directoryPathName.readlink #获取链接目标
            
            #         待续，设置内容长度。符号链接字符串的长度
            packagedFile['file_length']=linkTarget.to_s.bytesize #记录文件的内容长度。
            
            #读取文件内容：
            #       fileToReadContent=File.new(directoryPath,"rb") #创建文件。
            currentFileContent=StringIO.new(linkTarget.to_s).binmode.read #全部读取。
            @contentPartArray << currentFileContent #加入数组
            @bufferLength=@bufferLength + currentFileContent.length #记录缓冲区总长度
            #       @contentString= @contentString + StringIO.new(linkTarget.to_s).binmode.read #全部读取。
            
            assessDiskFlush(layer) #考虑是否要向磁盘先输出内容
            
        else #是目录。
            #       contentString="" #容纳内容的字符串。
            subFileStartIndex=startIndex #子文件的起始位置，以此目录的起始位置为基准。
            
            packagedFile['file_length']=0 #本目录的内容长度。

            puts "Listing for #{directoryPathName}" # Debug

            directoryPathName.each_child do |subFile| #一个个文件地处理。
                #           puts("sub file: #{subFile}, class: #{subFile.class}, symlink: #{subFile.symlink?}, expand_path: #{subFile.expand_path}, file?: #{subFile.file?}") #Debug.
                #     checkMemoryUsage(221)

                begin
                realPath=subFile.expand_path #获取绝对路径。
                
                packagedSubFile,subFileContent=checkOnce(realPath,subFileStartIndex, layer+1) #打包这个子文件。
                
                packagedFile['sub_files'] << packagedSubFile #加入到子文件列表中。
                
                #         puts("sub file content: #{subFileContent}, nil?: #{subFileContent.nil?}" ) #Debug
                
                #             puts(" content: #{contentString}, nil?: #{contentString.nil? }") #Debug
                
                #         contentString = contentString + subFileContent #串接文件内容。
                
                assessDiskFlush(layer) #考虑是否要向磁盘先输出内容
                
                
                subFileStartIndex+=packagedSubFile['file_length'] #记录打包的子文件的长度，更新下一个要打包的子文件的起始位置。
                
                #         puts("237, content string length: #{contentString.length}") #Debug
                
                packagedFile['file_length']+=packagedSubFile['file_length'] #随着子文件的打包而更新本目录的总长度。
                rescue Errno::EMFILE # File not exist
                    puts "Rescued by Errno::EMFILE statement. #{subFile}" #报告错误
                end
            end #directoryPathName.each_child do |subFile| #一个个文件地处理。
        end #if (isFile) #是文件，不用再列出其子文件了。
        
        #                 puts("300, contentString: #{contentString}, nil?: #{contentString.nil?}, direcotry path: #{directoryPath}, layer: #{layer}") #Debug
        
        
        #                 puts("302, contentString: #{contentString}, nil?: #{contentString.nil?}, direcotry path: #{directoryPath}, layer: #{layer}") #Debug
        
        contentToResult="" #要返回的内容
        
        if (layer==0) #是最外层
            assessDiskFlush(layer, true) #考虑是否要向磁盘先输出内容
            
            if (@diskFlush) #要向磁盘写入缓存内容
            else #不向磁盘写入缓存内容
                contentToResult=@contentPartArray.join #重新合并成字符串
                
            end #if (@diskFlush) #要向磁盘写入缓存内容
        end #if (layer==0) #是最外层
        return packagedFile, contentToResult #返回打包之后的对象。和文件内容字节数组。
    end #def downloadOne #下载一个视频。
end

