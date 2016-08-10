gulp = require 'gulp'
del = require 'del'
packageInfo = require './package.json'
_ = require 'lodash'
os = require 'os'
child = require 'child_process'
npm = require 'npm'

$ = require('gulp-load-plugins')()

gulp.task 'watch', ->
  gulp.watch './src/vendor/*.js', ['js:vendor']
  gulp.watch './src/**/*.coffee', ['js:coffee']
  gulp.watch './src/**/*.less', ['css:style']
  gulp.watch './src/**/*.css', ['css:style']
  gulp.watch './src/index.jade', ['html:index']
  gulp.watch ['./src/*.jade', '!./src/index.jade'], ['html:client-templates']

gulp.task 'dist:src:copy', ['clean:dist', 'compile'], ->
  gulp.src [
    './assets/**/*'
    './out/**/*'
    './package.json'
  ], {base: '.'}
  .pipe gulp.dest './dist/src/'

gulp.task 'dist:src', ['dist:src:copy'], (cb) ->
  done = (x...) ->
    process.chdir('../../')
    cb x...
  process.chdir('./dist/src/')
  npm.load {production: yes, progress: false}, (err) ->
    return done(err) if err?
    npm.commands.install [], (err, data) ->
      return done(err) if err?
      done()

outputs = []

makeBuildTask = (platform, arch) ->
  id = "#{platform}-#{arch}"
  outputs.push id
  gulp.task "dist:#{id}", ['dist:src'], ->
    gulp.src './dist/src/**/*'
    .pipe $.atomElectron
      version: packageInfo.devDependencies['electron-prebuilt']
      platform: platform
      arch: arch
      winIcon: './icon/ReliefValve.ico'
      darwinIcon: './icon/ReliefValve.icns'
      quiet: yes
      token: process.env['GITHUB_API_TOKEN']
    .pipe $.symdest "./dist/#{id}/Relief Valve v#{packageInfo.version}/"
  gulp.task "build:#{id}", ['clean:build', "dist:#{id}"], ->
    if platform is 'darwin'
      child.execSync 'mkdir -p ../../build', cwd: "./dist/#{id}"
      child.execSync "tar czf
        ../../build/Relief-Valve-v#{packageInfo.version}-#{id}.tar.gz
        *", cwd: "./dist/#{id}"
    else
      gulp.src "./dist/#{id}/**/*", base: "./dist/#{id}"
      .pipe $.zip "Relief-Valve-v#{packageInfo.version}-#{id}.zip"
      .pipe gulp.dest './build/'

makeBuildTask 'win32', 'x64'
makeBuildTask 'win32', 'ia32'
makeBuildTask 'darwin', 'x64'
makeBuildTask 'linux', 'arm'
makeBuildTask 'linux', 'ia32'
makeBuildTask 'linux', 'x64'

gulp.task 'dist:all', outputs.map((x) -> "dist:#{x}")

gulp.task 'build:all', outputs.map((x) -> "build:#{x}")

thisPlatform = os.platform()
thisArch = os.arch()

gulp.task 'dist', ["dist:#{thisPlatform}-#{thisArch}"]

gulp.task 'build', ["build:#{thisPlatform}-#{thisArch}"]
