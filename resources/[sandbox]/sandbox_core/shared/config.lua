Config = {}

Config.MenuTitle = "Sandbox Menu"
Config.OpenCommand = "sandboxmenu"
Config.KeybindCommand = "opensandboxmenu"
Config.DefaultMenuKey = "F5"

Config.World = {
    defaultWeather = "EXTRASUNNY",
    defaultHour = 12,
    defaultMinute = 0
}

Config.Player = {
    fastRunMultiplier = 1.49
}

Config.VehiclePresets = {
    "adder",
    "zentorno",
    "t20",
    "krieger",
    "italirsx",
    "comet2",
    "elegy",
    "sultan",
    "kuruma",
    "bati",
    "akuma",
    "manchez2",
    "sanchez",
    "oppressor2",
    "hydra",
    "lazer",
    "buzzard2",
    "annihilator",
    "deluxo",
    "insurgent",
    "nightshark",
    "mesa",
    "baller",
    "granger",
    "police",
    "police2",
    "fbi",
    "ambulance",
    "firetruk",
    "towtruck"
}

Config.Weapons = {
    { label = "Pistol", model = "weapon_pistol" },
    { label = "Combat Pistol", model = "weapon_combatpistol" },
    { label = "Heavy Pistol", model = "weapon_heavypistol" },
    { label = "Micro SMG", model = "weapon_microsmg" },
    { label = "SMG", model = "weapon_smg" },
    { label = "Assault Rifle", model = "weapon_assaultrifle" },
    { label = "Carbine Rifle", model = "weapon_carbinerifle" },
    { label = "Bullpup Rifle", model = "weapon_bullpuprifle" },
    { label = "Pump Shotgun", model = "weapon_pumpshotgun" },
    { label = "Combat MG", model = "weapon_combatmg" },
    { label = "Sniper Rifle", model = "weapon_sniperrifle" },
    { label = "Heavy Sniper", model = "weapon_heavysniper" },
    { label = "RPG", model = "weapon_rpg" },
    { label = "Grenade Launcher", model = "weapon_grenadelauncher" },
    { label = "Minigun", model = "weapon_minigun" },
    { label = "Knife", model = "weapon_knife" },
    { label = "Bat", model = "weapon_bat" },
    { label = "Molotov", model = "weapon_molotov" },
    { label = "Grenade", model = "weapon_grenade" },
    { label = "Sticky Bomb", model = "weapon_stickybomb" }
}

Config.WeatherTypes = {
    { label = "Extra Sunny", value = "EXTRASUNNY" },
    { label = "Clear", value = "CLEAR" },
    { label = "Clouds", value = "CLOUDS" },
    { label = "Overcast", value = "OVERCAST" },
    { label = "Rain", value = "RAIN" },
    { label = "Clearing", value = "CLEARING" },
    { label = "Thunder", value = "THUNDER" },
    { label = "Smog", value = "SMOG" },
    { label = "Foggy", value = "FOGGY" },
    { label = "Xmas", value = "XMAS" },
    { label = "Halloween", value = "HALLOWEEN" }
}

Config.TimePresets = {
    { label = "Morning", hour = 8, minute = 0 },
    { label = "Noon", hour = 12, minute = 0 },
    { label = "Evening", hour = 18, minute = 0 },
    { label = "Night", hour = 23, minute = 0 },
    { label = "Midnight", hour = 0, minute = 0 }
}

Config.WantedLevels = {
    { label = "0 Sterne", value = 0 },
    { label = "1 Stern", value = 1 },
    { label = "2 Sterne", value = 2 },
    { label = "3 Sterne", value = 3 },
    { label = "4 Sterne", value = 4 },
    { label = "5 Sterne", value = 5 }
}

Config.Bodyguards = {
    maxCount = 3,
    presets = {
        { label = "Merryweather", model = "s_m_y_blackops_01", weapon = "weapon_carbinerifle" },
        { label = "Grove Street", model = "g_m_y_famca_01", weapon = "weapon_smg" },
        { label = "NOOSE", model = "s_m_y_swat_01", weapon = "weapon_carbinerifle" }
    }
}

Config.Spawns = {
    openOnJoin = true,
    openOnRespawn = true,
    locations = {
        { label = "Legion Square", x = 215.76, y = -810.12, z = 30.73, heading = 157.0 },
        { label = "Vespucci Beach", x = -1206.17, y = -1560.63, z = 4.61, heading = 128.0 },
        { label = "Del Perro Pier", x = -1803.02, y = -1221.42, z = 13.02, heading = 54.0 },
        { label = "Los Santos Airport", x = -1037.88, y = -2738.09, z = 20.17, heading = 328.0 },
        { label = "Sandy Shores Airfield", x = 1741.66, y = 3272.45, z = 41.14, heading = 102.0 },
        { label = "Paleto Bay", x = -231.53, y = 6327.96, z = 31.49, heading = 221.0 },
        { label = "Mount Chiliad Base", x = 501.41, y = 5593.63, z = 796.08, heading = 172.0 },
        { label = "Maze Bank Roof", x = -75.52, y = -818.66, z = 326.18, heading = 348.0 },
        { label = "Fort Zancudo", x = -2049.66, y = 3132.04, z = 32.81, heading = 60.0 },
        { label = "Humane Labs", x = 3611.94, y = 3741.86, z = 28.69, heading = 268.0 }
    }
}

Config.MaxPedListForUI = 2000
