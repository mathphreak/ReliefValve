vdf = require 'vdf'
fs = require 'fs'
iconv = require 'iconv-lite'
_ = require "lodash"
{normalize, parse} = require 'path'

# TODO handle multiple platforms
folderListPath = "C:\\Program Files (x86)\\Steam\\steamapps\\libraryfolders.vdf"

$ ->
  lfBuffer = fs.readFileSync folderListPath
  rawVDF = iconv.decode lfBuffer, 'win1252'
  parsedFolders = vdf.parse(rawVDF).LibraryFolders

  keys = Object.getOwnPropertyNames(parsedFolders).filter (x) ->
    parseInt(x) > 0

  libraryPaths = (parsedFolders[n].replace(/\\\\/g, "\\") for n in keys)
  # TODO handle multiple platforms
  libraryPaths.unshift "C:\\Program Files (x86)\\Steam"

  libraryPaths = _(libraryPaths).map(normalize).sortBy().value()

  makePathObj = (path) ->
    abbr: parse(path).root
    path: normalize("#{path}/steamapps/common")
    rest: normalize("#{path}/steamapps/common").replace(parse(path).root, "")

  paths = _.map libraryPaths, makePathObj
  # TODO handle non-uniqueness

  games = _(paths)
    .map ({abbr, path}, i) ->
      _.map fs.readdirSync(path), (name) ->
        abbr: abbr
        rest: normalize("#{path}/#{name}").replace(abbr, "")
        name: name
        i: i
    .flatten()
    .sortBy "name"
    .value()
  result = template(games: games, paths: paths)
  document.getElementsByTagName("body")[0].innerHTML = result

  $(".edit").on "click", (event) ->
    # TODO document this terrible hack
    this.parentElement.parentElement.parentElement.classList.add("editing")

  $(".save").on "click", (event) ->
    # TODO document this terrible hack
    this.parentElement.parentElement.parentElement.classList.remove("editing")
