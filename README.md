VictoriaFreSh，用于应用程序内部的虚拟文件系统
===

快速体验
==

```Shell
gem install VictoriaFreSh #用于安装依赖项
git clone https://github.com/hxcan/victoriafresh
ruby ./victoriafresh/victoriafresh.rb/victoriafresh.example.rb victoriafresh
ls -lh #victoriafresh.v victoriafreshdata.v
```

说明
==

这是为普通应用程序实现的一个虚拟文件系统，用于在应用程序的程序包内部携带包含大量文件的目录树，或者在复杂应用程序系统的不同端之间传递包含大量文件的目录树。

利用 CBOR 格式作为字节流的结构基础。

实际使用示例，安卓应用程序可利用这个库来向自己的安装包中打包携带一个目录树作为资源使用，运行时利用便利的接口释放出目录树，或者就地读取指定虚拟路径下文件的内容。

实际使用示例，复杂分布式系统的节点可利用这个库将一个目录树打包传送到其它节点。

代码结构
==

victoriafresh.android
=

安卓版的实现，主要用于携带资源文件，仅支持读取和释放文件。将目录树打包成字节流的过程，则依赖Ruby版提供的示例脚本来进行。

victoriafresh.rb
=

Ruby版的实现，在 EXtremeZip 的需求推动下，已经具有完整的打包和解包功能。并提供示例脚本，用于将目录树打包成字节流，供其它语言的版本使用。
