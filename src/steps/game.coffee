Rx = require 'rx'
glob = require 'glob'
pathMod = require 'path'
fs = require 'fs'
_ = require "lodash"
vdf = require 'vdf'

readACF = (target) ->
  readFile = Rx.Observable.fromNodeCallback fs.readFile
  readFile(target, 'utf8').map vdf.parse

getPathACFs = (pathDetails, i) ->
  globBetter = Rx.Observable.fromNodeCallback glob
  steamappsPath = pathMod.join(pathDetails.path, "steamapps")
  globBetter("appmanifest_*.acf", cwd: steamappsPath)
    .map (matches) ->
      paths = _.map matches, (x) ->
        pathMod.join(steamappsPath, x)
      {path: pathDetails, i: i, apps: paths}

readAllACFs = (pathObj) ->
  Rx.Observable.fromArray(pathObj.apps)
    .flatMap (path) ->
      readACF(path).map (obj) -> {acfPath: path, data: obj}
    .map ({acfPath, data: {AppState}}) ->
      {path: pathObj.path, i: pathObj.i, gameInfo: AppState, acfPath: acfPath}

buildGameObject = ({path, i, gameInfo, acfPath}) ->
  fullPath = pathMod.join(
    path.path,
    "steamapps",
    "common",
    gameInfo.installdir
  )
  pathAbbr: path.abbr
  fullPath: fullPath
  rest: fullPath.replace(path.abbr, "")
  rel: fullPath.replace(path.path, "")
  name: gameInfo.name
  pathIndex: i
  acfPath: acfPath

module.exports =
  getPathACFs: getPathACFs
  readAllACFs: readAllACFs
  buildGameObject: buildGameObject
