/* global vex:false, $:false, document:false, clGames:false */

import EventEmitter from 'events';
import _ from 'lodash';
import Rx from 'rx';
import {shell, ipcRenderer as ipc} from 'electron';
import storage from 'electron-json-storage';
import contextMenu from 'electron-contextmenu-middleware';
import inputMenu from 'electron-input-menu';

import * as initSteps from '../steps/init';

function runUpdateCheck() {
  initSteps.updateMessage()
    .subscribe(([message, url]) => vex.dialog.confirm({
      message: `<p>${message}.</p>
        <p>Press OK to download the update or Cancel to not do that.</p>`,
      callback: x => x && shell.openExternal(url)
    }));
}

function handleError(e) {
  // TODO be useful
  console.error(e);
  // alert(e);
}

function watchForKonamiCode() {
  const codes = [
    38, // up
    38, // up
    40, // down
    40, // down
    37, // left
    39, // right
    37, // left
    39, // right
    66, // b
    65  // a
  ];
  const konami = Rx.Observable.fromArray(codes);

  Rx.Observable.fromEvent($(document), 'keyup')
    .map(e => e.keyCode)
    .windowWithCount(10, 1) // always take the most recent ten
    .selectMany(x => x.sequenceEqual(konami))
    .filter(x => x)
    .subscribe(() => ipc.send('showMenu', true));
}

ipc.on('menuItem', (event, item) => {
  if (item === 'about') {
    vex.dialog.alert(`<p>You are running Relief Valve
      v${require('../../package.json').version}</p>`);
  }
});

function checkPromptConfig() {
  if (global.Paths.length === 1) {
    vex.dialog.alert(`You only have one Steam library configured, so Relief
      Valve can't do much yet; if you want, you can
      <a class="full-button" target="_blank"
      href="http://code.mathphreak.me/ReliefValve/configure.html">get help</a>
      configuring Steam properly.`);
  }
}

function addContextMenu() {
  contextMenu.use(inputMenu);
  contextMenu.activate();
}

function ready() {
  watchForKonamiCode();
  addContextMenu();
  runUpdateCheck();

  clGames.on('pathsLoaded', checkPromptConfig);

  $(document).on('click', '#settings-link', event => {
    $('#settings-wrapper').show();
    storage.get('STEAM_API_KEY', (err, key) => {
      if (!_.isEmpty(key)) {
        $('#steamAPIkey').val(key);
      }
    });
    event.stopImmediatePropagation();
  });

  $(document).on('submit', '#settings form', event => {
    $('#settings-wrapper').hide();
    storage.get('STEAM_API_KEY', (err, key) => {
      if (key !== $('#steamAPIkey').val()) {
        storage.set('STEAM_API_KEY', $('#steamAPIkey').val(), err => {
          if (err) {
            handleError(err);
          }
          clGames.emit('fetchCategories');
        });
      }
    });
    event.stopImmediatePropagation();
    event.preventDefault();
  });

  $(document).on('click', 'a[target="_blank"]', function (event) {
    if (!_.isEmpty(this.title)) {
      vex.dialog.alert({
        message: this.title,
        callback: () => shell.openExternal(this.href)
      });
    }
    event.preventDefault();
  });
}

const clUtils = new EventEmitter();

clUtils.on('ready', ready);
clUtils.on('error', handleError);

export default clUtils;
