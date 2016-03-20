expect = require('chai').expect
fs = require 'fs.extra'
del = require 'del'
pathMod = require 'path'

catSteps = require '../src/steps/category'

describe 'categorySteps', ->
  describe '#getAccountIDs', ->
    context 'when there is one account', ->
      fs.mkdirpSync 'testdata/cat1/userdata/1337'
      it 'should find the account', (done) ->
        catSteps.getAccountIDs pathMod.normalize 'testdata/cat1'
          .subscribe (data) ->
            expect(data).to.have.length(1)
            expect(data[0]).to.equal('1337')
            done()

    context 'when there are multiple accounts', ->
      it 'should find all of them', ->
        fs.mkdirpSync 'testdata/cat2/userdata/1337'
        fs.mkdirpSync 'testdata/cat2/userdata/9001'
        it 'should find the account', (done) ->
          catSteps.getAccountIDs pathMod.normalize 'testdata/cat2'
            .subscribe (data) ->
              expect(data).to.have.length(2)
              expect(data).to.contain('1337')
              expect(data).to.contain('9001')
              done()

  describe '#getUsernames', ->
    context 'with one account', ->
      it 'should find the username', (done) ->
        catSteps.getUsernames(['84367485'], process.env.STEAM_API_KEY ||
          require('./dev_secret_config.json').STEAM_API_KEY)
          .subscribe (data) ->
            expect(data['84367485']).to.equal('mathphreak')
            done()

    context 'with multiple accounts', ->
      it 'should find all usernames', (done) ->
        catSteps.getUsernames(['84367485', '22202'],
          process.env.STEAM_API_KEY ||
          require('./dev_secret_config.json').STEAM_API_KEY)
          .subscribe (data) ->
            expect(data['84367485']).to.equal('mathphreak')
            expect(data['22202']).to.equal('Rabscuttle')
            done()

  describe '#getCategories', ->
    it 'should find all categories and games', (done) ->
      fs.mkdirpSync 'testdata/cat3/userdata/0/7/remote/'
      fs.writeFileSync 'testdata/cat3/userdata/0/7/remote/sharedconfig.vdf',
        '"UserLocalConfigStore"
        {
          "Software"
          {
            "Valve"
            {
              "Steam"
              {
                "apps"
                {
                  "400"
                  {
                    "tags"
                    {
                      "0"		"favorite"
                      "1"		"test"
                    }
                  }
                  "26900"
                  {
                    "tags"
                    {
                      "0"		"favorite"
                      "1"		"test"
                      "2"		"test2"
                    }
                  }
                }
              }
            }
          }
        }'
      catSteps.getCategories('testdata/cat3', '0')
        .subscribe (data) ->
          expect(data.favorite).to.contain('400')
          expect(data.favorite).to.contain('26900')
          expect(data.test).to.contain('400')
          expect(data.test).to.contain('26900')
          expect(data.test2).to.contain('26900')
          done()

  after ->
    del ['testdata/cat*']
