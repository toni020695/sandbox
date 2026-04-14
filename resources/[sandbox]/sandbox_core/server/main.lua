local worldState = {
    weather = Config.World.defaultWeather,
    hour = Config.World.defaultHour,
    minute = Config.World.defaultMinute
}
local actionCooldownMs = 3000
local actionCooldowns = {
    weather = {},
    time = {},
    commandWeather = {},
    commandTime = {}
}

local allowedWeather = {}
for _, weather in ipairs(Config.WeatherTypes) do
    allowedWeather[weather.value] = true
end

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function normalizeWeather(weatherName)
    local normalized = tostring(weatherName or ""):upper()
    if allowedWeather[normalized] then
        return normalized
    end

    return nil
end

local function nowMs()
    return GetGameTimer()
end

local function isRateLimited(sourceId, bucketName)
    if sourceId <= 0 then
        return false
    end

    local bucket = actionCooldowns[bucketName]
    if not bucket then
        return false
    end

    local currentTime = nowMs()
    local nextAllowedAt = bucket[sourceId] or 0
    if currentTime < nextAllowedAt then
        local remainingSeconds = math.ceil((nextAllowedAt - currentTime) / 1000)
        TriggerClientEvent("chat:addMessage", sourceId, {
            color = { 255, 175, 75 },
            args = { "Sandbox", ("Bitte warte %ds, bevor du das erneut nutzt."):format(remainingSeconds) }
        })
        print(("[sandbox_core] Rate limit hit (%s) by player %d"):format(bucketName, sourceId))
        return true
    end

    bucket[sourceId] = currentTime + actionCooldownMs
    return false
end

local function broadcastWorldState(target)
    TriggerClientEvent("sandbox:applyWorldState", target or -1, worldState)
end

RegisterNetEvent("sandbox:requestWorldState", function()
    local sourceId = source
    broadcastWorldState(sourceId)
end)

RegisterNetEvent("sandbox:updateWeather", function(newWeather)
    local sourceId = source
    if isRateLimited(sourceId, "weather") then
        return
    end

    local weather = normalizeWeather(newWeather)
    if not weather then
        return
    end

    worldState.weather = weather
    broadcastWorldState(-1)
end)

RegisterNetEvent("sandbox:updateTime", function(hour, minute)
    local sourceId = source
    if isRateLimited(sourceId, "time") then
        return
    end

    local parsedHour = tonumber(hour)
    local parsedMinute = tonumber(minute)
    if not parsedHour or not parsedMinute then
        return
    end

    worldState.hour = clamp(math.floor(parsedHour), 0, 23)
    worldState.minute = clamp(math.floor(parsedMinute), 0, 59)
    broadcastWorldState(-1)
end)

RegisterCommand("sandboxweather", function(sourceId, args)
    if isRateLimited(sourceId, "commandWeather") then
        return
    end

    local weather = normalizeWeather(args[1])
    if not weather then
        if sourceId > 0 then
            TriggerClientEvent("chat:addMessage", sourceId, {
                color = { 255, 75, 75 },
                args = { "Sandbox", "Ungültiges Wetter. Nutze das Menü oder einen gültigen Wettertyp." }
            })
        else
            print("[sandbox_core] Invalid weather type.")
        end
        return
    end

    worldState.weather = weather
    broadcastWorldState(-1)
end, false)

RegisterCommand("sandboxtime", function(sourceId, args)
    if isRateLimited(sourceId, "commandTime") then
        return
    end

    local parsedHour = tonumber(args[1] or "")
    local parsedMinute = tonumber(args[2] or "")
    if not parsedHour or not parsedMinute then
        if sourceId > 0 then
            TriggerClientEvent("chat:addMessage", sourceId, {
                color = { 255, 75, 75 },
                args = { "Sandbox", "Syntax: /sandboxtime <stunde 0-23> <minute 0-59>" }
            })
        else
            print("[sandbox_core] Usage: sandboxtime <hour> <minute>")
        end
        return
    end

    worldState.hour = clamp(math.floor(parsedHour), 0, 23)
    worldState.minute = clamp(math.floor(parsedMinute), 0, 59)
    broadcastWorldState(-1)
end, false)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    broadcastWorldState(-1)
end)

AddEventHandler("playerDropped", function()
    local sourceId = source
    actionCooldowns.weather[sourceId] = nil
    actionCooldowns.time[sourceId] = nil
    actionCooldowns.commandWeather[sourceId] = nil
    actionCooldowns.commandTime[sourceId] = nil
end)
