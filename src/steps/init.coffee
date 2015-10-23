Rx = require 'rx'
psList = require 'ps-list'
_ = require 'lodash'
request = require 'request'
semver = require 'semver'

latestVersion = undefined

isSteamRunning = (searchTarget = "steam") ->
  Rx.Observable.fromPromise psList()
    .map (data) ->
      _.any data, (x) -> _.contains x.name.toLowerCase(), searchTarget

updateMessage = (currentVersion = require('../../package.json').version) ->
  dataStream = Rx.Observable.just [no, {tag_name: latestVersion}]
  unless latestVersion?
    requestLater = Rx.Observable.fromNodeCallback request
    params =
      url: 'https://api.github.com/repos/mathphreak/ReliefValve/releases/latest'
      headers:
        Accept: 'application/vnd.github.v3+json'
        'User-Agent': 'ReliefValve update check'
      json: yes
    if process.env.GITHUB_API_TOKEN?
      params.headers['Authorization'] = "token #{process.env.GITHUB_API_TOKEN}"
    dataStream = requestLater(params)
  dataStream.materialize().flatMap (data) ->
    if data.kind is 'N'
      [metadata, latestRelease] = data.value
      latestVersion = latestRelease.tag_name
      if latestVersion? and semver.lt currentVersion, latestVersion
        Rx.Observable.just [
          "An update to Relief Valve #{latestVersion} is
          available (you're running #{currentVersion})"
          latestRelease.html_url
        ]
      else
        Rx.Observable.empty()
    else
      Rx.Observable.empty()

module.exports =
  isSteamRunning: isSteamRunning
  updateMessage: updateMessage
