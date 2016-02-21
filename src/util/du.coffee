Rx = require 'rx'
walk = require 'walk'

du = (target) ->
  observers = []

  walker = walk.walk target

  totalSize = 0

  # include the target directory itself
  totalNodes = 1

  walker.on 'file', (root, fileStats, next) ->
    totalSize += fileStats.size
    totalNodes++
    next()

  walker.on 'directory', (root, dirStats, next) ->
    totalNodes++
    next()

  # TODO handle errors properly

  walker.on 'end', ->
    observers.forEach (observer) ->
      observer.onNext(size: totalSize, nodes: totalNodes)
      observer.onCompleted()

  Rx.Observable.create (observer) -> observers.push observer

module.exports = du
