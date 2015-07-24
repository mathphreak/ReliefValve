Rx = require 'rx'
psList = require 'ps-list'
_ = require 'lodash'

isSteamRunning = (searchTarget = "steam") ->
  listLater = Rx.Observable.fromNodeCallback psList
  listLater().map (data) ->
    _.any data, (x) -> _.contains x.name.toLowerCase(), searchTarget

module.exports =
  isSteamRunning: isSteamRunning
