EventEmitter = require 'events'
_ = require 'lodash'
Rx = require 'rx'
filesize = require 'filesize'
compareIgnoringArticles = require 'compare-ignoring-articles'
storage = require 'electron-json-storage'

Categories = {}

pathSteps = require '../steps/path'
gameSteps = require '../steps/game'
sizeSteps = require '../steps/size'
catSteps = require '../steps/category'

libraryPath = pathSteps.getDefaultSteamLibraryPath()

folderListPath = "#{libraryPath}/steamapps/libraryfolders.vdf"

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

gameHasAbbr = (abbr) -> ->
  $(@).find('.base').text() is abbr

updateSelected = ->
  hasSelection = $('.game.selected').size() > 0
  updateCheckbox $('#globalSelect i'), $('.game.selected').size(),
    $('#games .game:not(.loading)').size()
  for path, i in global.Paths
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
    if _.includes(paths, global.Paths[i].abbr)
      yes
    else
      goodIndex ?= i
      null
  if goodIndex is null
    $('#move').addClass 'disabled'
  else
    $('#move:not(.inProgress)').removeClass 'disabled'
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
    result = Templates.game(game: game, paths: global.Paths)
    $('#games .game')
      .filter -> compareIgnoringArticles(@dataset.name, game.name, false) < 0
      .last()
      .after(result)
    Ps.update $('#gameList #games').get(0)
  , ((x) -> clUtils.emit 'error', x)
  , ->
    $('#gameList .loading').hide()

makeSizesStreamObserver = -> Rx.Observer.create ({name, data}) ->
  # update Games
  _.find(global.Games, name: name).sizeData = data

  # update game in table
  $('#games .game')
    .filter -> @dataset.name is name
    .children()
    .last()
    .text filesize(data.size, exponent: 3)

  # update the footer (recalculate total size of all selected)
  updateSelected()
, ((x) -> clUtils.emit 'error', x)
, off

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
    .subscribe (->), ((x) -> clUtils.emit 'error', x), ->
      loadSelection()

runProcess = ->
  fetchCategories()
  Rx.Observable.just folderListPath
    .flatMap pathSteps.readVDF
    .flatMap pathSteps.parseFolderList
    .toArray()
    .do (d) ->
      global.Paths = d
      footer = Templates.footer(paths: d)
      $('#selection').replaceWith(footer)
      libs = Templates.libs(paths: d)
      $('.libs').replaceWith(libs)
      clGames.emit 'pathsLoaded'
    .flatMap _.identity
    .flatMap gameSteps.getPathACFs
    .flatMap gameSteps.readAllACFs
    .map gameSteps.buildGameObject
    .toArray()
    .do (d) ->
      global.Games = d
    .flatMap _.identity
    .do makeGamesStreamObserver()
    .observeOn Rx.Scheduler.currentThread
    .do markGameLoading
    .flatMap sizeSteps.loadGameSize
    .subscribe makeSizesStreamObserver()

updateSearch = ->
  query = $('.search input').val()
  $('.game:not(.loading)').each (i, x) ->
    name = x.dataset.name
    $(x).toggle _.includes(name.toLocaleLowerCase(), query.toLocaleLowerCase())

saveSelection = ->
  storage.set 'selectedUser', $('.user select').val()
  storage.set 'selectedCategory', $('.category select').val()

loadSelection = ->
  storage.get 'selectedUser', (err, user) ->
    unless _.isEmpty user
      $('.user select').val(user)
      updateCategorySelect()
      storage.get 'selectedCategory', (err, category) ->
        unless _.isEmpty category
          $('.category select').val(category)

ready = ->
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

clGames = new EventEmitter

clGames.on 'ready', ready
clGames.on 'fetchCategories', fetchCategories
clGames.on 'refresh', runProcess

module.exports = clGames
