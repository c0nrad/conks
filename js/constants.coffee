$(document).ready ->
  app = window || {}

  app.constants ?= {}
  app.constants = _.extend app.constants, 
    directions: ["LEFT", "RIGHT", "UP"]
    canvasXBlock: 45
    canvasYBlock: 20

    canvasX: $(document).width() - 30

  app.constants = _.extend app.constants, 
    canvasY: app.constants.canvasX * app.constants.canvasYBlock / app.constants.canvasXBlock
    directions: ["LEFT", "RIGHT", "UP"]
