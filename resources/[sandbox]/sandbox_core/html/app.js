const resourceName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "sandbox_core";

const state = {
    opened: false,
    spawnOpen: false,
    activeTab: "tab-quick",
    spawns: [],
    vehicles: [],
    weapons: [],
    weather: [],
    times: [],
    bodyguardPresets: [],
    peds: [],
    world: {
        weather: "EXTRASUNNY",
        hour: 12,
        minute: 0
    },
    toggles: {
        invincible: false,
        unlimitedAmmo: false,
        superJump: false,
        fastRun: false,
        invisible: false,
        vehicleGodmode: false,
        explosiveAmmo: false,
        fireAmmo: false,
        noReload: false
    }
};

const app = document.getElementById("app");
const spawnOverlay = document.getElementById("spawn-overlay");
const spawnTitle = document.getElementById("spawn-title");
const spawnDescription = document.getElementById("spawn-description");
const spawnSearch = document.getElementById("spawn-search");
const spawnList = document.getElementById("spawn-list");
const spawnConfirm = document.getElementById("spawn-confirm");
const menuTitle = document.getElementById("menu-title");
const closeButton = document.getElementById("close-menu");
const worldStatus = document.getElementById("world-status");
const tabButtons = document.querySelectorAll(".tab-button");
const tabContents = document.querySelectorAll(".tab-content");
const MAX_VISIBLE_PEDS = 100;

const elements = {
    vehicleSearch: document.getElementById("vehicle-search"),
    vehicleSelect: document.getElementById("vehicle-select"),
    spawnVehicle: document.getElementById("spawn-vehicle"),
    healButtons: document.querySelectorAll('[data-action="healPlayer"]'),
    invincibleToggle: document.getElementById("toggle-invincible"),
    superJumpToggle: document.getElementById("toggle-super-jump"),
    fastRunToggle: document.getElementById("toggle-fast-run"),
    invisibleToggle: document.getElementById("toggle-invisible"),
    teleportWaypointButtons: document.querySelectorAll('[data-action="tpWaypoint"]'),
    wantedLevel: document.getElementById("wanted-level"),
    wantedLevelLabel: document.getElementById("wanted-level-label"),
    setWanted: document.getElementById("set-wanted"),
    clearWanted: document.getElementById("clear-wanted"),
    maxWanted: document.getElementById("max-wanted"),
    ammoToggle: document.getElementById("toggle-ammo"),
    noReloadToggle: document.getElementById("toggle-no-reload"),
    explosiveAmmoToggle: document.getElementById("toggle-explosive-ammo"),
    fireAmmoToggle: document.getElementById("toggle-fire-ammo"),
    weaponSearch: document.getElementById("weapon-search"),
    weaponSelect: document.getElementById("weapon-select"),
    giveWeapon: document.getElementById("give-weapon"),
    giveAllWeaponsButtons: document.querySelectorAll('[data-action="giveAllWeapons"]'),
    repairVehicle: document.getElementById("repair-vehicle"),
    flipVehicle: document.getElementById("flip-vehicle"),
    maxTuneVehicle: document.getElementById("max-tune-vehicle"),
    vehicleGodmodeToggle: document.getElementById("toggle-vehicle-godmode"),
    weatherSelect: document.getElementById("weather-select"),
    setWeather: document.getElementById("set-weather"),
    timePresetSelect: document.getElementById("time-preset-select"),
    setTimePreset: document.getElementById("set-time-preset"),
    timeHour: document.getElementById("time-hour"),
    timeMinute: document.getElementById("time-minute"),
    setTimeCustom: document.getElementById("set-time-custom"),
    bodyguardModel: document.getElementById("bodyguard-model"),
    bodyguardCount: document.getElementById("bodyguard-count"),
    spawnBodyguards: document.getElementById("spawn-bodyguards"),
    clearBodyguards: document.getElementById("clear-bodyguards"),
    pedSearch: document.getElementById("ped-search"),
    pedSelect: document.getElementById("ped-select"),
    setPed: document.getElementById("set-ped")
};

const postNui = async (endpoint, body) => {
    await fetch(`https://${resourceName}/${endpoint}`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(body || {})
    });
};

const sendAction = async (action, payload = {}) => {
    try {
        await postNui("action", { action, payload });
    } catch (error) {
        console.error("[sandbox_core] Failed to send action", action, error);
    }
};

const closeMenu = async () => {
    try {
        await postNui("closeMenu", {});
    } catch (error) {
        console.error("[sandbox_core] Failed to close menu", error);
    }
};

const closeSpawnOverlay = () => {
    state.spawnOpen = false;
    spawnOverlay.classList.add("hidden");
};

const requestSpawnByIndex = async (index) => {
    if (Number.isNaN(index)) {
        return;
    }

    try {
        await postNui("selectSpawn", { index });
        closeSpawnOverlay();
    } catch (error) {
        console.error("[sandbox_core] Failed to confirm spawn", error);
    }
};

const renderSpawnList = () => {
    const query = (spawnSearch.value || "").trim().toLowerCase();
    const filtered = state.spawns.filter((spawn) =>
        spawn.label.toLowerCase().includes(query) || (spawn.description || "").toLowerCase().includes(query)
    );

    spawnList.innerHTML = "";

    if (filtered.length === 0) {
        const empty = document.createElement("p");
        empty.className = "spawn-empty";
        empty.textContent = "Keine Spawnpunkte gefunden.";
        spawnList.appendChild(empty);
        return;
    }

    filtered.forEach((spawn) => {
        const row = document.createElement("button");
        row.type = "button";
        row.className = "spawn-item";
        row.dataset.index = String(spawn.index);
        row.innerHTML = `<strong>${spawn.label}</strong><span>${spawn.description || ""}</span>`;
        row.addEventListener("click", () => {
            requestSpawnByIndex(Number(spawn.index));
        });
        spawnList.appendChild(row);
    });
};

const openSpawnOverlay = (payload = {}) => {
    state.spawns = Array.isArray(payload.spawns) ? payload.spawns : [];
    spawnTitle.textContent = payload.title || "Spawn Auswahl";
    spawnDescription.textContent = payload.description || "Waehle einen Ort zum Spawnen.";
    spawnSearch.value = "";
    renderSpawnList();
    state.spawnOpen = true;
    spawnOverlay.classList.remove("hidden");
};

const setOpenState = (opened) => {
    state.opened = opened;
    app.classList.toggle("hidden", !opened);
};

const setActiveTab = (tabId) => {
    state.activeTab = tabId;
    tabButtons.forEach((button) => button.classList.toggle("active", button.dataset.tab === tabId));
    tabContents.forEach((panel) => panel.classList.toggle("active", panel.id === tabId));
};

const fillSelect = (selectElement, items, options = {}) => {
    const { mapLabel = (item) => item, mapValue = (item) => item } = options;
    const previousValue = selectElement.value;

    selectElement.innerHTML = "";
    items.forEach((item, index) => {
        const option = document.createElement("option");
        option.textContent = mapLabel(item);
        option.value = mapValue(item, index);
        selectElement.appendChild(option);
    });

    if (previousValue) {
        selectElement.value = previousValue;
    }
    if (!selectElement.value && selectElement.options.length > 0) {
        selectElement.selectedIndex = 0;
    }
};

const filterBy = (items, query, mapper) => {
    const normalized = query.trim().toLowerCase();
    if (!normalized) {
        return items;
    }
    return items.filter((item) => mapper(item).toLowerCase().includes(normalized));
};

const renderVehicles = () => {
    const filteredVehicles = filterBy(state.vehicles, elements.vehicleSearch.value, (item) => item);
    fillSelect(elements.vehicleSelect, filteredVehicles);
};

const renderWeapons = () => {
    const filteredWeapons = filterBy(state.weapons, elements.weaponSearch.value, (item) => item.label);
    fillSelect(elements.weaponSelect, filteredWeapons, {
        mapLabel: (item) => item.label,
        mapValue: (item) => item.model
    });
};

const renderWeather = () => {
    fillSelect(elements.weatherSelect, state.weather, {
        mapLabel: (item) => `${item.label} (${item.value})`,
        mapValue: (item) => item.value
    });
};

const renderTimePresets = () => {
    fillSelect(elements.timePresetSelect, state.times, {
        mapLabel: (item) => `${item.label} (${String(item.hour).padStart(2, "0")}:${String(item.minute).padStart(2, "0")})`,
        mapValue: (_, index) => String(index)
    });
};

const renderWantedLabel = () => {
    const level = Number(elements.wantedLevel.value || 0);
    const suffix = level === 1 ? "Stern" : "Sterne";
    elements.wantedLevelLabel.textContent = `Aktuelles Ziel: ${level} ${suffix}`;
};

const renderBodyguardPresets = () => {
    fillSelect(elements.bodyguardModel, state.bodyguardPresets, {
        mapLabel: (item) => item.label,
        mapValue: (item) => item.model
    });
};

const renderPeds = () => {
    const filteredPeds = filterBy(state.peds, elements.pedSearch.value, (item) => item.label);
    fillSelect(elements.pedSelect, filteredPeds.slice(0, MAX_VISIBLE_PEDS), {
        mapLabel: (item) => item.label,
        mapValue: (item) => `${item.hash}|${item.label}`
    });
};

const renderToggles = () => {
    elements.invincibleToggle.checked = state.toggles.invincible === true;
    elements.superJumpToggle.checked = state.toggles.superJump === true;
    elements.fastRunToggle.checked = state.toggles.fastRun === true;
    elements.invisibleToggle.checked = state.toggles.invisible === true;
    elements.ammoToggle.checked = state.toggles.unlimitedAmmo === true;
    elements.noReloadToggle.checked = state.toggles.noReload === true;
    elements.explosiveAmmoToggle.checked = state.toggles.explosiveAmmo === true;
    elements.fireAmmoToggle.checked = state.toggles.fireAmmo === true;
    elements.vehicleGodmodeToggle.checked = state.toggles.vehicleGodmode === true;
};

const renderWorldStatus = () => {
    const weather = state.world.weather || "UNKNOWN";
    const hour = String(state.world.hour ?? 0).padStart(2, "0");
    const minute = String(state.world.minute ?? 0).padStart(2, "0");
    worldStatus.textContent = `Aktuell: ${hour}:${minute} / ${weather}`;
    elements.timeHour.value = String(state.world.hour ?? 0);
    elements.timeMinute.value = String(state.world.minute ?? 0);
    if (weather) {
        elements.weatherSelect.value = weather;
    }
};

const openMenu = (payload = {}) => {
    state.vehicles = Array.isArray(payload.vehicles) ? payload.vehicles : state.vehicles;
    state.weapons = Array.isArray(payload.weapons) ? payload.weapons : state.weapons;
    state.weather = Array.isArray(payload.weather) ? payload.weather : state.weather;
    state.times = Array.isArray(payload.times) ? payload.times : state.times;
    state.bodyguardPresets = Array.isArray(payload.bodyguards) ? payload.bodyguards : state.bodyguardPresets;
    state.peds = Array.isArray(payload.peds) ? payload.peds : state.peds;
    state.world = payload.world || state.world;
    state.toggles = payload.toggles || state.toggles;

    menuTitle.textContent = payload.title || "Sandbox Menu";

    renderVehicles();
    renderWeapons();
    renderWeather();
    renderTimePresets();
    renderBodyguardPresets();
    renderWantedLabel();
    renderPeds();
    renderToggles();
    renderWorldStatus();
    setActiveTab("tab-quick");
    setOpenState(true);
};

tabButtons.forEach((button) => {
    button.addEventListener("click", () => setActiveTab(button.dataset.tab));
});

closeButton.addEventListener("click", () => {
    closeMenu();
});

elements.vehicleSearch.addEventListener("input", renderVehicles);
elements.weaponSearch.addEventListener("input", renderWeapons);
elements.pedSearch.addEventListener("input", renderPeds);
elements.wantedLevel.addEventListener("input", renderWantedLabel);
spawnSearch.addEventListener("input", renderSpawnList);

spawnConfirm.addEventListener("click", () => {
    if (!state.spawnOpen) {
        return;
    }

    const firstSpawn = state.spawns[0];
    const selectedIndex = firstSpawn ? Number(firstSpawn.index) : NaN;
    if (Number.isNaN(selectedIndex) && spawnList.firstElementChild) {
        const fallback = Number(spawnList.firstElementChild.dataset.index);
        if (!Number.isNaN(fallback)) {
            requestSpawnByIndex(fallback);
            return;
        }
    }

    if (Number.isNaN(selectedIndex)) {
        return;
    }
    requestSpawnByIndex(selectedIndex);
});

elements.spawnVehicle.addEventListener("click", () => {
    const model = elements.vehicleSelect.value;
    if (model) {
        sendAction("spawnVehicle", { model });
    }
});

elements.healButtons.forEach((button) => {
    button.addEventListener("click", () => sendAction("healPlayer"));
});

elements.invincibleToggle.addEventListener("change", (event) => {
    sendAction("setInvincible", { enabled: event.target.checked });
});

elements.superJumpToggle.addEventListener("change", (event) => {
    sendAction("setSuperJump", { enabled: event.target.checked });
});

elements.fastRunToggle.addEventListener("change", (event) => {
    sendAction("setFastRun", { enabled: event.target.checked });
});

elements.invisibleToggle.addEventListener("change", (event) => {
    sendAction("setInvisible", { enabled: event.target.checked });
});

elements.teleportWaypointButtons.forEach((button) => {
    button.addEventListener("click", () => {
        sendAction("teleportToWaypoint");
    });
});

elements.setWanted.addEventListener("click", () => {
    const level = Number(elements.wantedLevel.value);
    if (!Number.isNaN(level)) {
        sendAction("setWantedLevel", { level });
    }
});

elements.clearWanted.addEventListener("click", () => {
    sendAction("setWantedLevel", { level: 0 });
});

elements.maxWanted.addEventListener("click", () => {
    sendAction("setWantedLevel", { level: 5 });
});

elements.ammoToggle.addEventListener("change", (event) => {
    sendAction("setUnlimitedAmmo", { enabled: event.target.checked });
});

elements.noReloadToggle.addEventListener("change", (event) => {
    sendAction("setNoReload", { enabled: event.target.checked });
});

elements.explosiveAmmoToggle.addEventListener("change", (event) => {
    sendAction("setExplosiveAmmo", { enabled: event.target.checked });
});

elements.fireAmmoToggle.addEventListener("change", (event) => {
    sendAction("setFireAmmo", { enabled: event.target.checked });
});

elements.giveWeapon.addEventListener("click", () => {
    const model = elements.weaponSelect.value;
    if (model) {
        sendAction("giveWeapon", { model });
    }
});

elements.giveAllWeaponsButtons.forEach((button) => {
    button.addEventListener("click", () => sendAction("giveAllWeapons"));
});

elements.repairVehicle.addEventListener("click", () => {
    sendAction("repairVehicle");
});

elements.flipVehicle.addEventListener("click", () => {
    sendAction("flipVehicle");
});

elements.maxTuneVehicle.addEventListener("click", () => {
    sendAction("maxTuneVehicle");
});

elements.vehicleGodmodeToggle.addEventListener("change", (event) => {
    sendAction("setVehicleGodmode", { enabled: event.target.checked });
});

elements.setWeather.addEventListener("click", () => {
    const weather = elements.weatherSelect.value;
    if (weather) {
        sendAction("setWeather", { weather });
    }
});

elements.setTimePreset.addEventListener("click", () => {
    const index = Number(elements.timePresetSelect.value);
    if (!Number.isNaN(index) && state.times[index]) {
        const time = state.times[index];
        sendAction("setTime", { hour: time.hour, minute: time.minute });
    }
});

elements.setTimeCustom.addEventListener("click", () => {
    const hour = Number(elements.timeHour.value);
    const minute = Number(elements.timeMinute.value);
    if (!Number.isNaN(hour) && !Number.isNaN(minute)) {
        sendAction("setTime", { hour, minute });
    }
});

elements.spawnBodyguards.addEventListener("click", () => {
    const model = elements.bodyguardModel.value;
    const count = Number(elements.bodyguardCount.value || "1");
    if (model && !Number.isNaN(count)) {
        sendAction("spawnBodyguards", { model, count });
    }
});

elements.clearBodyguards.addEventListener("click", () => {
    sendAction("removeBodyguards");
});

elements.setPed.addEventListener("click", () => {
    const value = elements.pedSelect.value;
    if (!value) {
        return;
    }

    const separator = value.indexOf("|");
    if (separator < 0) {
        return;
    }

    const hash = Number(value.slice(0, separator));
    const label = value.slice(separator + 1);
    if (!Number.isNaN(hash) && label) {
        sendAction("setPed", { hash, label });
    }
});

window.addEventListener("message", (event) => {
    const data = event.data || {};
    if (data.type === "openMenu") {
        openMenu(data.payload || {});
    } else if (data.type === "closeMenu") {
        setOpenState(false);
    } else if (data.type === "openSpawnSelector") {
        openSpawnOverlay(data.payload || {});
    } else if (data.type === "closeSpawnSelector") {
        closeSpawnOverlay();
    } else if (data.type === "worldState") {
        state.world = data.payload || state.world;
        renderWorldStatus();
    }
});

window.addEventListener("keydown", (event) => {
    if (state.spawnOpen && event.key === "Escape") {
        event.preventDefault();
        return;
    }

    if (!state.opened) {
        return;
    }

    if (event.key === "Escape" || event.key === "Backspace") {
        event.preventDefault();
        closeMenu();
    }
});

window.addEventListener("mousedown", (event) => {
    if (state.spawnOpen && event.button === 2) {
        event.preventDefault();
        return;
    }

    if (!state.opened) {
        return;
    }

    if (event.button === 2) {
        event.preventDefault();
        closeMenu();
    }
});

window.addEventListener("contextmenu", (event) => {
    if (!state.opened && !state.spawnOpen) {
        return;
    }

    event.preventDefault();
});
