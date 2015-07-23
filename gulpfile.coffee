gulp = require "gulp"
coffee = require 'gulp-coffee'
less = require 'gulp-less'
jade = require 'gulp-jade'
namespace = require 'gulp-jade-namespace'
concat = require 'gulp-concat'
electron = require 'gulp-atom-electron'
del = require 'del'
packageInfo = require './package.json'
zip = require 'gulp-zip'
tar = require 'gulp-tar'
gzip = require 'gulp-gzip'
_ = require 'lodash'
os = require 'os'
child = require 'child_process'

gulp.task "js:vendor", ->
  gulp.src [
    "./src/vendor/*.js"
    "./node_modules/gulp-jade/node_modules/jade/runtime.js"
  ]
  .pipe gulp.dest "./out/"

gulp.task "js:coffee", ->
  gulp.src "./src/**/*.coffee", base: "./src"
  .pipe coffee()
  .pipe gulp.dest "./out/"

gulp.task "js", ["js:vendor", "js:coffee"], ->

gulp.task "css:style", ->
  gulp.src "./src/style.less"
  .pipe less()
  .pipe gulp.dest "./out/"

gulp.task "css", ["css:style"], ->

gulp.task "html:index", ->
  gulp.src "./src/index.jade"
  .pipe jade()
  .pipe gulp.dest "./out/"

gulp.task "html:client-templates", ->
  gulp.src ["./src/*.jade", "!./src/index.jade"]
  .pipe jade(client: yes)
  .pipe namespace()
  .pipe concat "templates.js"
  .pipe gulp.dest "./out/"

gulp.task "html", ["html:index", "html:client-templates"], ->

gulp.task "compile", ["js", "css", "html"], ->

gulp.task "watch", ->
  gulp.watch "./src/**/*", ["compile"]

gulp.task "clean:out", (cb) ->
  del ["out/"], cb

gulp.task "clean:dist", (cb) ->
  del ["dist/"], cb

gulp.task "clean:build", (cb) ->
  del ["build/"], cb

gulp.task "clean:dev", (cb) ->
  del ["coverage/"], cb

gulp.task "clean", ["clean:out", "clean:dist", "clean:build", "clean:dev"], ->

gulp.task "default", ["compile", "watch"], ->

distSources = _(packageInfo.dependencies)
  .keys()
  .map (mod) -> "./node_modules/#{mod}/**/*"
  .value()
  .concat [
    "./assets/**/*"
    "./out/**/*"
    "./package.json"
  ]

outputs = []

makeBuildTask = (platform, arch) ->
  id = "#{platform}-#{arch}"
  outputs.push id
  gulp.task "dist:#{id}", ["clean:dist", "compile"], ->
    gulp.src distSources, {base: "."}
    .pipe electron version: '0.30.0', platform: platform, arch: arch
    .pipe gulp.dest "./dist/#{id}/Relief Valve v#{packageInfo.version}/"
  gulp.task "fix:#{id}", ["dist:#{id}"], ->
    path = "./dist/#{id}/Relief Valve
      v#{packageInfo.version}/relief-valve.app/Contents/Frameworks"
    if platform is 'darwin' and os.platform() isnt 'win32'
      # fix things that don't download properly
      frameworks = ['Electron Framework', 'Mantle', 'ReactiveCocoa', 'Squirrel']
      fixFramework = (framework) ->
        fPath = "#{path}/#{framework}.framework"
        child.execSync "ln -s A Current", cwd: "#{fPath}/Versions"
        child.execSync "ln -s Versions/Current/* .", cwd: fPath
      frameworks.forEach fixFramework
  gulp.task "build:#{id}", ["clean:build", "fix:#{id}"], ->
    if platform is 'darwin'
      gulp.src "./dist/#{id}/**/*", base: "./dist/#{id}"
      .pipe tar "Relief-Valve-v#{packageInfo.version}-#{id}.tar"
      .pipe gzip()
      .pipe gulp.dest "./build/"
    else
      gulp.src "./dist/#{id}/**/*", base: "./dist/#{id}"
      .pipe zip "Relief-Valve-v#{packageInfo.version}-#{id}.zip"
      .pipe gulp.dest "./build/"

makeBuildTask 'win32', 'x64'
makeBuildTask 'win32', 'ia32'
makeBuildTask 'darwin', 'x64'
makeBuildTask 'linux', 'arm'
makeBuildTask 'linux', 'ia32'
makeBuildTask 'linux', 'x64'

gulp.task "dist:all", outputs.map((x) -> "dist:#{x}"), ->

gulp.task "build:all", outputs.map((x) -> "build:#{x}"), ->

thisPlatform = os.platform()
thisArch = os.arch()

gulp.task "dist", ["dist:#{thisPlatform}-#{thisArch}"], ->

gulp.task "build", ["build:#{thisPlatform}-#{thisArch}"], ->
