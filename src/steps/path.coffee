fs = require 'fs'
iconv = require 'iconv-lite'
Rx = require 'rx'
vdf = require 'vdf'
_ = require "lodash"
pathMod = require 'path'
os = require 'os'

# bind encodings like win1252 to Node's default tools
iconv.extendNodeEncodings()

getDefaultSteamLibraryPath = ->
  switch os.platform()
    when 'win32'
      switch os.arch()
        when 'x64'
          "C:\\Program Files (x86)\\Steam"
        when 'ia32'
          "C:\\Program Files\\Steam"
    when 'darwin'
      "~/Library/Application Support/Steam/SteamApps"
    when 'linux'
      "~/.local/share/Steam/steamapps"
    else
      throw Error "Unsupported OS"

readVDF = (target) ->
  readFile = Rx.Observable.fromNodeCallback fs.readFile
  readFile(target, 'win1252').map vdf.parse

parseFolderList = (details) ->
  parsed = details.LibraryFolders
  parsed["0"] = getDefaultSteamLibraryPath()
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
