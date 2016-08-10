/* globals $:false, Ps:false, clUtils:false, document:false */

import EventEmitter from 'events';
import _ from 'lodash';
import Rx from 'rx';
import filesize from 'filesize';
import compareIgnoringArticles from 'compare-ignoring-articles';
import storage from 'electron-json-storage';
import Templates from '../templates';

import * as pathSteps from '../steps/path';
import * as gameSteps from '../steps/game';
import * as sizeSteps from '../steps/size';
import * as catSteps from '../steps/category';

const Categories = {};

const libraryPath = pathSteps.getDefaultSteamLibraryPath();

const folderListPath = `${libraryPath}/steamapps/libraryfolders.vdf`;

const clGames = new EventEmitter();

function updateCheckbox(el, val, max) {
  if (val === max) {
    el
      .addClass('fa-check-square-o')
      .removeClass('fa-square')
      .removeClass('fa-square-o');
  } else if (val > 0) {
    el
      .removeClass('fa-check-square-o')
      .addClass('fa-square')
      .removeClass('fa-square-o');
  } else {
    el
      .removeClass('fa-check-square-o')
      .removeClass('fa-square')
      .addClass('fa-square-o');
  }
}

function markGameLoading(game) {
  function matches() {
    return this.dataset.name === game.name;
  }
  $('#games .game')
    .filter(matches)
    .children()
    .children('i')
    .addClass('fa-circle-o-notch')
    .addClass('fa-spin')
    .removeClass('fa-gamepad');
}

function toggleOverlap(toggledRow) {
  const thisFullPath = toggledRow.children('.cell:nth-child(2)').text();
  const thisSelected = toggledRow.is('.selected');
  $('.game .cell:nth-child(2)').get().filter(child => child.innerText.trim() === thisFullPath.trim())
    .forEach(child => $(child).closest('.game').toggleClass('selected', thisSelected));
}

function gameHasAbbr(abbr) {
  return function () {
    return $(this).find('.base').text() === abbr;
  };
}

function updateSelected() {
  const hasSelection = $('.game.selected').size() > 0;
  updateCheckbox($('#globalSelect i'), $('.game.selected').size(),
    $('#games .game:not(.loading)').size());
  global.Paths.forEach((path, i) => {
    updateCheckbox($(`.libs span:nth-child(${i + 1}) i`),
      $('.game.selected').filter(gameHasAbbr(path.abbr)).size(),
      $('#games .game:not(.loading)').filter(gameHasAbbr(path.abbr)).size());
  });
  updateCategorySelection();
  const names = $('.game.selected')
    .get()
    .map(el => el.dataset.name);
  const paths = $('.game.selected .cell .base')
    .get()
    .map(el => el.innerText);
  const sizes = Math.round($('.game.selected .cell:last-child')
    .get()
    .map(el => parseFloat(el.innerText) * 100)
    .reduce(((a, b) => a + b), 0)) / 100;
  let goodIndex;
  $('#selection option').attr('disabled', i => {
    if (_.includes(paths, global.Paths[i].abbr)) {
      return true;
    }
    goodIndex = goodIndex || i;
    return null;
  });
  if (goodIndex === undefined) {
    $('#move').addClass('disabled');
  } else {
    $('#move:not(.inProgress)').removeClass('disabled');
  }
  if ($('#selection option:selected').is(':disabled')) {
    $('#selection option:not(:disabled)').first().prop('selected', true);
  }
  $('#all-names').text(names.join(', '));
  $('#all-paths').text(paths.join(', '));
  if (_.isNaN(sizes)) {
    if ($('#total-size').text() !== '') {
      $('#total-size').html('');
      $('<i></i>')
        .addClass('fa')
        .addClass('fa-circle-o-notch')
        .addClass('fa-spin')
        .appendTo('#total-size');
    }
  } else {
    $('#total-size').text(`${sizes} GB`);
  }
  $('#selection').toggle(hasSelection);
  Ps.update($('#gameList #games').get(0));
}

function makeGamesStreamObserver() {
  let seen = false;
  function gotGame(game) {
    if (!seen) {
      seen = true;
      $('#games .game:not(.loading)').remove();
      $('#gameList .loading').show();
    }
    const result = Templates.game({game, paths: global.Paths});
    $('#games .game')
      .filter(function () {
        return compareIgnoringArticles(this.dataset.name, game.name, false) < 0;
      })
      .last()
      .after(result);
    Ps.update($('#gameList #games').get(0));
  }
  return Rx.Observer.create(gotGame, x => clUtils.emit('error', x), () => $('#gameList .loading').hide());
}

function makeSizesStreamObserver() {
  function gotSizes({name, data}) {
    // update Games
    _.find(global.Games, {name}).sizeData = data;

    // update game in table
    $('#games .game')
      .filter(function () {
        return this.dataset.name === name;
      })
      .children()
      .last()
      .text(filesize(data.size, {exponent: 3}));

    // update the footer (recalculate total size of all selected)
    updateSelected();
  }
  return Rx.Observer.create(gotSizes, x => clUtils.emit('error', x), false);
}

function updateCategorySelection() {
  let appIDs;
  function matchesAppID() {
    return appIDs.indexOf(this.dataset.appid) > -1;
  }
  try {
    appIDs = Categories[$('.user select').val()][$('.category select').val()];
    updateCheckbox($('#magic a i'),
      $('.game.selected').filter(matchesAppID).size(),
      $('#games .game:not(.loading)').filter(matchesAppID).size()
    );
  } catch (err) {
    // who cares
  }
}

function updateCategorySelect() {
  $('.category select').html('');
  let categories = _.keys(Categories[$('.user select').val()]).sort();
  categories = categories.filter(cat => Categories[$('.user select').val()][cat].some(appID => _.some(global.Games, {appID})));
  // Move favorites to front if they're at the back
  if (categories.indexOf('favorite') > 0) {
    categories = ['favorite'].concat(_.without(categories, 'favorite'));
  }
  for (const category of categories) {
    $(`<option>${category}</option>`).appendTo('.category select');
  }
  updateCategorySelection();
}

function fetchCategories() {
  $('.user select').html('');
  catSteps.getAccountIDs(libraryPath)
    .map(ids => _.without(ids, 'anonymous'))
    .flatMap(ids => {
      if (ids.length === 1) {
        $('.user').hide();
        return Rx.Observable.just([[ids[0], `[U:1:${ids[0]}]`]]);
      }
      $('.user').show();
      return Rx.Observable.fromNodeCallback(storage.get)('STEAM_API_KEY')
        .flatMap(key => {
          if (_.isEmpty(key)) {
            $('.user select').attr('title',
              'Check Settings to see usernames here');
            return Rx.Observable.just(ids.map(id => [id, `[U:1:${id}]`]));
          }
          $('.user select').attr('title', '');
          return catSteps.getUsernames(ids, key).map(x => _.toPairs(x));
        });
    })
    .flatMap(x => x)
    .flatMap(([userID, userDisplay]) => {
      $(`<option value="${userID}">${userDisplay}</option>`)
        .appendTo('.user select');
      return catSteps.getCategories(libraryPath, userID)
        .do(categories => {
          Categories[userID] = categories;
          updateCategorySelect();
        });
    })
    .subscribe(() => {}, x => clUtils.emit('error', x), loadSelection);
}

function runProcess() {
  fetchCategories();
  Rx.Observable.just(folderListPath)
    .flatMap(pathSteps.readVDF)
    .flatMap(pathSteps.parseFolderList)
    .toArray()
    .do(d => {
      global.Paths = d;
      const footer = Templates.footer({paths: d});
      $('#selection').replaceWith(footer);
      const libs = Templates.libs({paths: d});
      $('.libs').replaceWith(libs);
      clGames.emit('pathsLoaded');
    })
    .flatMap(_.identity)
    .flatMap(gameSteps.getPathACFs)
    .flatMap(gameSteps.readAllACFs)
    .map(gameSteps.buildGameObject)
    .toArray()
    .do(d => {
      global.Games = d;
      updateCategorySelect();
    })
    .flatMap(_.identity)
    .do(makeGamesStreamObserver())
    .observeOn(Rx.Scheduler.currentThread)
    .do(markGameLoading)
    .flatMap(sizeSteps.loadGameSize)
    .subscribe(makeSizesStreamObserver());
}

function updateSearch() {
  const query = $('.search input').val();
  $('.game:not(.loading)').each((i, x) => {
    const name = x.dataset.name;
    $(x).toggle(_.includes(name.toLocaleLowerCase(), query.toLocaleLowerCase()));
  });
}

function saveSelection() {
  storage.set('selectedUser', $('.user select').val());
  storage.set('selectedCategory', $('.category select').val());
}

function loadSelection() {
  storage.get('selectedUser', (err, user) => {
    if (!_.isEmpty(user)) {
      $('.user select').val(user);
      updateCategorySelect();
      storage.get('selectedCategory', (err, category) => {
        if (!_.isEmpty(category)) {
          $('.category select').val(category);
        }
      });
    }
  });
}

function ready() {
  Ps.initialize($('#gameList #games').get(0), {suppressScrollX: true});

  Rx.Observable.fromEvent($('#refresh'), 'click')
    .startWith('initial load event')
    .subscribe(runProcess);

  $(document).on('click', '#clearSearch', () => {
    $('.search input').val('').focus();
    updateSearch();
  });

  $(document).on('input', '.search input', updateSearch);

  $(document).on('click', '#globalSelect i', event => {
    const selected = $('#globalSelect i').is('.fa-square-o');
    $('#games .game:not(.loading)').toggleClass('selected', selected);
    updateSelected();
    event.stopImmediatePropagation();
  });

  $(document).on('click', '.libs span i', function (event) {
    const path = $(this).closest('.libs > span').text();
    const selected = $(this).closest('.libs > span i').is('.fa-square-o');
    $('#games .game:not(.loading)')
      .filter(gameHasAbbr(path))
      .toggleClass('selected', selected);
    updateSelected();
    event.stopImmediatePropagation();
  });

  $(document).on('click', '#games .game', function (event) {
    $(this).closest('.game').toggleClass('selected');
    toggleOverlap($(event.target).closest('.game'));
    updateSelected();
    event.stopImmediatePropagation();
  });

  $(document).on('change', '.user select', () => {
    updateCategorySelect();
    saveSelection();
  });

  $(document).on('change', '.category select', () => {
    updateCategorySelection();
    saveSelection();
  });

  $(document).on('click', '#magic a.select i', event => {
    const appIDs = Categories[$('.user select').val()][$('.category select').val()];
    const selected = $('#magic a.select i').is('.fa-square-o');
    for (const appID of appIDs) {
      // Ignore uninstalled favorites
      if ($(`.game[data-appID="${appID}"]`).size() > 0) {
        $(`.game[data-appID="${appID}"]`).toggleClass('selected', selected);
        toggleOverlap($(`.game[data-appID="${appID}"]`));
      }
    }
    updateSelected();
    event.stopImmediatePropagation();
  });
}

clGames.on('ready', ready);
clGames.on('fetchCategories', fetchCategories);
clGames.on('refresh', runProcess);

export default clGames;
