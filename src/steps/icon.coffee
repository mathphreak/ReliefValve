Rx = require 'rx'
steamcmd = require 'steamcmd'
_ = require 'lodash'

prep = _.once steamcmd.prep

getIconURL = (appID) ->
  # TODO ensure steamcmd.prep() has run at some point
  Rx.Observable.fromPromise prep()
    .flatMap -> steamcmd.getAppInfo appID
    .map (appInfo) ->
      'https://steamcdn-a.akamaihd.net/steamcommunity/public/images/apps/' +
      "#{appID}/#{appInfo.common.icon}.jpg"

module.exports =
  getIconURL: getIconURL
