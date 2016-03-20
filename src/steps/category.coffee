Rx = require 'rx'
glob = require 'glob'
pathMod = require 'path'
fs = require 'fs'
_ = require 'lodash'
vdf = require 'vdf'
SteamID = require 'steamid-interop'
userinfo = require 'steam-userinfo'

getAccountIDs = (rootLibPath) ->
  userdata = pathMod.join rootLibPath, 'userdata'
  globBetter = Rx.Observable.fromNodeCallback glob
  globBetter('*', cwd: userdata)

getUsernames = (acctIDs, steamAPIKey) ->
  userinfo.setup steamAPIKey
  steamIDs = acctIDs.map (x) ->
    SteamID.decode("[U:1:#{x}]").toString()
  .join ','
  userinfoLater = Rx.Observable.fromNodeCallback userinfo.getUserInfo
  userinfoLater(steamIDs)
    .map ({response: {players}}) ->
      _.fromPairs players.map ({steamid, personaname}) ->
        [SteamID.decode(steamid).accountID, personaname]

getCategories = (rootLibPath, acctID) ->
  sharedconfigPath = pathMod.join rootLibPath, 'userdata', acctID, '7',
    'remote', 'sharedconfig.vdf'
  readFile = Rx.Observable.fromNodeCallback fs.readFile
  readFile(sharedconfigPath, 'utf8')
    .map vdf.parse
    .map (sharedconfig) ->
      _(sharedconfig.UserLocalConfigStore.Software.Valve.Steam.apps)
        .mapValues ({tags}) -> _.values(tags)
        .toPairs()
        .map ([appID, tags]) -> tags.map (tag) -> [tag, appID]
        .flatten()
        .groupBy('0')
        .mapValues (pairs) -> pairs.map ([tag, appID]) -> appID
        .value()

module.exports =
  getAccountIDs: getAccountIDs
  getUsernames: getUsernames
  getCategories: getCategories
