# Module to control application life.
app = require('electron').app
# Module to create native browser window.
BrowserWindow = require('electron').BrowserWindow
# Module to communicate with browser window.
ipc = require('electron').ipcMain
# Module to control application menu
Menu = require('electron').Menu
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
    {label, role, submenu}
  miniItem = (label, accelerator, role) ->
    unless role?
      role = accelerator
      accelerator = undefined
    {label, accelerator, role}
  fancyItem = (label, accelerator, click) ->
    unless click?
      click = accelerator
      accelerator = undefined
    {label, accelerator, click}
  sep = -> {type: 'separator'}

  template = [
    parentMenu 'View', undefined,
      fancyItem 'Reload', 'CmdOrCtrl+R', (item, focusedWindow) ->
        focusedWindow?.reload()
    parentMenu 'Window', 'window',
      miniItem 'Minimize', 'CmdOrCtrl+M', 'minimize'
      miniItem 'Close', 'CmdOrCtrl+W', 'close'
    parentMenu 'Help', 'help',
      fancyItem 'Relief Valve Website', ->
        shell.openExternal 'http://code.mathphreak.me/ReliefValve'
  ]

  if includeDevTools
    devToolsAccelerator = if process.platform == 'darwin'
      'Alt+Command+I'
    else
      'Ctrl+Shift+I'
    template[0].submenu.push fancyItem(
      'Toggle Developer Tools',
      devToolsAccelerator, (item, focusedWindow) ->
      focusedWindow?.toggleDevTools()
    )

  if process.platform == 'darwin'
    template.unshift parentMenu 'Relief Valve', undefined,
      miniItem 'About Relief Valve', 'about'
      sep()
      miniItem 'Hide Relief Valve', 'Command+H', 'hide'
      miniItem 'Hide Others', 'Command+Alt+H', 'hideothers'
      miniItem 'Show All', 'unhide'
      sep()
      fancyItem 'Quit', 'Command+Q', -> app.quit()
    # Window menu.
    template[2].submenu.push sep(), miniItem 'Bring All to Front', 'front'
  else
    # Help menu
    template[2].submenu.push fancyItem 'About Relief Valve', ->
      mainWindow.webContents.send 'menuItem', 'about'

  menu = Menu.buildFromTemplate(template)
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
