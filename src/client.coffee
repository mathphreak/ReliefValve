global.Games = []
global.Paths = []

global.clGames = require './client/games'
global.clMove = require './client/move'
global.clUtils = require './client/utils'

$ ->
  clGames.emit 'ready'
  clMove.emit 'ready'
  clUtils.emit 'ready'
