gulp = require "gulp"
coffee = require 'gulp-coffee'
less = require 'gulp-less'
runElectron = require 'gulp-run-electron'
jade = require 'gulp-jade'
namespace = require 'gulp-jade-namespace'
concat = require 'gulp-concat'
electron = require 'gulp-atom-electron'
del = require 'del'
packageInfo = require './package.json'
zip = require 'gulp-zip'

gulp.task "js-client", ->
  gulp.src "./src/client.coffee"
  .pipe coffee()
  .pipe gulp.dest "./out/"

gulp.task "js-main", ->
  gulp.src "./src/main.coffee"
  .pipe coffee()
  .pipe gulp.dest "./out/"

gulp.task "js-vendor", ->
  gulp.src [
    "./src/*.js"
    "./node_modules/gulp-jade/node_modules/jade/runtime.js"
  ]
  .pipe gulp.dest "./out/"

gulp.task "js-util", ->
  gulp.src "./src/util/*.coffee"
  .pipe coffee()
  .pipe gulp.dest "./out/util/"

gulp.task "js", ["js-client", "js-main", "js-vendor", "js-util"], ->

gulp.task "css-style", ->
  gulp.src "./src/style.less"
  .pipe less()
  .pipe gulp.dest "./out/"

gulp.task "css", ["css-style"], ->

gulp.task "html-index", ->
  gulp.src "./src/index.jade"
  .pipe jade()
  .pipe gulp.dest "./out/"

gulp.task "html-client-templates", ->
  gulp.src ["./src/*.jade", "!./src/index.jade"]
  .pipe jade(client: yes)
  .pipe namespace()
  .pipe concat "templates.js"
  .pipe gulp.dest "./out/"

gulp.task "html", ["html-index", "html-client-templates"], ->

gulp.task "compile", ["js", "css", "html"], ->

gulp.task "run", ["compile"], ->
  gulp.src "."
  .pipe runElectron()

gulp.task "restart", runElectron.rerun

gulp.task "live", ["compile", "run"], ->
  gulp.watch "./src/**/*", ["compile", "restart"]

gulp.task "watch", ->
  gulp.watch "./src/**/*", ["compile"]

gulp.task "clean:out", (cb) ->
  del ["out/"], cb

gulp.task "clean:dist", (cb) ->
  del ["dist/"], cb

gulp.task "clean:build", (cb) ->
  del ["build/"], cb

gulp.task "clean", ["clean:out", "clean:dist", "clean:build"], ->

gulp.task "default", ["compile", "watch"], ->

gulp.task "dist", ["clean:dist", "compile"], ->
  gulp.src [
    "./assets/**/*"
    "./node_modules/**/*"
    "!./node_modules/gulp*"
    "!./node_modules/gulp*/**/*"
    "./out/**/*"
    "./package.json"
  ], {base: "."}
  .pipe electron version: '0.29.2', platform: 'win32', arch: 'x64'
  .pipe gulp.dest "./dist/Relief Valve v#{packageInfo.version}/"

gulp.task "build", ["clean:build", "dist"], ->
  gulp.src "./dist/**/*", base: "./dist"
  .pipe zip "Relief Valve v#{packageInfo.version}.zip"
  .pipe gulp.dest "./build/"
