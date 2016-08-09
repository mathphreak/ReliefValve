// Import the Electron stuff
import {app, BrowserWindow, ipcMain as ipc, Menu, MenuItem, shell} from 'electron';
import _ from 'lodash';

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the javascript object is GCed.
let mainWindow = null;

ipc.on('progress', (event, arg) => {
  if (!mainWindow || !mainWindow.setProgressBar) {
    return;
  }
  if (_.isNumber(arg)) {
    mainWindow.setProgressBar(_.clamp(arg, 0.01, 1));
  } else {
    mainWindow.setProgressBar(-1);
  }
});

ipc.on('showMenu', (event, arg) => buildMenu(arg));

ipc.on('isSteamRunning', event => {
  // For some reason, ps-list doesn't work in the renderer.
  // So we call isSteamRunning here instead.
  require('./steps/init').isSteamRunning()
    .subscribe(x => event.sender.send('isSteamRunning', x));
});

// Quit when all windows are closed. Even on OS X.
app.on('window-all-closed', () => app.quit());

// Build menus
function buildMenu(includeDevTools) {
  // Get some helpers
  function parentMenu(label, role, ...submenu) {
    const realsub = new Menu();
    for (const x of _.compact(submenu)) {
      realsub.append(x);
    }
    return new MenuItem({label, role, submenu: realsub});
  }
  const miniItem = (label, accelerator, role) => new MenuItem({label, accelerator, role});
  const fancyItem = (label, accelerator, click) => new MenuItem({label, accelerator, click});
  const sep = () => new MenuItem({type: 'separator'});

  const menu = new Menu();

  const isDarwin = process.platform === 'darwin';

  if (isDarwin) {
    menu.append(parentMenu('Relief Valve', undefined,
      [miniItem('About Relief Valve', undefined, 'about'),
      sep(),
      miniItem('Hide Relief Valve', 'Command+H', 'hide'),
      miniItem('Hide Others', 'Command+Alt+H', 'hideothers'),
      miniItem('Show All', undefined, 'unhide'),
      sep(),
      fancyItem('Quit', 'Command+Q', () => app.quit())]
    ));
  }

  menu.append(parentMenu('View', undefined, [
    fancyItem('Reload', 'CmdOrCtrl+R', (item, focusedWindow) => focusedWindow && focusedWindow.reload()),
    includeDevTools && (
      fancyItem('Toggle Developer Tools', isDarwin ? 'Alt+Command+I' : 'Ctrl+Shift+I', (item, focusedWindow) => focusedWindow && focusedWindow.toggleDevTools())
    )
  ]));
  menu.append(parentMenu('Window', 'window', [
    miniItem('Minimize', 'CmdOrCtrl+M', 'minimize'),
    miniItem('Close', 'CmdOrCtrl+W', 'close'),
    isDarwin && sep(),
    isDarwin && miniItem('Bring All to Front', undefined, 'front')]
  ));
  menu.append(parentMenu('Help', 'help', [
    fancyItem('Relief Valve Website', undefined, () => shell.openExternal('http://code.mathphreak.me/ReliefValve')),
    !isDarwin && fancyItem('About Relief Valve', undefined, () => mainWindow.webContents.send('menuItem', 'about'))
  ]));

  Menu.setApplicationMenu(menu);
}

// This method will be called when Electron has done everything
// initialization and ready for creating browser windows.
app.on('ready', () => {
  // Create the browser window.
  mainWindow = new BrowserWindow({width: 800, height: 600, show: false});

  // By default, don't show dev tools in the menu
  buildMenu(false);

  const url = `file://${__dirname}/index.html`;

  // and load the index.html of the app.
  mainWindow.loadURL(url);

  mainWindow.show();

  // Emitted when the window is closed.
  mainWindow.on('closed', () => {
    // Dereference the window object, usually you would store windows
    // in an array if your app supports multi windows, this === the time
    // when you should delete the corresponding element.
    mainWindow = null;
  });
});
