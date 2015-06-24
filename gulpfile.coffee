gulp = require "gulp"
coffee = require 'gulp-coffee'
less = require 'gulp-less'
runElectron = require 'gulp-run-electron'
jade = require 'gulp-jade'

gulp.task "js-client", ->
  gulp.src "./src/client.coffee"
  .pipe coffee()
  .pipe gulp.dest "./out/"

gulp.task "js-main", ->
  gulp.src "./src/main.coffee"
  .pipe coffee()
  .pipe gulp.dest "./out/"

gulp.task "js-vendor", ->
  gulp.src "./src/*.js"
  .pipe gulp.dest "./out/"

gulp.task "js-jade-runtime", ->
  gulp.src "./node_modules/gulp-jade/node_modules/jade/runtime.js"
  .pipe gulp.dest "./out/"

gulp.task "js", ["js-client", "js-main", "js-vendor", "js-jade-runtime"], ->

gulp.task "css-style", ->
  gulp.src "./src/style.less"
  .pipe less()
  .pipe gulp.dest "./out/"

gulp.task "css", ["css-style"], ->

gulp.task "html-index", ->
  gulp.src "./src/index.jade"
  .pipe jade()
  .pipe gulp.dest "./out/"

gulp.task "html-gameList", ->
  gulp.src "./src/gameList.jade"
  .pipe jade(client: yes)
  .pipe gulp.dest "./out/"

gulp.task "html", ["html-index", "html-gameList"], ->

gulp.task "run", ["js", "css", "html"], ->
  gulp.src "."
  .pipe runElectron()

gulp.task "restart", runElectron.rerun

gulp.task "watch", ->
  gulp.watch "./src/*.coffee", ['js', 'restart']
  gulp.watch "./src/*.less", ['css', 'restart']
  gulp.watch "./src/*.jade", ['html', 'restart']

gulp.task "default", ["run", "watch"], ->
  # maybe do something idk
