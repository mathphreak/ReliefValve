import test from 'ava';
import fs from 'fs.extra';
import tempfile from 'tempfile';

import loadGameSize from '../src/steps/size';

const gamePath = tempfile('');

let totalSize = 0;

function makeFile(path, mbSize) {
  const fileSize = mbSize * 1024 * 1024;
  totalSize += fileSize;
  fs.writeFileSync(path, new Buffer(fileSize));
}

test.before('setup for sizeSteps', () => {
  fs.mkdirpSync(`${gamePath}/Sub`);
  makeFile(`${gamePath}/Test1`, 3);
  makeFile(`${gamePath}/Test2`, 6);
  makeFile(`${gamePath}/Sub/Test3`, 14);
  makeFile(`${gamePath}/Sub/Test4`, 21);
});

test('sizeSteps#loadGameSize should read sizes properly', async t => {
  const {name, data} = await loadGameSize({name: 'A Game', fullPath: gamePath}).toPromise();
  t.is(name, 'A Game');
  t.is(data.nodes, 1 + 1 + 4);
  t.is(data.size, totalSize);
});
