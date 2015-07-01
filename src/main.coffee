# Module to control application life.
app = require('app')
# Module to create native browser window.
BrowserWindow = require('browser-window')

# use http://git.io/vt4FS

# Report crashes to our server.
require('crash-reporter').start()

# Keep a global reference of the window object, if you don't, the window will
# be closed automatically when the javascript object is GCed.
mainWindow = null

# Quit when all windows are closed.
app.on 'window-all-closed', ->
  if process.platform isnt 'darwin'
    app.quit()

# This method will be called when Electron has done everything
# initialization and ready for creating browser windows.
app.on 'ready', ->
  # Create the browser window.
  mainWindow = new BrowserWindow width: 800, height: 600, show: false

  url = "file://#{__dirname}/index.html"

  # and load the index.html of the app.
  mainWindow.loadUrl(url)

  mainWindow.show()

  # Emitted when the window is closed.
  mainWindow.on 'closed', ->
    # Dereference the window object, usually you would store windows
    # in an array if your app supports multi windows, this is the time
    # when you should delete the corresponding element.

    # don't exit since we're still testing
    # mainWindow = null
