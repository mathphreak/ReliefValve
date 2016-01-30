# Module to control application life.
app = require('electron').app
# Module to create native browser window.
BrowserWindow = require('electron').BrowserWindow
# Module to communicate with browser window.
ipc = require('electron').ipcMain
# Module to control application menu
Menu = require('electron').Menu

# Keep a global reference of the window object, if you don't, the window will
# be closed automatically when the javascript object is GCed.
mainWindow = null

noMenu = ->
  if process.platform is 'darwin'
    Menu.buildFromTemplate [
      {
        label: 'Relief Valve'
        submenu: [
          {
            label: 'About Relief Valve'
            selector: 'orderFrontStandardAboutPanel:'
          }
        ]
      }
    ]
  else
    null

fullMenu = ->
  if process.platform is 'darwin'
    Menu.buildFromTemplate [
      {
        label: 'Relief Valve'
        submenu: [
          {
            label: 'About Relief Valve'
            selector: 'orderFrontStandardAboutPanel:'
          }
        ]
      }
      {
        label: 'Tools'
        submenu: [
          {
            label: 'Reload'
            accelerator: 'Cmd+R'
            click: -> mainWindow.reload()
          }
          {
            label: 'Toggle DevTools'
            accelerator: 'Alt+Cmd+I'
            click: -> mainWindow.toggleDevTools()
          }
          {
            label: 'Toggle Verification'
            accelerator: 'Alt+Shift+V'
            click: -> mainWindow.webContents.send 'menuItem', 'verifyToggle'
          }
        ]
      }
    ]
  else
    Menu.buildFromTemplate [
      {
        label: 'Relief Valve'
        submenu: [
          {
            label: 'About Relief Valve'
            click: -> mainWindow.webContents.send 'menuItem', 'about'
          }
        ]
      }
      {
        label: 'Tools'
        submenu: [
          {
            label: 'Reload'
            accelerator: 'Ctrl+R'
            click: -> mainWindow.reload()
          }
          {
            label: 'Toggle DevTools'
            accelerator: 'Shift+Ctrl+I'
            click: -> mainWindow.toggleDevTools()
          }
          {
            label: 'Toggle Verification'
            accelerator: 'Alt+Shift+V'
            click: -> mainWindow.webContents.send 'menuItem', 'verifyToggle'
          }
        ]
      }
    ]

ipc.on 'running', (event, arg) ->
  if arg is yes
    mainWindow?.setProgressBar? 1.1
  else
    mainWindow?.setProgressBar? -1

ipc.on 'showMenu', (event, arg) ->
  if arg is yes
    Menu.setApplicationMenu fullMenu()
  else
    Menu.setApplicationMenu noMenu()

# Quit when all windows are closed.
app.on 'window-all-closed', ->
  if process.platform isnt 'darwin'
    app.quit()

# This method will be called when Electron has done everything
# initialization and ready for creating browser windows.
app.on 'ready', ->
  # Create the browser window.
  mainWindow = new BrowserWindow width: 800, height: 600, show: false

  # Don't use a menu bar.
  Menu.setApplicationMenu noMenu()

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
