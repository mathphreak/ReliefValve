/* eslint camelcase:off */

import Rx from 'rx';
import psList from 'ps-list';
import _ from 'lodash';
import request from 'request';
import semver from 'semver';
import packageInfo from '../../package.json';

let latestVersion;

export function isSteamRunning(searchTarget = 'steam') {
  return Rx.Observable.fromPromise(psList())
    .map(data => _.some(data, x => _.includes(x.name.toLowerCase(), searchTarget)));
}

export function updateMessage(currentVersion = packageInfo.version) {
  let dataStream = Rx.Observable.just([false, {tag_name: latestVersion}]);
  if (!latestVersion) {
    const requestLater = Rx.Observable.fromNodeCallback(request);
    const params = {
      url: 'https://api.github.com/repos/mathphreak/ReliefValve/releases/latest',
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'ReliefValve update check'
      },
      json: true
    };
    if (process.env.GITHUB_API_TOKEN) {
      params.headers.Authorization = `token ${process.env.GITHUB_API_TOKEN}`;
    }
    dataStream = requestLater(params);
  }
  return dataStream.materialize().flatMap(data => {
    if (data.kind === 'N') {
      const [, latestRelease] = data.value;
      latestVersion = latestRelease.tag_name;
      const assets = latestRelease.assets;
      const outdated = latestVersion && semver.lt(currentVersion, latestVersion);
      if (outdated && assets.length > 0) {
        return Rx.Observable.just([
          `An update to Relief Valve ${latestVersion} is
          available (you're running ${currentVersion})`,
          latestRelease.html_url
        ]);
      }
    }
    return Rx.Observable.empty();
  });
}
