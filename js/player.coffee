$(document).ready ->
  app = window || {}

  app.constants ?= {}
  app.constants = _.extend app.constants, 
    playerSizeX: app.constants.canvasX / app.constants.canvasXBlock
    playerSizeY: app.constants.canvasY / app.constants.canvasYBlock

  app.constants = _.extend app.constants, 
    playerFillStyle: "#0000FF"

    playerDeltaX: app.constants.playerSizeX / 2
    playerDeltaY: app.constants.playerSizeY * 6

    playerFallSpeed: app.constants.playerSizeX / 5
    playerFallMultipler: 1.05

  app.PlayerModel = Backbone.Model.extend
    initialize: ->
      @on('change', @validatePos)
      @setupFall()
  
    setupFall: ->
      setInterval @fall.bind(@), 20

    moveRight: ->
      @set('x', @get('x') + app.constants.playerDeltaX )
      @set('direction', 'RIGHT')

    moveLeft:->
      @set('x', @get('x') - app.constants.playerDeltaX )
      @set('direction', 'LEFT')

    jump: _.debounce -> # no flying
      @set('y', @get('y') - app.constants.playerDeltaY )
    , 50, true

    validatePos: ->
      if @get('x') > app.constants.canvasX
        @set('x', 0)
      else if @get('x') <  0
        @set('x', app.constants.canvasX)

      floorHeight = _.max _.map @blockX(), (corner) -> 
        app.rounds.height(corner) * app.constants.playerSizeX

      if @get('y') > app.constants.canvasY - app.constants.playerSizeY - floorHeight
        @set('y', app.constants.canvasY - app.constants.playerSizeY - floorHeight)

    fall: ->
      floorHeight = _.max _.map @blockX(), (corner) -> 
        app.rounds.height(corner) * app.constants.playerSizeX

      if @get('y') != app.constants.canvasY - app.constants.playerSizeY - floorHeight
        @set('y', @get('y') + @get('fallSpeed'))
        @set('fallSpeed', app.constants.playerFallMultipler * @get('fallSpeed'))
      else
        @set('fallSpeed', app.constants.playerFallSpeed)

    radius: -> app.constants.playerSizeX / 2

    # Returns [leftBlock, rightBlock]
    blockX: -> [Math.floor( (@get('x') + 1) / app.constants.playerSizeX), 
                Math.floor( (@get('x') + app.constants.playerSizeX - 1) / app.constants.playerSizeX)]
    blockY: -> Math.floor(@get('y') / app.constants.playerSizeY)

  app.PlayerView = Backbone.View.extend
    el: "#gameCanvas"

    initialize: ->
      _.bindAll @, "render"
      @model.view = @

    render: (ctx) ->
      canvas = ($(@el)[0])
      ctx = canvas.getContext("2d")
      ctx.fillStyle = app.constants.playerFillStyle

      ctx.fillRect(@model.get('x'),@model.get('y'),app.constants.playerSizeX,app.constants.playerSizeY)
