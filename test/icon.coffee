expect = require('chai').expect

iconSteps = require '../src/steps/icon'

describe 'iconSteps', ->
  describe '#getIconURL', ->
    @timeout 10000
    it 'should get the icon URL', (done) ->
      iconSteps.getIconURL(730)
        .subscribe (url) ->
          expect(url).to.equal('https://steamcdn-a.akamaihd.net/' +
            'steamcommunity/public/images/apps/730/' +
            '69f7ebe2735c366c65c0b33dae00e12dc40edbe4.jpg')
          done()
