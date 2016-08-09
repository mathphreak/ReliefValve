import test from 'ava';
import fs from 'fs.extra';
import Rx from 'rx';
import lipsum from 'lorem-ipsum';
import tempfile from 'tempfile';

import * as moveSteps from '../src/steps/move';

const rootPath = tempfile('');

const sourcePath = `${rootPath}/move_src/Test`;
const destPath = `${rootPath}/move_dst/Test`;
const dualSrcPath = `${rootPath}/move_dsrc/Test`;
const dualDstPath = `${rootPath}/move_ddst/Test`;
const failPath = `${rootPath}/move_fail/Test`;
const deletePath = `${rootPath}/move_delete/Test`;

const acfData = lipsum();
const test1Data = lipsum();
const test2Data = lipsum();
const test3Data = lipsum();

const opt = {encoding: 'utf8'};

test.before('setup for moveSteps', () => {
  fs.mkdirpSync(`${sourcePath}/Sub`);
  fs.writeFileSync(`${sourcePath}.acf`, acfData);
  fs.writeFileSync(`${sourcePath}/Test1.txt`, test1Data);
  fs.writeFileSync(`${sourcePath}/Sub/Test2.txt`, test2Data);
  fs.writeFileSync(`${sourcePath}/Test3.txt`, test3Data);
  fs.writeFileSync(`${sourcePath}/Test3Again.txt`, test3Data);
  fs.writeFileSync(`${sourcePath}/NotTest3.txt`, `This isn't ${test3Data}`);
  // generate some dust
  for (let i = 0; i < 1000; i++) {
    fs.writeFileSync(`${sourcePath}/Sub/${Math.random()}.txt`, lipsum());
  }
  fs.mkdirpSync(`${destPath}`);
  fs.mkdirpSync(dualSrcPath);
  fs.writeFileSync(`${dualSrcPath}1.acf`, `1 ${acfData}`);
  fs.writeFileSync(`${dualSrcPath}2.acf`, `2 ${acfData}`);
  fs.writeFileSync(`${dualSrcPath}/Test1.txt`, test1Data);
  fs.mkdirpSync(dualDstPath);
  fs.mkdirpSync(failPath);
  fs.writeFileSync(`${failPath}.acf`, 'Nope!');
  fs.mkdirpSync(deletePath);
  fs.writeFileSync(`${deletePath}.acf`, acfData);
  fs.writeFileSync(`${deletePath}/Test1.txt`, test1Data);
});

test('moveSteps#moveGame when the destination doesn\'t already exist should move everything', async t => {
  await moveSteps.moveGame({
    source: sourcePath,
    destination: destPath,
    acfSource: `${sourcePath}.acf`,
    acfDest: `${destPath}.acf`
  }).toPromise();
  const newContents = fs.readFileSync(`${destPath}.acf`, opt);
  t.is(newContents, acfData);
  const newContents1 = fs.readFileSync(`${destPath}/Test1.txt`, opt);
  t.is(newContents1, test1Data);
  const newContents2 = fs.readFileSync(`${destPath}/Sub/Test2.txt`, opt);
  t.is(newContents2, test2Data);
  const newContents3 = fs.readFileSync(`${destPath}/Test3.txt`, opt);
  t.is(newContents3, test3Data);
});

test('moveSteps#moveGame when the destination already exists should cause an error and not copy anything', async t => {
  function failPathExists() {
    try {
      fs.accessSync(`${failPath}/Test1.txt`);
      console.log(failPath, 'got copied to! Wat');
      return true;
    } catch (err) {
      return false;
    }
  }
  const error = await moveSteps.moveGame({
    source: sourcePath,
    destination: failPath,
    acfSource: `${sourcePath}.acf`,
    acfDest: `${failPath}.acf`
  }).catch(err => Rx.Observable.just(err)).toPromise();
  t.truthy(error);
  t.false(failPathExists());
});

test('moveSteps#moveGame when there are multiple ACF files should move both ACFs and game files', async t => {
  await moveSteps.moveGame({
    source: dualSrcPath,
    destination: dualDstPath,
    acfSource: [`${dualSrcPath}1.acf`, `${dualSrcPath}2.acf`],
    acfDest: [`${dualDstPath}1.acf`, `${dualDstPath}2.acf`]
  }).toPromise();
  const newContents1 = fs.readFileSync(`${dualDstPath}1.acf`, opt);
  t.is(newContents1, `1 ${acfData}`);
  const newContents2 = fs.readFileSync(`${dualDstPath}2.acf`, opt);
  t.is(newContents2, `2 ${acfData}`);
  const newContents = fs.readFileSync(`${destPath}/Test1.txt`, opt);
  t.is(newContents, test1Data);
});

test('moveSteps#deleteOriginal should delete the source', async t => {
  await moveSteps.deleteOriginal({
    source: deletePath,
    acfSource: `${deletePath}.acf`
  }).toPromise();
  t.throws(() => fs.readFileSync(`${deletePath}/Test1.txt`));
  t.throws(() => fs.readdirSync(deletePath));
  t.throws(() => fs.readFileSync(`${deletePath}.acf`));
});
