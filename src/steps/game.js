import pathMod from 'path';
import fs from 'fs';
import Rx from 'rx';
import glob from 'glob';
import _ from 'lodash';
import vdf from 'vdf';

const validStateFlags = {
  1: false,
  4: true,
  32: false
};

function readACF(target) {
  const readFile = Rx.Observable.fromNodeCallback(fs.readFile);
  return readFile(target, 'utf8').map(vdf.parse);
}

export function getPathACFs(pathDetails, i) {
  const globBetter = Rx.Observable.fromNodeCallback(glob);
  const steamappsPath = pathMod.join(pathDetails.path, 'steamapps');
  return globBetter('appmanifest_*.acf', {cwd: steamappsPath})
    .map(matches => {
      const paths = _.map(matches, x => pathMod.join(steamappsPath, x));
      return {path: pathDetails, i, apps: paths};
    });
}

export function readAllACFs(pathObj) {
  return Rx.Observable.fromArray(pathObj.apps)
    .flatMap(path => readACF(path).map(obj => ({acfPath: path, data: obj})))
    .map(({acfPath, data: {AppState}}) =>
      ({path: pathObj.path, i: pathObj.i, gameInfo: AppState, acfPath}))
    .filter(({gameInfo, acfPath}) => {
      try {
        const state = parseInt(gameInfo.StateFlags, 10);
        return _.every(_.toPairs(validStateFlags), ([flag, val]) => ((state & parseInt(flag, 10)) === parseInt(flag, 10)) === val);
      } catch (err) {
        throw new Error(`Failed to parse ${acfPath}`);
      }
    });
}

export function buildGameObject({path, i, gameInfo, acfPath}) {
  const fullPath = pathMod.join(
    path.path,
    'steamapps',
    'common',
    gameInfo.installdir
  );
  return {
    pathAbbr: path.abbr,
    fullPath,
    rest: fullPath.replace(path.abbr, ''),
    rel: fullPath.replace(path.path, ''),
    name: gameInfo.name,
    pathIndex: i,
    acfPath,
    appID: gameInfo.appID || gameInfo.appid
  };
}
