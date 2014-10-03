$(document).ready ->
  app = window || {}

  app.preferences ?= {}
  app.preferences = _.extend app.preferences,
    soundOn: true

  app.constants ?= {}
  app.constants = _.extend app.constants, 

    statsColor: "#007F00"
    statsFont: "16px Arial"

  app.GameView = Backbone.View.extend
    el: "body"

    events: 
      'keyup' : 'logKey'
      'keydown': 'logKey'

    logKey: (e) ->
      if e.type == "keydown"
        @keyMap[e.keyCode] = true
      else if e.type == "keyup"
        @keyMap[e.keyCode] = false

      # Singular Events
      if e.type == "keydown"
        if e.keyCode == 32 
          if app.preferences.soundOn
            app.bulletAudio.currentTime = 0
            app.bulletAudio.play()
          bullet = new app.BulletModel {x: app.playerModel.get('x'), y: app.playerModel.get('y'), direction: app.playerModel.get('direction'), active: true}
          bulletView = new app.BulletView { model: bullet }
          app.bullets.add bullet
        if e.keyCode == 83
          app.preferences.soundOn = !app.preferences.soundOn
        if e.keyCode == 78
          app.monsters.reset()
          app.bullets.reset()
          app.rounds.nextRound()


    movePlayer: ->
      if @keyMap[39]
        app.playerModel.moveRight()
      if @keyMap[37]
        app.playerModel.moveLeft()
      if @keyMap[38]
        app.playerModel.jump()

    collisionDetection: ->
      app.bullets.forEach (bullet) ->
        if bullet.get('active')
          app.monsters.forEach (monster) ->
            if monster.get('active')
              if app.distance(bullet, monster) < bullet.radius() + monster.radius()
                monster.set('active', false)
                bullet.set('active', false)   
                app.score += 1

      app.monsters.forEach (monster) ->
        if monster.get('active')
          if app.distance(app.playerModel, monster) < app.playerModel.radius() + monster.radius()
            app.gameView.gameOver()

    gameOver: ->
      console.log "GAME OVER"
      clearInterval app.gameTimer
      $('body').append("<h1> GAME OVER </h1> <h2> Score #{app.score}")

    render: ->
      canvas = ($("#gameCanvas")[0])
      ctx = canvas.getContext("2d")

      #Clear Screen
      if app.rounds.getBackground()
        ctx.drawImage(app.rounds.getBackground(),0, 0,app.constants.canvasX, app.constants.canvasY)
      else
        ctx.clearRect(0, 0, canvas.width, canvas.height)

      app.playerModel.view.render()
      app.bullets.renderAll()
      app.monsters.renderAll()
      app.rounds.render()
      @renderStats()
      # @renderGrid()

    renderStats: ->
      canvas = ($("#gameCanvas")[0])
      ctx = canvas.getContext("2d")
      ctx.fillStyle = app.constants.statsColor
      ctx.font = app.constants.statsFont
      [x,y] = [app.constants.canvasX - 200, 50]
      ctx.strokeRect x-5, y - 20, 190, 110
      ctx.fillText "Round-Wave: #{app.rounds.getRoundNumber()}-#{app.rounds.getWaveNumber()}",x, y
      ctx.fillText "Monsters Left: #{app.monsters.alive()}", x, y + 20
      ctx.fillText "Total Monsters Killed: #{app.score}", x, y + 40
      ctx.fillText "Frame Number: #{app.gameCounter}", x, y + 60
      ctx.fillText "Player (x,y): #{app.playerModel.blockX()}, #{app.playerModel.blockY()}", x, y + 80

    renderGrid: ->
      canvas = ($("#gameCanvas")[0])
      ctx = canvas.getContext("2d")

      currX = 0
      while currX < app.constants.canvasX
        ctx.beginPath()
        ctx.moveTo(currX, 0)
        ctx.lineTo(currX, app.constants.canvasY)
        ctx.stroke()
        currX += app.constants.playerSizeX

      currY = 0
      while currY < app.constants.canvasY
        ctx.beginPath()
        ctx.moveTo 0, currY
        ctx.lineTo app.constants.canvasX, currY
        ctx.stroke()
        currY += app.constants.playerSizeY

    gameLoop: ->
      app.gameCounter += 1

      # Move/spawn stuff
      app.rounds.update()
      @movePlayer()
      app.monsters.moveAll()
      app.bullets.moveAll()

      # Detect/validate
      @collisionDetection()

      # Render
      @render()

    initialize: ->
      canvas = ($('#gameCanvas')[0])
      canvas.width = app.constants.canvasX
      canvas.height = app.constants.canvasY
      app.playerModel = new app.PlayerModel {x: 0, y:  0, fallSpeed: 1, direction: "RIGHT"}
      app.playerView = new app.PlayerView { model: app.playerModel }  
      app.bullets = new app.Bullets
      app.monsters = new app.Monsters
      app.rounds = new app.Rounds

      @keyMap = {}

      app.gameTimer = setInterval @gameLoop.bind(@), 25


  app.distance = (modelA, modelB) ->
    Math.sqrt (Math.pow (modelA.get('x') - modelB.get('x')), 2) + (Math.pow (modelA.get('y') - modelB.get('y')), 2)

  app.score = 0
  app.gameCounter = 0
  app.gameView = new app.GameView 
  app.numberOfMonsters = 1
  app.bulletAudio = new Audio('audio/laser.wav')