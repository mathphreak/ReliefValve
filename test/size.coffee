expect = require('chai').expect
fs = require 'fs.extra'
del = require 'del'

sizeSteps = require '../src/steps/size'

gamePath = "testdata/size_library/steamapps/common/TestGame"

totalSize = 0

makeFile = (path, mbSize) ->
  fileSize = mbSize*1024*1024
  totalSize += fileSize
  fs.writeFileSync path, new Buffer fileSize

describe 'sizeSteps', ->
  before ->
    fs.mkdirpSync "#{gamePath}/Sub"
    makeFile "#{gamePath}/Test1", 3
    makeFile "#{gamePath}/Test2", 6
    makeFile "#{gamePath}/Sub/Test3", 14
    makeFile "#{gamePath}/Sub/Test4", 21

  describe '#loadGameSize', ->
    it 'should read sizes properly', (done) ->
      sizeSteps.loadGameSize({name:"A Game",fullPath:gamePath})
        .subscribe ({name, data}) ->
          expect(name).to.equal("A Game")
          expect(data).to.equal(totalSize)
          done()

  after (done) ->
    del ['testdata/size_library'], done
