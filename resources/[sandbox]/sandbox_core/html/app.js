const resourceName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "sandbox_core";

const state = {
    opened: false,
    activeTab: "tab-quick",
    vehicles: [],
    weapons: [],
    weather: [],
    times: [],
    peds: [],
    world: {
        weather: "EXTRASUNNY",
        hour: 12,
        minute: 0
    },
    toggles: {
        invincible: false,
        unlimitedAmmo: false
    }
};

const app = document.getElementById("app");
const menuTitle = document.getElementById("menu-title");
const closeButton = document.getElementById("close-menu");
const worldStatus = document.getElementById("world-status");
const tabButtons = document.querySelectorAll(".tab-button");
const tabContents = document.querySelectorAll(".tab-content");

const elements = {
    vehicleSearch: document.getElementById("vehicle-search"),
    vehicleSelect: document.getElementById("vehicle-select"),
    spawnVehicle: document.getElementById("spawn-vehicle"),
    healButtons: document.querySelectorAll('[data-action="healPlayer"]'),
    invincibleToggle: document.getElementById("toggle-invincible"),
    ammoToggle: document.getElementById("toggle-ammo"),
    weaponSearch: document.getElementById("weapon-search"),
    weaponSelect: document.getElementById("weapon-select"),
    giveWeapon: document.getElementById("give-weapon"),
    giveAllWeaponsButtons: document.querySelectorAll('[data-action="giveAllWeapons"]'),
    weatherSelect: document.getElementById("weather-select"),
    setWeather: document.getElementById("set-weather"),
    timePresetSelect: document.getElementById("time-preset-select"),
    setTimePreset: document.getElementById("set-time-preset"),
    timeHour: document.getElementById("time-hour"),
    timeMinute: document.getElementById("time-minute"),
    setTimeCustom: document.getElementById("set-time-custom"),
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

const renderPeds = () => {
    const filteredPeds = filterBy(state.peds, elements.pedSearch.value, (item) => item.label);
    fillSelect(elements.pedSelect, filteredPeds, {
        mapLabel: (item) => item.label,
        mapValue: (item) => `${item.hash}|${item.label}`
    });
};

const renderToggles = () => {
    elements.invincibleToggle.checked = state.toggles.invincible === true;
    elements.ammoToggle.checked = state.toggles.unlimitedAmmo === true;
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
    state.peds = Array.isArray(payload.peds) ? payload.peds : state.peds;
    state.world = payload.world || state.world;
    state.toggles = payload.toggles || state.toggles;

    menuTitle.textContent = payload.title || "Sandbox Menu";

    renderVehicles();
    renderWeapons();
    renderWeather();
    renderTimePresets();
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

elements.ammoToggle.addEventListener("change", (event) => {
    sendAction("setUnlimitedAmmo", { enabled: event.target.checked });
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
    } else if (data.type === "worldState") {
        state.world = data.payload || state.world;
        renderWorldStatus();
    }
});

window.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && state.opened) {
        closeMenu();
    }
});
