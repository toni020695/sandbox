local isMenuOpen = false
local isInvincible = false
local hasUnlimitedAmmo = false
local pedModels = {}
local worldState = {
    weather = Config.World.defaultWeather,
    hour = Config.World.defaultHour,
    minute = Config.World.defaultMinute
}

local function notify(message)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

local function requestModel(modelHash)
    if not IsModelInCdimage(modelHash) or not IsModelValid(modelHash) then
        return false
    end

    RequestModel(modelHash)

    local attempts = 0
    while not HasModelLoaded(modelHash) and attempts < 200 do
        attempts = attempts + 1
        Wait(25)
    end

    return HasModelLoaded(modelHash)
end

local function loadPedModels()
    local rawPedList = LoadResourceFile(GetCurrentResourceName(), "shared/ped_models.txt")
    if not rawPedList then
        print("^1[sandbox_core] Missing shared/ped_models.txt^7")
        return
    end

    for line in rawPedList:gmatch("[^\r\n]+") do
        local modelName, modelHash = line:match("^([^=]+)=(-?%d+)$")
        if modelName and modelHash then
            local normalized = modelName:lower()
            if normalized ~= "mp_m_freemode_01" and normalized ~= "mp_f_freemode_01" then
                pedModels[#pedModels + 1] = {
                    label = modelName,
                    hash = tonumber(modelHash)
                }
            end
        end
    end

    table.sort(pedModels, function(a, b)
        return a.label < b.label
    end)
end

local function getPedModelsForUI()
    local maxItems = Config.MaxPedListForUI or #pedModels
    if maxItems >= #pedModels then
        return pedModels
    end

    local sliced = {}
    for i = 1, maxItems do
        sliced[#sliced + 1] = pedModels[i]
    end

    return sliced
end

local function setMenuState(enabled)
    isMenuOpen = enabled
    SetNuiFocus(enabled, enabled)
    SetNuiFocusKeepInput(false)

    if enabled then
        SendNUIMessage({
            type = "openMenu",
            payload = {
                title = Config.MenuTitle,
                vehicles = Config.VehiclePresets,
                weapons = Config.Weapons,
                weather = Config.WeatherTypes,
                times = Config.TimePresets,
                peds = getPedModelsForUI(),
                pedCount = #pedModels,
                world = worldState,
                toggles = {
                    invincible = isInvincible,
                    unlimitedAmmo = hasUnlimitedAmmo
                }
            }
        })
    else
        SendNUIMessage({ type = "closeMenu" })
    end
end

local function toggleMenu()
    setMenuState(not isMenuOpen)
end

local function spawnVehicle(modelName)
    local ped = PlayerPedId()
    local modelHash = joaat(modelName)

    if not requestModel(modelHash) then
        notify(("~r~Ungültiges Fahrzeugmodell: %s"):format(modelName))
        return
    end

    local pedCoords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnCoords = vector3(
        pedCoords.x + forward.x * 6.0,
        pedCoords.y + forward.y * 6.0,
        pedCoords.z + 1.0
    )

    local vehicle = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, GetEntityHeading(ped), true, false)

    if DoesEntityExist(vehicle) then
        SetVehicleOnGroundProperly(vehicle)
        SetPedIntoVehicle(ped, vehicle, -1)
        SetVehicleDirtLevel(vehicle, 0.0)
        notify(("~g~Fahrzeug gespawnt: %s"):format(modelName))
    else
        notify("~r~Fahrzeug konnte nicht erstellt werden.")
    end

    SetModelAsNoLongerNeeded(modelHash)
end

local function healPlayer()
    local ped = PlayerPedId()
    local maxHealth = GetEntityMaxHealth(ped)
    SetEntityHealth(ped, maxHealth)
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    notify("~g~Du wurdest vollständig geheilt.")
end

local function setInvincible(enabled)
    isInvincible = enabled
    local ped = PlayerPedId()
    SetEntityInvincible(ped, enabled)
    SetPlayerInvincible(PlayerId(), enabled)
    SetPedCanRagdoll(ped, not enabled)
    notify(enabled and "~g~Unverwundbarkeit aktiviert." or "~y~Unverwundbarkeit deaktiviert.")
end

local function giveWeapon(weaponModel)
    local ped = PlayerPedId()
    local weaponHash = joaat(weaponModel)

    if not IsWeaponValid(weaponHash) then
        notify(("~r~Ungültige Waffe: %s"):format(weaponModel))
        return
    end

    GiveWeaponToPed(ped, weaponHash, 500, false, true)
    notify(("~g~Waffe erhalten: %s"):format(weaponModel))
end

local function giveAllWeapons()
    for _, weapon in ipairs(Config.Weapons) do
        GiveWeaponToPed(PlayerPedId(), joaat(weapon.model), 500, false, false)
    end
    notify("~g~Alle Sandbox-Waffen wurden gegeben.")
end

local function setPlayerPedModel(pedHash, label)
    local playerId = PlayerId()
    local oldPed = PlayerPedId()
    local coords = GetEntityCoords(oldPed)
    local heading = GetEntityHeading(oldPed)
    local health = GetEntityHealth(oldPed)
    local armour = GetPedArmour(oldPed)

    if not requestModel(pedHash) then
        notify("~r~Ped-Modell konnte nicht geladen werden.")
        return
    end

    SetPlayerModel(playerId, pedHash)
    SetModelAsNoLongerNeeded(pedHash)

    local newPed = PlayerPedId()
    SetEntityCoordsNoOffset(newPed, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(newPed, heading)
    SetPedDefaultComponentVariation(newPed)
    SetEntityHealth(newPed, math.max(health, 100))
    SetPedArmour(newPed, armour)

    if isInvincible then
        SetEntityInvincible(newPed, true)
        SetPlayerInvincible(playerId, true)
    end

    notify(("~g~Ped gesetzt: %s"):format(label))
end

RegisterNetEvent("sandbox:applyWorldState", function(newState)
    if type(newState) ~= "table" then
        return
    end

    if newState.weather ~= nil then
        worldState.weather = newState.weather
    end
    if newState.hour ~= nil then
        worldState.hour = newState.hour
    end
    if newState.minute ~= nil then
        worldState.minute = newState.minute
    end

    if isMenuOpen then
        SendNUIMessage({
            type = "worldState",
            payload = worldState
        })
    end
end)

RegisterNUICallback("closeMenu", function(_, cb)
    setMenuState(false)
    cb({ ok = true })
end)

RegisterNUICallback("action", function(data, cb)
    local action = data.action
    local payload = data.payload or {}

    if action == "spawnVehicle" then
        local modelName = tostring(payload.model or "")
        if modelName ~= "" then
            spawnVehicle(modelName)
        end
    elseif action == "healPlayer" then
        healPlayer()
    elseif action == "setInvincible" then
        setInvincible(payload.enabled == true)
    elseif action == "setUnlimitedAmmo" then
        hasUnlimitedAmmo = payload.enabled == true
        notify(hasUnlimitedAmmo and "~g~Unlimited Ammo aktiviert." or "~y~Unlimited Ammo deaktiviert.")
    elseif action == "giveWeapon" then
        local weaponModel = tostring(payload.model or "")
        if weaponModel ~= "" then
            giveWeapon(weaponModel)
        end
    elseif action == "giveAllWeapons" then
        giveAllWeapons()
    elseif action == "setWeather" then
        local weatherType = tostring(payload.weather or ""):upper()
        if weatherType ~= "" then
            TriggerServerEvent("sandbox:updateWeather", weatherType)
        end
    elseif action == "setTime" then
        local hour = tonumber(payload.hour)
        local minute = tonumber(payload.minute)
        if hour and minute then
            TriggerServerEvent("sandbox:updateTime", hour, minute)
        end
    elseif action == "setPed" then
        local pedHash = tonumber(payload.hash)
        local label = tostring(payload.label or "Ped")
        if pedHash then
            setPlayerPedModel(pedHash, label)
        end
    end

    cb({ ok = true })
end)

RegisterCommand(Config.OpenCommand, function()
    toggleMenu()
end, false)

RegisterCommand(Config.KeybindCommand, function()
    toggleMenu()
end, false)

RegisterKeyMapping(Config.KeybindCommand, "Open Sandbox Menu", "keyboard", Config.DefaultMenuKey)

CreateThread(function()
    loadPedModels()
    TriggerServerEvent("sandbox:requestWorldState")
end)

AddEventHandler("playerSpawned", function()
    TriggerServerEvent("sandbox:requestWorldState")
    if isInvincible then
        local ped = PlayerPedId()
        SetEntityInvincible(ped, true)
        SetPlayerInvincible(PlayerId(), true)
    end
end)

CreateThread(function()
    while true do
        Wait(0)

        SetScenarioPedDensityMultiplierThisFrame(1.0, 1.0)
        SetPedDensityMultiplierThisFrame(1.0)
        SetVehicleDensityMultiplierThisFrame(1.0)
        SetRandomVehicleDensityMultiplierThisFrame(1.0)
        SetParkedVehicleDensityMultiplierThisFrame(1.0)
    end
end)

CreateThread(function()
    while true do
        Wait(1000)

        SetCreateRandomCops(true)
        SetCreateRandomCopsOnScenarios(true)
        SetCreateRandomCopsNotOnScenarios(true)
        SetDispatchCopsForPlayer(PlayerId(), true)
        SetPoliceIgnorePlayer(PlayerId(), false)

        for serviceId = 1, 15 do
            EnableDispatchService(serviceId, true)
        end

        SetWeatherTypePersist(worldState.weather)
        SetWeatherTypeNow(worldState.weather)
        SetWeatherTypeNowPersist(worldState.weather)
        NetworkOverrideClockTime(worldState.hour, worldState.minute, 0)
    end
end)

CreateThread(function()
    while true do
        Wait(0)

        if hasUnlimitedAmmo then
            local ped = PlayerPedId()
            local _, currentWeapon = GetCurrentPedWeapon(ped, true)
            SetPedInfiniteAmmoClip(ped, true)
            if currentWeapon and currentWeapon ~= 0 then
                SetPedInfiniteAmmo(ped, true, currentWeapon)
            end
        else
            local ped = PlayerPedId()
            local _, currentWeapon = GetCurrentPedWeapon(ped, true)
            SetPedInfiniteAmmoClip(ped, false)
            if currentWeapon and currentWeapon ~= 0 then
                SetPedInfiniteAmmo(ped, false, currentWeapon)
            end
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if isMenuOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 106, true)
            DisableControlAction(0, 322, true)
        else
            Wait(500)
        end
    end
end)
