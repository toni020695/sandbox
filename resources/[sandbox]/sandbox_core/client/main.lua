local isMenuOpen = false
local isInvincible = false
local hasUnlimitedAmmo = false
local pedModels = {}
local lastSpawnedVehicle = 0
local lastTrackedWeapon = 0
local worldState = {
    weather = Config.World.defaultWeather,
    hour = Config.World.defaultHour,
    minute = Config.World.defaultMinute
}

local trackedWeaponModels = {
    "weapon_knife",
    "weapon_nightstick",
    "weapon_hammer",
    "weapon_bat",
    "weapon_golfclub",
    "weapon_crowbar",
    "weapon_bottle",
    "weapon_dagger",
    "weapon_hatchet",
    "weapon_knuckle",
    "weapon_machete",
    "weapon_flashlight",
    "weapon_switchblade",
    "weapon_poolcue",
    "weapon_wrench",
    "weapon_battleaxe",
    "weapon_stone_hatchet",
    "weapon_pistol",
    "weapon_pistol_mk2",
    "weapon_combatpistol",
    "weapon_appistol",
    "weapon_pistol50",
    "weapon_snspistol",
    "weapon_snspistol_mk2",
    "weapon_heavypistol",
    "weapon_vintagepistol",
    "weapon_marksmanpistol",
    "weapon_revolver",
    "weapon_revolver_mk2",
    "weapon_doubleaction",
    "weapon_ceramicpistol",
    "weapon_navyrevolver",
    "weapon_gadgetpistol",
    "weapon_stungun",
    "weapon_flaregun",
    "weapon_microsmg",
    "weapon_smg",
    "weapon_smg_mk2",
    "weapon_assaultsmg",
    "weapon_combatpdw",
    "weapon_machinepistol",
    "weapon_minismg",
    "weapon_pumpshotgun",
    "weapon_pumpshotgun_mk2",
    "weapon_sawnoffshotgun",
    "weapon_assaultshotgun",
    "weapon_bullpupshotgun",
    "weapon_musket",
    "weapon_heavyshotgun",
    "weapon_dbshotgun",
    "weapon_autoshotgun",
    "weapon_combatshotgun",
    "weapon_assaultrifle",
    "weapon_assaultrifle_mk2",
    "weapon_carbinerifle",
    "weapon_carbinerifle_mk2",
    "weapon_advancedrifle",
    "weapon_specialcarbine",
    "weapon_specialcarbine_mk2",
    "weapon_bullpuprifle",
    "weapon_bullpuprifle_mk2",
    "weapon_compactrifle",
    "weapon_militaryrifle",
    "weapon_heavyrifle",
    "weapon_tacticalrifle",
    "weapon_mg",
    "weapon_combatmg",
    "weapon_combatmg_mk2",
    "weapon_gusenberg",
    "weapon_sniperrifle",
    "weapon_heavysniper",
    "weapon_heavysniper_mk2",
    "weapon_marksmanrifle",
    "weapon_marksmanrifle_mk2",
    "weapon_precisionrifle",
    "weapon_rpg",
    "weapon_grenadelauncher",
    "weapon_grenadelauncher_smoke",
    "weapon_minigun",
    "weapon_firework",
    "weapon_railgun",
    "weapon_hominglauncher",
    "weapon_compactlauncher",
    "weapon_rayminigun",
    "weapon_grenade",
    "weapon_bzgas",
    "weapon_smokegrenade",
    "weapon_flare",
    "weapon_molotov",
    "weapon_stickybomb",
    "weapon_proxmine",
    "weapon_snowball",
    "weapon_pipebomb",
    "weapon_ball",
    "weapon_petrolcan",
    "weapon_fireextinguisher",
    "weapon_parachute"
}
local trackedWeaponHashes = {}
for _, weaponModel in ipairs(trackedWeaponModels) do
    trackedWeaponHashes[#trackedWeaponHashes + 1] = joaat(weaponModel)
end

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

local function deleteVehicleIfExists(vehicle)
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
end

local function capturePedWeapons(ped)
    local weapons = {}
    local _, currentWeaponHash = GetCurrentPedWeapon(ped, true)

    for _, weaponHash in ipairs(trackedWeaponHashes) do
        if HasPedGotWeapon(ped, weaponHash, false) then
            weapons[#weapons + 1] = {
                hash = weaponHash,
                ammo = GetAmmoInPedWeapon(ped, weaponHash),
                isCurrent = currentWeaponHash == weaponHash
            }
        end
    end

    return weapons
end

local function restorePedWeapons(ped, weapons)
    for _, weaponData in ipairs(weapons) do
        GiveWeaponToPed(ped, weaponData.hash, weaponData.ammo, false, weaponData.isCurrent == true)
        SetPedAmmo(ped, weaponData.hash, weaponData.ammo)
    end
end

local function setInfiniteAmmoForCurrentWeapon(enabled)
    local ped = PlayerPedId()
    local _, currentWeapon = GetCurrentPedWeapon(ped, true)
    SetPedInfiniteAmmoClip(ped, enabled)

    if currentWeapon and currentWeapon ~= 0 then
        SetPedInfiniteAmmo(ped, enabled, currentWeapon)
        lastTrackedWeapon = currentWeapon
    elseif not enabled then
        lastTrackedWeapon = 0
    end
end

local function spawnVehicle(modelName)
    local ped = PlayerPedId()
    local modelHash = joaat(modelName)

    if not requestModel(modelHash) then
        notify(("~r~Ungültiges Fahrzeugmodell: %s"):format(modelName))
        return
    end

    local currentVehicle = 0
    if IsPedInAnyVehicle(ped, false) then
        currentVehicle = GetVehiclePedIsIn(ped, false)
    end

    if currentVehicle ~= 0 and GetPedInVehicleSeat(currentVehicle, -1) == ped then
        deleteVehicleIfExists(currentVehicle)
        if currentVehicle == lastSpawnedVehicle then
            lastSpawnedVehicle = 0
        end
    end

    if lastSpawnedVehicle ~= 0 then
        deleteVehicleIfExists(lastSpawnedVehicle)
        lastSpawnedVehicle = 0
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
        lastSpawnedVehicle = vehicle
        notify(("~g~Fahrzeug gespawnt: %s"):format(modelName))
    else
        lastSpawnedVehicle = 0
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
    local savedWeapons = capturePedWeapons(oldPed)

    if not requestModel(pedHash) then
        notify("~r~Ped-Modell konnte nicht geladen werden.")
        return
    end

    SetPlayerModel(playerId, pedHash)
    SetModelAsNoLongerNeeded(pedHash)
    Wait(50)

    local newPed = PlayerPedId()
    SetEntityCoordsNoOffset(newPed, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(newPed, heading)
    SetPedDefaultComponentVariation(newPed)
    SetEntityHealth(newPed, math.max(health, 100))
    SetPedArmour(newPed, armour)
    restorePedWeapons(newPed, savedWeapons)

    if isInvincible then
        SetEntityInvincible(newPed, true)
        SetPlayerInvincible(playerId, true)
    end

    if hasUnlimitedAmmo then
        setInfiniteAmmoForCurrentWeapon(true)
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
        setInfiniteAmmoForCurrentWeapon(hasUnlimitedAmmo)
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

    if hasUnlimitedAmmo then
        setInfiniteAmmoForCurrentWeapon(true)
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
        Wait(500)

        if not hasUnlimitedAmmo then
            goto continue
        end

        local ped = PlayerPedId()
        local _, currentWeapon = GetCurrentPedWeapon(ped, true)
        if currentWeapon and currentWeapon ~= 0 and currentWeapon ~= lastTrackedWeapon then
            SetPedInfiniteAmmoClip(ped, true)
            SetPedInfiniteAmmo(ped, true, currentWeapon)
            lastTrackedWeapon = currentWeapon
        end

        ::continue::
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
