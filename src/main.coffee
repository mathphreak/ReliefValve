# Module to control application life.
app = require('electron').app
# Module to create native browser window.
BrowserWindow = require('electron').BrowserWindow
# Module to communicate with browser window.
ipc = require('electron').ipcMain
# Module to control application menu
Menu = require('electron').Menu
MenuItem = require('electron').MenuItem
# Module that can open URLs
shell = require('electron').shell
_ = require 'lodash'

# Keep a global reference of the window object, if you don't, the window will
# be closed automatically when the javascript object is GCed.
mainWindow = null

ipc.on 'progress', (event, arg) ->
  if _.isNumber arg
    mainWindow?.setProgressBar? _.clamp arg, 0.01, 1
  else
    mainWindow?.setProgressBar? -1

ipc.on 'showMenu', (event, arg) ->
  buildMenu arg

# Quit when all windows are closed.
app.on 'window-all-closed', ->
  if process.platform isnt 'darwin'
    app.quit()

# Build menus
buildMenu = (includeDevTools) ->
  # Get some helpers
  parentMenu = (label, role, submenu...) ->
    realsub = new Menu()
    realsub.append(x) for x in _.compact submenu
    new MenuItem {label, role, submenu: realsub}
  miniItem = (label, accelerator, role) ->
    new MenuItem {label, accelerator, role}
  fancyItem = (label, accelerator, click) ->
    new MenuItem {label, accelerator, click}
  sep = -> new MenuItem {type: 'separator'}

  menu = new Menu()

  if process.platform is 'darwin'
    menu.append parentMenu 'Relief Valve', undefined,
      miniItem 'About Relief Valve', undefined, 'about'
      sep()
      miniItem 'Hide Relief Valve', 'Command+H', 'hide'
      miniItem 'Hide Others', 'Command+Alt+H', 'hideothers'
      miniItem 'Show All', undefined, 'unhide'
      sep()
      fancyItem 'Quit', 'Command+Q', -> app.quit()

  menu.append parentMenu 'View', undefined,
      fancyItem 'Reload', 'CmdOrCtrl+R', (item, focusedWindow) ->
        focusedWindow?.reload()
      if includeDevTools
        fancyItem 'Toggle Developer Tools',
          if process.platform == 'darwin'
            'Alt+Command+I'
          else
            'Ctrl+Shift+I'
          , (item, focusedWindow) ->
            focusedWindow?.toggleDevTools()
  menu.append parentMenu 'Window', 'window',
      miniItem 'Minimize', 'CmdOrCtrl+M', 'minimize'
      miniItem 'Close', 'CmdOrCtrl+W', 'close'
      if process.platform is 'darwin'
        sep()
        miniItem 'Bring All to Front', undefined, 'front'
  menu.append parentMenu 'Help', 'help',
      fancyItem 'Relief Valve Website', undefined, ->
        shell.openExternal 'http://code.mathphreak.me/ReliefValve'
      if process.platform isnt 'darwin'
        fancyItem 'About Relief Valve', undefined, ->
          mainWindow.webContents.send 'menuItem', 'about'

  Menu.setApplicationMenu menu

# This method will be called when Electron has done everything
# initialization and ready for creating browser windows.
app.on 'ready', ->
  # Create the browser window.
  mainWindow = new BrowserWindow width: 800, height: 600, show: false

  # By default, don't show dev tools in the menu
  buildMenu(false)

  url = "file://#{__dirname}/index.html"

  # and load the index.html of the app.
  mainWindow.loadURL(url)

  mainWindow.show()

  # Emitted when the window is closed.
  mainWindow.on 'closed', ->
    # Dereference the window object, usually you would store windows
    # in an array if your app supports multi windows, this is the time
    # when you should delete the corresponding element.

    mainWindow = null
