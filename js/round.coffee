$(document).ready ->
  app = window || {}

  app.constants ?= {}
  app.constants = _.extend app.constants, 
    roundStates: ["intro", "wave", "outro", "exit"]
    roundCountersPerLetter: 4
    startRound: 0
    npcColor:
      Princess: "#FF5CCD"
      Thor: "#290014"
    ledgeColor: "#964B00"
    textColor: "#000000"
    textFont: "18px Arial"
    smallTextFont: "14px Arial"

    arrowLineWidth: 3
    
    groundColor: "#00FF00"

  app.RoundModel = Backbone.Model.extend
    defaults: ->
      currentWaveNumber: -1
      roundState: "intro"
      roundCounter: 0

    initialize: ->
      # Calculate the length of intro text

      if @get('isGameOver')
        @set('roundState', 'gameOver')
        return

      if !@get('introText')?
        @set('roundState', "wave")

      @set 'introLength', _.reduce @get('introText'), (acc, [name, text]) ->
        acc + text.length
      , 0

      @set 'outroLength', _.reduce @get('outroText'), (acc, [name, text]) ->
        acc + text.length
      , 0

    nextWave: ->
      waveNumber = @get('currentWaveNumber')
      numberOfMonstersPerWave = @get('numberOfMonstersPerWave')

      numberOfMonsters = numberOfMonstersPerWave[waveNumber]

      for x in [0..numberOfMonsters - 1]
        app.monsters.spawnMonster(@get('monsterColor'))

    update: ->
      @set('roundCounter', @get('roundCounter') + 1)

      switch @get('roundState')
        when "intro"
          if app.gameView.keyMap[13]
            @set('roundState', 'wave')
          if @get('roundCounter')  > @get('introLength') * app.constants.roundCountersPerLetter
            @set('roundState', 'wave')

        when "wave"
          if not app.monsters.allDead()
            return
          else
            @set('currentWaveNumber', @get('currentWaveNumber') + 1)

          if @get('currentWaveNumber') > @get('numberOfMonstersPerWave').length
            @set('roundState', 'outro')
            @set('roundCounter', 0)
            return 
          @nextWave()

        when "outro"
          if app.gameView.keyMap[13]
            @set('roundState', 'exit')
          if @get('roundCounter') > @get('outroLength') * app.constants.roundCountersPerLetter
            @set('roundState', "exit")

        when "exit"
          if app.playerModel.get('x') > app.constants.canvasX - app.constants.playerSizeX * 2
            app.playerModel.set('x', app.constants.playerSizeX * 2)
            @trigger "roundComplete"

    height: (x) ->
      if !@get('groundHeight')?
        return 0
      return @get('groundHeight')[x] || 0

  app.RoundView = Backbone.View.extend
    el: "#gameCanvas"

    initialize: ->
      _.bindAll @, "render"
      @model.view = @

    render: ->
      canvas = ($(@el)[0])
      ctx = canvas.getContext("2d")

      switch @model.get('roundState')
        when "intro"
          @renderCini ctx, 'introText', app.constants.npcColor[@model.get('introNPC')]
        when "outro"
          @renderCini(ctx, 'outroText', app.constants.npcColor[@model.get('outroNPC')])
        when "exit"
          @drawArrow(ctx, app.constants.canvasX - 300, app.constants.canvasY / 3)
          @drawArrow(ctx, app.constants.canvasX - 300, 2 * app.constants.canvasY / 3)
        when "gameOver"
          @renderGameOver()

      @drawGround(ctx)
      @

    renderCini: (ctx, textType, npcColor) ->
      roundCountersLeft = @model.get('roundCounter')
      for [name, text] in @model.get(textType)
        if roundCountersLeft == 0
          break
        else if roundCountersLeft > text.length * app.constants.roundCountersPerLetter
          roundCountersLeft -= text.length * app.constants.roundCountersPerLetter
          continue
        else
          displayText = text[0..roundCountersLeft / app.constants.roundCountersPerLetter]
          roundCountersLeft = 0

          if name == "Blocky"
            [x,y] = [app.playerModel.get('x') - 30, app.playerModel.get('y') - 10]
          else
            [x, y] = [app.constants.canvasX - 400, 230]
          ctx.fillStyle = app.constants.textColor
          ctx.font = app.constants.textFont
          ctx.fillText displayText, x, y

      @renderLedge(npcColor)
      @renderSkipText()

    drawGround: (ctx) ->
      for x in [0..app.constants.canvasXBlock-1]
        height = @model.height(x)
        for y in [0..height]
          @fillBlock(ctx, x, app.constants.canvasYBlock - y)

    fillBlock: (ctx, x, y) ->
      ctx.fillStyle = app.constants.groundColor
      width = height = app.constants.playerSizeX - 2
      [x, y] = [x * app.constants.playerSizeX - 1, y * app.constants.playerSizeY - 1]

      ctx.fillRect x, y, width, height

    drawArrow: (ctx, startX, startY) ->
      lineWidth = ctx.lineWidth
      ctx.lineWidth = app.constants.arrowLineWidth
      ctx.beginPath()
      ctx.moveTo(startX, startY)
      ctx.lineTo(startX + 150, startY)
      ctx.lineTo(startX + 120, startY + 30)
      ctx.moveTo(startX + 150, startY)
      ctx.lineTo(startX + 120, startY - 30)
      ctx.stroke()
      ctx.lineWidth = lineWidth

    renderSkipText: () ->
      canvas = ($(@el)[0])
      ctx = canvas.getContext("2d")
      ctx.fillStyle = app.constants.textColor
      ctx.font = app.constants.textFont
      ctx.fillText "Press [Enter] to Skip Cinema", 10, 20

    renderLedge: (npcColor) ->
      canvas = ($(@el)[0])
      ctx = canvas.getContext("2d")

      ctx.fillStyle = app.constants.ledgeColor
      ctx.fillRect(app.constants.canvasX - 300, 300, 300, 50)

      ctx.fillStyle = npcColor
      ctx.fillRect(app.constants.canvasX - 280, 248, app.constants.playerSizeX, app.constants.playerSizeY)

    renderGameOver: ->
      canvas = ($(@el)[0])
      ctx = canvas.getContext("2d")
      ctx.fillStyle = app.constants.textColor

      ctx.font = app.constants.textFont
      ctx.fillText "You win!", app.constants.canvasX / 2, app.constants.canvasY / 2
      ctx.font == app.constants.smallTextFont
      ctx.fillText "Sort of...", app.constants.canvasX / 2, app.constants.canvasY / 2 + 50


  app.Rounds = Backbone.Collection.extend
    model: app.RoundModel

    update: ->
      if !@currentRound?
        @nextRound()

      @currentRound.update()

    initialize: ->
      @add [
        { 
          numberOfMonstersPerWave: [1,2,3] 
          introText: [
            ["Princess", "Save me Blocky! You're my only hope!  "]
            ["Blocky", "/wink, hey babe.  "]
            ["Princess", "Omg gross. Just save me alright.  "]
          ]
          introNPC: "Princess"
          groundHeight: [0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0]
          bgImageSrc: "img/background1.png"
        }
        { 
          numberOfMonstersPerWave: [3,4,6] 
          introText: [
            ["Thor", "Don't get cocky son.   "]
            ["Blocky", "Who the hell are you?   "]
            ["Thor", "I am Thor. Creator of death...   "]
            ["Blocky", "/cough loser  "]
            ["Thor", "YOU WILL PAY FOR YOUR INSOLENCE!   "]
          ]
          introNPC: "Thor"
          groundHeight: [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,2,2,2,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0]
          bgImageSrc: "img/background2.png"
        }
        { 
          numberOfMonstersPerWave: [5,7,9,11]
          introText: [
            ["Blocky", "DAMN GIRL, THOSE PANTS ARE TIGHT.   "]
            ["Princess", "fml... Watch out! More minions!   "]
          ]
          introNPC: "Princess"
          groundHeight: [0,0,1,2,3,4,5,6,7,8,9,10,9,8,7,6,5,5,5,5,5,5,5,5,5,5,5,5,5,6,7,8,9,10,9,8,7,6,5,4,3,2,1,0,0]
          bgImageSrc: "img/background3.png"
        }
        { 
          bgImageSrc: "img/background4.png"
          numberOfMonstersPerWave: [10, 10, 15] 
          introText: [
            ["Thor", "My my, you're doing better than I thought   "]
            ["Blocky", "LIKE A BOSS  "]
            ["Thor", "Such cockiness, it's going to get you killed.   "]
            ["Blocky", "Thor, have you heard the lore, of your mother, the whore?   "]
            ["Thor", "ENOUGH. This madness has gone on long enough!   "]
          ]
          introNPC: "Thor"
          groundHeight: [0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,15,15,15,15,15,15,15,15,15,15,15,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0,0]
        
          outroNPC: "Princess"
          outroText: [
            ["Princess", "Maybe I was a little mean to you...   "]
            ["Blocky", "Babe, it coo  "]
            ["Princess", "Rescue me, and I have a little surprise for you :)   "]
            ["Blocky", "aww yeah  "]
            ["Princess", "Careful. He's in the next room   "]
          ]
        }
        {
          bgImageSrc: "img/background5.png"
          monsterColor: app.constants.npcColor['Thor']
          numberOfMonstersPerWave: [1] 
          introNPC: "Thor"
          introText: [
            ["Thor", "Well well well, look what the cat dragged in.  "]
            ["Blocky", "The finest piece of ass?   "]
            ["Thor", "Are you implying that you're... nvm, anyways...   "]
            ["Blocky", ""]
            ["Thor", "Prepare to die! Mwahahaha"]
          ]

          outroNPC: "Thor"
          outroText: [
            ["Thor", "Nooooo, rainbow bullets, my only weakness.   "] 
            ["BLocky", ""]
            ["Thor", "How did you know?   "]
          ]
        }
        { 
          numberOfMonstersPerWave: [] 

          bgImageSrc: "img/background6.png"
          introNPC: "Princess"
          introText: [
            ["Princess", "You saved me?! You did it!"]
            ["Blocky", "So about that \"Special Surprise\"... /wink   "]
            ["Princess", "LULLERBLADES, let's get real...    "]
            ["Blocky", ":(   "]
          ]
        }
        { 
          isGameOver: true
        }
      ]

      @roundNumber = 0
      if app.constants.startRound > 0
        for x in [0..app.constants.startRound]
          @shift()
          @roundNumber += 1

    nextRound: ->
      if ! @isEmpty()
        @roundNumber += 1
        @currentRound = @shift()
        @loadImage()
        @listenTo @currentRound, 'roundComplete', @nextRound
        @currentView = new app.RoundView { model: @currentRound }

    loadImage: ->
      if @currentRound.get('bgImageSrc')
        image = new Image()
        image.src = @currentRound.get('bgImageSrc')
        @currentRound.set('bgImage', image)

    getRoundNumber: ->
      @roundNumber

    getWaveNumber: ->
      @currentRound.get('currentWaveNumber')

    getBackground: ->
      @currentRound.get('bgImage')

    render: ->
      @currentView.render()

    height: (x) ->
      if !@currentRound?
        return 0
      @currentRound.height(x)
