vdf = require 'vdf'
fs = require 'fs'
iconv = require 'iconv-lite'
_ = require "lodash"
pathMod = require 'path'
Rx = require 'rx'
filesize = require 'filesize'
du = require './du'

# bind encodings like win1252 to Node's default tools
iconv.extendNodeEncodings()

Rx.config.longStackSupport = yes

# TODO handle multiple platforms
folderListPath = "C:\\Program Files (x86)\\Steam\\steamapps\\libraryfolders.vdf"

$ ->
  folderListStream = Rx.Observable.just folderListPath

  pathsStream = folderListStream
    .flatMap (detailsPath) ->
      readFile = Rx.Observable.fromNodeCallback fs.readFile
      readFile detailsPath, 'win1252'
    .flatMap (detailsVDF) ->
      parsed = vdf.parse(detailsVDF).LibraryFolders
      # TODO handle multiple platforms
      parsed["0"] = "C:\\Program Files (x86)\\Steam"
      folders = _.pick parsed, (v, k) ->
        _.isFinite parseInt k
      result = []
      _.forOwn folders, (v, k) ->
        result[k] = pathMod.normalize v.replace(/\\\\/g, "\\")
      result
    .map (path) ->
      # TODO handle non-uniqueness
      abbr = pathMod.parse(path).root
      abbr: abbr
      path: pathMod.normalize("#{path}/steamapps/common")
      rest: pathMod.normalize("#{path}/steamapps/common").replace(abbr, "")
    .toArray()
    .do (d) -> window.paths = d
    .flatMap _.identity
    .share()

  gamesStream = pathsStream
    .flatMap (pathDetails, i) ->
      readdir = Rx.Observable.fromNodeCallback fs.readdir
      [Rx.Observable.just({d: pathDetails, i: i}), readdir pathDetails.path]
    .concatMap (x) -> x # we can't just return an array of observables
    .bufferWithCount 2
    .flatMap ([{d: {path, abbr, name}, i}, files]) ->
      _.map files, (name) ->
        abbr: abbr
        rest: pathMod.normalize("#{path}/#{name}").replace(abbr, "")
        name: name
        pathIndex: i
    .share()

  gamesStream.subscribe (game) ->
    # console.log "Rendering #{game.name}"
    result = Templates.game(game: game, paths: paths)
    $("#gameList tbody tr")
      .filter -> @dataset.name.localeCompare(game.name) < 0
      .last()
      .after(result)
  , (err) ->
    console.log err
  , ->
    $("#gameList .loading").remove()

  sizesStream = gamesStream
    .do (game) ->
      $("#gameList tbody tr")
        .filter -> @dataset.name is game.name
        .children()
        .children("i")
        .addClass("fa-circle-o-notch")
        .addClass("fa-spin")
        .removeClass("fa-gamepad")
    .flatMap (game) ->
      duLater = Rx.Observable.fromNodeCallback du
      gamePath = game.abbr + game.rest
      duLater(gamePath).map (d) -> {name: game.name, data: filesize(d, exponent: 3)}
    .subscribe(({name, data}) ->
      $("#gameList tbody tr")
        .filter -> @dataset.name is name
        .children()
        .last()
        .text(data)
    , (-> console.log "Bad stuff happened")
    , -> console.log "Done finding sizes!"
    )

  $(document).on "click", ".edit", (event) ->
    # TODO document this terrible hack
    this.parentElement.parentElement.parentElement.classList.add("editing")

  $(document).on "click", ".save", (event) ->
    # TODO document this terrible hack
    this.parentElement.parentElement.parentElement.classList.remove("editing")
