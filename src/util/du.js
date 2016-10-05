import walk from 'walk';
import Rx from '../util/rx';

function du(target) {
  const observers = [];

  const walker = walk.walk(target);

  let totalSize = 0;

  // include the target directory itself
  let totalNodes = 1;

  walker.on('file', (root, fileStats, next) => {
    totalSize += fileStats.size;
    totalNodes++;
    next();
  });

  walker.on('directory', (root, dirStats, next) => {
    totalNodes++;
    next();
  });

  // TODO handle errors properly

  walker.on('end', () => observers.forEach(observer => {
    observer.onNext({size: totalSize, nodes: totalNodes});
    observer.onCompleted();
  }));

  return Rx.Observable.create(observer => observers.push(observer));
}

export default du;
