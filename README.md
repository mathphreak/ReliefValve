# Relief Valve

Prevents dangerous Steam buildups by letting you move games between library locations.

# Description

If you have a small SSD and a large HDD, you may want some Steam games on the SSD and others on the HDD.
Applications like [Steam Mover][] and [SteamTool][] were created to move games from one drive to another while leaving links to them in the original locations so that Steam would still have access to them.
In 2012, Valve added support for installing games to different directories to Steam in [this update](http://store.steampowered.com/news/9494/).
Steam Mover and other applications were never updated to be aware of this.
Relief Valve is (to my knowledge) the first application that works with Steam's multiple library support.

# Features

* Works on Windows, Mac, and Linux (older applications that use NTFS Junction Points, like Steam Mover and SteamTool, don't)
* Moves multiple applications at once
* Select and filter based on Steam categories

# Installation

Relief Valve currently has no installer.
You can [download][latest release], extract, and run Relief Valve directly on Windows, Mac, or Linux.

Alternatively, Relief Valve is available [on itch.io][itch], and you can use the itch native app to install and launch Relief Valve.

# Basic Usage

0. Make sure Steam already knows about your existing libraries.
   You may find [this guide][library guide] helpful.
1. Download the [latest release of Relief Valve][latest release], extract it, and run `relief-valve`.
2. Wait for Relief Valve to populate all your Steam games.
3. Check the box next to one or more games.
4. Make sure the proper destination is selected.
5. Click "Move".
   If Steam is running, you will be prompted to quit Steam.
6. Wait for your selected games to finish moving.
7. Relaunch Steam. Your games will be in their new locations.

# Advanced Usage

You can select or deselect all games in a location by using the checkbox next to that location in the Location column heading.
You can also select or deselect all games by using the checkbox in the Name column heading.

Next to the Search bar there is either one or two dropdowns.
If multiple users have signed in to Steam on your computer, you will see a dropdown for which user's categories to use.
You will definitely see a dropdown with all categories for the selected user.
Selecting a category (the default is to select favorites) will allow you to select or deselect all games in that category with the checkbox next to the category dropdown.

# Support

If you have a GitHub account, you can [report issues directly on GitHub][issues].
If you don't, there's a [Steam group][] where you can discuss things.

# Development [![Travis](https://img.shields.io/travis/mathphreak/ReliefValve.svg?style=flat-square)](https://travis-ci.org/mathphreak/ReliefValve) [![Codecov](https://img.shields.io/codecov/c/github/mathphreak/ReliefValve.svg?style=flat-square)](https://codecov.io/github/mathphreak/ReliefValve)

[![GitHub Release Downloads](https://img.shields.io/github/downloads/mathphreak/ReliefValve/latest/total.svg?style=flat-square)][latest release]
[![GitHub Latest Release](https://img.shields.io/github/release/mathphreak/ReliefValve.svg?style=flat-square)][latest release]
[![GitHub issues](https://img.shields.io/github/issues/mathphreak/ReliefValve.svg?style=flat-square)][issues]

If you want to add features or fix bugs, follow the directions in [CONTRIBUTING.md][].

# Stack

Relief Valve is built on Electron and uses the Noto Sans fonts from Google,
Yahoo's pure.css, Font Awesome, Zepto.js, [Vex][], and
[all this stuff][npm dependencies].

# Design

Relief Valve is designed to imitate the [Pressure][] skin because it's the best.

I'm not sure yet how I feel about Pressure².

[Steam Mover]: http://www.traynier.com/software/steammover
[SteamTool]: http://www.stefanjones.ca/steam/
[itch]: https://mathphreak.itch.io/reliefvalve
[library guide]: http://code.mathphreak.me/ReliefValve/configure.html
[latest release]: https://github.com/mathphreak/ReliefValve/releases/latest
[npm dependencies]: https://github.com/mathphreak/ReliefValve/blob/v0.16.1/package.json#L7-L48
[Pressure]: http://hydra.tf/pressure/
[Vex]: http://github.hubspot.com/vex/
[issues]: https://github.com/mathphreak/ReliefValve/issues
[CONTRIBUTING.md]: https://github.com/mathphreak/ReliefValve/blob/master/CONTRIBUTING.md
[Steam group]: http://steamcommunity.com/groups/ReliefValv3
