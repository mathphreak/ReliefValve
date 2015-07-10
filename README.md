# Relief Valve
Prevents dangerous Steam buildups by letting you juggle games
between library locations.

# Usage
ReliefValve now works, but only barely, and only on Windows.
Right now, you're still better off with
[Steam Mover][], but that won't
be true forever.

0.  Make sure Steam already knows about your existing libraries.
1.  Download the [latest release][] and run `ReliefValve.exe`.
2.  Wait for Relief Valve to populate all your Steam games.
3.  Check the box next to one or more games.
4.  Select a destination at the bottom of the window.
5.  Click "Copy".
6.  Wait for your selected games to finish copying.
    A progress bar should appear below the footer you just clicked inside.
7.  In your Steam library, find one of the games you moved over.
8.  Right-click it, click "Delete Local Content...", and confirm that you want to delete it.
9.  Install the game and select the new location. Steam will not re-download everything,
    as long as Relief Valve worked. Don't count on it.
10. If needed, go back and delete the game from its old location. Steam might not
    get rid of everything when you told it to.

# Stack
ReliefValve is built on Electron and uses the Noto Sans fonts from Google,
Yahoo's pure.css, Font Awesome, Zepto.js, and
[all this stuff][npm dependencies].

# Design
ReliefValve is designed to imitate the Pressure skin because it's the best.

[Steam Mover]: http://www.traynier.com/software/steammover
[latest release]: https://github.com/mathphreak/ReliefValve/releases/latest
[npm dependencies]: https://github.com/mathphreak/ReliefValve/blob/v0.1/package.json#L6-L20
