_ = require 'lodash'
Rx = require 'rx'
ipc = require('electron').ipcRenderer
storage = require 'electron-json-storage'

initSteps = require '../steps/init'
{fetchCategories} = require('./games')

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
        v#{require('../package.json').version}</p>"

ready = ->
  watchForKonamiCode()

  runUpdateCheck()

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
          fetchCategories()
    event.stopImmediatePropagation()
    event.preventDefault()

  $(document).on 'click', 'a[target="_blank"]', (event) ->
    alert 'If it asks for a domain name, just put random garbage'
    require('electron').shell.openExternal(@href)
    event.preventDefault()

module.exports = {ready}
