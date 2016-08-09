import pathMod from 'path';
import test from 'ava';
import iconv from 'iconv-lite';
import fs from 'fs.extra';
import _ from 'lodash';
import tempfile from 'tempfile';

import * as pathSteps from '../src/steps/path';

const libraryPath = pathSteps.getDefaultSteamLibraryPath();

const testdata = tempfile('');

const n = (...p) => pathMod.normalize(p.join(pathMod.sep));

test.before('setup for pathSteps', () => {
  fs.mkdirpSync(testdata);
  fs.writeFileSync(n(testdata, 'none.vdf'), iconv.encode(
    `
    "LibraryFolders"
    {
      "TimeNextStatsReport"		"1337133769"
      "ContentStatsID"		"-1337133713371337137"
    }
    `, 'win1252'));
  fs.writeFileSync(n(testdata, 'several-ascii.vdf'), iconv.encode(
    `
    "LibraryFolders"
    {
      "TimeNextStatsReport"		"1337133769"
      "ContentStatsID"		"-1337133713371337137"
      "1"		"E:\\\\TestOne"
      "2"		"F:\\\\TestTwo"
    }
    `, 'win1252'));
  fs.writeFileSync(n(testdata, 'several-extended.vdf'), iconv.encode(
    `
    "LibraryFolders"
    {
      "TimeNextStatsReport"		"1337133769"
      "ContentStatsID"		"-1337133713371337137"
      "1"		"E:\\\\TestÖne"
      "2"		"F:\\\\TéstTwô"
    }
    `, 'win1252'));
});

test('pathSteps#getDefaultSteamLibraryPath should return an absolute path', t => {
  t.true(pathMod.isAbsolute(libraryPath));
});

test('pathSteps#readVDF when there are no folders should parse the file properly', async t => {
  const details = await pathSteps.readVDF(n(testdata, 'none.vdf')).toPromise();
  t.is(details.LibraryFolders['1'], undefined);
});

test('pathSteps#readVDF when there are several folders should parse an ASCII-only file properly', async t => {
  const details = await pathSteps.readVDF(n(testdata, 'several-ascii.vdf')).toPromise();
  t.is(details.LibraryFolders['1'], 'E:\\\\TestOne');
  t.is(details.LibraryFolders['2'], 'F:\\\\TestTwo');
});

test('pathSteps#readVDF when there are several folders should parse a file with extended characters properly', async t => {
  const details = await pathSteps.readVDF(n(testdata, 'several-extended.vdf')).toPromise();
  t.is(details.LibraryFolders['1'], 'E:\\\\TestÖne');
  t.is(details.LibraryFolders['2'], 'F:\\\\TéstTwô');
});

test('pathSteps#parseFolderList when there are no folders should have only the default library', t => {
  const result = pathSteps.parseFolderList({
    LibraryFolders: {
      TimeNextStatsReport: 42,
      ContentStatsID: 1
    }
  });
  t.is(result.length, 1);
  t.true(_.map(result, 'path').indexOf(n(libraryPath)) > -1, 'default library is included');
});

test('pathSteps#parseFolderList when there are no folders should split the path intelligently', t => {
  const result = pathSteps.parseFolderList({
    LibraryFolders: {
      TimeNextStatsReport: 42,
      ContentStatsID: 1
    }
  });
  t.is(result[0].abbr + result[0].rest, result[0].path);
});

test('pathSteps#parseFolderList when there are folders in distinct places should start with the default library', t => {
  const result = pathSteps.parseFolderList({
    LibraryFolders: {
      TimeNextStatsReport: 42,
      ContentStatsID: 1,
      1: n('E:', 'TestOne'),
      2: n('F:', 'TestTwo')
    }
  });
  t.is(result[0].path, n(libraryPath));
});

test('pathSteps#parseFolderList when there are folders in distinct places should include the extra libraries', t => {
  const result = pathSteps.parseFolderList({
    LibraryFolders: {
      TimeNextStatsReport: 42,
      ContentStatsID: 1,
      1: n('E:', 'TestOne'),
      2: n('F:', 'TestTwo')
    }
  });
  t.true(_.map(result, 'path').indexOf(n('E:', 'TestOne')) > -1, 'TestOne is included');
  t.true(_.map(result, 'path').indexOf(n('F:', 'TestTwo')) > -1, 'TestTwo is included');
  t.is(result.length, 3);
});

test('pathSteps#parseFolderList when there are folders in similar places should include everything', t => {
  const result = pathSteps.parseFolderList({
    LibraryFolders: {
      TimeNextStatsReport: 42,
      ContentStatsID: 1,
      1: n('E:', 'Test', 'One', 'Library'),
      2: n('E:', 'Test', 'Two', 'Library')
    }
  });
  const paths = _.map(result, 'path');
  t.true(paths.indexOf(n(libraryPath)) > -1, 'default library is included');
  t.true(paths.indexOf(n('E:', 'Test', 'One', 'Library')) > -1, 'Test/One is included');
  t.true(paths.indexOf(n('E:', 'Test', 'Two', 'Library')) > -1, 'Test/Two is included');
  t.is(result.length, 3);
});

test('pathSteps#parseFolderList when there are folders in similar places should give them different abbreviations', t => {
  const result = pathSteps.parseFolderList({
    LibraryFolders: {
      TimeNextStatsReport: 42,
      ContentStatsID: 1,
      1: n('E:', 'Test', 'One', 'Library'),
      2: n('E:', 'Test', 'Two', 'Library')
    }
  });
  t.not(result[1].abbr, result[2].abbr);
});
