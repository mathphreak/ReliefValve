/* globals vex:false, $:false, clUtils:false, clGames:false, document:false */

import EventEmitter from 'events';
import _ from 'lodash';
import Rx from 'rx';
import {ipcRenderer as ipc} from 'electron';

import * as moveSteps from '../steps/move';

vex.defaultOptions.className = 'vex-theme-plain';

// Helper utilities for building buttons
function vexSubmitButton(text) {
  return {
    text,
    type: 'submit',
    className: 'vex-dialog-button-primary'
  };
}

function vexCancelButton(text) {
  return {
    text,
    type: 'button',
    className: 'vex-dialog-button-secondary',
    click: $vexContent => {
      $vexContent.data().vex.value = false;
      return vex.close($vexContent.data().vex.id);
    }
  };
}

const resetProgress = () => $('#progress-outer').html('');

function initializeProgress(games) {
  const sizeKey = process.platform === 'win32' ? 'size' : 'nodes';
  const acfSize = process.platform === 'win32' ? moveSteps.DUMMY_SIZE : 1;
  // calculate total size
  let totalSize = _(games)
    .map('sizeData')
    .map(sizeKey)
    .map(x => x + acfSize)
    .reduce((a, b) => a + b);
  if (process.platform !== 'win32') {
    totalSize *= moveSteps.DUMMY_SIZE;
  }
  $('#progress-outer').data('total', totalSize);

  // make sure the progress bar starts at zero
  resetProgress();

  // show the progress bar
  $('#progress-container').show();
  $('#progress-container').height('2rem');
}

const updateSystemProgress = _.throttle(() => {
  const currentProgress = $('.progress')
    .map((i, x) => $(x).width())
    .reduce((a, b) => a + b);
  const totalProgress = $('#progress-outer').width();
  ipc.send('progress', currentProgress / totalProgress);
}, 100);

function addProgress(x) {
  const el = $('<div class="progress">&nbsp;</div>');
  el.appendTo('#progress-outer');
  el.data('size', x.size);
  el.data('id', x.id);
  const total = parseInt($('#progress-outer').data('total'), 10);
  const percent = x.size / total * 100;
  el.width(0);
  setTimeout(() => {
    el.width(`${percent}%`);
    updateSystemProgress();
  }, 1);
  return true;
}

function combineOverlappingGames(allGames) {
  return _(allGames)
    .map((oldGame, idx) => {
      const game = _.clone(oldGame);
      const duplicates = _.filter(allGames, otherGame => otherGame.source === game.source);
      duplicates.forEach((otherGame, idx2) => {
        if (idx2 !== idx) {
          otherGame.drop = true;
        }
      });
      game.acfSource = _.map(duplicates, 'acfSource');
      game.acfDest = _.map(duplicates, 'acfDest');
      return game;
    })
    .reject('drop')
    .value();
}

function makeCopyProgressObserver() {
  return Rx.Observer.create(x => addProgress(x), x => clUtils.emit('error', x));
}

function makeDeleteProgressObserver() {
  return Rx.Observer.create(false, e => clUtils.emit('error', e), () =>
    setTimeout(() => {
      ipc.send('progress', false);
      $('#progress-container').height('0%');
      $('.progress').height(0);
      setTimeout(() => clGames.emit('refresh'), 400);
    }, 400)
  );
}

function runningConfirm(cancelText) {
  return function (running) {
    let result = new Rx.Subject();
    if (running) {
      const message = `<p>It looks like Steam is currently running.</p>
        <p>If you move games while Steam is running, bad things may happen.</p>
        <p>If you have quit Steam or Steam isn't actually running,
        just continue.</p>`;
      vex.dialog.confirm({
        message,
        buttons: [
          vexSubmitButton('Continue'),
          vexCancelButton(cancelText)
        ],
        callback: x => {
          result.onNext(x);
          result.onCompleted();
        }
      });
    } else {
      result = Rx.Observable.just(true);
    }
    return result;
  };
}

function checkRunning() {
  const result = new Rx.Subject();
  ipc.once('isSteamRunning', (evt, x) => {
    console.log('isSteamRunning:', x);
    result.onNext(x);
    result.onCompleted();
  });
  ipc.send('isSteamRunning');
  return result;
}

function ready() {
  $(document).on('click', '#move:not(.disabled)', () => {
    // This will be undone when we call refresh in clGames
    $('#move')
      .addClass('disabled')
      .addClass('inProgress')
      .html((i, data) => data.replace('Move ', 'Moving... '));
    $('#move i')
      .removeClass('fa-arrow-right')
      .addClass('fa-circle-o-notch')
      .addClass('fa-spin');

    // get the selected path
    const selectedAbbr = $('#selection select').val();
    const path = _.find(global.Paths, {abbr: selectedAbbr});

    const destination = path.path;

    const copyProgressObserver = makeCopyProgressObserver();
    const deleteProgressObserver = makeDeleteProgressObserver();

    checkRunning()
      .flatMap(runningConfirm('Cancel'))
      .flatMap(go => {
        if (go) {
          ipc.send('progress', 0);
          return Rx.Observable.from(global.Games);
        }
        return Rx.Observable.empty();
      })
      .filter(game => $(`.game[data-name="${game.name}"]`).hasClass('selected'))
      .toArray()
      .do(initializeProgress)
      .flatMap(x => x)
      .map(moveSteps.makeBuilder(destination))
      .toArray()
      .map(combineOverlappingGames)
      .flatMap(x => x)
      .flatMap(x =>
        moveSteps.moveGame(x)
          .do(copyProgressObserver)
          .last()
          .map(() => x)
      )
      .flatMap(gameData =>
        moveSteps.deleteOriginal(gameData)
          .map(() => gameData))
      .subscribe(deleteProgressObserver);
  });
}

const clMove = new EventEmitter();

clMove.on('ready', ready);

export default clMove;
