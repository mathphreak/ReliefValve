Rx = require 'rx'
steamcmd = require 'steamcmd'

getIconURL = (appID) ->
  # TODO ensure steamcmd.prep() has run at some point
  # Rx.Observable.fromPromise steamcmd.prep()
  #  .flatMap -> steamcmd.getAppInfo appID
  Rx.Observable.fromPromise steamcmd.getAppInfo appID
    .map (appInfo) ->
      'https://steamcdn-a.akamaihd.net/steamcommunity/public/images/apps/' +
      "#{appID}/#{appInfo.common.icon}.jpg"

module.exports =
  getIconURL: getIconURL
