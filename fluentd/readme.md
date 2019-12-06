## fluentd

### macos 安装

参考官网提供的[安装教程](https://docs.fluentd.org/installation/install-by-dmg)

- 启动服务

```bash
sudo launchctl load /Library/LaunchDaemons/td-agent.plist
```

- 关闭服务

```bash
sudo launchctl unload /Library/LaunchDaemons/td-agent.plist
```

- 配置文件目录 */etc/td-agent/td-agent.conf*

- fluentd日志目录 */var/log/td-agent/td-agent.log**

## conf配置文件

see */etc/td-agent/td-agent.conf*

- source 标签

> 作用：配置匹配输入的数据源, 通过**type**字段指定使用的输入插件, 如http, tail(文件输入)

- match 标签

> 作用: 配置匹配输入数据的规则及匹配成功后需要执行的操作

- filter标签

> 配置数据输入流的过滤操作

- system 标签

> directives set system wide configuration

- label标签

> directives group the output and filter for internal
routing

- @include

> directives include other files

## event

fluentd 将输入的数据提交到source输入插件的过程通过一个事件传递数据, 事件主要由 **tag**, **time**, **record**组成. 如http输入
```bash 
curl -XPOST -d 'json={"json": "message"}' http://localhost:8888/debug.test
```

生成的事件如下:

> 2019-12-04 11:57:29.851484000 +0800 debug.test: {"json":"message"}

- time: Unix时间格式, 由source指定
- tag: string, 由 *.* 分割
- record: json格式, 日志的message信息



## Input/Output

### http输入

- conf配置

```bash
# HTTP input
# POST http://localhost:8888/<tag>?json=<json>
# POST http://localhost:8888/td.myapp.login?json={"user"%3A"me"}
# @see http://docs.fluentd.org/articles/in_http
<source>
  @type http
  @id input_http # 该规则的标识,唯一
  port 8888
</source>

## match tag=debug.** and dump to console
<match debug.**>
  @type stdout
  @id output_stdout
</match>
```

- 发送请求

```bash
➜ curl -XPOST -d 'json={"json": "message"}' http://localhost:8888/debug.test
```

**注意http的请求路径会作为input的tag, match时匹配该tag值**

```bash
➜ curl -XPOST -d 'json={"json": "message"}' http://localhost:8888/debug.test/dev.test

2019-12-04 10:37:33.550221000 +0800 debug.test.dev.test: {"json":"message"}
```

- 查看日志

```bash
➜ tail -f /var/log/td-agent/td-agent.log
# 2019-12-04 10:11:57.292401000 +0800 debug.test: {"json":"message"}
```

## filter

fluentd对数据的处理流程是 *input => filter1 => filter2 => filterN => output*

因此可在filter步骤中定义对数据的操作, 如增删改字段

- 定义filter

```bash
<filter tagReg>
 @type record_transformer # required
 enable_ruby # 可选, 可执行ruby脚本
 <record>
   # 数据的操作
   NEW_FIELD NEW_VALUE
 </record>
</filter>
```

如：

```bash
<filter mytest>
 @type record_transformer # required
 enable_ruby # 可选, 执行ruby脚本
 <record>
   host "#{Socket.gethostname}" # 主机名
   tag ${tag}
   avg ${record["total"] / record["count"]} # 若字段不存在会报错
 </record>
</filter>
```

执行

```bash
curl -XPOST -d 'json={"message": "she is not rachel","total": 100, "count": 10}' http://localhost:8888/mytest
```

输出：

```bash
2019-12-04T14:29:04+08:00       mytest  {"message":"she is not rachel","total":100,"count":10,"host":"123deMac-mini-2.local","tag":"mytest","avg":10}
```

## plugin

### elasticsearch-plugin

- 安装

下载*docker pull fluent/fluentd:latest*镜像, 通过该镜像创建容器, **gem install fluent-plugin-elasticsearch**
使用该镜像安装的plugin所在的目录是*/usr/lib/ruby/gems/2.5.0/gems*