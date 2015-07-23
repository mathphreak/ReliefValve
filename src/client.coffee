_ = require "lodash"
Rx = require 'rx'
filesize = require 'filesize'

pathSteps = require './steps/path'
gameSteps = require './steps/game'
sizeSteps = require './steps/size'
moveSteps = require './steps/move'

# enable long stack traces so that RxJS errors are less terrible to debug
Rx.config.longStackSupport = yes

libraryPath = pathSteps.getDefaultSteamLibraryPath()

folderListPath = "#{libraryPath}/steamapps/libraryfolders.vdf"

Games = []
Paths = []

markGameLoading = (game) ->
  $("#gameList tbody tr")
    .filter -> @dataset.name is game.name
    .children()
    .children("i")
    .addClass("fa-circle-o-notch")
    .addClass("fa-spin")
    .removeClass("fa-gamepad")

updateSelected = ->
  hasSelection = $("tr.selected").size() > 0
  if hasSelection
    $("#globalSelect i")
      .addClass "fa-check-square-o"
      .removeClass "fa-square-o"
  else
    $("#globalSelect i")
      .removeClass "fa-check-square-o"
      .addClass "fa-square-o"
  names = $("tr.selected")
    .get()
    .map (el) -> el.dataset.name
  paths = $("tr.selected td .base")
    .get()
    .map (el) -> el.innerText
  sizes = Math.round($("tr.selected td:last-child")
    .get()
    .map (el) -> parseFloat(el.innerText) * 100
    .reduce(((a, b) -> a + b), 0)) / 100
  goodIndex = null
  $("#selection option").attr "disabled", (i) ->
    if _.contains(paths, Paths[i].abbr)
      yes
    else
      goodIndex ?= i
      null
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
  $("tfoot#selection").toggle(hasSelection)

makeGamesStreamObserver = ->
  seen = no
  Rx.Observer.create (game) ->
    if not seen
      seen = yes
      $("#gameList tbody tr:not(.loading)").remove()
      $("#gameList .loading").show()
    result = Templates.game(game: game, paths: Paths)
    $("#gameList tbody tr")
      .filter -> @dataset.name.localeCompare(game.name) < 0
      .last()
      .after(result)
  , off # use default error handling for now
  , ->
    $("#gameList .loading").hide()

makeSizesStreamObserver = -> Rx.Observer.create ({name, data}) ->
  # update Games
  _.find(Games, "name", name).size = data

  # update game in table
  $("#gameList tbody tr")
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
  totalSize = _(games).pluck("size").reduce((a,b)->a+b+moveSteps.DUMMY_ACF_SIZE)
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
      $("#progress-container").height("0%")
      $(".progress").height(0)
      runProcess()
    , 400

runProcess = ->
  Rx.Observable.just folderListPath
    .flatMap pathSteps.readVDF
    .flatMap pathSteps.parseFolderList
    .map pathSteps.buildPathObject
    .toArray()
    .do (d) ->
      Paths = d
      footer = Templates.footer(paths: d)
      $("tfoot#selection").replaceWith(footer)
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

$ ->
  Rx.Observable.fromEvent $("#refresh"), 'click'
    .startWith "initial load event"
    .subscribe runProcess

  $(document).on "click", "#globalSelect i.fa-check-square-o", (event) ->
    $("tr.selected").removeClass("selected")
    updateSelected()
    event.stopImmediatePropagation()

  $(document).on "click", "#globalSelect i.fa-square-o", (event) ->
    $("tbody tr").addClass("selected")
    updateSelected()
    event.stopImmediatePropagation()

  $(document).on "click", "tbody tr", (event) ->
    $(@).closest("tr").toggleClass("selected")
    updateSelected()
    event.stopImmediatePropagation()

  $(document).on "click", "#move", (event) ->
    # get the selected path
    pathIndex = $("tfoot#selection select")
      .children()
      .map (i,a) ->
        i if a.innerHTML is $("tfoot#selection select").val()
      .get()
      .filter( (x) -> x > -1 )[0]

    destination = Paths[pathIndex].path

    copyProgressObserver = makeCopyProgressObserver()
    verifyProgressObserver = makeVerifyProgressObserver()
    deleteProgressObserver = makeDeleteProgressObserver()

    Rx.Observable.from(Games)
      .filter (game) ->
        $("tr[data-name=\"#{game.name}\"]").hasClass("selected")
      .toArray()
      .do initializeProgress
      .flatMap (x) -> x
      .map moveSteps.makeBuilder destination
      .flatMap (x) ->
        moveSteps.moveGame(x)
          .do copyProgressObserver
          .flatMap moveSteps.verifyFile
          .do verifyProgressObserver
          .last()
          .map -> x
      .flatMap (data) ->
        moveSteps.deleteOriginal(data)
          .map -> data
      .subscribe deleteProgressObserver
