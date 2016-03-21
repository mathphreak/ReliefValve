_ = require 'lodash'
Rx = require 'rx'
filesize = require 'filesize'
ipc = require('electron').ipcRenderer
compareIgnoringArticles = require 'compare-ignoring-articles'
storage = require 'electron-json-storage'

initSteps = require './steps/init'
pathSteps = require './steps/path'
gameSteps = require './steps/game'
sizeSteps = require './steps/size'
moveSteps = require './steps/move'
catSteps = require './steps/category'

# enable long stack traces so that RxJS errors are less terrible to debug
Rx.config.longStackSupport = yes

vex.defaultOptions.className = 'vex-theme-plain'

# Helper utilities for building buttons
vexSubmitButton = (text) ->
  text: text
  type: 'submit'
  className: 'vex-dialog-button-primary'
vexCancelButton = (text) ->
  text: text
  type: 'button'
  className: 'vex-dialog-button-secondary'
  click: ($vexContent, event) ->
    $vexContent.data().vex.value = false
    return vex.close($vexContent.data().vex.id)

libraryPath = pathSteps.getDefaultSteamLibraryPath()

folderListPath = "#{libraryPath}/steamapps/libraryfolders.vdf"

Games = []
Paths = []
Categories = {}

markGameLoading = (game) ->
  $('#games .game')
    .filter -> @dataset.name is game.name
    .children()
    .children('i')
    .addClass('fa-circle-o-notch')
    .addClass('fa-spin')
    .removeClass('fa-gamepad')

toggleOverlap = (toggledRow) ->
  thisName = toggledRow.data('name')
  thisFullPath = toggledRow.children('.cell:nth-child(2)').text()
  thisSelected = toggledRow.is('.selected')
  $('.game .cell:nth-child(2)').get().filter (child) ->
    child.innerText.trim() is thisFullPath.trim()
  .forEach (child) ->
    $(child).closest('.game').toggleClass('selected', thisSelected)

updateCheckbox = (el, val, max) ->
  if val is max
    el
      .addClass 'fa-check-square-o'
      .removeClass 'fa-square'
      .removeClass 'fa-square-o'
  else if val > 0
    el
      .removeClass 'fa-check-square-o'
      .addClass 'fa-square'
      .removeClass 'fa-square-o'
  else
    el
      .removeClass 'fa-check-square-o'
      .removeClass 'fa-square'
      .addClass 'fa-square-o'

gameHasAbbr = (abbr) -> ->
  $(@).find('.base').text() is abbr

updateSelected = ->
  hasSelection = $('.game.selected').size() > 0
  updateCheckbox $('#globalSelect i'), $('.game.selected').size(),
    $('#games .game:not(.loading)').size()
  for path, i in Paths
    updateCheckbox $(".libs span:nth-child(#{i + 1}) i"),
      $('.game.selected').filter(gameHasAbbr(path.abbr)).size(),
      $('#games .game:not(.loading)').filter(gameHasAbbr(path.abbr)).size()
  updateCategorySelection()
  names = $('.game.selected')
    .get()
    .map (el) -> el.dataset.name
  paths = $('.game.selected .cell .base')
    .get()
    .map (el) -> el.innerText
  sizes = Math.round($('.game.selected .cell:last-child')
    .get()
    .map (el) -> parseFloat(el.innerText) * 100
    .reduce(((a, b) -> a + b), 0)) / 100
  goodIndex = null
  $('#selection option').attr 'disabled', (i) ->
    if _.includes(paths, Paths[i].abbr)
      yes
    else
      goodIndex ?= i
      null
  if goodIndex is null
    $('#move').addClass 'disabled'
  else
    $('#move').removeClass 'disabled'
  if $('#selection option:selected').is(':disabled')
    $('#selection option:not(:disabled)').first().prop('selected', true)
  $('#all-names').text names.join ', '
  $('#all-paths').text paths.join ', '
  if _.isNaN sizes
    if $('#total-size').text() isnt ''
      $('#total-size').html('')
      $('<i></i>')
        .addClass('fa')
        .addClass('fa-circle-o-notch')
        .addClass('fa-spin')
        .appendTo('#total-size')
  else
    $('#total-size').text("#{sizes} GB")
  $('#selection').toggle(hasSelection)
  Ps.update $('#gameList #games').get(0)

makeGamesStreamObserver = ->
  seen = no
  Rx.Observer.create (game) ->
    if not seen
      seen = yes
      $('#games .game:not(.loading)').remove()
      $('#gameList .loading').show()
    result = Templates.game(game: game, paths: Paths)
    $('#games .game')
      .filter -> compareIgnoringArticles(@dataset.name, game.name, false) < 0
      .last()
      .after(result)
    Ps.update $('#gameList #games').get(0)
  , off # use default error handling for now
  , ->
    $('#gameList .loading').hide()

makeSizesStreamObserver = -> Rx.Observer.create ({name, data}) ->
  # update Games
  _.find(Games, name: name).sizeData = data

  # update game in table
  $('#games .game')
    .filter -> @dataset.name is name
    .children()
    .last()
    .text filesize(data.size, exponent: 3)

  # update the footer (recalculate total size of all selected)
  updateSelected()
, off
, off

initializeProgress = (games) ->
  sizeKey = if process.platform is 'win32'
    'size'
  else
    'nodes'
  acfSize = if process.platform is 'win32'
    moveSteps.DUMMY_SIZE
  else
    1
  # calculate total size
  totalSize = _(games)
    .map('sizeData')
    .map(sizeKey)
    .map (x) -> x + acfSize
    .reduce((a, b) -> a + b)
  totalSize *= moveSteps.DUMMY_SIZE unless process.platform is 'win32'
  $('#progress-outer').data('total', totalSize)

  # make sure the progress bar starts at zero
  resetProgress()

  # show the progress bar
  $('#progress-container').show()
  $('#progress-container').height('2rem')

resetProgress = ->
  $('#progress-outer').html('')

updateSystemProgress = _.throttle ->
  currentProgress = $('.progress')
    .map (i, x) -> $(x).width()
    .reduce (a, b) -> a + b
  totalProgress = $('#progress-outer').width()
  ipc.send 'progress', currentProgress / totalProgress
, 100

addProgress = (x) ->
  el = $('<div class="progress">&nbsp;</div>')
  el.appendTo('#progress-outer')
  el.data('size', x.size)
  el.data('id', x.id)
  total = parseInt($('#progress-outer').data('total'))
  percent = x.size / total * 100
  el.width 0
  setTimeout ->
    el.width("#{percent}%")
    updateSystemProgress()
  , 1
  yes

makeCopyProgressObserver = -> Rx.Observer.create (x) ->
  addProgress x
, ((x) -> console.log "Error while moving: #{x}")

makeDeleteProgressObserver = -> Rx.Observer.create ((x) -> console.log 'Done!'),
  ((e) -> throw e), (x) ->
    setTimeout ->
      ipc.send 'progress', no
      $('#progress-container').height('0%')
      $('.progress').height(0)
      runProcess()
    , 400

runningConfirm = (cancelText) -> (running) ->
  result = new Rx.Subject()
  if running
    message = "<p>It looks like Steam is currently running.</p>
      <p>If you move games while Steam is running, bad things may happen.</p>
      <p>If you have quit Steam or Steam isn't actually running,
      just continue.</p>"
    vex.dialog.confirm
      message: message
      buttons: [
        vexSubmitButton 'Continue'
        vexCancelButton cancelText
      ]
      callback: (x) ->
        result.onNext(x)
        result.onCompleted()
  else
    result = Rx.Observable.just(yes)
  return result

makeSteamRunningObserver = -> Rx.Observer.create (continuing) ->
  if not continuing
    window.close()

runUpdateCheck = ->
  initSteps.updateMessage()
    .subscribe ([message, url]) ->
      vex.dialog.confirm
        message: "<p>#{message}.</p>
          <p>Press OK to download the update or Cancel to not do that.</p>"
        callback: (x) -> require('shell').openExternal url if x

updateCategorySelection = ->
  try
    appIDs = Categories[$('.user select').val()][$('.category select').val()]
    matchesAppID = -> appIDs.indexOf(@dataset.appid) > -1
    updateCheckbox $('#magic a i'),
      $('.game.selected').filter(matchesAppID).size(),
      $('#games .game:not(.loading)').filter(matchesAppID).size()

updateCategorySelect = ->
  $('.category select').html('')
  categories = _.keys(Categories[$('.user select').val()]).sort()
  # Move favorites to front if they're at the back
  if categories.indexOf('favorite') > 0
    categories = ['favorite'].concat _.without categories, 'favorite'
  for category in categories
    $("<option>#{category}</option>").appendTo('.category select')
  updateCategorySelection()

saveSelection = ->
  storage.set 'selectedUser', $('.user select').val()
  storage.set 'selectedCategory', $('.category select').val()

loadSelection = ->
  storage.get 'selectedUser', (err, data) ->
    unless _.isEmpty data
      $('.user select').val(data)
      updateCategorySelect()
      storage.get 'selectedCategory', (err, data) ->
        unless _.isEmpty data
          $('.category select').val(data)

fetchCategories = ->
  $('.user select').html('')
  catSteps.getAccountIDs(libraryPath)
    .map (ids) -> _.without ids, 'anonymous'
    .flatMap (ids) ->
      if ids.length is 1
        $('.user').hide()
        Rx.Observable.just [[ids[0], "[U:1:#{ids[0]}]"]]
      else
        $('.user').show()
        Rx.Observable.fromNodeCallback(storage.get)('STEAM_API_KEY')
          .flatMap (key) ->
            if _.isEmpty key
              $('.user select').attr('title',
                'Check Settings to see usernames here')
              Rx.Observable.just ids.map (id) -> [id, "[U:1:#{id}]"]
            else
              $('.user select').attr('title', '')
              catSteps.getUsernames(ids, key)
                .map (x) -> _.toPairs x
    .flatMap (x) -> x
    .flatMap ([userID, userDisplay]) ->
      $("<option value=\"#{userID}\">#{userDisplay}</option>")
        .appendTo('.user select')
      catSteps.getCategories(libraryPath, userID)
        .do (categories) ->
          Categories[userID] = categories
          updateCategorySelect()
    .subscribe (->), (->), ->
      loadSelection()

runProcess = ->
  fetchCategories()
  Rx.Observable.just folderListPath
    .flatMap pathSteps.readVDF
    .flatMap pathSteps.parseFolderList
    .toArray()
    .do (d) ->
      Paths = d
      footer = Templates.footer(paths: d)
      $('#selection').replaceWith(footer)
      libs = Templates.libs(paths: d)
      $('.libs').replaceWith(libs)
    .flatMap _.identity
    .flatMap gameSteps.getPathACFs
    .flatMap gameSteps.readAllACFs
    .map gameSteps.buildGameObject
    .toArray()
    .do (d) ->
      Games = d
    .flatMap _.identity
    .do makeGamesStreamObserver()
    .observeOn Rx.Scheduler.currentThread
    .do markGameLoading
    .flatMap sizeSteps.loadGameSize
    .subscribe makeSizesStreamObserver()

watchForKonamiCode = ->
  codes = [
    38 # up
    38 # up
    40 # down
    40 # down
    37 # left
    39 # right
    37 # left
    39 # right
    66 # b
    65 # a
  ]
  konami = Rx.Observable.fromArray codes

  Rx.Observable.fromEvent $(document), 'keyup'
    .map (e) ->
      e.keyCode
    .windowWithCount 10, 1 # always take the most recent ten
    .selectMany (x) -> x.sequenceEqual konami
    .filter (x) -> x
    .subscribe ->
      ipc.send 'showMenu', yes

combineOverlappingGames = (allGames) ->
  _(allGames)
    .map (oldGame, idx) ->
      game = _.clone oldGame
      duplicates = _.filter allGames, (otherGame, idx2) ->
        otherGame.source is game.source
      _.each duplicates, (otherGame, idx2) ->
        if idx2 isnt idx
          otherGame.drop = yes
      game.acfSource = _.map duplicates, 'acfSource'
      game.acfDest = _.map duplicates, 'acfDest'
      game
    .reject 'drop'
    .value()

ipc.on 'menuItem', (event, item) ->
  switch item
    when 'about'
      vex.dialog.alert "<p>You are running Relief Valve
        v#{require('../package.json').version}</p>"

updateSearch = ->
  query = $('.search input').val()
  $('.game:not(.loading)').each (i, x) ->
    name = x.dataset.name
    $(x).toggle _.includes(name.toLocaleLowerCase(), query.toLocaleLowerCase())

$ ->
  initSteps.isSteamRunning()
    .flatMap runningConfirm 'Quit'
    .subscribe makeSteamRunningObserver()

  watchForKonamiCode()

  runUpdateCheck()

  Ps.initialize $('#gameList #games').get(0), suppressScrollX: yes

  Rx.Observable.fromEvent $('#refresh'), 'click'
    .startWith 'initial load event'
    .subscribe runProcess

  $(document).on 'click', '#clearSearch', (event) ->
    $('.search input').val('').focus()
    updateSearch()

  $(document).on 'input', '.search input', (event) ->
    updateSearch()

  $(document).on 'click', '#globalSelect i', (event) ->
    selected = $('#globalSelect i').is('.fa-square-o')
    $('#games .game:not(.loading)').toggleClass('selected', selected)
    updateSelected()
    event.stopImmediatePropagation()

  $(document).on 'click', '.libs span i', (event) ->
    path = $(@).closest('.libs > span').text()
    selected = $(@).closest('.libs > span i').is('.fa-square-o')
    $('#games .game:not(.loading)')
      .filter(gameHasAbbr(path))
      .toggleClass('selected', selected)
    updateSelected()
    event.stopImmediatePropagation()

  $(document).on 'click', '#games .game', (event) ->
    $(@).closest('.game').toggleClass('selected')
    toggleOverlap $(event.target).closest('.game')
    updateSelected()
    event.stopImmediatePropagation()

  $(document).on 'click', '#settings-link', (event) ->
    $('#settings-wrapper').show()
    storage.get 'STEAM_API_KEY', (err, key) ->
      unless _.isEmpty key
        $('#steamAPIkey').val(key)
    event.stopImmediatePropagation()

  $(document).on 'submit', '#settings form', (event) ->
    $('#settings-wrapper').hide()
    storage.get 'STEAM_API_KEY', (err, data) ->
      if data isnt $('#steamAPIkey').val()
        storage.set 'STEAM_API_KEY', $('#steamAPIkey').val(), (err) ->
          fetchCategories()
    event.stopImmediatePropagation()
    event.preventDefault()

  $(document).on 'click', 'a[target="_blank"]', (event) ->
    alert 'If it asks for a domain name, just put random garbage'
    require('electron').shell.openExternal(@href)
    event.preventDefault()

  $(document).on 'click', '#move:not(.disabled)', (event) ->
    # get the selected path
    pathIndex = $('#selection select')
      .children()
      .map (i, a) ->
        i if a.innerHTML is $('#selection select').val()
      .get()
      .filter( (x) -> x > -1 )[0]

    destination = Paths[pathIndex].path

    copyProgressObserver = makeCopyProgressObserver()
    deleteProgressObserver = makeDeleteProgressObserver()

    initSteps.isSteamRunning()
      .flatMap runningConfirm 'Cancel'
      .flatMap (go) ->
        if go
          ipc.send 'progress', 0
          Rx.Observable.from Games
        else
          Rx.Observable.empty()
      .filter (game) ->
        $(".game[data-name=\"#{game.name}\"]").hasClass('selected')
      .toArray()
      .do initializeProgress
      .flatMap (x) -> x
      .map moveSteps.makeBuilder destination
      .toArray()
      .map combineOverlappingGames
      .flatMap (x) -> x
      .flatMap (x) ->
        moveSteps.moveGame(x)
          .do copyProgressObserver
          .last()
          .map -> x
      .flatMap (data) ->
        moveSteps.deleteOriginal(data)
          .map -> data
      .subscribe deleteProgressObserver

  $(document).on 'change', '.user select', ->
    updateCategorySelect()
    saveSelection()

  $(document).on 'change', '.category select', ->
    updateCategorySelection()
    saveSelection()

  $(document).on 'click', '#magic a.select i', (event) ->
    appIDs = Categories[$('.user select').val()][$('.category select').val()]
    selected = $('#magic a.select i').is('.fa-square-o')
    for appID in appIDs
      # Ignore uninstalled favorites
      if $(".game[data-appID=\"#{appID}\"]").size() > 0
        $(".game[data-appID=\"#{appID}\"]").toggleClass 'selected', selected
        toggleOverlap $(".game[data-appID=\"#{appID}\"]")
    updateSelected()
    event.stopImmediatePropagation()
