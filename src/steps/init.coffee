Rx = require 'rx'
psList = require 'ps-list'
_ = require 'lodash'
request = require 'request'
semver = require 'semver'

isSteamRunning = (searchTarget = "steam") ->
  Rx.Observable.fromPromise psList()
    .map (data) ->
      _.any data, (x) -> _.contains x.name.toLowerCase(), searchTarget

updateMessage = (currentVersion = require('../../package.json').version) ->
  requestLater = Rx.Observable.fromNodeCallback request
  requestLater(
    url: 'https://api.github.com/repos/mathphreak/ReliefValve/releases/latest'
    headers:
      Accept: 'application/vnd.github.v3+json'
      'User-Agent': 'request'
    json: yes
  ).flatMap ([metadata, latestRelease]) ->
    latestVersion = latestRelease.tag_name
    if semver.lt currentVersion, latestVersion
      Rx.Observable.just [
        "An update to Relief Valve #{latestVersion} is
        available (you're running #{currentVersion})"
        latestRelease.html_url
      ]
    else
      Rx.Observable.empty()

module.exports =
  isSteamRunning: isSteamRunning
  updateMessage: updateMessage
