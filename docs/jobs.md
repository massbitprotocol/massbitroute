# Delayed tasks and scheduled tasks

In the game, there will be a lot of operations that need to be delayed or timed. For example, it takes 2 hours for the departing troops to reach their destination.

For such operations, GBC provides the `Jobs` interface to handle. Let's take a look at the basic usage first:

~~~lua
-- Barracks module
local gbc = cc.import("#gbc")
local BarrackAction = cc.class("BarrackAction", gbc.ActionBase)

-- interface for sending troops
function BarrackAction:sentAction(arg)
    -- These data will be included in the task and passed to the specified interface when the task time arrives
    local data = {
        troops   = "knight",
        quantity = 30,
        level    = 2,
    }

    -- Get the jobs interface and add tasks
    local jobs = self:getInstance():getJobs()
    jobs:add({
        action = 'battle.arrival', -- the task is passed to battle.arrival
        data = data, -- data to pass to the task interface
        delay = 10, -- delay task execution for 10 seconds
    })
end

return BarrackAction
~~~

When the `barrack.sent` interface is called, a delayed task is added to the system.

After the specified time arrives, the system will call the `battle.arrival` interface specified by the task.

~~~lua
local gbc = cc.import("#gbc")
local BattleAction = cc.class("BattleAction", gbc.ActionBase)

BattleAction.ACCEPTED_REQUEST_TYPE = "worker" -- specifies that this interface is only used for Job background tasks

function BattleAction:arrivalAction(job)
    -- The entire task will be passed into the interface as a parameter

    print(job.delay) -- the waiting time set by the task
    print(job.pri) -- the priority set by the task
    print(job.ttr) -- task execution time limit

    -- The data provided in barrack.sent will be used as the job.data parameter
    local troops   = job.data.troops
    local quantity = job.data.quantity
    local level    = job.data.level

    ...
end

return BattleAction
~~~

**Note**: The `BattleAction.lua` file must be placed in the application's `jobs` directory.

1. The important thing to say three times: The interface file of the Job must be placed in the `jobs` directory of the application.
2. The important thing is said three times: The interface file of the Job must be placed in the `jobs` directory of the application.
3. The important thing to say three times: The interface file of the Job must be placed in the `jobs` directory of the application.


## task execution result

After the task interface is executed, it cannot directly return the result to the interface that adds the task. So the task interface should write the execution result to the database, or notify the client through the message interface.

If an error occurs in task execution, the following two methods are recommended:

1. Return `false` to indicate that the task execution failed and the task will be started again. Usually, this method can be used when there are some data write conflicts, and the system can automatically re-execute the task.

2. Add a log, delete the task, and return `false`. Since the task has been deleted, it will not be restarted. However, GBC will record the task situation that returns `false` to the log for query.

During the execution of the task, if the functions that interrupt the execution, such as `error()` and `throw()`, are called, the task will be re-executed.


## Jobs: provided interface

### `Jobs:add()` - add a delayed job

illustrate:

- `Jobs:add(args)`: `arg` is a table with the following fields:
    - `action`: which interface to call when the task expires
    - `data`: the data to be passed to the task interface, must be a `table`
    - `delay`: the waiting time of the task
    - `pri`: (optional) The priority of the task. The smaller the number, the higher the priority. The default is 2048, which means the normal priority. Priority levels below 1024 indicate urgent tasks. Tasks with the same delay time will be executed first with higher priority.
    - `ttr`: (optional) How much time the task interface can take to process the task. Default is 10 seconds. If the task is not processed within the specified time, the task will be re-queued. Therefore, for tasks that may take a long time, a larger `ttr` value should be specified.

`add()` will return an integer as `JobId` if successful. You can use `JobId` to remove the job or suspend the job later.

If `add()` fails, it will return `nil` and an error message, which can be determined by the following code:

~~~lua
local jobid, err = jobs:add(....)
if not jobid then
    -- do error handling
    print(err)
end
~~~


### `Jobs:at()` - add a cron job

illustrate:

- `Jobs:at(arg)`: `arg` is a `table`, only the `delay` field is changed to a `time` field compared to the `add()` interface:
    - `time`: The number of seconds since 1970, specifying the time the task will execute.
    - Other parameters and return values ​​are the same as the `Jobs:add()` interface.

Due to timezone issues, you can get the seconds (UTC) of a specified time with the following code:

~~~lua
local time = os.gettime({2015, 12, 24, 22, 30})
~~~

PS: The `os.gettime()` function is a custom function provided by GBC, not a standard library function.


### `Jobs:delete()` - delete a job

illustrate:

-   `Jobs:delete(jobid)`
    - `jobid`: The `JobId` of the job to delete, returned by the `Jobs:add()` and `Jobs:at()` interfaces.

`delete()` returns `true` if successful, `nil` and an error message otherwise.


### `Jobs:get()` - Query a job

illustrate:

-   `Jobs:get(jobid)`
    - `jobid`: If the specified job has not been deleted, return a `table` containing all job information:

~~~lua
local job, err = jobs:get(jobid)
if not job then
    -- do error handling
    print(err)
else
    -- print job content
    print(job.id)
    print(job.action)
    print(job.delay)
    print(job.pri)
    print(job.ttr)
    cc.dump(job.data)
end
~~~

Returns `nil` and an error message if the specified task does not exist.


### `Jobs:getready()` - Query a job that has reached the specified time, if there is no job, wait until the timeout

illustrate:

-   `Jobs:getready()`

`getready()` If successful, returns a `table`, the same as `get()`. On failure, `nil` and an error message are returned.
