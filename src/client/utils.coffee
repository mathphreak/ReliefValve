EventEmitter = require 'events'
_ = require 'lodash'
Rx = require 'rx'
ipc = require('electron').ipcRenderer
storage = require 'electron-json-storage'

initSteps = require '../steps/init'

runUpdateCheck = ->
  initSteps.updateMessage()
    .subscribe ([message, url]) ->
      vex.dialog.confirm
        message: "<p>#{message}.</p>
          <p>Press OK to download the update or Cancel to not do that.</p>"
        callback: (x) -> require('shell').openExternal url if x

watchForKonamiCode = ->
  codes = [
    38 # up
    38 # up
    40 # down
    40 # down
    37 # left
    39 # right
    37 # left
    39 # right
    66 # b
    65 # a
  ]
  konami = Rx.Observable.fromArray codes

  Rx.Observable.fromEvent $(document), 'keyup'
    .map (e) ->
      e.keyCode
    .windowWithCount 10, 1 # always take the most recent ten
    .selectMany (x) -> x.sequenceEqual konami
    .filter (x) -> x
    .subscribe ->
      ipc.send 'showMenu', yes

ipc.on 'menuItem', (event, item) ->
  switch item
    when 'about'
      vex.dialog.alert "<p>You are running Relief Valve
        v#{require('../../package.json').version}</p>"

checkPromptConfig = ->
  if global.Paths.length is 1
    vex.dialog.alert 'You only have one Steam library configured, so Relief
      Valve can\'t do much yet; if you want, you can
      <a class="full-button" target="_blank"
      href="http://code.mathphreak.me/ReliefValve/configure.html">get help</a>
      configuring Steam properly.'

addContextMenu = ->
  context = require 'electron-contextmenu-middleware'
  context.use require 'electron-input-menu'
  context.activate()

ready = ->
  watchForKonamiCode()
  addContextMenu()
  runUpdateCheck()

  clGames.on 'pathsLoaded', checkPromptConfig

  $(document).on 'click', '#settings-link', (event) ->
    $('#settings-wrapper').show()
    storage.get 'STEAM_API_KEY', (err, key) ->
      unless _.isEmpty key
        $('#steamAPIkey').val(key)
    event.stopImmediatePropagation()

  $(document).on 'submit', '#settings form', (event) ->
    $('#settings-wrapper').hide()
    storage.get 'STEAM_API_KEY', (err, key) ->
      if key isnt $('#steamAPIkey').val()
        storage.set 'STEAM_API_KEY', $('#steamAPIkey').val(), (err) ->
          clGames.emit 'fetchCategories'
    event.stopImmediatePropagation()
    event.preventDefault()

  $(document).on 'click', 'a[target="_blank"]', (event) ->
    unless _.isEmpty @title
      alert @title
    require('electron').shell.openExternal(@href)
    event.preventDefault()

clUtils = new EventEmitter

clUtils.on 'ready', ready

module.exports = clUtils
