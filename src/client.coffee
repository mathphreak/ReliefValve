global.Games = []
global.Paths = []

clGames = require './client/games'
clMove = require './client/move'
clUtils = require './client/utils'

$ ->
  clGames.ready()
  clMove.ready()
  clUtils.ready()
