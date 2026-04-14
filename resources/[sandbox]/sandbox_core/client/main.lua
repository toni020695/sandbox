local isMenuOpen = false
local isInvincible = false
local hasUnlimitedAmmo = false
local hasSuperJump = false
local hasFastRun = false
local isInvisible = false
local hasVehicleGodmode = false
local hasExplosiveAmmo = false
local hasFireAmmo = false
local hasNoReload = false
local pedModels = {}
local lastSpawnedVehicle = 0
local lastTrackedWeapon = 0
local lastShotTimestamp = 0
local bodyguards = {}
local spawnSelectionOpen = false
local hasOpenedInitialSpawn = false
local controlBlockerThreadRunning = false
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

local bodyguardPresets = (Config.Bodyguards and Config.Bodyguards.presets) or {}
local maxBodyguards = (Config.Bodyguards and Config.Bodyguards.maxCount) or 3
local fastRunMultiplier = (Config.Player and Config.Player.fastRunMultiplier) or 1.49
local spawnLocations = (Config.Spawns and Config.Spawns.locations) or {}
local openSpawnOnJoin = not (Config.Spawns and Config.Spawns.openOnJoin == false)
local openSpawnOnRespawn = not (Config.Spawns and Config.Spawns.openOnRespawn == false)

local function disableMenuControlsThisFrame()
    DisableControlAction(0, 1, true)
    DisableControlAction(0, 2, true)
    DisableControlAction(0, 24, true)
    DisableControlAction(0, 25, true)
    DisableControlAction(0, 142, true)
    DisableControlAction(0, 106, true)
    DisableControlAction(0, 322, true)
end

local function ensureControlBlockerThread()
    if controlBlockerThreadRunning then
        return
    end

    controlBlockerThreadRunning = true
    CreateThread(function()
        while isMenuOpen or spawnSelectionOpen do
            Wait(0)
            disableMenuControlsThisFrame()
        end
        controlBlockerThreadRunning = false
    end)
end

local function setPedInvisibleState(ped, enabled)
    SetEntityVisible(ped, not enabled, false)
    SetEntityAlpha(ped, enabled and 0 or 255, false)
    SetEntityCollision(ped, true, true)
    SetLocalPlayerVisibleLocally(true)
    SetEveryoneIgnorePlayer(PlayerId(), enabled)
    SetPoliceIgnorePlayer(PlayerId(), enabled)
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
        ensureControlBlockerThread()
    end

    if enabled then
        SendNUIMessage({
            type = "openMenu",
            payload = {
                title = Config.MenuTitle,
                vehicles = Config.VehiclePresets,
                weapons = Config.Weapons,
                weather = Config.WeatherTypes,
                times = Config.TimePresets,
                wantedLevels = Config.WantedLevels,
                bodyguards = bodyguardPresets,
                peds = getPedModelsForUI(),
                pedCount = #pedModels,
                world = worldState,
                toggles = {
                    invincible = isInvincible,
                    unlimitedAmmo = hasUnlimitedAmmo,
                    superJump = hasSuperJump,
                    fastRun = hasFastRun,
                    invisible = isInvisible,
                    vehicleGodmode = hasVehicleGodmode,
                    explosiveAmmo = hasExplosiveAmmo,
                    fireAmmo = hasFireAmmo,
                    noReload = hasNoReload
                }
            }
        })
    else
        SendNUIMessage({ type = "closeMenu" })
    end
end

local function setSpawnSelectorState(enabled)
    spawnSelectionOpen = enabled
    if enabled then
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        ensureControlBlockerThread()
        SendNUIMessage({
            type = "openSpawnSelector",
            payload = {
                title = Config.MenuTitle,
                spawns = spawnLocations
            }
        })
    else
        SendNUIMessage({ type = "closeSpawnSelector" })
        if not isMenuOpen then
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
        end
    end
end

local function openSpawnSelector()
    if #spawnLocations == 0 then
        print("^1[sandbox_core] No spawn locations configured in shared/config.lua^7")
        return
    end

    setSpawnSelectorState(true)
end

local function applySpawnLocation(spawnIndex)
    local index = tonumber(spawnIndex)
    if not index then
        return false, "Ungültige Spawn-Auswahl."
    end

    local spawn = spawnLocations[index]
    if not spawn then
        return false, "Spawnpunkt nicht gefunden."
    end

    local ped = PlayerPedId()
    local x = tonumber(spawn.x) or 0.0
    local y = tonumber(spawn.y) or 0.0
    local z = tonumber(spawn.z) or 72.0
    local heading = tonumber(spawn.heading) or 0.0

    local vehicle = 0
    if IsPedInAnyVehicle(ped, false) then
        vehicle = GetVehiclePedIsIn(ped, false)
    end

    local entity = vehicle ~= 0 and vehicle or ped
    SetEntityCoordsNoOffset(entity, x, y, z + 0.2, false, false, false)
    SetEntityHeading(entity, heading)
    FreezeEntityPosition(entity, true)
    Wait(120)
    FreezeEntityPosition(entity, false)

    return true, spawn.label or "Spawn"
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

local function clearDeadBodyguards()
    local alive = {}
    for _, guard in ipairs(bodyguards) do
        if guard and DoesEntityExist(guard) and not IsEntityDead(guard) then
            alive[#alive + 1] = guard
        end
    end
    bodyguards = alive
end

local function removeBodyguards()
    for _, guard in ipairs(bodyguards) do
        if guard and DoesEntityExist(guard) then
            SetEntityAsMissionEntity(guard, true, true)
            DeleteEntity(guard)
        end
    end
    bodyguards = {}
end

local function setWantedLevel(level)
    local clamped = math.min(math.max(tonumber(level) or 0, 0), 5)
    SetPlayerWantedLevel(PlayerId(), clamped, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
    notify(("~g~Fahndungslevel gesetzt: %d Sterne"):format(clamped))
end

local function teleportToWaypoint()
    local waypointBlip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(waypointBlip) then
        notify("~r~Kein Wegpunkt auf der Karte gesetzt.")
        return
    end

    local destination = GetBlipInfoIdCoord(waypointBlip)
    local ped = PlayerPedId()
    local entity = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or ped

    for height = 1, 1000 do
        SetEntityCoordsNoOffset(entity, destination.x, destination.y, height + 0.0, false, false, false)
        local foundGround, groundZ = GetGroundZFor_3dCoord(destination.x, destination.y, height + 0.0, false)
        if foundGround then
            SetEntityCoordsNoOffset(entity, destination.x, destination.y, groundZ + 1.0, false, false, false)
            notify("~g~Zum Wegpunkt teleportiert.")
            return
        end
        Wait(5)
    end

    SetEntityCoordsNoOffset(entity, destination.x, destination.y, destination.z + 1.0, false, false, false)
    notify("~y~Teleport ohne Ground-Lock ausgeführt.")
end

local function setInvisibility(enabled)
    isInvisible = enabled
    local ped = PlayerPedId()
    setPedInvisibleState(ped, enabled)
    notify(enabled and "~g~Unsichtbarkeit aktiviert." or "~y~Unsichtbarkeit deaktiviert.")
end

local function repairAndWashVehicle()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify("~r~Du sitzt in keinem Fahrzeug.")
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleDirtLevel(vehicle, 0.0)
    notify("~g~Fahrzeug repariert und gewaschen.")
end

local function flipVehicle()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify("~r~Du sitzt in keinem Fahrzeug.")
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    local coords = GetEntityCoords(vehicle)
    local heading = GetEntityHeading(vehicle)
    SetEntityCoordsNoOffset(vehicle, coords.x, coords.y, coords.z + 0.8, false, false, false)
    SetEntityRotation(vehicle, 0.0, 0.0, heading, 2, true)
    SetVehicleOnGroundProperly(vehicle)
    notify("~g~Fahrzeug aufgerichtet.")
end

local function maxTuneVehicle()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify("~r~Du sitzt in keinem Fahrzeug.")
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    SetVehicleModKit(vehicle, 0)
    local modSlots = {
        11, -- engine
        12, -- brakes
        13, -- transmission
        15, -- suspension
        16  -- armor
    }

    for _, slot in ipairs(modSlots) do
        local count = GetNumVehicleMods(vehicle, slot)
        if count and count > 0 then
            SetVehicleMod(vehicle, slot, count - 1, false)
        end
    end

    ToggleVehicleMod(vehicle, 18, true) -- turbo
    SetVehicleTyresCanBurst(vehicle, false)
    SetVehicleEnginePowerMultiplier(vehicle, 25.0)
    notify("~g~Performance-Tuning auf Maximum gesetzt.")
end

local function setVehicleGodmode(enabled)
    hasVehicleGodmode = enabled
    local ped = PlayerPedId()
    local vehicle = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or 0

    if vehicle ~= 0 then
        SetEntityInvincible(vehicle, enabled)
        SetVehicleCanBeVisiblyDamaged(vehicle, not enabled)
        SetVehicleTyresCanBurst(vehicle, not enabled)
        SetDisableVehiclePetrolTankDamage(vehicle, enabled)
        SetDisableVehiclePetrolTankFires(vehicle, enabled)
        SetDisableVehicleEngineFires(vehicle, enabled)
        SetVehicleEngineCanDegrade(vehicle, not enabled)
    end

    notify(enabled and "~g~Vehicle Godmode aktiviert." or "~y~Vehicle Godmode deaktiviert.")
end

local function setNoReload(enabled)
    hasNoReload = enabled
    notify(enabled and "~g~No Reload aktiviert." or "~y~No Reload deaktiviert.")
end

local function setExplosiveAmmo(enabled)
    hasExplosiveAmmo = enabled
    if enabled then
        hasFireAmmo = false
    end
    notify(enabled and "~g~Explosivmunition aktiviert." or "~y~Explosivmunition deaktiviert.")
end

local function setFireAmmo(enabled)
    hasFireAmmo = enabled
    if enabled then
        hasExplosiveAmmo = false
    end
    notify(enabled and "~g~Feuermunition aktiviert." or "~y~Feuermunition deaktiviert.")
end

local function spawnBodyguards(count, modelName)
    clearDeadBodyguards()

    local spawnCount = math.max(tonumber(count) or 1, 1)
    spawnCount = math.min(spawnCount, maxBodyguards)
    if #bodyguardPresets == 0 then
        notify("~r~Keine Bodyguard-Presets in der Config gefunden.")
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    for i = 1, spawnCount do
        local offset = vector3((i * 1.6), (i % 2 == 0 and -2.0 or 2.0), 0.0)
        local spawnPos = vector3(coords.x + offset.x, coords.y + offset.y, coords.z + 0.3)
        local preset = bodyguardPresets[((#bodyguards + i - 1) % #bodyguardPresets) + 1]
        if modelName and modelName ~= "" then
            for _, candidate in ipairs(bodyguardPresets) do
                if candidate.model == modelName then
                    preset = candidate
                    break
                end
            end
        end

        local modelHash = joaat(preset.model)
        local weaponHash = joaat(preset.weapon or "weapon_carbinerifle")

        if requestModel(modelHash) then
            local guard = CreatePed(4, modelHash, spawnPos.x, spawnPos.y, spawnPos.z, heading, true, true)
            if guard and DoesEntityExist(guard) then
                SetEntityAsMissionEntity(guard, true, true)
                SetPedCanSwitchWeapon(guard, true)
                SetPedRelationshipGroupHash(guard, joaat("PLAYER"))
                SetPedAsGroupMember(guard, GetPedGroupIndex(ped))
                SetPedNeverLeavesGroup(guard, true)
                SetPedKeepTask(guard, true)
                SetPedCombatAttributes(guard, 5, true)
                SetPedCombatAttributes(guard, 46, true)
                SetPedCombatAbility(guard, 2)
                SetPedCombatMovement(guard, 2)
                SetPedCombatRange(guard, 2)
                SetPedAccuracy(guard, 60)
                SetPedSeeingRange(guard, 120.0)
                SetPedHearingRange(guard, 80.0)
                SetPedArmour(guard, 100)
                SetEntityHealth(guard, 250)
                SetEntityInvincible(guard, false)
                GiveWeaponToPed(guard, weaponHash, 9999, false, true)
                SetCurrentPedWeapon(guard, weaponHash, true)
                SetPedDropsWeaponsWhenDead(guard, false)
                TaskFollowToOffsetOfEntity(guard, ped, 0.0, -1.2, 0.0, 3.0, -1, 2.0, true)
                bodyguards[#bodyguards + 1] = guard
            end
            SetModelAsNoLongerNeeded(modelHash)
        end
    end

    notify(("~g~Bodyguards aktiv: %d"):format(#bodyguards))
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

local function weaponUsesAmmo(ped, weaponHash)
    if not weaponHash or weaponHash == 0 then
        return false
    end

    local success, maxAmmo = GetMaxAmmo(ped, weaponHash)
    return success and maxAmmo and maxAmmo > 0
end

local function setInfiniteAmmoForCurrentWeapon(enabled)
    local ped = PlayerPedId()
    local _, currentWeapon = GetCurrentPedWeapon(ped, true)
    local canUseAmmo = weaponUsesAmmo(ped, currentWeapon)

    SetPedInfiniteAmmoClip(ped, enabled and canUseAmmo)

    if enabled and canUseAmmo then
        SetPedInfiniteAmmo(ped, true, currentWeapon)
        lastTrackedWeapon = currentWeapon
    else
        if lastTrackedWeapon and lastTrackedWeapon ~= 0 and weaponUsesAmmo(ped, lastTrackedWeapon) then
            SetPedInfiniteAmmo(ped, false, lastTrackedWeapon)
        end
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
    local spawnCoords = vector3(pedCoords.x, pedCoords.y, pedCoords.z + 0.2)

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

RegisterNUICallback("selectSpawn", function(data, cb)
    local selectedIndex = data and (data.index or data.id)
    local success, message = applySpawnLocation(selectedIndex)
    if success then
        setSpawnSelectorState(false)
        notify(("~g~Spawn gesetzt: %s"):format(message))
        cb({ ok = true })
    else
        notify(("~r~%s"):format(message or "Spawn fehlgeschlagen."))
        cb({ ok = false, message = message })
    end
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
    elseif action == "setWantedLevel" then
        setWantedLevel(payload.level)
    elseif action == "teleportToWaypoint" or action == "tpWaypoint" then
        teleportToWaypoint()
    elseif action == "setSuperJump" then
        hasSuperJump = payload.enabled == true
        notify(hasSuperJump and "~g~Super Jump aktiviert." or "~y~Super Jump deaktiviert.")
    elseif action == "setFastRun" then
        hasFastRun = payload.enabled == true
        notify(hasFastRun and "~g~Fast Run aktiviert." or "~y~Fast Run deaktiviert.")
    elseif action == "setInvisible" then
        setInvisibility(payload.enabled == true)
    elseif action == "giveWeapon" then
        local weaponModel = tostring(payload.model or "")
        if weaponModel ~= "" then
            giveWeapon(weaponModel)
        end
    elseif action == "giveAllWeapons" then
        giveAllWeapons()
    elseif action == "repairVehicle" then
        repairAndWashVehicle()
    elseif action == "flipVehicle" then
        flipVehicle()
    elseif action == "maxTuneVehicle" then
        maxTuneVehicle()
    elseif action == "setVehicleGodmode" then
        setVehicleGodmode(payload.enabled == true)
    elseif action == "setExplosiveAmmo" then
        setExplosiveAmmo(payload.enabled == true)
    elseif action == "setFireAmmo" then
        setFireAmmo(payload.enabled == true)
    elseif action == "setNoReload" then
        setNoReload(payload.enabled == true)
    elseif action == "spawnBodyguards" then
        spawnBodyguards(payload.count or 1, payload.model)
    elseif action == "removeBodyguards" or action == "dismissBodyguards" then
        removeBodyguards()
        notify("~y~Bodyguards entfernt.")
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
    Wait(250)
    if openSpawnOnJoin and not hasOpenedInitialSpawn then
        hasOpenedInitialSpawn = true
        openSpawnSelector()
    end
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

    if isInvisible then
        setPedInvisibleState(PlayerPedId(), true)
    end

    if openSpawnOnRespawn then
        Wait(150)
        openSpawnSelector()
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
        Wait(0)

        if hasSuperJump then
            SetSuperJumpThisFrame(PlayerId())
        end

        if hasFastRun then
            SetRunSprintMultiplierForPlayer(PlayerId(), fastRunMultiplier)
        else
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        end

        if hasNoReload then
            local ped = PlayerPedId()
            local _, currentWeapon = GetCurrentPedWeapon(ped, true)
            if currentWeapon and currentWeapon ~= 0 then
                local _, maxAmmoInClip = GetMaxAmmoInClip(ped, currentWeapon, true)
                if maxAmmoInClip and maxAmmoInClip > 0 then
                    SetAmmoInClip(ped, currentWeapon, maxAmmoInClip)
                end
            end
        end

        if hasVehicleGodmode then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                SetEntityInvincible(vehicle, true)
                SetVehicleCanBeVisiblyDamaged(vehicle, false)
                SetVehicleTyresCanBurst(vehicle, false)
                SetDisableVehiclePetrolTankDamage(vehicle, true)
                SetDisableVehiclePetrolTankFires(vehicle, true)
                SetDisableVehicleEngineFires(vehicle, true)
                SetVehicleEngineCanDegrade(vehicle, false)
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)

        if hasExplosiveAmmo or hasFireAmmo then
            local ped = PlayerPedId()
            if IsPedShooting(ped) then
                local currentTime = GetGameTimer()
                if currentTime - lastShotTimestamp > 80 then
                    lastShotTimestamp = currentTime
                    local startPos = GetGameplayCamCoord()
                    local direction = GetGameplayCamRot(2)
                    local forward = vector3(
                        -math.sin(math.rad(direction.z)) * math.cos(math.rad(direction.x)),
                        math.cos(math.rad(direction.z)) * math.cos(math.rad(direction.x)),
                        math.sin(math.rad(direction.x))
                    )
                    local endPos = vector3(
                        startPos.x + forward.x * 250.0,
                        startPos.y + forward.y * 250.0,
                        startPos.z + forward.z * 250.0
                    )
                    local ray = StartShapeTestRay(startPos.x, startPos.y, startPos.z, endPos.x, endPos.y, endPos.z, 1, ped, 0)
                    local _, hit, hitCoords = GetShapeTestResult(ray)
                    if hit == 1 then
                        if hasExplosiveAmmo then
                            AddExplosion(hitCoords.x, hitCoords.y, hitCoords.z, 2, 2.0, true, false, 1.0)
                        elseif hasFireAmmo then
                            StartScriptFire(hitCoords.x, hitCoords.y, hitCoords.z, 8, false)
                        end
                    end
                end
            end
        end

        clearDeadBodyguards()
        if #bodyguards > 0 then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            for _, guard in ipairs(bodyguards) do
                if guard and DoesEntityExist(guard) and not IsEntityDead(guard) then
                    local guardCoords = GetEntityCoords(guard)
                    local distance = #(guardCoords - playerCoords)
                    if distance > 35.0 then
                        SetEntityCoordsNoOffset(guard, playerCoords.x + 1.5, playerCoords.y + 1.5, playerCoords.z, false, false, false)
                    elseif not IsPedInCombat(guard, 0) and not IsPedRagdoll(guard) then
                        TaskFollowToOffsetOfEntity(guard, playerPed, 0.0, -1.2, 0.0, 3.0, -1, 2.0, true)
                    end
                end
            end
        end
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
        Wait(150)
        if (isMenuOpen or spawnSelectionOpen) and IsPedDeadOrDying(PlayerPedId(), true) then
            if isMenuOpen then
                setMenuState(false)
            end
            if spawnSelectionOpen then
                setSpawnSelectorState(false)
            end
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    removeBodyguards()
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    setPedInvisibleState(PlayerPedId(), false)
    setInfiniteAmmoForCurrentWeapon(false)
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
            if weaponUsesAmmo(ped, currentWeapon) then
                SetPedInfiniteAmmoClip(ped, true)
                SetPedInfiniteAmmo(ped, true, currentWeapon)
            else
                SetPedInfiniteAmmoClip(ped, false)
            end
            lastTrackedWeapon = currentWeapon
        end

        ::continue::
    end
end)
