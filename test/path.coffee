expect = require('chai').expect
iconv = require 'iconv-lite'
fs = require 'fs.extra'
del = require 'del'
pathMod = require 'path'
_ = require 'lodash'

pathSteps = require '../src/steps/path'

libraryPath = pathSteps.getDefaultSteamLibraryPath()

n = (p...) -> pathMod.normalize p.join pathMod.sep

describe 'pathSteps', ->
  before ->
    fs.mkdirpSync "testdata"
    fs.writeFileSync 'testdata/none.vdf', iconv.encode(
      """
      "LibraryFolders"
      {
        "TimeNextStatsReport"		"1337133769"
        "ContentStatsID"		"-1337133713371337137"
      }
      """, 'win1252')
    fs.writeFileSync 'testdata/several-ascii.vdf', iconv.encode(
      """
      "LibraryFolders"
      {
        "TimeNextStatsReport"		"1337133769"
        "ContentStatsID"		"-1337133713371337137"
        "1"		"E:\\\\TestOne"
        "2"		"F:\\\\TestTwo"
      }
      """, 'win1252')
    fs.writeFileSync 'testdata/several-extended.vdf', iconv.encode(
      """
      "LibraryFolders"
      {
        "TimeNextStatsReport"		"1337133769"
        "ContentStatsID"		"-1337133713371337137"
        "1"		"E:\\\\TestÖne"
        "2"		"F:\\\\TéstTwô"
      }
      """, 'win1252')

  describe '#getDefaultSteamLibraryPath', ->
    it 'should return an absolute path', ->
      expect(pathMod.isAbsolute libraryPath).to.be.true
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
      result = pathSteps.parseFolderList
        LibraryFolders:
          TimeNextStatsReport: 42
          ContentStatsID: 1
      it 'should have only the default library', ->
        expect(result).to.have.length(1)
        expect(_.pluck(result, 'path')).to.include n(libraryPath)
      it 'should split the path intelligently', ->
        expect(result[0].abbr+result[0].rest).to.equal(result[0].path)
    context 'when there are folders in distinct places', ->
      result = pathSteps.parseFolderList
        LibraryFolders:
          TimeNextStatsReport: 42
          ContentStatsID: 1
          '1': n("E:","TestOne")
          '2': n("F:","TestTwo")
      it 'should start with the default library', ->
        expect(result[0].path).to.equal n(libraryPath)
      it 'should include the extra libraries', ->
        expect(_.pluck(result, 'path')).to.include n("E:","TestOne")
        expect(_.pluck(result, 'path')).to.include n("F:","TestTwo")
        expect(result).to.have.length(3)
    context 'when there are folders in similar places', ->
      result = pathSteps.parseFolderList
        LibraryFolders:
          TimeNextStatsReport: 42
          ContentStatsID: 1
          '1': n("E:", "Test", "One", "Library")
          '2': n("E:", "Test", "Two", "Library")
      it 'should include everything', ->
        paths = _.pluck(result, 'path')
        expect(paths).to.include n(libraryPath)
        expect(paths).to.include n("E:","Test","One","Library")
        expect(paths).to.include n("E:","Test","Two","Library")
        expect(result).to.have.length(3)
      it 'should give them different abbreviations', ->
        expect(result[1].abbr).to.not.equal(result[2].abbr)

after (done) ->
  del ['testdata/'], done
