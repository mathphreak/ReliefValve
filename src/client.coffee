vdf = require 'vdf'
fs = require 'fs.extra'
iconv = require 'iconv-lite'
_ = require "lodash"
pathMod = require 'path'
Rx = require 'rx'
filesize = require 'filesize'
du = require './du'

# bind encodings like win1252 to Node's default tools
iconv.extendNodeEncodings()

# enable long stack traces so that RxJS errors are less terrible to debug
Rx.config.longStackSupport = yes

folderListPath = "C:\\Program Files (x86)\\Steam\\steamapps\\libraryfolders.vdf"

Games = []
Paths = []

moveGame = ({source, destination, gameInfo}) ->
  copyRec = Rx.Observable.fromNodeCallback fs.copyRecursive
  copyRec(source, destination)
    .map -> gameInfo

readFolderList = (detailsPath) ->
  readFile = Rx.Observable.fromNodeCallback fs.readFile
  readFile detailsPath, 'win1252'

parseFolderList = (detailsVDF) ->
  parsed = vdf.parse(detailsVDF).LibraryFolders
  parsed["0"] = "C:\\Program Files (x86)\\Steam"
  folders = _.pick parsed, (v, k) ->
    _.isFinite parseInt k
  result = []
  _.forOwn folders, (v, k) ->
    result[k] = pathMod.normalize v.replace(/\\\\/g, "\\")
  result

buildPathObject = (path) ->
  abbr = pathMod.parse(path).root
  abbr: abbr
  path: pathMod.normalize("#{path}/steamapps/common")
  rest: pathMod.normalize("#{path}/steamapps/common").replace(abbr, "")

buildGameObjects = ([{d: {path, abbr, name}, i}, files]) ->
  _.map files, (name) ->
    pathAbbr: abbr
    fullPath: pathMod.normalize "#{path}/#{name}"
    rest: pathMod.normalize("#{path}/#{name}").replace(abbr, "")
    name: name
    pathIndex: i

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
    .join ", "
  paths = $("tr.selected td .base")
    .get()
    .map (el) -> el.innerText
    .join ", "
  sizes = Math.round($("tr.selected td:last-child")
    .get()
    .map (el) -> parseFloat(el.innerText) * 100
    .reduce(((a, b) -> a + b), 0)) / 100
  $("#all-names").text(names)
  $("#all-paths").text(paths)
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

updateProgress = (current) ->
  # save the current state
  $("#progress-inner").data("current", current)

  # do the calculation
  total = parseInt($("#progress-inner").data("total"))
  percent = current / total * 100
  $("#progress-inner").width("#{percent}%")

gamesStreamObserver = Rx.Observer.create (game) ->
  result = Templates.game(game: game, paths: Paths)
  $("#gameList tbody tr")
    .filter -> @dataset.name.localeCompare(game.name) < 0
    .last()
    .after(result)
, off # use default error handling for now
, ->
  $("#gameList .loading").remove()

loadGameSize = (game) ->
  duLater = Rx.Observable.fromNodeCallback du
  gamePath = game.fullPath
  duLater(gamePath)
    .map (d) -> {name: game.name, data: d}

sizesStreamObserver = Rx.Observer.create ({name, data}) ->
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
  totalSize = _(games).pluck("size").reduce((a,b)->a+b)
  $("#progress-inner").data("total", totalSize)

  # set total to number of games because we're lazy
  $("#progress-inner").data("total", games.length)

  # make sure the progress bar starts at zero
  updateProgress 0

  # show the progress bar
  $("#progress-container").show()

progressObserver = Rx.Observer.create (x) ->
  console.log x
  updateProgress parseInt $("#progress-inner").data("current") + 1
, ((x) -> console.log "Error while moving: #{x}")
, -> $("#progress-container").hide()

$ ->
  folderListStream = Rx.Observable.just folderListPath

  pathsStream = folderListStream
    .flatMap readFolderList
    .flatMap parseFolderList
    .map buildPathObject
    .toArray()
    .do (d) ->
      Paths = d
      footer = Templates.footer(paths: d)
      $("tfoot#selection").replaceWith(footer)
    .flatMap _.identity
    .share()

  gamesStream = pathsStream
    .flatMap (pathDetails, i) ->
      readdir = Rx.Observable.fromNodeCallback fs.readdir
      [Rx.Observable.just({d: pathDetails, i: i}), readdir pathDetails.path]
    .concatMap (x) -> x # we can't just return an array of observables
    .bufferWithCount 2
    .flatMap buildGameObjects
    .toArray()
    .do (d) ->
      Games = d
    .flatMap _.identity
    .share()

  gamesStream.subscribe gamesStreamObserver

  sizesStream = gamesStream
    .observeOn Rx.Scheduler.currentThread
    .do markGameLoading
    .flatMap loadGameSize
    .subscribe sizesStreamObserver

  $(document).on "click", "#globalSelect i.fa-check-square-o", (event) ->
    $("tr.selected").removeClass("selected")
    updateSelected()
    event.stopImmediatePropagation()

  $(document).on "click", "#globalSelect i.fa-square-o", (event) ->
    $("tbody tr").addClass("selected")
    updateSelected()
    event.stopImmediatePropagation()

  $(document).on "click", "tbody .select", (event) ->
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

    Rx.Observable.from(Games)
      .filter (game) ->
        $("tr[data-name=\"#{game.name}\"]").hasClass("selected")
      .toArray()
      .do initializeProgress
      .flatMap (x) -> x
      .map (game) ->
        source: game.fullPath
        destination: pathMod.normalize "#{destination}/#{game.name}"
        gameInfo: game
      .flatMap (x) -> moveGame x
      .subscribe progressObserver
    console.log "Moving stuff"
