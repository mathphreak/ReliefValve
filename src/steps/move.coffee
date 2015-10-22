Rx = require 'rx'
fs = require 'fs.extra'
verify = require '../util/verify'
del = require 'del'
pathMod = require 'path'
child = require 'child_process'
_ = require 'lodash'

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
  observers = []
  processLine = (line) ->
  gameCopyProcess = {}
  if process.platform is 'win32'
    ### !pragma coverage-skip-block ###
    gameCopyProcess = child.spawn "robocopy.exe", [
      data.source
      data.destination
      "/e" # recurse into empty subdirectories
      "/bytes" # print raw byte size
      "/np" # no progress
      "/njh" # no job header
      "/njs" # no job summary
      "/ndl" # don't print directories separately
      "/nc" # don't tell us it's a new file; we don't care
    ]
    processLine = (line) ->
      pieces = line.split /\t+/
      if pieces.length is 2
        fileData =
          id: Math.random()
          src: pathMod.normalize pieces[1]
          dst: pathMod.normalize pieces[1].replace data.source, data.destination
          size: parseInt pieces[0]
        observers.forEach (observer) ->
          observer.onNext fileData
  else
    gameCopyProcess = child.spawn "cp", [
      "-Rvp"
      pathMod.resolve data.source
      pathMod.resolve data.destination, ".."
    ]
    processLine = (line) ->
      if line.trim() isnt ""
        pieces = /[‘`](.*?)[’'] -> [‘`](.*?)[’']/.exec line
        fileData =
          id: Math.random()
          src: pathMod.normalize pieces[1]
          dst: pathMod.normalize pieces[2]
          size: DUMMY_ACF_SIZE
        observers.forEach (observer) ->
          observer.onNext fileData
  dataBuffer = new Buffer(0)
  gameCopyProcess.stdout.on 'data', (newData) ->
    dataBuffer = Buffer.concat [dataBuffer, newData]
    lastNewlineIndex = -1
    nextNewlineIndex = dataBuffer.indexOf("\n")
    while nextNewlineIndex > -1
      lastNewlineIndex = nextNewlineIndex
      nextNewlineIndex = dataBuffer.indexOf("\n", lastNewlineIndex+1)
    if lastNewlineIndex > -1
      lines = dataBuffer.slice(0, lastNewlineIndex).toString().trim().split "\n"
      dataBuffer = dataBuffer.slice lastNewlineIndex+1
      for line in lines
        processLine line
  gameCopyProcess.stdout.on 'error', (err) ->
  gameCopyProcess.stdout.on 'end', ->
    observers.forEach (observer) ->
      observer.onCompleted()
  acfPairs = _.zip([].concat(data.acfSource), [].concat(data.acfDest))
  copyACFs = Rx.Observable.fromArray(acfPairs)
    .flatMap ([src, dst]) ->
      copyFile(src, dst)
    .map ->
      id: Math.random()
      src: data.acfSource
      dst: data.acfDest
      size: DUMMY_ACF_SIZE
  copyACFs.merge Rx.Observable.create (observer) ->
    observers.push observer

verifyFile = (data) ->
  verify(data.src, data.dst).map (x) ->
    if x
      # verified properly
      return data
    else
      # not verified
      return x

deleteOriginal = (data) ->
  Rx.Observable.fromPromise del([data.source, data.acfSource], force: yes)

module.exports =
  DUMMY_ACF_SIZE: DUMMY_ACF_SIZE
  makeBuilder: makeBuilder
  moveGame: moveGame
  verifyFile: verifyFile
  deleteOriginal: deleteOriginal
