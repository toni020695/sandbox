# FiveM Freeroam Sandbox

Reiner **Sandbox/Fun/Freeroam-Gamemode** fuer FiveM ohne Economy und ohne RP-Zwang.  
Ziel: GTA V Singleplayer-Feeling mit lebendiger Welt, aktivem Dispatch-System und integriertem Cheat-Menue.

## Features (aktuell)

- Lebendige Welt:
  - Zivilisten/NPCs aktiv
  - Verkehr aktiv
  - Random Cops aktiv
  - Dispatch Services aktiv
  - Polizei-/Wanted-System bleibt wie im Singleplayer aktiv
- Integriertes Ingame-Menue (NUI, modern, Schwarz-Gruen Design)
- Fahrzeug-Spawn
- Spieler heilen (volle Gesundheit + 100 Armor)
- Unverwundbarkeit (Toggle)
- Unlimited Ammo (Toggle)
- Wanted Level steuern (0-5 Sterne)
- Teleport zum Waypoint
- Super Jump (Toggle)
- Fast Run (Toggle)
- Unsichtbarkeit (Toggle)
- Waffen geben (einzeln oder alle)
- Explosive Ammo (Toggle)
- Fire Ammo (Toggle)
- No Reload (Toggle)
- Serverweites Wetter setzen
- Serverweite Uhrzeit setzen
- Fahrzeug reparieren & waschen
- Vehicle Godmode (Toggle)
- Fahrzeug flippen
- Instant Max Tuning
- Bodyguards (1-3 NPC-Beschuetzer)
- Ped-System:
  - Auswahl aus GTA V Standard-Peds (inkl. Tiere)
  - Freemode Male/Female bewusst ausgeschlossen

## Projektstruktur

```text
resources/
  [sandbox]/
    sandbox_core/
      fxmanifest.lua
      client/main.lua
      server/main.lua
      shared/config.lua
      shared/ped_models.txt
      html/index.html
      html/style.css
      html/app.js
```

## Installation

1. Resource liegt bereits unter:
   - `resources/[sandbox]/sandbox_core`
2. In deiner `server.cfg` sicherstellen:
   - `ensure sandbox_core`
3. Server neu starten.

## Bedienung (Ingame)

- Menue oeffnen:
  - Taste: `F5`
  - oder Command: `/sandboxmenu`
- Menue schliessen:
  - `Esc`
  - `Backspace`
  - Rechtsklick (rechte Maustaste)

## Verfuegbare Commands

### Client

- `/sandboxmenu`
  - Oeffnet/Schliesst das Sandbox-Menue.

### Server (Weltsteuerung)

- `/sandboxweather <wettertyp>`
  - Setzt serverweit das Wetter.
  - Beispiele: `EXTRASUNNY`, `CLEAR`, `RAIN`, `THUNDER`
- `/sandboxtime <stunde 0-23> <minute 0-59>`
  - Setzt serverweit die Uhrzeit.
  - Beispiel: `/sandboxtime 18 30`

## Menue-Reiter und Funktionen

- **Quick**
  - Heilen (HP + Armor)
  - Unverwundbarkeit Toggle
  - Unlimited Ammo Toggle
  - Super Jump Toggle
  - Fast Run Toggle
  - Unsichtbarkeit Toggle
  - Wanted 0 Sterne / Wanted 5 Sterne
  - Teleport zum Waypoint
  - Bodyguards (1 / 2 / 3)
  - Alle Waffen geben
- **Fahrzeuge**
  - Fahrzeug aus Preset-Liste suchen und spawnen
  - Fahrzeug reparieren & waschen
  - Vehicle Godmode Toggle
  - Fahrzeug flippen
  - Instant Max Tuning
- **Waffen**
  - Einzelne Waffe suchen und geben
  - Alle Waffen geben
  - Explosive Ammo Toggle
  - Fire Ammo Toggle
  - No Reload Toggle
- **Welt**
  - Wetter per Auswahl setzen
  - Uhrzeit per Preset oder Custom HH:MM setzen
- **Peds**
  - Ped-/Tier-Liste durchsuchen
  - Ausgewaehlten Ped direkt anwenden

## Technische Hinweise

- Weltstatus (Wetter/Zeit) wird serverseitig verwaltet und an alle Clients synchronisiert.
- Ped-Liste basiert auf `shared/ped_models.txt`.
- Freemode-Modelle (`mp_m_freemode_01`, `mp_f_freemode_01`) werden automatisch gefiltert.
- Beim Ped-Wechsel werden Waffen inkl. Munition gepuffert und auf dem neuen Ped wiederhergestellt.
- Fahrzeug-Spawn ersetzt das vorherige Sandbox-Spawnfahrzeug, um Fahrzeug-Spam zu vermeiden.
- Wetter-/Zeit-Updates besitzen ein serverseitiges Rate-Limit pro Spieler (Anti-Spam).
- Unlimited Ammo laeuft nicht mehr per Frame-Loop, sondern per 500ms-Waffenwechsel-Check.
- Weapon FX (Explosive/Fire) und No Reload werden als lokale Kampf-Modifier verarbeitet.
- Vehicle Godmode und Player Movement Cheats (Super Jump/Fast Run/Invisible) laufen als lokale Toggles.
- Bodyguards werden als bewaffnete NPC-Beschuetzer in der Naehe des Spielers erzeugt und verfolgen den Spieler.

## Naechste sinnvolle Erweiterungen

- Teleport-Favoriten / Map-Blips
- Vehicle-Tuning-Presets
- Saved Loadouts (Waffen + Ped + Fahrzeug)
- Rechte-/Gruppensystem fuer Menue-Optionen (optional)
