/* globals $:false */

import clGames from './client/games';
import clMove from './client/move';
import clUtils from './client/utils';

global.Games = [];
global.Paths = [];

global.clGames = clGames;
global.clMove = clMove;
global.clUtils = clUtils;

$(() => {
  clGames.emit('ready');
  clMove.emit('ready');
  clUtils.emit('ready');
});
