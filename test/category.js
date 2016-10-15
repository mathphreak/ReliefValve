/* eslint import/no-unresolved: [2, { ignore: ['dev_secret_config\.json$'] } ] */
import pathMod from 'path';
import test from 'ava';
import fs from 'fs.extra';
import tempfile from 'tempfile';
import _ from 'lodash';

import * as catSteps from '../src/steps/category';

const rootPath = tempfile('');

const STEAM_API_KEY = process.env.STEAM_API_KEY || require('./dev_secret_config.json').STEAM_API_KEY;

test('categorySteps#getAccountIDs when there is one account should find the account', async t => {
  fs.mkdirpSync(rootPath + '/cat1/userdata/1337');
  const data = await catSteps.getAccountIDs(pathMod.normalize(rootPath + '/cat1')).toPromise();
  t.is(data.length, 1);
  t.is(data[0], '1337');
});

test('categorySteps#getAccountIDs when there are multiple accounts should find all of them', async t => {
  fs.mkdirpSync(rootPath + '/cat2/userdata/1337');
  fs.mkdirpSync(rootPath + '/cat2/userdata/9001');
  const data = await catSteps.getAccountIDs(pathMod.normalize(rootPath + '/cat2')).toPromise();
  t.is(data.length, 2);
  t.true(_.includes(data, '1337'));
  t.true(_.includes(data, '9001'));
});

test('categorySteps#getUsernames with one account should find the username', async t => {
  const data = await catSteps.getUsernames(['84367485'], STEAM_API_KEY).toPromise();
  t.is(data['84367485'], 'mathphreak');
});

test('categorySteps#getUsernames with multiple accounts should find all usernames', async t => {
  const data = await catSteps.getUsernames(['84367485', '22202'], STEAM_API_KEY).toPromise();
  t.is(data['84367485'], 'mathphreak');
  t.is(data['22202'], 'Rabscuttle');
});

test('categorySteps#getCategories should find all categories and games', async t => {
  fs.mkdirpSync(rootPath + '/cat3/userdata/0/7/remote/');
  fs.writeFileSync(rootPath + '/cat3/userdata/0/7/remote/sharedconfig.vdf',
    `"UserLocalConfigStore"
    {
      "Software"
      {
        "Valve"
        {
          "Steam"
          {
            "apps"
            {
              "400"
              {
                "tags"
                {
                  "0"		"favorite"
                  "1"		"test"
                }
              }
              "26900"
              {
                "tags"
                {
                  "0"		"favorite"
                  "1"		"test"
                  "2"		"test2"
                }
              }
            }
          }
        }
      }
    }`
  );
  const data = await catSteps.getCategories(rootPath + '/cat3', '0').toPromise();
  t.true(_.includes(data.favorite, '400'));
  t.true(_.includes(data.favorite, '26900'));
  t.true(_.includes(data.test, '400'));
  t.true(_.includes(data.test, '26900'));
  t.true(_.includes(data.test2, '26900'));
});
