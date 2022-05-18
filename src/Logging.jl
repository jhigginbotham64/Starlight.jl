#
# Author: https://github.com/Clemapfel/
#

"""
logging utilities, safe in concurrent environments

# Basic Usage

There are 4 types of log message levels:

### Log / Info

To send a simple log message, similar to `Base.@info`, use `Log.@log` called with any number
of strings. These will be concatenated, similar to `Base.println`.

### Warning

To send a warning, use `Log.@warning`. The message will be displayed in yellow and should be
reserved to non-critical issues raised during execution.

### Errors

To send a critical error message, use `Log.@error`. This message will be displayed in red
and contains a stacktrace. It does not raise an actual exception, users are encouraged to
manually do so immediately proceeding the `Log.@error` call.

### Debug

To send debug messages, use `Log.@debug`. These message will not be displayed or logged,
unless `Log.set_debug_enabled(true)` was called before.

# Logging To Files

You can tell `Log` to write all its messages to a file (instead of `stdout`) by calling

```julia
Log.init("/path/to/file.log")
```

Where `"path/to/file.log"` is the log file. If it does not exist yet, it will be created. If the
file already contains text, it will be cleared and overridden.

By default, the output is in human readable form. To switch to csv (comma separated values),
instead call `Log.init("/path/to/file.log", CSV)`.

At the end of execution, call `Log.quit()` to safely close the logging environment. If the application
crashes or otherwise quits unexpectedly, all already logged message will still be in the file.
"""
module Log

    """
    enum of formatting options, decides additional log contents

    ## Values
    - `LABEL`: addes type of log message (`LOG`, `WARNING`, `EXCEPTION`, `ERROR`) as label
    - `TIMESTAMP`: adds a timestamp of the form "<hour>:<minute>:<second>"
    - `DATESTAMP`: adds a date of the from "<day>/<month>"
    - `THREADID`: native handle of current thread
    """
    @enum FormattingOptions begin
        LABEL      # print label
        TIMESTAMP  # print current time
        DATESTAMP  # print current date
        THREADID   # print id of thread write was called from
    end
    export FormattingOptions
    export LABEL
    export TIMESTAMP
    export DATESTAMP
    export THREADID

    """
    enum of formatting modes, decides the general structue of log message strings

    ## Values
    - `PRETTY`: human readable output, colored if writing to stdout
    - `CSV`: format output as CSV
    """
    @enum FormattingMode begin
        PRETTY
        CSV
    end
    export FormattingMode
    export PRETTY
    export CSV

    """
    enum of message types, if in PRETTY mode, type influences color of the message

    ## Values
    - `LOG`: grey text with `[LOG]` prefix
    - `WARNING`: yellow text with `[WARNING]` prefix
    - `EXCEPTION`: red text with `[EXCEPTION]` prefix
    - `ERROR`: blinking red text with `[ERROR]` prefix
    """
    @enum MessageType begin
        LOG
        WARNING
        EXCEPTION
        DEBUG
    end
    export MessageType
    export LOG
    export WARNING
    export EXCEPTION
    export DEBUG

    """
    internal implementation details, end-users should not interact with anything in this module
    """
    #module detail

        using Dates
        using Test
        using DataStructures

        const _init_lock = Base.ReentrantLock()
        _mode = Log.PRETTY
        _options = Log.FormattingOptions[LABEL, TIMESTAMP]

        _debug_enabled = false

        const _task_storage = Queue{Task}()
        const _task_storage_lock = Base.ReentrantLock()

        _stream = stdout
        const _stream_lock = Base.ReentrantLock()

        const _csv_delimiter = ","
        _csv_header = ""
        const _initialization_message = "Logging initialized"
        const _shutdown_message = "Logging shutdown"

        const _log_label = "LOG"
        const _warning_label = "WARNING"
        const _exception_label = "FATAL"
        const _debug_label = "DEBUG"

        const _log_color = :cyan
        const _warning_color = :light_yellow
        const _exception_color = :light_red
        const _debug_color = :magenta
        const _other_color = :light_black

        """
        `append(type::MessageType, message::String) -> Nothing`

        append a message to the log stream

        ## Arguments
        + `type`: Message Type
        + `message`: raw string
        """
        function append(type::MessageType, message::String) ::Nothing

            if type == DEBUG && !_debug_enabled
                return
            end

            lock(_task_storage_lock)

            # cleanup finished tasks
            while !isempty(_task_storage) && istaskdone(first(_task_storage))
                dequeue!(_task_storage)
            end

            enqueue!(_task_storage, Task(() -> begin

                out::String = ""
                m = deepcopy(message)
                now = Dates.now()

                function add_zero(num) ::String
                    out = ""
                    if num < 10 out *= "0" end
                    return out * string(num)
                end

                if _mode == CSV

                    # type
                    if LABEL in _options
                        out *= string(type) * _csv_delimiter
                    end

                    # day, month
                    if DATESTAMP in _options
                        out *= string(Dates.day(now)) * _csv_delimiter
                        out *= string(Dates.month(now)) * _csv_delimiter
                    end

                    # time
                    if TIMESTAMP in _options
                        out *= string(Dates.format(Dates.now(), DateFormat("H:M:S.MS"))) * _csv_delimiter
                    end

                    # thread_id
                    if THREADID in _options
                        out *= string(Threads.threadid()) * _csv_delimiter
                    end

                    # message
                    out *= message * "\n"

                    @lock _stream_lock begin
                        Base.write(_stream, out)
                        flush(_stream)
                    end

                elseif _mode == PRETTY

                    if LABEL in _options

                        if !(_stream isa IOBuffer)

                            if type == LOG
                                printstyled(_stream, "[" * _log_label * "]", color=_log_color)
                            elseif type == WARNING
                                printstyled(_stream, "[" * _warning_label * "]", color=_warning_color)
                            elseif type == EXCEPTION
                                printstyled(_stream, "[" * _exception_label * "]", color=_exception_color)
                            elseif type == DEBUG
                                printstyled(_stream, "[" * _debug_label * "]", color=_debug_color)
                            end
                        else

                            if type == LOG
                                out *= "[" * _log_label * "]"
                            elseif type == WARNING
                                out *= "[" * _warning_label * "]"
                            elseif type == EXCEPTION
                                out *= "[" * _exception_label * "]"
                            elseif type == DEBUG
                                out *= "[" * _debug_label * "]"
                            end
                        end
                    end

                    if TIMESTAMP in _options || DATESTAMP in _options

                        out *= "["

                        if DATESTAMP in _options
                            out *= add_zero(Dates.day(now)) * "."
                            out *= add_zero(Dates.month(now)) * "-"
                        end

                        if DATESTAMP in _options && TIMESTAMP in _options
                           out *= "|"
                        end

                        if TIMESTAMP in _options
                           out *= add_zero(Dates.hour(now)) * ":"
                            out *= add_zero(Dates.minute(now)) * ":"
                            out *= add_zero(Dates.second(now))
                        end

                        out *= "]"
                    end

                    if THREADID in _options
                        out *= "[" * Threads.threadid() * "]"
                    end

                    if length(_options) >= 1 # more than one char left of the message
                        out *= " "
                    end

                    printstyled(_stream, out, color=_other_color)
                    print(_stream, m * "\n")
                    flush(_stream)
                end
            end))

            # when running non-concurrently, immediately evaluate in main
            if Threads.nthreads() == 1
                schedule(last(_task_storage))
                wait(last(_task_storage))
            else
                last(_task_storage).sticky = false
                schedule(last(_task_storage))
            end

            unlock(_task_storage_lock)
            return nothing
        end
        # no export

        """
        `test() -> Nothing`

        testset of module `Log`
        """
        function test() ::Nothing

            Test.@testset "Logging" begin

                try

                Log.init(Base.Filesystem.pwd() * "/_.log", CSV, [Log.TIMESTAMP, Log.DATESTAMP, Log.THREADID])

                Test.@test Base.Filesystem.isfile(Log._stream)
                Test.@test isopen(Log._stream)

                Log.write("test line")
                Log.quit()
                Test.@test !isopen(Log._stream)

                file = open(Base.Filesystem.pwd() * "/_.log", read=true)

                Test.@test occursin(_csv_header, readline(file, keep=true))
                Test.@test occursin(Log._initialization_message, readline(file))
                Test.@test occursin("test line", readline(file))

                finally Base.Filesystem.rm(Base.Filesystem.pwd() * "/_.log") end
            end
            return nothing
        end
        # no export
    #end

    """
    `write(xs::Any...; [message_type::MessageType]) -> Nothing`

    write to the log stream. If julia was initialized with more than 1 thread,
    writing is concurrent and does not pause the main thread.

    ## Arguments
    + `xs`: any number of objects, will be converted to strings, similar to Base.print
    + `message_type`: [optional] one of `LOG`, `WARNING`, `EXCEPTION`, `ERROR`
    """
    function write(xs...; type::MessageType = LOG)

        if length(xs) == 1 && string(getindex(xs, 1)) == ""
            return nothing
        end

        append(type, prod(string.([xs...])))
        yield()
    end
    export write

    """
    `initialize([path::String], [mode::FormattingMode], [options::Vector{FormattingOptions}]) -> Bool`

    initialize the logging environment

    ## Arguments
    + `path`: [optional] path of the log output file, or `""` if the log should write to stdout instead
    + `mode`: [optional] `PRETTY` for human-readable output, `CSV` for csv output with delimiter `,`
    + `options`: [optional] vector of FormattingOptions. Vector may contain:
        - `LABEL` for type of message, such as `[LOG]`, `[WARNING]`, etc.
        - `TIMESTAMP` time in `Y:M:S` format if in `PRETTY` mode, `Y:M:S.MS` if in `CSV` mode
        - `DATESTAMP` current day and month
        - `THREADID` native handle of the thread `Log.write` is called from

    ## Returns
    `true` if initialization was successful, `false` otherwise
    """
    function init(
        path::String = "",
        mode::FormattingMode = PRETTY,
        options::Vector{FormattingOptions} = (path == "" ? [LABEL] : [LABEL, DATESTAMP, TIMESTAMP])
    ) ::Bool

        @lock _init_lock begin

            if path != ""
                eval(:(_stream = open($path, append=true, truncate=true)))
            else
                eval(:(_stream = stdout))
            end

            eval(:(_mode = $mode))
            eval(:(_options = $options))

            if mode == CSV

                csv_header = ""

                if LABEL in options
                    csv_header *= "type" * _csv_delimiter
                end

                if DATESTAMP in options
                   csv_header *= "day" * _csv_delimiter
                   csv_header *= "month" * _csv_delimiter
                end

                if TIMESTAMP in options
                    csv_header *= "time" * _csv_delimiter
                end

                if THREADID in options
                    csv_header *= "thread_id" * _csv_delimiter
                end

                csv_header *= "message" * "\n"

                eval(:(_csv_header = $csv_header))
            end
        end

        out = isopen(_stream)

        if !out
           Log.write("in Log.init(" * path * ") : initialization failed.")
        else
            if mode == CSV
                Base.write(_stream, _csv_header)
            end
            Log.write(_initialization_message)
        end
        return out
    end
    export init

    """
    `quit() -> Bool`

    safely exist the logging environment

    ## Returns
    `true` if shutdown was successful, false otherwise
    """
    function quit() ::Bool

        for task in _task_storage
            wait(task)
        end
        Log.write(_shutdown_message)

        try
            lock(_task_storage_lock)
            lock(_init_lock)

            for task in _task_storage
                wait(task)
            end

            empty!(_task_storage)

            if _stream isa IOStream
                close(_stream)
            end

            return true
        catch (_)
            return false
        end
    end

    """
    `set_debug_enabled(::Bool) -> Nothing`

    enabled debug mode, unless specifically enabled, all
    logging with type=DEBUG will not be printed or appended to the log file
    """
    function set_debug_enabled(value::Bool)

        lock(_init_lock)
        if value
            Log.write("Debug logging enabled", type=LOG)
        else
            Log.write("Debug loggin disabled", type=LOG)
        end
        eval(:(global _debug_enabled = $value))
        unlock(_init_lock)
        return nothing
    end

    """
    `log(::Expr) -> Nothing`

    convert any arguments to strings, then print as log message
    """
    macro log(xs)
        return :(Log.write($(xs)))
    end
    export log

    """
    `warning(::Expr) -> Nothing`

    convert any arguments to strings, then print as warning message
    """
    macro warning(xs)
        return :(Log.write($(xs), type=Log.WARNING))
    end
    export warning

    """
    `debug(::Expr) -> Nothing`

    convert any arguments to strings, then print as debug message
    if `Log.set_debug_enabled(true)` was called before
    """
    macro debug(xs)
        return :(Log.write($(xs), type=Log.DEBUG))
    end
    export debug

    """
    `error(::Expr) -> Nothing`

    write to the log and print stacktrace, does not actually raise an exception
    """
    macro error(xs)
        return :(Log.write($(xs), type=Log.EXCEPTION))
    end
end
