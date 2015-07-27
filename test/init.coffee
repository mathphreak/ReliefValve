expect = require('chai').expect

initSteps = require '../src/steps/init'

describe 'initSteps', ->
  describe '#isSteamRunning', ->
    @timeout 5000
    @slow 2000
    it 'should see when something is not running', (done) ->
      initSteps.isSteamRunning('xyzzy_dummy_task_name')
        .subscribe (x) ->
          expect(x).to.be.false
          done()
    it 'should see when something is running', (done) ->
      initSteps.isSteamRunning('node')
        .subscribe (x) ->
          expect(x).to.be.true
          done()
