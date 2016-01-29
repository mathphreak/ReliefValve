_ = require "lodash"
Rx = require 'rx'
filesize = require 'filesize'
ipc = require 'ipc'

initSteps = require './steps/init'
pathSteps = require './steps/path'
gameSteps = require './steps/game'
sizeSteps = require './steps/size'
moveSteps = require './steps/move'

# enable long stack traces so that RxJS errors are less terrible to debug
Rx.config.longStackSupport = yes

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

libraryPath = pathSteps.getDefaultSteamLibraryPath()

folderListPath = "#{libraryPath}/steamapps/libraryfolders.vdf"

Games = []
Paths = []

shouldVerify = no

markGameLoading = (game) ->
  $("#games .game")
    .filter -> @dataset.name is game.name
    .children()
    .children("i")
    .addClass("fa-circle-o-notch")
    .addClass("fa-spin")
    .removeClass("fa-gamepad")

toggleOverlap = (toggledRow) ->
  thisName = toggledRow.data("name")
  thisFullPath = toggledRow.children(".cell:nth-child(2)").text()
  thisSelected = toggledRow.is(".selected")
  $(".game .cell:nth-child(2)").get().filter (child) ->
    child.innerText.trim() is thisFullPath.trim()
  .forEach (child) ->
    $(child).closest(".game").toggleClass("selected", thisSelected)

updateSelected = ->
  hasSelection = $(".game.selected").size() > 0
  if hasSelection
    $("#globalSelect i")
      .addClass "fa-check-square-o"
      .removeClass "fa-square-o"
  else
    $("#globalSelect i")
      .removeClass "fa-check-square-o"
      .addClass "fa-square-o"
  names = $(".game.selected")
    .get()
    .map (el) -> el.dataset.name
  paths = $(".game.selected .cell .base")
    .get()
    .map (el) -> el.innerText
  sizes = Math.round($(".game.selected .cell:last-child")
    .get()
    .map (el) -> parseFloat(el.innerText) * 100
    .reduce(((a, b) -> a + b), 0)) / 100
  goodIndex = null
  $("#selection option").attr "disabled", (i) ->
    if _.includes(paths, Paths[i].abbr)
      yes
    else
      goodIndex ?= i
      null
  if goodIndex is null
    $("#move").addClass "disabled"
  else
    $("#move").removeClass "disabled"
  if $("#selection option:selected").is(":disabled")
    $("#selection option:not(:disabled)").first().prop("selected", true)
  $("#all-names").text names.join ", "
  $("#all-paths").text paths.join ", "
  if _.isNaN sizes
    if $("#total-size").text() isnt ""
      $("#total-size").html("")
      $("<i></i>")
        .addClass("fa")
        .addClass("fa-circle-o-notch")
        .addClass("fa-spin")
        .appendTo("#total-size")
  else
    $("#total-size").text("#{sizes} GB")
  $("#selection").toggle(hasSelection)
  Ps.update $('#gameList #games').get(0)

makeGamesStreamObserver = ->
  seen = no
  Rx.Observer.create (game) ->
    if not seen
      seen = yes
      $("#games .game:not(.loading)").remove()
      $("#gameList .loading").show()
    result = Templates.game(game: game, paths: Paths)
    $("#games .game")
      .filter -> @dataset.name.localeCompare(game.name) < 0
      .last()
      .after(result)
    Ps.update $('#gameList #games').get(0)
  , off # use default error handling for now
  , ->
    $("#gameList .loading").hide()

makeSizesStreamObserver = -> Rx.Observer.create ({name, data}) ->
  # update Games
  _.find(Games, name: name).size = data

  # update game in table
  $("#games .game")
    .filter -> @dataset.name is name
    .children()
    .last()
    .text filesize(data, exponent: 3)

  # update the footer (recalculate total size of all selected)
  updateSelected()
, off
, off

initializeProgress = (games) ->
  # calculate total size
  totalSize = _(games).map("size").reduce((a,b)->a+b+moveSteps.DUMMY_ACF_SIZE)
  $("#progress-outer").data("total", totalSize)

  # make sure the progress bar starts at zero
  resetProgress()

  # show the progress bar
  $("#progress-container").show()
  $("#progress-container").height("2rem")

resetProgress = ->
  $("#progress-outer").html("")

addProgress = (x) ->
  el = $('<div class="progress">&nbsp;</div>')
  el.appendTo("#progress-outer")
  el.data("size", x.size)
  el.data("id", x.id)
  total = parseInt($("#progress-outer").data("total"))
  percent = x.size / total * 100
  el.width 0
  setTimeout (-> el.width("#{percent}%")), 1
  yes

makeCopyProgressObserver = -> Rx.Observer.create (x) ->
  addProgress x
, ((x) -> console.log "Error while moving: #{x}")

makeVerifyProgressObserver = -> Rx.Observer.create (x) ->
  $(".progress[data-id='#{x.id}']").addClass("verified")

makeDeleteProgressObserver = -> Rx.Observer.create ((x)->console.log "Done!"),
  ((e)->throw e), (x) ->
    setTimeout ->
      ipc.send 'running', no
      $("#progress-container").height("0%")
      $(".progress").height(0)
      runProcess()
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
        vexSubmitButton "Continue"
        vexCancelButton cancelText
      ]
      callback: (x) ->
        result.onNext(x)
        result.onCompleted()
  else
    result = Rx.Observable.just(yes)
  return result

makeSteamRunningObserver = -> Rx.Observer.create (continuing) ->
  if not continuing
    window.close()

runUpdateCheck = ->
  initSteps.updateMessage()
    .subscribe ([message, url]) ->
      vex.dialog.confirm
        message: "<p>#{message}.</p>
          <p>Press OK to download the update or Cancel to not do that.</p>"
        callback: (x) -> require("shell").openExternal url if x

runProcess = ->
  Rx.Observable.just folderListPath
    .flatMap pathSteps.readVDF
    .flatMap pathSteps.parseFolderList
    .toArray()
    .do (d) ->
      Paths = d
      footer = Templates.footer(paths: d)
      $("#selection").replaceWith(footer)
    .flatMap _.identity
    .flatMap gameSteps.getPathACFs
    .flatMap gameSteps.readAllACFs
    .map gameSteps.buildGameObject
    .toArray()
    .do (d) ->
      Games = d
    .flatMap _.identity
    .do makeGamesStreamObserver()
    .observeOn Rx.Scheduler.currentThread
    .do markGameLoading
    .flatMap sizeSteps.loadGameSize
    .subscribe makeSizesStreamObserver()

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

ipc.on 'menuItem', (item) ->
  switch item
    when 'about'
      vex.dialog.alert "<p>You are running Relief Valve
        v#{require('../package.json').version}</p>"
    when 'verifyToggle'
      vex.dialog.confirm
        message: "<p>Verifying copied files is currently
          broken, and Steam can already verify installed games.</p>
          <p>Enable anyways?</p>"
        callback: (x) -> shouldVerify = x

$ ->
  initSteps.isSteamRunning()
    .flatMap runningConfirm "Quit"
    .subscribe makeSteamRunningObserver()

  watchForKonamiCode()

  runUpdateCheck()

  Ps.initialize $('#gameList #games').get(0), suppressScrollX: yes

  Rx.Observable.fromEvent $("#refresh"), 'click'
    .startWith "initial load event"
    .subscribe runProcess

  $(document).on "click", "#globalSelect i.fa-check-square-o", (event) ->
    $(".game.selected").removeClass("selected")
    updateSelected()
    event.stopImmediatePropagation()

  $(document).on "click", "#globalSelect i.fa-square-o", (event) ->
    $("#games .game:not(.loading)").addClass("selected")
    updateSelected()
    event.stopImmediatePropagation()

  $(document).on "click", "#games .game", (event) ->
    $(@).closest(".game").toggleClass("selected")
    toggleOverlap $(event.target).closest(".game")
    updateSelected()
    event.stopImmediatePropagation()

  $(document).on "click", "#move:not(.disabled)", (event) ->
    # get the selected path
    pathIndex = $("#selection select")
      .children()
      .map (i,a) ->
        i if a.innerHTML is $("#selection select").val()
      .get()
      .filter( (x) -> x > -1 )[0]

    destination = Paths[pathIndex].path

    copyProgressObserver = makeCopyProgressObserver()
    verifyProgressObserver = makeVerifyProgressObserver()
    deleteProgressObserver = makeDeleteProgressObserver()

    initSteps.isSteamRunning()
      .flatMap runningConfirm "Cancel"
      .flatMap (go) ->
        if go
          ipc.send 'running', yes
          Rx.Observable.from Games
        else
          Rx.Observable.empty()
      .filter (game) ->
        $(".game[data-name=\"#{game.name}\"]").hasClass("selected")
      .toArray()
      .do initializeProgress
      .flatMap (x) -> x
      .map moveSteps.makeBuilder destination
      .toArray()
      .map combineOverlappingGames
      .flatMap (x) -> x
      .flatMap (x) ->
        if shouldVerify
          moveSteps.moveGame(x)
            .do copyProgressObserver
            .flatMap moveSteps.verifyFile
            .do verifyProgressObserver
            .last()
            .map -> x
        else
          moveSteps.moveGame(x)
            .do copyProgressObserver
            .last()
            .map -> x
      .flatMap (data) ->
        moveSteps.deleteOriginal(data)
          .map -> data
      .subscribe deleteProgressObserver
