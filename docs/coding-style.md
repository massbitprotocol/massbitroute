# Coding Standards


This specification includes naming conventions, conventions, and more. It includes the following aspects:

- Application directory structure
- Package structure
- named
    - package naming
    - class naming
    - Function and function naming
    - variable naming
    - Constant naming
    - Event naming
- parameters
- return value
- Error handling
- define modules
- define class
- HTTP/WebSocket external interface
- Delay task interface
- Command line interface

<br />

## Application directory structure

The following directory structure is recommended for each app:

~~~
+-- <APP_ROOT>/
  +-- HttpInstance.lua
  +-- WebSocketInstance.lua
  +-- WorkerInstance.lua
  +-- CommandLineInstance.lua
  |
  +-- conf/
  | +-- app_entry.conf
  | \-- app_config.lua
  |
  +-- actions/
  | \-- HelloAction.lua
  |
  +-- jobs/
  | \-- MapAction.lua
  |
  +-- commands/
  | \-- ToolAction.lua
  |
  +-- packages/
    +-- <PACKAGE_NAME>/
      \-- <PACKAGE_NAME>.lua
~~~

illustrate:

- `<APP_ROOT>` is the app root directory and must be placed in a directory without spaces and Chinese characters.
- Four `????Instance.lua` files are optional, for HTTP requests, WebSocket connections, delayed tasks, and startup code for the command line.
- The `conf/app_entry.conf` file is required and contains the settings that Nginx needs to initialize the app.
- `conf/app_config.lua` contains app specific settings.
- The `actions` directory houses all the interfaces called by HTTP requests and WebSocket connections.
- The `jobs` directory holds the handler interface for all deferred jobs.
- The `commands` directory houses all command line interfaces.
- The `packages` directory holds all extension packages.

reference:

- For the four `????Instance.lua` startup files and the configuration files in the `conf` directory, please refer to the [Startup Application](startup-app.md) document.
- For the interface definitions in the `actions` directory, please refer to the [Defining Interfaces for External Access](exports-api.md) document.
- For interface definitions in the `jobs` directory, please refer to the [Handling Delayed Jobs](jobs.md) document.
- For the `packages` directory, please refer to the "Package Structure" section later in this document.

<br />


## package structure

To facilitate organizing application content, GBC (short for GameBox Cloud) supports a simple package structure. Each package is a directory that contains a `.lua` file with the same name as the directory.

For example, a package named `hello` is stored in `packages/hello/hello.lua`:

~~~
local _M = {}

function _M.say()
    print("hello")
end

return _M
~~~

To use the package named `hello` above, simply call:

~~~lua
local hello = cc.import("#hello")
hello.say()
~~~

In a package, there can be any number of files. For example, `packages/gbc` that comes with GBC contains all the module files of the entire GBC framework.

illustrate:

- Package directories and files must have all lowercase names
- There must be a `.lua` file with the same name as the directory in the package directory for `cc.import()` to load
- Package directories and files must be placed in the application's `packages` directory
- When `cc.import()` loads a package, the symbol `#` must be added before the package name

<br />


## Naming

Naming is divided into multiple parts.


### package naming

Although Lua supports more characters, considering the compatibility of different operating environments, the package name must be composed of all lowercase letters or numbers and underscores. In addition, the package name should reflect the actual purpose of the extension package.

If an extension package contains multiple modules, they should be named as follows:

~~~
+-- <PACKAGE_NAME>/
  +-- <PACKAGE_NAME>.lua
  +-- <MODULE_NAME>.lua
  \-- <MODULE_NAME>.lua
~~~

For example, the extension package directory structure of GBC core is as follows:

~~~
+-- gbc
  +-- gbc.lua
  +-- ActionBase.lua
  +-- InstanceBase.lua
  \-- more files
~~~

In `gbc.lua`, load different modules separately:

~~~lua
local _M = {
    ActionBase   = cc.import(".ActionBase"),
    InstanceBase = cc.import(".InstanceBase"),

    ...
}

return _M
~~~

Where you need to use the `gbc` extension package, you can use the following code:

~~~lua
local gbc = cc.import("#gbc")
local HelloAction = cc.class("HelloAction", gbc.ActionBase)
~~~


### class naming

Class names should be single or multiple words with each word capitalized. E.g:

~~~
HelloAction
MapAction
~~~

If a class is a base class, it is recommended to use `Base` as the last word. E.g:

~~~
ActionBase
InstanceBase
~~~


### Functions and function names

The basic rules for naming functions and functions are:

- The first word is "verb" or "preposition", such as `set`, `get`, `on`, `after`, etc.
- Full function names like `setPosition`, `getOpacity`, `afterUserSignIn`.

Depending on the purpose of the function, different naming conventions are used:

- If it is used as a basic function, the function name should refer to the Lua standard library and use all lowercase names. E.g:

    ~~~lua
    cc.class()
    cc.printf()
    string.ucfirst()
    ~~~

- In other cases, functions should be named by single or multiple words, with the first letter of words other than the first capitalized. E.g:

    ~~~lua
    countAction()
    echoAction()
    ~~~

- If it is a function or function for use inside a module or class, the `_` character should be added before the name. E.g:

    ~~~lua
    _openSession()
    _newRedis()
    ~~~

- If it is an event handler, it is recommended to start with `on`. E.g:

    ~~~lua
    onConnected()
    onDisconnected()
    ~~~

- Local references to external functions should use the form `module_function_name`. E.g:

    ~~~lua
    local string_format = string.format
    local os_time = os.time
    ~~~

In addition to the above rules, the following conventions are recommended:


- Functions that change the state of an object immediately

    Naming conventions:

    - **verb** + [noun]
    - If a single verb can clearly express its meaning, it does not need to be followed by a noun.

    Example:

    ~~~lua
    node:move(...) -- move to the specified position immediately
    node:rotate(...) -- immediately rotate to the specified angle
    node:show() -- show object
    node:align(...) -- align objects
    ~~~

- Functions that continuously change the state of an object

    Naming conventions:

    - **verb** + [noun] + [preposition]
    - If a single verb can clearly express its meaning, it does not need to be followed by a noun.
    - Prepositions usually choose `to`, `by`, etc.:
        - `to` means to ignore the current state of the object and finally reach the specified state
        - `by` indicates that the current state is the basis and changes to a certain extent, and the final state is determined by the current state and the degree of change

    Example:

    ~~~lua
    node:moveTo(...) -- move to the specified position
    node:moveBy(...) -- move a certain distance based on the current position
    ~~~

- perform operations on objects

    Naming conventions:

    - **verb** + [noun] + [adverb | preposition]
    - If a single verb can clearly express its meaning, it does not need to be followed by a noun.

    Example:

    ~~~lua
    node:add(...) -- add child objects
    node:addTo(...) -- add object to parent
    node:playAnimationOnce(...) -- play an animation on the object once
    node:playAnimationForever(...) -- play animation continuously on object
    ~~~


### variable naming

Variable names should be concise and clear, capitalizing all but the first word. E.g:

~~~lua
local username
local sessionId
~~~

If it is an internal member variable of a class, the `_` character should be added before the name. E.g:

~~~lua
self._session
self._count
~~~

If it is a placeholder variable used in syntax such as `for`, you can use `_` directly as the variable name. E.g:

~~~lua
for _, v in ipairs(arr) do
    print(v)
end
~~~


### Constant naming

Use all caps and separate words with "_" underscores. E.g:

~~~lua
local DEFAULT_DELAY = 1
Constants.DEFAULT_ACTION = "index"
~~~


### Event naming

The naming rules for events are the same as constants, all uppercase, and words are separated by "_" underscores. E.g:

~~~lua
local Bear = cc.class("Bear")

Bear.EVENT = table.readonly({
    WALK = "WALK",
    RUN  = "RUN",
})
~~~

Use function:

~~~lua
local bear = Bear:new()
bear:bind(Bear.EVENT.WALK, cc.handler(self, self.onWalk))
~~~

When defining the `EVENT` event list for the class, the `table.readonly()` function is used:

- `table.readonly()` can make a `table` read-only, ensuring that the event list is not modified at runtime.
- Secondly, if a value that is not defined in the list is accessed at runtime, an error will also be thrown, which is convenient for troubleshooting.

<br />


## parameters

If the input parameters have importance priority, they are sorted by priority. E.g:

~~~lua
display.newSprite(filename, x, y)
~~~

If there is a target to operate on, the target should be the first argument. E.g:

~~~lua
transition.move(target, ...)
~~~

<br />


## return value

The return value is designed according to the function and function of the function, using the following rules:

- For functional functions or functions that do not involve specific logic, only one value should be returned.
- Should be wrapped as a `table` if there are multiple values ​​to return.
- If an error occurs in the execution of the function, and the error is recoverable or needs to be returned to the caller, `nil` and the error message string should be returned.
- If it is a function of a class, and the caller does not need a return value, you can return `self` to achieve chained calls:

    ~~~lua
    obj:doSomething():again()
    ~~~

<br />


## Error handling

Different contexts require different mechanisms for error handling. Basically divided by the severity of the error:

- If execution must be interrupted, use the `cc.throw()` function to throw an error message directly.
- If execution is allowed to continue, use the `cc.printerror()` function to output an error message, and then continue execution. Since `cc.printerror()` prints the call stack, you can see the exact location of the problem in the log.
- If it is just an unexpected situation that needs to be alerted to the developer, not an error, `cc.printwarn()` should be used to output a warning message.
- For pure debug information, use `cc.printinfo()` and `cc.printdebug()` to output. The difference between the two is that they are filtered by different `cc.DEBUG` settings.
- If a function or function needs to return specific error information to the caller when an error occurs internally, it should use the following form:

    ~~~lua
    function test(arg)
        if type(arg) == "string" then
            return arg .. " hello"
        else
            return nil, "invalid parameter"
        end
    end

    local result, err = test(arg)
    if not result then
        -- If the first return value is nil, an error occurred
        cc.printerror(err)
    else
        ...
    end
    ~~~

<br />


## define the module

A module is a single `.lua` file and can be loaded with the `require()` or `cc.import()` functions.

Modules must be defined as a `local` `table`, and `return` the `table` at the end of the `.lua` file. E.g:

~~~lua
-- external references
local string_format = string.format

-- declare a module
local _M = {}

-- private function references
local _concat

-- exports API
function _M.say(name)
    print(_concat("hello", name))
end

-- private

_concat = function(str1, str2)
    return string_format("%s, %s", str1, str2)
end

-- return the module
return _M
~~~

specification:

- Add external references at the top of the source code
- use `_M` as the `table` defining the module
- All interfaces that need to be exported are defined as `function` of `_M`
- If they are variables and functions that are only used inside a module, they are all defined as `local`
- Internal functions are defined in the form previously referenced, then implement the function after `--private`

<br />


## define class

Classes are defined in modules. E.g:

~~~lua
local gbc = cc.import("#gbc")
local HelloAction = cc.class("HelloAction", gbc.ActionBase)

function HelloAction:sayAction(args)
    ...
end

return HelloAction
~~~

Classes in modules follow the same conventions as module definitions.

<br />


## HTTP/WebSocket external interface

In GBC, the naming rules for interfaces are as follows:

- Interfaces (referred to as `action` elsewhere in the documentation) are always named in all lowercase.
- `action` is separated by the `.` symbol and has at least two parts. For example `hello.say`, `user.signin`
- `action` can consist of more than two parts. For example `game.battle.attack`
- In `action`, the last part separated by `.` is `action function`.
- In `action`, the penultimate part separated by `.` is `action module`.
- In `action`, the other part separated by `.` is `directory`.

`action module` corresponds to an interface class:

- The name of the interface class is `action module` followed by `Action` in capital letters. For example, the interface class name corresponding to the `hello.say` interface is `HelloAction`.

`action function` corresponds to an interface function:

- The name of the interface function is `action function` plus `Action`. For example, the interface function name corresponding to the `hello.say` interface is `sayAction()`.

Other rules:

- The interface class needs to be placed in a `.lua` file with the same name.
- The interface class must be an inherited class of `gbc.ActionBase`.
- The interface class must explicitly define the types of requests that the interface can accept through the `ACCEPTED_REQUEST_TYPE` field.
- Interface classes must be placed in the application's `actions/` directory.

So the `hello.say` interface is to call the `sayAction()` function of the application `<APP_ROOT>/actions/HelloAction.lua` from the client.

If the interface name contains a `directory` part, the interface file also needs to be placed in the corresponding directory. For example: `game.battle.attack` corresponds to `<APP_ROOT>/actions/game/BattleAction.lua` file.

Interface class example:

~~~lua
local gbc = cc.import("#gbc")
local HelloAction = cc.class("HelloAction", gbc.ActionBase)

HelloAction.ACCEPTED_REQUEST_TYPE = {"http", "websocket"}

function HelloAction:init()
    self._number = math.random()
end

function HelloAction:sayAction(args)
    local username = args.username
    return {text = string.format("%s say %s", username, tostring(self._number))}
end

return HelloAction
~~~

illustrate:

- When a client requests any of the interfaces of `hello.????`, an instance of the `HelloAction` class is constructed.
- `ACCEPTED_REQUEST_TYPE` can be a single request type string, or a `table` containing multiple request types.
- `init()` function will be called after the interface class is constructed, you can do some initialization work here.
- The `sayAction()` function will be called when the client requests `hello.say`.
- The interface function has only one parameter, the type is `table`, which saves all the data contained in the request.

Summarize:

- When `hello.say` is requested, the `<APP_ROOT>/actions/HelloAction.lua` file will be loaded first. Then create an instance of the `HelloAction` object defined in it, and finally call the `sayAction()` function.
- When `game.battle.attack` is requested, the `<APP_ROOT>/actions/game/BattleAction.lua` file is loaded first. Then create an instance of the `BattleAction` object defined in it, and finally call the `attackAction()` function.

<br />


## Delay task interface

The definition rules for the delayed task interface and the HTTP/WebSocket interface differ only in the following ways:

- Interface classes are placed in the `<APP_ROOT>/jobs` directory by default.

<br />


## command line interface

The rules for defining the command line interface and the HTTP/WebSocket interface have only the following differences:

- Interface classes are placed in the `<APP_ROOT>/commands` directory by default.

\-EOF\-
