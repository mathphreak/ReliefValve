Rx = require 'rx'
walk = require 'walk'

du = (target) ->
  observers = []

  walker = walk.walk target

  totalSize = 0

  walker.on "file", (root, fileStats, next) ->
    totalSize += fileStats.size
    next()

  # TODO handle errors properly

  walker.on "end", ->
    observers.forEach (observer) ->
      observer.onNext(totalSize)
      observer.onCompleted()

  Rx.Observable.create (observer) -> observers.push observer

module.exports = du
