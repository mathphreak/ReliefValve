import test from 'ava';
import fs from 'fs.extra';
import _ from 'lodash';
import Rx from 'rx';
import tempfile from 'tempfile';

import * as gameSteps from '../src/steps/game';

const rootPath = tempfile('');

test.before('setup for gameSteps', () => {
  fs.mkdirpSync(rootPath + '/library1/steamapps');
  fs.mkdirpSync(rootPath + '/library2/steamapps/common/TestGame');
  fs.writeFileSync(rootPath + '/library2/steamapps/appmanifest_1337.acf',
    `
    "AppState"
    {
      "appID"		"1337"
      "name"		"A Test Game"
      "installdir"		"TestGame"
      "StateFlags"		"4"
    }
    `
  );
  fs.writeFileSync(rootPath + '/library2/steamapps/appmanifest_9001.acf',
    `
    "AppState"
    {
      "appID"		"9001"
      "name"		"A Downloading Game"
      "installdir"		"Downloading"
      "StateFlags"		"1026"
    }
    `
  );
  fs.writeFileSync(rootPath + '/library2/steamapps/appmanifest_42.acf',
    `
    "AppStat"
    {
      "appID"		"42"
      "name"		"A Corrupted appmanifest"
    }
    `
  );
});

test('gameSteps#getPathACFs when there are no games should find no games', async t => {
  const emptyLibPathData = {path: rootPath + '/library1'};
  const {apps} = await gameSteps.getPathACFs(emptyLibPathData, 0).toPromise();
  t.true(_.isEmpty(apps));
});

test('gameSteps#getPathACFs when there are games listed should find the games', async t => {
  const fullLibPathData = {path: rootPath + '/library2'};
  const {apps} = await gameSteps.getPathACFs(fullLibPathData, 0).toPromise();
  t.is(apps.length, 3);
  t.true(_.includes(apps[0], 'appmanifest_1337.acf'));
  t.true(_.includes(apps[1], 'appmanifest_42.acf'));
  t.true(_.includes(apps[2], 'appmanifest_9001.acf'));
});

test('gameSteps#readAllACFs when there is a game installed should parse the ACF file', async t => {
  const desiredACFPath = rootPath + '/library2/steamapps/appmanifest_1337.acf';
  const input = {
    path: {path: rootPath + '/library2'},
    i: 0,
    apps: [desiredACFPath]
  };
  const {path, i, gameInfo, acfPath} = await gameSteps.readAllACFs(input).toPromise();
  t.is(path.path, rootPath + '/library2');
  t.is(i, 0);
  t.is(acfPath, desiredACFPath);
  t.is(gameInfo.appID, '1337');
  t.is(gameInfo.name, 'A Test Game');
  t.is(gameInfo.installdir, 'TestGame');
});

test('gameSteps#readAllACFs when there is a game downloading should not parse the ACF file', async t => {
  const desiredACFPath = rootPath + '/library2/steamapps/appmanifest_9001.acf';
  const input = {
    path: {path: rootPath + '/library2'},
    i: 0,
    apps: [desiredACFPath]
  };
  const games = await gameSteps.readAllACFs(input).toArray().toPromise();
  t.is(games.length, 0);
});

test('gameSteps#readAllACFs when there is a game with a broken appmanifest should throw a meaningful error', async t => {
  const desiredACFPath = rootPath + '/library2/steamapps/appmanifest_42.acf';
  const input = {
    path: {path: rootPath + '/library2'},
    i: 0,
    apps: [desiredACFPath]
  };
  const err = await gameSteps.readAllACFs(input).toArray().catch(err => Rx.Observable.just(err)).toPromise();
  t.true(_.isError(err));
  t.is(err.message, `Failed to parse ${desiredACFPath}`);
});
