expect = require('chai').expect

initSteps = require '../src/steps/init'

describe 'initSteps', ->
  describe '#isSteamRunning', ->
    @timeout 10000
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

  describe '#updateMessage', ->
    it 'should give a message when the current version is old', (done) ->
      initSteps.updateMessage('0.0.1')
        .subscribe (x) ->
          expect(x).to.be.an 'array'
          expect(x).to.have.length(2)
          done()
    it 'should not give a message when the current version is new', (done) ->
      initSteps.updateMessage('9001.0.0')
        .toArray()
        .subscribe (x) ->
          expect(x).to.be.empty
          done()
