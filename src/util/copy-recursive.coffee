Rx = require 'rx'
walk = require 'walk'
path = require 'path'
fs = require 'fs.extra'

copy = (src, dst) ->
  observers = []

  allNext = (args...) ->
    observers.forEach (observer) ->
      observer.onNext args...

  fs.mkdirp path.join(dst), ->
    walker = walk.walk src

    walker.on "directory", (root, stat, next) ->
      newDir = path.join(dst, root.substr(src.length + 1), stat.name)
      fs.mkdirp newDir, stat.mode, next

    walker.on "file", (root, stat, next) ->
      curFile = path.join(root, stat.name)
      newFile = path.join(dst, root.substr(src.length + 1), stat.name)
      fs.copy curFile, newFile, (err) ->
        if err?
          # crap
          console.log "Something went bad while copying"
        else
          allNext
            id: Math.random()
            src: curFile
            dst: newFile
            size: stat.size
          next()

    # TODO handle errors properly

    walker.on "end", ->
      observers.forEach (observer) ->
        observer.onCompleted()

  Rx.Observable.create (observer) -> observers.push observer

module.exports = copy
