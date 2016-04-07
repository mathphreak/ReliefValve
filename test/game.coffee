expect = require('chai').expect
fs = require 'fs.extra'
del = require 'del'

gameSteps = require '../src/steps/game'

describe 'gameSteps', ->
  before ->
    fs.mkdirpSync 'testdata/library1/steamapps'
    fs.mkdirpSync 'testdata/library2/steamapps/common/TestGame'
    fs.writeFileSync 'testdata/library2/steamapps/appmanifest_1337.acf',
      '''
      "AppState"
      {
        "appID"		"1337"
        "name"		"A Test Game"
        "installdir"		"TestGame"
        "StateFlags"		"4"
      }
      '''
    fs.writeFileSync 'testdata/library2/steamapps/appmanifest_9001.acf',
      '''
      "AppState"
      {
        "appID"		"9001"
        "name"		"A Downloading Game"
        "installdir"		"Downloading"
        "StateFlags"		"1026"
      }
      '''
    fs.writeFileSync 'testdata/library2/steamapps/appmanifest_42.acf',
      '''
      "AppStat"
      {
        "appID"		"42"
        "name"		"A Corrupted appmanifest"
      }
      '''

  describe '#getPathACFs', ->
    context 'when there are no games', ->
      emptyLibPathData = {path: 'testdata/library1'}
      it 'should find no games', (done) ->
        gameSteps.getPathACFs(emptyLibPathData, 0)
          .subscribe ({apps}) ->
            expect(apps).to.be.empty
            done()
    context 'when there are games listed', ->
      fullLibPathData = {path: 'testdata/library2'}
      it 'should find the games', (done) ->
        gameSteps.getPathACFs(fullLibPathData, 0)
          .subscribe ({apps}) ->
            expect(apps).to.have.length(3)
            expect(apps[0]).to.contain('appmanifest_1337.acf')
            expect(apps[1]).to.contain('appmanifest_42.acf')
            expect(apps[2]).to.contain('appmanifest_9001.acf')
            done()

  describe '#readAllACFs', ->
    context 'when there is a game installed', ->
      desiredACFPath = 'testdata/library2/steamapps/appmanifest_1337.acf'
      input =
        path: {path: 'testdata/library2'}
        i: 0
        apps: [desiredACFPath]
      it 'should parse the ACF file', (done) ->
        gameSteps.readAllACFs(input)
          .subscribe (game) ->
            {path, i, gameInfo, acfPath} = game
            expect(path.path).to.equal('testdata/library2')
            expect(i).to.equal(0)
            expect(acfPath).to.equal(desiredACFPath)
            expect(gameInfo.appID).to.equal('1337')
            expect(gameInfo.name).to.equal('A Test Game')
            expect(gameInfo.installdir).to.equal('TestGame')
            done()
    context 'when there is a game downloading', ->
      desiredACFPath = 'testdata/library2/steamapps/appmanifest_9001.acf'
      input =
        path: {path: 'testdata/library2'}
        i: 0
        apps: [desiredACFPath]
      it 'should not parse the ACF file', (done) ->
        gameSteps.readAllACFs(input)
          .toArray()
          .subscribe (games) ->
            expect(games).to.have.length(0)
            done()
    context 'when there is a game with a broken appmanifest', ->
      desiredACFPath = 'testdata/library2/steamapps/appmanifest_42.acf'
      input =
        path: {path: 'testdata/library2'}
        i: 0
        apps: [desiredACFPath]
      it 'should throw a meaningful error', (done) ->
        gameSteps.readAllACFs(input)
          .toArray()
          .subscribe (data) ->
            expect(data).to.not.be.ok
            expect(false).to.equal(true)
            done()
          , (err) ->
            expect(err.message).to.equal("Failed to parse #{desiredACFPath}")
            done()
          , done

  after ->
    del ['testdata/library*']
