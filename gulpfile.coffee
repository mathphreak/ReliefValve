gulp = require "gulp"
coffee = require 'gulp-coffee'
less = require 'gulp-less'
runElectron = require 'gulp-run-electron'
jade = require 'gulp-jade'

gulp.task "js", ->
  gulp.src "./src/*.coffee"
  .pipe coffee()
  .pipe gulp.dest "./out/"

gulp.task "css", ->
  gulp.src "./src/*.less"
  .pipe less()
  .pipe gulp.dest "./out/"

gulp.task "html", ->
  gulp.src "./src/*.jade"
  .pipe jade()
  .pipe gulp.dest "./out/"

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
