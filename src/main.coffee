# Module to control application life.
app = require('app')
# Module to create native browser window.
BrowserWindow = require('browser-window')
# Module to communicate with browser window.
ipc = require 'ipc'
# Module to control application menu
Menu = require 'menu'

# Keep a global reference of the window object, if you don't, the window will
# be closed automatically when the javascript object is GCed.
mainWindow = null

emptyMenuTemplate = -> []

menuTemplate = ->
  if process.platform is 'darwin'
    [
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
        label: 'View'
        submenu: [
          {
            label: 'Reload'
            accelerator: 'Cmd+R'
            click: -> mainWindow.reload()
          }
          {
            label: 'Toggle DevTools'
            accelerator: 'Option+Cmd+I'
            click: -> mainWindow.toggleDevTools()
          }
        ]
      }
    ]
  else
    [
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
        label: 'View'
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
        ]
      }
    ]

ipc.on 'running', (event, arg) ->
  console.log "Running: #{arg}"
  if arg is yes
    mainWindow?.setProgressBar 1.1
  else
    mainWindow?.setProgressBar -1

ipc.on 'showMenu', (event, arg) ->
  console.log "Menu: #{arg}"
  if arg is yes
    Menu.setApplicationMenu Menu.buildFromTemplate menuTemplate()
  else
    Menu.setApplicationMenu Menu.buildFromTemplate emptyMenuTemplate()

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
  Menu.setApplicationMenu Menu.buildFromTemplate emptyMenuTemplate()

  url = "file://#{__dirname}/index.html"

  # and load the index.html of the app.
  mainWindow.loadUrl(url)

  mainWindow.show()

  # Emitted when the window is closed.
  mainWindow.on 'closed', ->
    # Dereference the window object, usually you would store windows
    # in an array if your app supports multi windows, this is the time
    # when you should delete the corresponding element.

    mainWindow = null
