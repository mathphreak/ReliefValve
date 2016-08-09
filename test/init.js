import test from 'ava';
import _ from 'lodash';

import * as initSteps from '../src/steps/init';

test('initSteps#isSteamRunning should see when something is not running', async t => {
  setTimeout(() => {
    throw new Error('Timeout');
  }, 10000);
  t.false(await initSteps.isSteamRunning('xyzzy_dummy_task_name').toPromise());
});

test('initSteps#isSteamRunning should see when something is running', async t => {
  t.true(await initSteps.isSteamRunning('node').toPromise());
});

test('initSteps#updateMessage should give a message when the current version is old', async t => {
  const x = await initSteps.updateMessage('0.0.1').toPromise();
  t.true(_.isArray(x));
  t.is(x.length, 2);
});

test('initSteps#updateMessage should not give a message when the current version is new', async t => {
  const x = await initSteps.updateMessage('9001.0.0').toPromise();
  t.true(_.isEmpty(x));
});
