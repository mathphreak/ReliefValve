import pathMod from 'path';
import child from 'child_process';
import fs from 'fs.extra';
import del from 'del';
import _ from 'lodash';
import Rx from '../util/rx';

export const DUMMY_SIZE = 1337;

export function makeBuilder(destination) {
  return game => {
    const acfName = pathMod.basename(game.acfPath);
    return {
      source: game.fullPath,
      destination: pathMod.join(destination, game.rel),
      acfSource: game.acfPath,
      acfDest: pathMod.join(destination, 'steamapps', acfName),
      gameInfo: game
    };
  };
}

export function moveGame(data) {
  try {
    fs.accessSync(data.destination);
    throw new Error('Destination directory already exists!');
  } catch (err) {
    // good, the destination doesn't exist
  }
  [].concat(data.acfDest).forEach(file => {
    try {
      fs.accessSync(file);
      throw new Error('Destination ACF already exists!');
    } catch (err) {
      // good
    }
  });
  const copyFile = Rx.Observable.fromNodeCallback(fs.copy);
  const observers = [];
  let processLine = () => {};
  let gameCopyProcess = {};
  if (process.platform === 'win32') {
    gameCopyProcess = child.spawn('robocopy.exe', [
      data.source,
      data.destination,
      '/e', // recurse into empty subdirectories
      '/bytes', // print raw byte size
      '/np', // no progress
      '/njh', // no job header
      '/njs', // no job summary
      '/ndl', // don't print directories separately
      '/nc' // don't tell us it's a new file; we don't care
    ]);
    processLine = line => {
      const pieces = line.split(/\t+/);
      if (pieces.length === 2) {
        const fileSize = parseInt(pieces[0], 10);
        observers.forEach(observer => observer.onNext(fileSize));
      }
    };
  } else {
    gameCopyProcess = child.spawn('cp', [
      '-Rvp',
      pathMod.resolve(data.source),
      pathMod.resolve(data.destination, '..')
    ]);
    processLine = line => {
      if (line.trim() !== '') {
        const fileSize = DUMMY_SIZE;
        observers.forEach(observer => observer.onNext(fileSize));
      }
    };
  }
  let dataBuffer = new Buffer(0);
  gameCopyProcess.stdout.on('data', newData => {
    dataBuffer = Buffer.concat([dataBuffer, newData]);
    let lastNewlineIndex = -1;
    let nextNewlineIndex = dataBuffer.indexOf('\n');
    while (nextNewlineIndex > -1) {
      lastNewlineIndex = nextNewlineIndex;
      nextNewlineIndex = dataBuffer.indexOf('\n', lastNewlineIndex + 1);
    }
    if (lastNewlineIndex > -1) {
      const lines = dataBuffer.slice(0, lastNewlineIndex).toString().trim().split('\n');
      dataBuffer = dataBuffer.slice(lastNewlineIndex + 1);
      lines.forEach(processLine);
    }
  });
  gameCopyProcess.stdout.on('error', err => {
    throw err;
  });
  gameCopyProcess.stdout.on('end', () => observers.forEach(observer => observer.onCompleted()));
  const acfPairs = _.zip([].concat(data.acfSource), [].concat(data.acfDest));
  const copyACFs = Rx.Observable.fromArray(acfPairs)
    .flatMap(([src, dst]) => copyFile(src, dst).map(() => DUMMY_SIZE));
  return copyACFs.merge(Rx.Observable.create(observer => observers.push(observer)));
}

export function deleteOriginal(data) {
  let sources = [data.source].concat(data.acfSource);
  // If data.source is a symlink, delete both the link and its target
  const realSource = fs.realpathSync(data.source);
  if (realSource !== data.source) {
    sources = sources.concat(realSource);
  }
  return Rx.Observable.fromPromise(del(sources, {force: true}));
}
