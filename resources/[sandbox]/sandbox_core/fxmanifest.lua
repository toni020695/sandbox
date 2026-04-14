fx_version "cerulean"
game "gta5"
lua54 "yes"

name "sandbox_core"
description "Freeroam sandbox core with cheat menu and world sync"
author "Lead Developer"
version "1.0.0"

shared_scripts {
    "shared/config.lua"
}

client_scripts {
    "client/main.lua"
}

server_scripts {
    "server/main.lua"
}

ui_page "html/index.html"

files {
    "html/index.html",
    "html/style.css",
    "html/app.js",
    "shared/ped_models.txt"
}
