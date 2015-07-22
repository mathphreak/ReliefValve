du = require '../util/du'

loadGameSize = (game) ->
  gamePath = game.fullPath
  du(gamePath)
    .map (d) -> {name: game.name, data: d}

module.exports =
  loadGameSize: loadGameSize
