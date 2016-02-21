fs = require 'fs'
iconv = require 'iconv-lite'
Rx = require 'rx'
vdf = require 'vdf'
_ = require 'lodash'
pathMod = require 'path'
os = require 'os'

getDefaultSteamLibraryPath = ->
  ### !pragma coverage-skip-next ###
  switch os.platform()
    when 'win32'
      switch os.arch()
        when 'x64'
          'C:\\Program Files (x86)\\Steam'
        when 'ia32'
          'C:\\Program Files\\Steam'
    when 'darwin'
      "#{process.env.HOME}/Library/Application Support/Steam"
    when 'linux'
      "#{process.env.HOME}/.local/share/Steam"
    else
      throw Error 'Unsupported OS'

readVDF = (target) ->
  readFile = Rx.Observable.fromNodeCallback fs.readFile
  readFile(target)
    .map (x) -> iconv.decode(x, 'win1252')
    .map vdf.parse

parseFolderList = (details) ->
  parsed = details.LibraryFolders
  parsed['0'] = getDefaultSteamLibraryPath()
  folders = _.pickBy parsed, (v, k) ->
    _.isFinite parseInt k
  paths = []
  _.forOwn folders, (v, k) ->
    paths[k] = pathMod.normalize v.replace(/\\\\/g, '\\')

  result = []

  buildPathObject = (path, i) ->
    segments = pathMod.normalize(path).split(pathMod.sep)
    k = 1
    conflict = -1
    x = -1
    find = -> _.findIndex result, (otherPath) ->
      otherPathSegments = pathMod.normalize(otherPath.path).split(pathMod.sep)
      myKAbbr = segments[0...k].join(pathMod.sep)
      otherKAbbr = otherPathSegments[0...k].join(pathMod.sep)
      myKAbbr is otherKAbbr
    while (x = find()) > -1 and x isnt i
      k++
      conflict = x
    result[i] =
      abbr: segments[0...k].join(pathMod.sep) + pathMod.sep
      path: pathMod.normalize(path)
      rest: segments[k..].join(pathMod.sep)
    if conflict > -1
      conflictPath = result[conflict].path
      conflictSegments = pathMod.normalize(conflictPath).split(pathMod.sep)
      result[conflict] =
        abbr: conflictSegments[0...k].join(pathMod.sep) + pathMod.sep
        path: pathMod.normalize(conflictPath)
        rest: conflictSegments[k..].join(pathMod.sep)

  paths.forEach buildPathObject

  result.map (x) ->
    abbr: x.abbr
    path: x.path
    rest: x.rest

module.exports =
  getDefaultSteamLibraryPath: getDefaultSteamLibraryPath
  readVDF: readVDF
  parseFolderList: parseFolderList
