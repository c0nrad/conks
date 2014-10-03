$(document).ready ->
  app = window || {}

  app.constants ?= {}
  app.constants = _.extend app.constants, 
    #Bullet
    bulletSpeed: app.constants.playerDeltaX * 2 - 10
    bulletSizeX: app.constants.playerSizeX / 6
    bulletSizeY: app.constants.playerSizeY / 6
    bulletFillStyle: "#00FF00"

  app.BulletCounter = 0
  app.BulletModel = Backbone.Model.extend
    defaults: ->
      color: ["#FF0000","#FF7F00","#FFFF00","#00FF00","#0000FF","#FFB7D5","#8B00FF"][app.BulletCounter = (app.BulletCounter + 1)% 7]
      x: 0
      y: 0

    initialize: ->

    move: ->
      switch @get('direction')
        when "LEFT"
          @set('x', @get('x') - app.constants.bulletSpeed)
        when "RIGHT"
          @set('x', @get('x') + app.constants.bulletSpeed)
        when "UP"
          @set('y', @get('y') - app.constants.bulletSpeed)
      @validate()

    validate: ->
      if @get('x') > app.constants.canvasX || @get('x') < 0 || @get('y') < 0
        @set('active', false)

      floorHeight = _.max _.map @blockX(), (corner) -> 
        app.rounds.height(corner) * app.constants.playerSizeX

      if @get('y') > app.constants.canvasY - app.constants.bulletSizeY - floorHeight
        @set('active', false)

    blockX: -> [Math.floor( (@get('x') + 1) / app.constants.playerSizeX), 
                Math.floor( (@get('x') + app.constants.bulletSizeY - 1) / app.constants.playerSizeX)]
    
    radius: -> app.constants.bulletSizeY / 2

  app.BulletView = Backbone.View.extend
    el: "#gameCanvas"

    initialize: ->
      _.bindAll @, "render"
      @model.view = @

    render: (ctx) ->
      canvas = ($(@el)[0])
      ctx = canvas.getContext("2d")
      ctx.fillStyle = @model.get('color')
      ctx.fillRect(@model.get('x'),@model.get('y'),app.constants.bulletSizeX,app.constants.bulletSizeY)

  app.Bullets = Backbone.Collection.extend
    model: app.BulletView

    renderAll: ->
      @forEach (bullet) ->
        if bullet.get('active')
          bullet.view.render()

    moveAll: ->
      @forEach (bullet) ->
        if bullet.get('active')
          bullet.move()
