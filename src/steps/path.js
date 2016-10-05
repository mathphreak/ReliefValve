import fs from 'fs';
import pathMod from 'path';
import os from 'os';
import iconv from 'iconv-lite';
import vdf from 'vdf';
import _ from 'lodash';
import Rx from '../util/rx';

const steamLibraryPaths = {
  win32: {
    x64: 'C:\\Program Files (x86)\\Steam',
    ia32: 'C:\\Program Files\\Steam'
  },
  darwin: `${process.env.HOME}/Library/Application Support/Steam`,
  linux: `${process.env.HOME}/.local/share/Steam`
};

export function getDefaultSteamLibraryPath() {
  let result = steamLibraryPaths[os.platform()];
  if (_.isObject(result)) {
    result = result[os.arch()];
  }
  if (_.isString(result)) {
    return result;
  }
  if (result === undefined) {
    throw new Error('Unsupported OS: ' + os.platform());
  }
}

export function readVDF(target) {
  const readFile = Rx.Observable.fromNodeCallback(fs.readFile);
  return readFile(target)
    .map(x => iconv.decode(x, 'win1252'))
    .map(vdf.parse);
}

export function parseFolderList(details) {
  const parsed = details.LibraryFolders;
  parsed['0'] = getDefaultSteamLibraryPath();
  const folders = _.pickBy(parsed, (v, k) => _.isFinite(parseInt(k, 10)));
  const paths = [];
  _.forOwn(folders, (v, k) => {
    paths[k] = pathMod.normalize(v.replace(/\\\\/g, '\\'));
  });

  const result = [];

  function buildPathObject(path, i) {
    const segments = pathMod.normalize(path).split(pathMod.sep);
    let k = 1;
    let conflict = -1;
    let x = -1;
    function find() {
      return _.findIndex(result, otherPath => {
        const otherPathSegments = pathMod.normalize(otherPath.path).split(pathMod.sep);
        const myKAbbr = segments.slice(0, k).join(pathMod.sep);
        const otherKAbbr = otherPathSegments.slice(0, k).join(pathMod.sep);
        return myKAbbr === otherKAbbr;
      });
    }
    while ((x = find()) > -1 && x !== i) {
      k++;
      conflict = x;
    }
    result[i] = {
      abbr: segments.slice(0, k).join(pathMod.sep) + pathMod.sep,
      path: pathMod.normalize(path),
      rest: segments.slice(k).join(pathMod.sep)
    };
    if (conflict > -1) {
      const conflictPath = result[conflict].path;
      const conflictSegments = pathMod.normalize(conflictPath).split(pathMod.sep);
      result[conflict] = {
        abbr: conflictSegments.slice(0, k).join(pathMod.sep) + pathMod.sep,
        path: pathMod.normalize(conflictPath),
        rest: conflictSegments.slice(k).join(pathMod.sep)
      };
    }
  }

  paths.forEach(buildPathObject);

  return result.map(x => ({
    abbr: x.abbr,
    path: x.path,
    rest: x.rest
  }));
}
