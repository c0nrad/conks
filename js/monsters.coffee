$(document).ready ->
  app = window || {}

  app.constants ?= {}
  app.constants = _.extend app.constants, 
    #Monster
    monsterSizeX: app.constants.playerSizeX
    monsterSizeY: app.constants.playerSizeY
    monsterFillStyle: "#FF0000"

    monsterDeltaX: app.constants.playerDeltaX / 2.5

    monsterFallSpeed: app.constants.playerFallSpeed / 2
    monsterFallMultipler: app.constants.playerFallMultipler + .05

  app.MonsterModel = Backbone.Model.extend
    initialize: ->
      @on('change', @validatePos)

    move: ->
      if @get('direction') == "RIGHT"
        @set('x', @get('x') + app.constants.monsterDeltaX )
      else if @get('direction') == "LEFT"
        @set('x', @get('x') - app.constants.monsterDeltaX )

    validatePos: ->
      if @get('x') > app.constants.canvasX
        @set('x', 0)
      else if @get('x') <  0
        @set('x', app.constants.canvasX)

      floorHeight = _.max _.map @blockX(), (corner) ->  
        app.rounds.height(corner) * app.constants.playerSizeX

      if @get('y') > app.constants.canvasY - app.constants.monsterSizeY - floorHeight
        @set('y', app.constants.canvasY - app.constants.monsterSizeY - floorHeight)

    fall: ->

      floorHeight = _.max _.map @blockX(), (corner) -> 
        app.rounds.height(corner) * app.constants.playerSizeX

      if @get('y') != app.constants.canvasY - app.constants.monsterSizeY - floorHeight
        @set('y', @get('y') + @get('fallSpeed'))
        @set('fallSpeed', app.constants.monsterFallMultipler * @get('fallSpeed'))
      else
        @set('fallSpeed', app.constants.monsterFallSpeed)

    radius: -> app.constants.monsterSizeY / 2

    blockX: -> [Math.floor( (@get('x') + 1) / app.constants.playerSizeX), 
                Math.floor( (@get('x') + app.constants.playerSizeX - 1) / app.constants.playerSizeX)]

  app.MonsterView = Backbone.View.extend
    el: "#gameCanvas"

    initialize: ->
      _.bindAll @, "render"
      @model.view = @

    render: (ctx) ->
      if @model.get('active')
        canvas = ($(@el)[0])
        ctx = canvas.getContext("2d")

        ctx.fillStyle = app.constants.monsterFillStyle


        if @model.get('color')
          ctx.fillStyle = @model.get('color')
        ctx.fillRect(@model.get('x'),@model.get('y'),app.constants.monsterSizeX,app.constants.monsterSizeY)

  app.Monsters = Backbone.Collection.extend
    model: app.MonsterView

    renderAll: ->
      @forEach (monster) ->
        if monster.get('active')
          monster.view.render()

    moveAll: ->
      @forEach (monster) ->
        if monster.get('active')
          monster.move()
          monster.fall()

    allDead: ->
      @all (monster) -> not monster.get('active')

    spawnMonster: (color) ->
      startX = Math.floor((Math.random()*app.constants.canvasX)+1);
      direction = Math.floor((Math.random()*2));
      monster = new app.MonsterModel {x: startX, y:  0, fallSpeed: 1, direction: app.constants.directions[direction], active: true}

      if color
        monster.set('color', color)

      monsterView = new app.MonsterView { model: monster } 
      @add monster

    alive: ->
      @filter (monster) -> 
        monster.get('active')
      .length
