import du from '../util/du';

export default function loadGameSize(game) {
  const gamePath = game.fullPath;
  return du(gamePath)
    .map(d => ({name: game.name, data: d}));
}
