fs = require 'fs'
iconv = require 'iconv-lite'
Rx = require 'rx'
vdf = require 'vdf'
_ = require "lodash"
pathMod = require 'path'

# bind encodings like win1252 to Node's default tools
iconv.extendNodeEncodings()

readVDF = (target) ->
  readFile = Rx.Observable.fromNodeCallback fs.readFile
  readFile(target, 'win1252').map vdf.parse

parseFolderList = (details) ->
  parsed = details.LibraryFolders
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
  path: pathMod.normalize(path)
  rest: pathMod.normalize(path).replace(abbr, "")

module.exports =
  readVDF: readVDF
  parseFolderList: parseFolderList
  buildPathObject: buildPathObject
