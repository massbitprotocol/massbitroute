# quick start

GameBox Cloud (hereinafter referred to as GBC) provides developers with a stable, reliable and scalable server-side architecture, allowing developers to quickly complete server-side function development using the Lua scripting language.

Let's follow the guidelines of this article and start the GBC journey!


## run demo

1. The first is [install and start GBC] (install.md). After completing this step, we first open the browser and visit `http://localhost:8088`, and the welcome page of GBC should be available.

2. Click **Demo** at the top of the page to enter a test page of GBC:

    ![](img/demo_page.png)

3. Enter a username here and click "Sign In" to log in to the server. Various tests are available after logging in.


In this **Demo** test, the functions that can be used are:

- Session: Click the **Add Counter** button below the username to see the value increasing. This value is stored in the Session of the server.

- Send messages to users: you can open several more pages, visit the `http://localhost:8088` page and log in with different usernames. This way you can see all logged in users in **Online Users**. Select any user, enter the content, and click the **Send** button to send the message to the specified user. Click **Send All** to send the message to all logged in users.

    ![](img/demo_say.png)

- Scheduled message sending: Select the waiting time, enter the message content, and click **Send to Job** to add a delayed task. After the specified time, you will see the previously entered message on the page.

    ![](img/demo_job.png)


## run unit tests

GBC comes with a set of unit tests. This set of unit tests is used both for functional verification and error checking in the GBC development phase, and as a reference for learning GBC usage.

To run unit tests, go to the installed GBC directory on the command line and execute:

```bash
$ cd /opt/gbc-core
$ ./apps/tests/shells/run_tests
```

You will see output similar to the following:

```
## Test Case : beanstalkd
[SERVER beanstalkd.basics] ok
[CLI    beanstalkd.basics] ok
[SERVER beanstalkd.tube] ok
[CLI    beanstalkd.tube] ok

## Test Case : components
[SERVER components.binding] ok
[CLI    components.binding] ok

## Test Case : jobs
[SERVER jobs.add] ok
[CLI    jobs.add] ok
```

The main code for unit tests is in the `./apps/tests/actions` and `./apps/jobs` directories. The latest source code can be viewed online: [https://github.com/dualface/gbc-core/tree/develop/apps/tests](https://github.com/dualface/gbc-core/tree/develop/apps /tests).



## Create your own Hello app

After trying the demo and unit tests, let's start creating our first `Hello` application.

First create an application directory, such as `hello`, and create the following directories and files in it:

```
+-- hello/
  +-- conf/
  | \-- app_entry.conf
  |
  +-- actions/
    \-- HelloAction.lua
```

The contents of the two files are:

**`conf/app_entry.conf`**

```
location /hello/ {
    content_by_lua 'nginxBootstrap:runapp("_APP_ROOT_")';
}
```

Be sure to write `/hello/` here, not `/hello`. If there is no trailing `/`, an error occurs when accessing.

**`actions/HelloAction.lua`**

```lua
local gbc = cc.import("#gbc")
local HelloAction = cc.class("HelloAction", gbc.ActionBase)

function HelloAction:sayAction(args)
    local word = args.word or "world"
    return {result = "hello, " .. word}
end

return HelloAction
```

After adding files, you also need to modify the `conf/config.lua` file in the GBC installation directory.

The `conf/config.lua` file defines the paths to all applications that need to be loaded:

```lua
-- all apps
apps = {
    welcome = "_GBC_CORE_ROOT_/apps/welcome",
    tests   = "_GBC_CORE_ROOT_/apps/tests",
},
```

We now add our application to it:

```lua
-- all apps
apps = {
    welcome = "_GBC_CORE_ROOT_/apps/welcome",
    tests   = "_GBC_CORE_ROOT_/apps/tests",
    hello   = "/home/duck/hello",
},
```

Note that `/home/duck/hello` here is the absolute path of the app, fill in according to the actual path.

After finishing the modification, GBC must be restarted:

```bash
./stop_server && sleep 2
./start_server --debug && sleep 2
./check_server
```

After the boot is complete you should see:

```
worker-hello:00                  STARTING
worker-hello:01                  STARTING
```

Indicates that our `hello` has started normally.

Let's test it now:

```bash
curl -o - "http://localhost:8088/hello/?action=hello.say"

{"result":"hello, world"}


curl -o - "http://localhost:8088/hello/?action=hello.say&word=code"

{"result":"hello, code"}
```

Remember how `/hello/` was written in `app_entry.conf` before, so it should also be written here with `/hello/?action=`.

Try modifying `HelloAction.lua` and test to see if the result is different.

To add more interfaces to the `Hello` application, please refer to [coding-style](coding-style.md).

<br />

### Reference

- [Install and start GBC](install.md)
- [coding specification](coding-style.md)
- [Configuration file](configs.md)
