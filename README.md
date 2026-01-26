# MidnightUI

![WoW Version](https://img.shields.io/badge/WoW-12.0%2B-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

**MidnightUI** is a complete, modular, and modern User Interface replacement for World of Warcraft. 

Built strictly for **Interface 12.0**, it prioritizes readability, performance, and a sleek, dark aesthetic. It removes the clutter of the default Blizzard UI while retaining feature-rich functionality through a suite of integrated modules.

## ✨ Features

MidnightUI is divided into lightweight modules. You can enable or disable them individually via the settings.

* **🌑 Global Dark Theme:** Applies a consistent "Midnight" dark skin to supported frames and panels.
* **📊 Info Bar (Data Brokers):** A fully customizable top/bottom bar displaying:
    * **System:** FPS, Latency, and Addon Memory usage (with color-coded alerts).
    * **Volume:** Integrated volume mixer with click-to-mute and mousewheel control.
    * **Currency:** Gold tracking and WoW Token prices.
    * **Utility:** Bag space, Durability, Friend/Guild lists, and Clock (with daily/weekly reset timers).
    * **Location:** Zone text with coordinates.
* **⚔️ Action Bars:** Modernized layout that hides default art (Gryphons) and applies clean, square skins to buttons.
* **🗺️ Maps:** Rectangular Minimap with auto-zoom, coordinates, and cleaned-up tracking icons.
* **❤️ Unit Frames:** Flat texture replacements for Player, Target, and Focus frames with class-colored health bars.
* **⏱️ Cooldowns:** Built-in digital timers on ability icons.
* **🛠️ Tweaks:** Quality of life improvements, including Fast Looting.

## 📦 Dependencies

This addon requires the following libraries (included in the `libs` folder or installable separately):
* **Ace3** (Configuration, Events, Hooks)
* **LibSharedMedia-3.0** (Fonts, Textures)
* **LibDataBroker-1.1** (Data display)
* **Masque** (Optional, for button skinning support)

## 🚀 Installation

1.  Download the latest release.
2.  Extract the **MidnightUI** folder.
3.  Place the folder into your WoW AddOns directory:
    * `World of Warcraft\_retail_\Interface\AddOns\`
4.  Launch World of Warcraft.

## ⚙️ Configuration

You can access the configuration menu to toggle modules, adjust bar positions, or change fonts via:

1.  Press **Esc** to open the Game Menu.
2.  Navigate to **Options** > **AddOns**.
3.  Select **MidnightUI**.

*Alternatively, right-click the "Midnight Bar" frame (if unlocked) to open settings directly.*

## 📂 Directory Structure

```text
MidnightUI/
├── MidnightUI.toc          # Addon Metadata (Interface 12.0)
├── Core.lua                # Main Engine & Module Loader
├── Modules/
│   ├── Bar.lua             # Info Bar & Data Brokers
│   ├── ActionBars.lua      # Button Skinning & Art Removal
│   ├── UnitFrames.lua      # Player/Target Frame Skinning
│   ├── Maps.lua            # Minimap Customization
│   ├── Cooldowns.lua       # Ability Timers
│   ├── UIButtons.lua       # Menu/Bag Button styling
│   └── Tweaks.lua          # Automation & QoL
└── libs/                   # Embedded Libraries
