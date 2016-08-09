import pathMod from 'path';
import fs from 'fs';
import Rx from 'rx';
import glob from 'glob';
import _ from 'lodash';
import vdf from 'vdf';
import SteamID from 'steamid-interop';
import userinfo from 'steam-userinfo';

export function getAccountIDs(rootLibPath) {
  const userdata = pathMod.join(rootLibPath, 'userdata');
  const globBetter = Rx.Observable.fromNodeCallback(glob);
  return globBetter('*', {cwd: userdata});
}

export function getUsernames(acctIDs, steamAPIKey) {
  userinfo.setup(steamAPIKey);
  const steamIDs = acctIDs.map(x => SteamID.decode(`[U:1:${x}]`).toString()).join(',');
  const userinfoLater = Rx.Observable.fromNodeCallback(userinfo.getUserInfo);
  return userinfoLater(steamIDs)
    .map(({response: {players}}) => {
      return _.fromPairs(players.map(({steamid, personaname}) => [SteamID.decode(steamid).accountID, personaname]));
    });
}

export function getCategories(rootLibPath, acctID) {
  const sharedconfigPath = pathMod.join(rootLibPath, 'userdata', acctID, '7',
    'remote', 'sharedconfig.vdf');
  const readFile = Rx.Observable.fromNodeCallback(fs.readFile);
  return readFile(sharedconfigPath, 'utf8')
    .map(vdf.parse)
    .map(sharedconfig => {
      let configStore = sharedconfig.UserLocalConfigStore;
      if (!configStore) {
        configStore = sharedconfig.UserRoamingConfigStore;
      }
      let config = configStore.Software.Valve.Steam.Apps;
      if (!config) {
        config = configStore.Software.Valve.Steam.apps;
      }
      return _(config)
        .mapValues(({tags}) => _.values(tags))
        .toPairs()
        .map(([appID, tags]) => tags.map(tag => [tag, appID]))
        .flatten()
        .groupBy('0')
        .mapValues(pairs => pairs.map(([, appID]) => appID))
        .value();
    });
}
