Rx = require 'rx'
walk = require 'walk'
path = require 'path'
fs = require 'fs'
XXH = require 'xxhashjs'
_ = require 'lodash'

verify = (templatePath, copyPath) ->
  observers = []

  hashSeed = 0 # XXH(templatePath, 0)

  templateHash = copyHash = no

  templateStream = fs.ReadStream templatePath
  templateHasher = XXH(hashSeed)
  templateStream.on 'data', _.bind templateHasher.update, templateHasher
  templateStream.on 'end', ->
    templateHash = templateHasher.digest().toString()
    if copyHash isnt no
      compare()

  copyStream = fs.ReadStream copyPath
  copyHasher = XXH(hashSeed)
  copyStream.on 'data', _.bind copyHasher.update, copyHasher
  copyStream.on 'end', ->
    copyHash = copyHasher.digest().toString()
    if templateHash isnt no
      compare()

  compare = ->
    if templateHash isnt no and copyHash isnt no
      if templateHash is copyHash
        observers.forEach (observer) ->
          observer.onNext yes
      else
        observers.forEach (observer) ->
          observer.onNext no
      observers.forEach (observer) ->
        observer.onCompleted()

  Rx.Observable.create (observer) ->
    observers.push observer
    compare()

module.exports = verify
