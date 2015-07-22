# Relief Valve [![Travis](https://img.shields.io/travis/mathphreak/ReliefValve.svg?style=flat-square)](https://travis-ci.org/mathphreak/ReliefValve) [![Codecov](https://img.shields.io/codecov/c/github/mathphreak/ReliefValve.svg?style=flat-square)](https://codecov.io/github/mathphreak/ReliefValve)

[![GitHub Release Downloads](https://img.shields.io/github/downloads/mathphreak/ReliefValve/latest/total.svg?style=flat-square)](https://github.com/mathphreak/ReliefValve/releases/latest)
[![GitHub Latest Release](https://img.shields.io/github/release/mathphreak/ReliefValve.svg?style=flat-square)](https://github.com/mathphreak/ReliefValve/releases/latest)
[![GitHub issues](https://img.shields.io/github/issues/mathphreak/ReliefValve.svg?style=flat-square)](https://github.com/mathphreak/ReliefValve/issues)

[![Dependencies](https://img.shields.io/david/mathphreak/ReliefValve.svg?style=flat-square)](https://david-dm.org/mathphreak/ReliefValve)
[![Development Dpendencies](https://img.shields.io/david/dev/mathphreak/ReliefValve.svg?style=flat-square)](https://david-dm.org/mathphreak/ReliefValve#info=devDependencies)

Prevents dangerous Steam buildups by letting you juggle games
between library locations.

# Usage
ReliefValve now works properly, but only on Windows.
I'd say it's now better than [Steam Mover][]
in some ways, but it will keep improving.

0. Make sure Steam already knows about your existing libraries.
1. Exit Steam (this is important).
2. Download the [latest release][], extract it, and run `relief-valve.exe`.
3. Wait for Relief Valve to populate all your Steam games.
4. Check the box next to one or more games.
5. Select a destination at the bottom of the window.
6. Click "Move".
7. Wait for your selected games to finish moving.
   A progress bar should appear below the footer you just clicked inside.
   It will animate and look cool.
8. Relaunch Steam. Your games will be in their new locations.

# Stack
ReliefValve is built on Electron and uses the Noto Sans fonts from Google,
Yahoo's pure.css, Font Awesome, Zepto.js, and
[all this stuff][npm dependencies].

# Design
ReliefValve is designed to imitate the [Pressure][] skin because it's the best.

[Steam Mover]: http://www.traynier.com/software/steammover
[latest release]: https://github.com/mathphreak/ReliefValve/releases/latest
[npm dependencies]: https://github.com/mathphreak/ReliefValve/blob/v0.4.0/package.json#L6-L31
[Pressure]: http://hydra.tf/pressure/
