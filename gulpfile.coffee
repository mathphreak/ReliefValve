gulp = require "gulp"
del = require 'del'
packageInfo = require './package.json'
_ = require 'lodash'
os = require 'os'
child = require 'child_process'
npm = require 'npm'

$ = require('gulp-load-plugins')()

gulp.task "js:vendor", ->
  gulp.src [
    "./src/vendor/**/*.js"
    "./node_modules/jade/runtime.js"
  ]
  .pipe gulp.dest "./out/"

gulp.task "js:coffee", ->
  gulp.src "./src/**/*.coffee", base: "./src"
  .pipe $.coffee()
  .pipe gulp.dest "./out/"

gulp.task "js", ["js:vendor", "js:coffee"]

gulp.task "css:style", ->
  gulp.src "./src/style.less"
  .pipe $.less()
  .pipe gulp.dest "./out/"

gulp.task "css", ["css:style"]

gulp.task "html:index", ->
  gulp.src "./src/index.jade"
  .pipe $.jade()
  .pipe gulp.dest "./out/"

gulp.task "html:client-templates", ->
  gulp.src ["./src/*.jade", "!./src/index.jade"]
  .pipe $.jade(client: yes)
  .pipe $.jadeNamespace()
  .pipe $.concat "templates.js"
  .pipe gulp.dest "./out/"

gulp.task "html", ["html:index", "html:client-templates"]

gulp.task "compile", ["js", "css", "html"]

gulp.task "watch", ->
  gulp.watch "./src/vendor/*.js", ["js:vendor"]
  gulp.watch "./src/**/*.coffee", ["js:coffee"]
  gulp.watch "./src/**/*.less", ["css:style"]
  gulp.watch "./src/**/*.css", ["css:style"]
  gulp.watch "./src/index.jade", ["html:index"]
  gulp.watch ["./src/*.jade", "!./src/index.jade"], ["html:client-templates"]

gulp.task "clean:out", -> del ["out/"]

gulp.task "clean:dist", -> del ["dist/"]

gulp.task "clean:build", -> del ["build/"]

gulp.task "clean:dev", -> del ["coverage/"]

gulp.task "clean", ["clean:out", "clean:dist", "clean:build", "clean:dev"]

gulp.task "default", ["compile", "watch"]

gulp.task "dist:src:copy", ["clean:dist", "compile"], ->
  gulp.src [
    "./assets/**/*"
    "./out/**/*"
    "./package.json"
  ], {base: '.'}
  .pipe gulp.dest "./dist/src/"

gulp.task "dist:src", ["dist:src:copy"], (cb) ->
  done = (x...) ->
    process.chdir('../../')
    cb x...
  process.chdir('./dist/src/')
  npm.load {only: 'prod'}, (err) ->
    return done(err) if err?
    npm.commands.install [], (err, data) ->
      return done(err) if err?
      done()

outputs = []

makeBuildTask = (platform, arch) ->
  id = "#{platform}-#{arch}"
  outputs.push id
  gulp.task "dist:#{id}", ["dist:src"], ->
    gulp.src './dist/src/**/*'
    .pipe $.atomElectron
      version: packageInfo.devDependencies["electron-prebuilt"]
      platform: platform
      arch: arch
    .pipe $.symdest "./dist/#{id}/Relief Valve v#{packageInfo.version}/"
  gulp.task "build:#{id}", ["clean:build", "dist:#{id}"], ->
    if platform is 'darwin'
      child.execSync "mkdir -p ../../build", cwd: "./dist/#{id}"
      child.execSync "tar czf
        ../../build/Relief-Valve-v#{packageInfo.version}-#{id}.tar.gz
        *", cwd: "./dist/#{id}"
    else
      gulp.src "./dist/#{id}/**/*", base: "./dist/#{id}"
      .pipe $.zip "Relief-Valve-v#{packageInfo.version}-#{id}.zip"
      .pipe gulp.dest "./build/"

makeBuildTask 'win32', 'x64'
makeBuildTask 'win32', 'ia32'
makeBuildTask 'darwin', 'x64'
makeBuildTask 'linux', 'arm'
makeBuildTask 'linux', 'ia32'
makeBuildTask 'linux', 'x64'

gulp.task "dist:all", outputs.map((x) -> "dist:#{x}")

gulp.task "build:all", outputs.map((x) -> "build:#{x}")

thisPlatform = os.platform()
thisArch = os.arch()

gulp.task "dist", ["dist:#{thisPlatform}-#{thisArch}"]

gulp.task "build", ["build:#{thisPlatform}-#{thisArch}"]
