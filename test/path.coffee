expect = require('chai').expect
iconv = require 'iconv-lite'
fs = require 'fs.extra'
del = require 'del'

iconv.extendNodeEncodings()

pathSteps = require '../src/steps/path'

# syntactic sugar ftw
even = it

before ->
  fs.mkdirpSync "testdata"
  fs.writeFileSync 'testdata/none.vdf',
    """
    "LibraryFolders"
    {
      "TimeNextStatsReport"		"1337133769"
      "ContentStatsID"		"-1337133713371337137"
    }
    """, {encoding: 'win1252'}
  fs.writeFileSync 'testdata/several-ascii.vdf',
    """
    "LibraryFolders"
    {
      "TimeNextStatsReport"		"1337133769"
      "ContentStatsID"		"-1337133713371337137"
      "1"		"E:\\\\TestOne"
      "2"		"F:\\\\TestTwo"
    }
    """, {encoding: 'win1252'}
  fs.writeFileSync 'testdata/several-extended.vdf',
    """
    "LibraryFolders"
    {
      "TimeNextStatsReport"		"1337133769"
      "ContentStatsID"		"-1337133713371337137"
      "1"		"E:\\\\TestÖne"
      "2"		"F:\\\\TéstTwô"
    }
    """, {encoding: 'win1252'}

describe 'pathSteps', ->
  describe '#readVDF', ->
    context 'when there are no folders', ->
      it 'should parse the file properly', (done) ->
        pathSteps.readVDF('testdata/none.vdf')
          .subscribe (details) ->
            folders = details.LibraryFolders
            expect(folders['1']).to.be.undefined
            done()
    context 'when there are several folders', ->
      it 'should parse an ASCII-only file properly', (done) ->
        pathSteps.readVDF('testdata/several-ascii.vdf')
          .subscribe (details) ->
            folders = details.LibraryFolders
            expect(folders['1']).to.equal("E:\\\\TestOne")
            expect(folders['2']).to.equal("F:\\\\TestTwo")
            done()
      it 'should parse a file with extended characters properly', (done) ->
        pathSteps.readVDF('testdata/several-extended.vdf')
          .subscribe (details) ->
            folders = details.LibraryFolders
            expect(folders['1']).to.equal("E:\\\\TestÖne")
            expect(folders['2']).to.equal("F:\\\\TéstTwô")
            done()

  describe '#parseFolderList', ->
    context 'when there are no folders', ->
      it 'should have only the default library', ->
        result = pathSteps.parseFolderList
          LibraryFolders:
            TimeNextStatsReport: 42
            ContentStatsID: 1
        expect(result).to.have.length(1)
        expect(result).to.include("C:\\Program Files (x86)\\Steam")
    context 'when there are folders', ->
      result = pathSteps.parseFolderList
        LibraryFolders:
          TimeNextStatsReport: 42
          ContentStatsID: 1
          '1': "E:\\\\TestOne"
          '2': "F:\\\\TestTwo"
      it 'should start with the default library', ->
        expect(result[0]).to.equal("C:\\Program Files (x86)\\Steam")
      it 'should include the extra libraries', ->
        expect(result).to.include("E:\\TestOne")
        expect(result).to.include("F:\\TestTwo")
        expect(result).to.have.length(3)

after (done) ->
  del ['testdata/'], done
