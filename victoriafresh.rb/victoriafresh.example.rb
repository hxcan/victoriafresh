#!/usr/bin/ruby

# require 'victoriafresh'
require File.dirname(__FILE__)+'/lib/victoriafresh'

if (ARGV.empty? ) #未指定命令行参数。
else #指定了命令行参数。
  $rootPath=ARGV[0] #记录要打包的目录树的根目录。
  
  $clipDownloader=VictoriaFresh.new #创建下载器。

  $clipDownloader.diskFlush=false #不向磁盘写入缓存
  $clipDownloader.diskMultiFile=true #写多个磁盘文件
  $clipDownloader.diskFileName='victoriafreshdata.v.' #磁盘文件名前缀
  $clipDownloader.diskFlushSize=32*1024*1024 #磁盘文件大小
  
  victoriaFresh,victoriaFreshData=$clipDownloader.checkOnce($rootPath) #打包该目录树。
  
  #利用protobuf打包成字节数组：
  replyByteArray="" #回复时使用的字节数组。
#   victoriaFresh.encode(replyByteArray) #打包成字节数组。
#   replyByteArray=Com::Stupidbeauty::Victoriafresh::FileMessage.encode(victoriaFresh) ##打包成字节数组。
  replyByteArray=victoriaFresh.to_cbor ##打包成字节数组。

  victoriaFreshFile=File.new("victoriafresh.v","wb") #创建文件。
  victoriaFreshFile.syswrite(replyByteArray) #写入文件。
  
  victoriaFreshFile.close #关闭文件。
  
  victoriaFreshDataFile=File.new("victoriafreshdata.v","wb") #数据文件。
  victoriaFreshDataFile.syswrite(victoriaFreshData) #写入文件。
  victoriaFreshDataFile.close #关闭文件。
end
