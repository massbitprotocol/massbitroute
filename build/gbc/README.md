# Welcome to GameBox Cloud Core

GameBox Cloud Core 为开发者提供一个稳定可靠，可伸缩的服务端架构，让开发者可以使用 Lua 脚本语言快速完成服务端的功能开发。

主要特征:

-   稳定可靠、经过验证的高性能游戏服务端架构

    基于 OpenResty_ 和 LuaJIT_ 架构，得到了包括 CloudFlare 等大型机构的应用，无论是稳定性还是性能都得到了验证。

    GameBox Cloud Core 在 OpenResty 之上封装了一个 Lua Server Framework，为开发者创建游戏服务端功能提供了一个容易学习、容易扩展的基础架构。

    -   [OpenResty](http://openresty.org)
    -   [LuaJIT](http://luajit.org)


-   使用 Lua 脚本语言开发服务端功能

    也许您认为在服务端使用 Lua 脚本显得有点不务正业，但 NodeJS 的流行却证明了合适的基础架构可以让一种语言突破原本的应用场景。更何况相比 NodeJS，OpenResty 提供的同步非阻塞编程模型，可以避免写出大量的嵌套 callback，不管是从开发效率还是维护成本上来说都更胜 NodeJS。

    用 Lua 脚本语言开发服务端功能还有一个巨大的好处，那就是可以和使用 Cocos2d-Lua（quick-cocos2d-x）的客户端共享大量代码。比如数据 Schema 定义、数据对象、游戏逻辑等等，都可以在客户端和服务端之间共享同一份代码。做过网络游戏的同学一定对如何保持客户端和服务端代码在数据接口上的一致头疼过。现在使用 GameBox Cloud Core，这些问题统统消失不见。


-   支持短连接和长连接，满足从异步网络到实时网络的各种需求

    GameBox Cloud Core 支持 HTTP 和 WebSocket_ 两种连接方式，分别对应短连接和长连接，满足了异步和实时网络游戏的需求。

    > WebSocket 是一种通讯协议。在连接时通过 HTTP 协议进行。在客户端和服务端连接成功后，则变成标准的 TCP Socket 通讯。
    >
    > 而相比自己实现 TCP Socket，WebSocket 已经内部处理了数据包的拼合、拆分等问题，极大简化了服务端底层的复杂度。而在传输性能、带宽消耗上，WebSocket 相比传统 TCP Socket 没有任何区别。

    -   [WebSocket RFC 文档](https://tools.ietf.org/html/rfc6455)
    -   [WebSocket](http://zh.wikipedia.org/wiki/WebSocket)

## 下载 GameBox Cloud Core

-   下载页面： [https://github.com/dualface/gbc-core/releases](https://github.com/dualface/gbc-core/releases)


## Get Started

-   [快速开始](https://github.com/dualface/gbc-docs/blob/master/src/guide/get-started.md)
-   [更多文档](https://github.com/dualface/gbc-docs/)
-   [源代码仓库](https://github.com/dualface/gbc-core)
-   [项目管理](https://www.pivotaltracker.com/n/projects/1474648)
-   [Bug 报告](https://github.com/dualface/gbc-core/issues)
-   技术支持: QQ群 <315146510>
