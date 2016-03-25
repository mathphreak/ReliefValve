EventEmitter = require 'events'
_ = require 'lodash'
Rx = require 'rx'
ipc = require('electron').ipcRenderer

initSteps = require '../steps/init'
moveSteps = require '../steps/move'

vex.defaultOptions.className = 'vex-theme-plain'

# Helper utilities for building buttons
vexSubmitButton = (text) ->
  text: text
  type: 'submit'
  className: 'vex-dialog-button-primary'
vexCancelButton = (text) ->
  text: text
  type: 'button'
  className: 'vex-dialog-button-secondary'
  click: ($vexContent, event) ->
    $vexContent.data().vex.value = false
    return vex.close($vexContent.data().vex.id)

initializeProgress = (games) ->
  sizeKey = if process.platform is 'win32'
    'size'
  else
    'nodes'
  acfSize = if process.platform is 'win32'
    moveSteps.DUMMY_SIZE
  else
    1
  # calculate total size
  totalSize = _(games)
    .map('sizeData')
    .map(sizeKey)
    .map (x) -> x + acfSize
    .reduce((a, b) -> a + b)
  totalSize *= moveSteps.DUMMY_SIZE unless process.platform is 'win32'
  $('#progress-outer').data('total', totalSize)

  # make sure the progress bar starts at zero
  resetProgress()

  # show the progress bar
  $('#progress-container').show()
  $('#progress-container').height('2rem')

resetProgress = ->
  $('#progress-outer').html('')

updateSystemProgress = _.throttle ->
  currentProgress = $('.progress')
    .map (i, x) -> $(x).width()
    .reduce (a, b) -> a + b
  totalProgress = $('#progress-outer').width()
  ipc.send 'progress', currentProgress / totalProgress
, 100

addProgress = (x) ->
  el = $('<div class="progress">&nbsp;</div>')
  el.appendTo('#progress-outer')
  el.data('size', x.size)
  el.data('id', x.id)
  total = parseInt($('#progress-outer').data('total'))
  percent = x.size / total * 100
  el.width 0
  setTimeout ->
    el.width("#{percent}%")
    updateSystemProgress()
  , 1
  yes

combineOverlappingGames = (allGames) ->
  _(allGames)
    .map (oldGame, idx) ->
      game = _.clone oldGame
      duplicates = _.filter allGames, (otherGame, idx2) ->
        otherGame.source is game.source
      _.each duplicates, (otherGame, idx2) ->
        if idx2 isnt idx
          otherGame.drop = yes
      game.acfSource = _.map duplicates, 'acfSource'
      game.acfDest = _.map duplicates, 'acfDest'
      game
    .reject 'drop'
    .value()

makeCopyProgressObserver = -> Rx.Observer.create (x) ->
  addProgress x
, ((x) -> console.log "Error while moving: #{x}")

makeDeleteProgressObserver = -> Rx.Observer.create ((x) -> console.log 'Done!'),
  ((e) -> throw e), (x) ->
    setTimeout ->
      ipc.send 'progress', no
      $('#progress-container').height('0%')
      $('.progress').height(0)
      setTimeout ->
        clGames.emit 'refresh'
      , 400
    , 400

runningConfirm = (cancelText) -> (running) ->
  result = new Rx.Subject()
  if running
    message = "<p>It looks like Steam is currently running.</p>
      <p>If you move games while Steam is running, bad things may happen.</p>
      <p>If you have quit Steam or Steam isn't actually running,
      just continue.</p>"
    vex.dialog.confirm
      message: message
      buttons: [
        vexSubmitButton 'Continue'
        vexCancelButton cancelText
      ]
      callback: (x) ->
        result.onNext(x)
        result.onCompleted()
  else
    result = Rx.Observable.just(yes)
  return result

ready = ->
  $(document).on 'click', '#move:not(.disabled)', (event) ->
    # get the selected path
    pathIndex = $('#selection select')
      .children()
      .map (i, a) ->
        i if a.innerHTML is $('#selection select').val()
      .get()
      .filter( (x) -> x > -1 )[0]

    destination = global.Paths[pathIndex].path

    copyProgressObserver = makeCopyProgressObserver()
    deleteProgressObserver = makeDeleteProgressObserver()

    initSteps.isSteamRunning()
      .flatMap runningConfirm 'Cancel'
      .flatMap (go) ->
        if go
          ipc.send 'progress', 0
          Rx.Observable.from global.Games
        else
          Rx.Observable.empty()
      .filter (game) ->
        $(".game[data-name=\"#{game.name}\"]").hasClass('selected')
      .toArray()
      .do initializeProgress
      .flatMap (x) -> x
      .map moveSteps.makeBuilder destination
      .toArray()
      .map combineOverlappingGames
      .flatMap (x) -> x
      .flatMap (x) ->
        moveSteps.moveGame(x)
          .do copyProgressObserver
          .last()
          .map -> x
      .flatMap (gameData) ->
        moveSteps.deleteOriginal(gameData)
          .map -> gameData
      .subscribe deleteProgressObserver

clMove = new EventEmitter

clMove.on 'ready', ready

module.exports = clMove
