local select = select
local type = type
local getmetatable = getmetatable
local xpcall = xpcall
local math_floor = math.floor
local math_ceil = math.ceil

table.unpack = unpack

table.pack = function(...)
    return { n = select('#', ...), ... }
end

math.maxinteger = 0x7FFFFFFFLL
local function tointeger(x)
    if type(x) ~= "number" then
        return nil
    end

    local int = x >= 0 and math_floor(x) or math_ceil(x)

    if int == x then
        return int
    else
        return nil
    end
end

math.tointeger = tointeger

function math.type(x)
    if type(x) == "number" then
        return tointeger(x) and "integer" or "number"
    else
        return nil
    end
end

local coroutine_resume = coroutine.resume
local coroutine_status = coroutine.status
local coroutine_running = coroutine.running

local cancel_table = setmetatable({}, { __mode = 'kv' })

function coroutine.resume(co, ...)
    if cancel_table[co] then
        return false, 'cannot resume dead coroutine'
    end

    return coroutine_resume(co, ...)
end

function coroutine.status(co)
    if cancel_table[co] then
        return 'dead'
    end

    return coroutine_status(co)
end

function coroutine.close(co)
    if coroutine_status(co) == 'suspended' then
        cancel_table[co] = true
    end
end

function defer(toBeClosed, callback)
    local ctype = type(toBeClosed)
    local meta = getmetatable(toBeClosed)
    local closeCallback = nil
    local ok, result

    local co = coroutine_running()
    if coroutine.status(co) ~= 'dead' then
        ok, result = xpcall(callback, log.error)
    end

    if meta and meta.__close then
        meta.__close(toBeClosed)
    elseif ctype == 'function' then
        toBeClosed()
    end

    if ok then
        return result
    end
end
