expect = require('chai').expect
fs = require 'fs.extra'
del = require 'del'
lipsum = require 'lorem-ipsum'
child = require 'child_process'
pathMod = require 'path'

moveSteps = require '../src/steps/move'

sourcePath = "testdata/move_src/Test"
destPath = "testdata/move_dst/Test"
failPath = "testdata/move_fail/Test"
deletePath = "testdata/move_delete/Test"
benchPath = "testdata/move_benchmark/"

acfData = lipsum()
test1Data = lipsum()
test2Data = lipsum()
test3Data = lipsum()

opt = encoding: 'utf8'

describe 'moveSteps', ->
  before ->
    fs.mkdirpSync "#{sourcePath}/Sub"
    fs.writeFileSync "#{sourcePath}.acf", acfData
    fs.writeFileSync "#{sourcePath}/Test1.txt", test1Data
    fs.writeFileSync "#{sourcePath}/Sub/Test2.txt", test2Data
    fs.writeFileSync "#{sourcePath}/Test3.txt", test3Data
    fs.writeFileSync "#{sourcePath}/Test3Again.txt", test3Data
    fs.writeFileSync "#{sourcePath}/NotTest3.txt", "This isn't #{test3Data}"
    # generate some dust
    for i in [0..1000]
      fs.writeFileSync "#{sourcePath}/Sub/#{Math.random()}.txt", lipsum()
    fs.mkdirpSync "#{destPath}"
    fs.mkdirpSync failPath
    fs.writeFileSync "#{failPath}.acf", "Nope!"
    fs.mkdirpSync deletePath
    fs.writeFileSync "#{deletePath}.acf", acfData
    fs.writeFileSync "#{deletePath}/Test1.txt", test1Data
    fs.mkdirpSync benchPath

  describe '#moveGame', ->
    context "when the destination doesn't already exist", ->
      before (done) ->
        moveSteps.moveGame
          source: sourcePath
          destination: destPath
          acfSource: "#{sourcePath}.acf"
          acfDest: "#{destPath}.acf"
        .subscribe (->), done, done
      it 'should move the ACF', ->
        newContents = fs.readFileSync "#{destPath}.acf", opt
        expect(newContents).to.equal(acfData)
      it 'should move the game files', ->
        newContents1 = fs.readFileSync "#{destPath}/Test1.txt", opt
        expect(newContents1).to.equal(test1Data)
        newContents2 = fs.readFileSync "#{destPath}/Sub/Test2.txt", opt
        expect(newContents2).to.equal(test2Data)
        newContents3 = fs.readFileSync "#{destPath}/Test3.txt", opt
        expect(newContents3).to.equal(test3Data)
    context 'when the destination already exists', ->
      error = null
      before (done) ->
        moveSteps.moveGame
          source: sourcePath
          destination: failPath
          acfSource: "#{sourcePath}.acf"
          acfDest: "#{failPath}.acf"
        .subscribe (->), (err) ->
          error = err
          done()
      it 'should cause an error', ->
        expect(error).to.exist
      it 'should not copy anything', ->
        expect(-> fs.readFileSync("#{failPath}/Test1.txt")).to.throw(Error)

  describe '#verifyFile', ->
    context 'when the files are different', ->
      obj =
        src: "#{sourcePath}/Test3.txt"
        dst: "#{sourcePath}/NotTest3.txt"
      it 'should detect that they are different', (done) ->
        moveSteps.verifyFile(obj).subscribe (x) ->
          expect(x).to.be.false
        , (->), done
    context 'when the files are identical', ->
      obj =
        src: "#{sourcePath}/Test3.txt"
        dst: "#{sourcePath}/Test3Again.txt"
      it 'should detect that they are identical', (done) ->
        moveSteps.verifyFile(obj).subscribe (x) ->
          expect(x).to.equal(obj)
        , (->), done

  describe '#deleteOriginal', ->
    it 'should delete the source', (done) ->
      moveSteps.deleteOriginal
        source: deletePath
        acfSource: "#{deletePath}.acf"
      .subscribe (->), (->), ->
        expect(-> fs.readFileSync("#{deletePath}/Test1.txt")).to.throw(Error)
        expect(-> fs.readdirSync(deletePath)).to.throw(Error)
        expect(-> fs.readFileSync("#{deletePath}.acf")).to.throw(Error)
        done()

  describe 'as a whole', ->
    @timeout 10000
    cpDuration = -1
    before ->
      # we need to get the time without JS overhead
      if process.platform is 'win32'
        powershellPath =
          'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe'
        args = [
          "-command"
          "\"& {& 'Measure-Command' {robocopy
            #{pathMod.normalize sourcePath}
            #{pathMod.normalize benchPath} /e}}\""
        ]
        command = "powershell -command \"& {& 'Measure-Command' {robocopy
          #{pathMod.normalize sourcePath} #{pathMod.normalize benchPath} /e}}\""
        ###
        child.exec command, (err, stdout, stderr) ->
          console.log "It Finished!"
          if err?
            console.log "native copy error: #{err}"
          else
            console.log "no native copy error"
          match = /TotalMilliseconds\s*:\s*([\d\.]+)/.exec(stdout.toString())
          console.log "Native copy result: #{match}"
          cpDuration = match[1]
          del [benchPath], done
        timeProcess = child.spawn powershellPath, args, {stdio: 'inherit'}
        timeProcess.on 'exit', done
        ###
        output = child.execSync(command).toString()
        match = /TotalMilliseconds\s*:\s*([\d\.]+)/.exec(output)
        cpDuration = parseFloat match[1]
        del ["#{benchPath}/*"]
      else
        child.exec "/usr/bin/time -f %e cp -R #{sourcePath} #{benchPath}",
          (err, stdout, stderr) ->
            if err?
              console.log "native copy error: #{err}"
            cpDuration = parseFloat(stderr.toString()) * 1000
            del ["#{benchPath}/*"]
    it 'should be no more than 3x as slow as cp', (done) ->
      stepsStart = Date.now()
      moveSteps.moveGame
        source: sourcePath
        destination: "#{benchPath}/Test"
        acfSource: "#{sourcePath}.acf"
        acfDest: "#{benchPath}/Test.acf"
      # .flatMap moveSteps.verifyFile
      .subscribe ((x) -> expect(x).to.be.ok), (->), ->
        stepsDuration = Date.now() - stepsStart
        ###
        console.log "minimum: #{cpDuration}"
        console.log "actual: #{stepsDuration}"
        console.log "maximum: #{3*cpDuration}"
        ###
        expect(stepsDuration, 'duration (ms)')
          .to.be.below(3*cpDuration)
        done()

  after ->
    del ['testdata/move_*']
