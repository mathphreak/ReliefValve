Rx = require 'rx'
fs = require 'fs.extra'
copyRecursive = require '../util/copy-recursive'
verify = require '../util/verify'
del = require 'del'
pathMod = require 'path'

DUMMY_ACF_SIZE = 1337

makeBuilder = (destination) -> (game) ->
  acfName = pathMod.basename game.acfPath
  source: game.fullPath
  destination: pathMod.join destination, game.rel
  acfSource: game.acfPath
  acfDest: pathMod.join destination, "steamapps", acfName
  gameInfo: game

moveGame = (data) ->
  copyFile = Rx.Observable.fromNodeCallback(fs.copy)
  copyGame = copyRecursive data.source, data.destination
  copyACF = copyFile(data.acfSource, data.acfDest).map ->
    id: Math.random()
    src: data.acfSource
    dst: data.acfDest
    size: DUMMY_ACF_SIZE
  copyGame
    .merge copyACF

verifyFile = (data) ->
  verify(data.src, data.dst).map (x) ->
    if x
      # verified properly
      return data
    else
      # not verified
      return x

deleteOriginal = (data) ->
  delLater = Rx.Observable.fromNodeCallback del
  delLater([data.source, data.acfSource], force: yes)

module.exports =
  DUMMY_ACF_SIZE: DUMMY_ACF_SIZE
  makeBuilder: makeBuilder
  moveGame: moveGame
  verifyFile: verifyFile
  deleteOriginal: deleteOriginal
