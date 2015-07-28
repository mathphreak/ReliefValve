expect = require('chai').expect
fs = require 'fs.extra'
del = require 'del'

gameSteps = require '../src/steps/game'

describe 'gameSteps', ->
  before ->
    fs.mkdirpSync "testdata/library1/steamapps"
    fs.mkdirpSync "testdata/library2/steamapps/common/TestGame"
    fs.writeFileSync 'testdata/library2/steamapps/appmanifest_1337.acf',
      """
      "AppState"
      {
        "appID"		"1337"
        "name"		"A Test Game"
        "installdir"		"TestGame"
      }
      """

  describe '#getPathACFs', ->
    context 'when there are no games installed', ->
      emptyLibPathData = {path: "testdata/library1"}
      it 'should find no games', (done) ->
        gameSteps.getPathACFs(emptyLibPathData, 0)
          .subscribe ({apps}) ->
            expect(apps).to.be.empty
            done()
    context 'when there is a game installed', ->
      fullLibPathData = {path: "testdata/library2"}
      it 'should find the game', (done) ->
        gameSteps.getPathACFs(fullLibPathData, 0)
          .subscribe ({apps}) ->
            expect(apps).to.have.length(1)
            expect(apps[0]).to.contain("appmanifest_1337.acf")
            done()

  describe '#readAllACFs', ->
    context 'when there is a game installed', ->
      desiredACFPath = "testdata/library2/steamapps/appmanifest_1337.acf"
      input =
        path: {path: "testdata/library2"}
        i: 0
        apps: [desiredACFPath]
      it 'should parse the ACF file', (done) ->
        gameSteps.readAllACFs(input)
          .subscribe (game) ->
            {path, i, gameInfo, acfPath} = game
            expect(path.path).to.equal("testdata/library2")
            expect(i).to.equal(0)
            expect(acfPath).to.equal(desiredACFPath)
            expect(gameInfo.appID).to.equal("1337")
            expect(gameInfo.name).to.equal("A Test Game")
            expect(gameInfo.installdir).to.equal("TestGame")
            done()

  after (done) ->
    del ['testdata/library*'], done
