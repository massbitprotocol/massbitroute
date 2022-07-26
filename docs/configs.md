# config file

There are two types of configuration files in GBC:

- GBC global configuration file
- Application profiles

The global configuration file is used to adjust the operating settings of GBC, and the application configuration file is used to adjust the operating settings of the application.


## global configuration

The core global configuration file of GBC is `conf/config.lua`, which is divided into three parts:

```lua

local config = {
    DEBUG = cc.DEBUG_VERBOSE,

    -- all apps
    apps = {
        -- application name = "application absolute path",
        welcome = "_GBC_CORE_ROOT_/apps/welcome",
        ...
    },

    -- default app config
    app = {
        ...
    },

    -- server config
    server = {
        nginx = {
            numOfWorkers = 4, -- the number of nginx processes
            port = 8088 -- external service port
        },

        -- internal memory database
        redis = {
            ...
        },

        -- background job server
        beanstalkd = {
            ...
        },
    }
}

return config
```

- `apps` defines the applications to be loaded when GBC starts

    Each application has a unique name that corresponds to the absolute path to the directory where the application is located. Names cannot contain special characters, preferably only a combination of letters and numbers.

- `app` defines a default configuration shared by all applications

    Modifying the settings here will affect all applications, so it is strongly recommended not to change these settings. We can override these default settings in each application's `app_config.lua`.

- `server` defines the configuration of each service in GBC

    In most cases, only two items related to `nginx` need to be modified:

    - `nginx.numOfWorkers` is the number of nginx processes and should be set to the same as the number of CPUs the server has
    - `nginx.port` is the port number for external services, set it according to your needs

**Special Note:**

The Redis that is automatically installed when GBC is installed is an in-memory database only for GBC's internal operation, and this internal Redis should not be used in applications. For questions about Redis, refer to [Using Redis in Applications](use-redis.md).


## application configuration file

Each application has two configuration files:

- `Application directory/conf/app_entry.conf` defines the access entry for the application
- `app-dir/conf/app_config.lua` defines custom settings for the app

### `app_entry.conf`

The contents of this file are as follows:

```bash
location = /ENTRY {
    content_by_lua 'nginxBootstrap:runapp("_APP_ROOT_")';
}
```

The `ENTRY` in the file indicates what address to use to access the application-defined interface.

For example, the address of GBC server is `localhost:8088`, and `ENTRY` is `hello`, then the access address of the application is `localhost:8088/hello`.

### `app_config.lua`

The contents of this file directly override the `app` section of the global configuration file `conf/config.lua`. So if you need to modify the application running settings, it should be placed in `app_config.lua`.

Runtime settings that can be specified:

Options | Description
-----|-----
`messageFormat` | Specifies the message format for exchanging data between client and server, defaults to `json`.
`defaultAcceptedRequestType` | Specifies which request method the server interface supports by default. The default is `http`. It can be set to `websocket` or `{"http", "websocket"}` to support multiple request methods. But for security, it should be set to `http`, and then explicitly specified in the interface that needs to support other request types.
`sessionExpiredTime` | Specifies the expiration time of the session. After the Session is established, if the `Session:setKeepAlive()` method is not called, the Session will be invalid after the specified time.
`httpEnabled` | Specifies whether the application accepts HTTP requests.
`httpMessageFormat` | Specifies the message format used by the client to interact with the server through HTTP requests, the default is `json`.
`websocketEnabled` | Specifies whether the application accepts WebSocket requests.
`websocketMessageFormat` | Specifies the message format used by the client to interact with the server through WebSocket requests, the default is `json`.
`websocketsTimeout` | Specifies the timeout time for the server to wait for messages from the client when the client and server use WebSocket to communicate. When this time is set to a short time, it can be checked faster that the client has disconnected, but it will slightly increase the burden on the server. The default is 60 seconds.
`websocketsMaxPayloadLen` | Specifies the maximum length (bytes) of each message when the client and server use WebSocket to interact, the default is `16KB`.
`jobMessageFormat` | Specifies the message format of the background job, defaults to `json`.
`numOfJobWorkers` | Specifies how many background processes the app starts. It is recommended to set it according to the number of CPUs of the server.
`jobWorkerRequests` | Specifies how many tasks each background task process handles and restarts once (to avoid memory leaks caused by code problems).

For examples of `app_entry.conf` and `app_config.lua`, you can look at the two applications `welcome` and `tests` that come with GBC.
