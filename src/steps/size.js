import du from '../util/du';

export function loadGameSize(game) {
  const gamePath = game.fullPath;
  return du(gamePath)
    .map(d => ({name: game.name, data: d}));
}
