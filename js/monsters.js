// Generated by CoffeeScript 1.6.3
(function() {
  $(document).ready(function() {
    var app;
    app = window || {};
    if (app.constants == null) {
      app.constants = {};
    }
    app.constants = _.extend(app.constants, {
      monsterSizeX: app.constants.playerSizeX,
      monsterSizeY: app.constants.playerSizeY,
      monsterFillStyle: "#FF0000",
      monsterDeltaX: app.constants.playerDeltaX / 2.5,
      monsterFallSpeed: app.constants.playerFallSpeed / 2,
      monsterFallMultipler: app.constants.playerFallMultipler + .05
    });
    app.MonsterModel = Backbone.Model.extend({
      initialize: function() {
        return this.on('change', this.validatePos);
      },
      move: function() {
        if (this.get('direction') === "RIGHT") {
          return this.set('x', this.get('x') + app.constants.monsterDeltaX);
        } else if (this.get('direction') === "LEFT") {
          return this.set('x', this.get('x') - app.constants.monsterDeltaX);
        }
      },
      validatePos: function() {
        var floorHeight;
        if (this.get('x') > app.constants.canvasX) {
          this.set('x', 0);
        } else if (this.get('x') < 0) {
          this.set('x', app.constants.canvasX);
        }
        floorHeight = _.max(_.map(this.blockX(), function(corner) {
          return app.rounds.height(corner) * app.constants.playerSizeX;
        }));
        if (this.get('y') > app.constants.canvasY - app.constants.monsterSizeY - floorHeight) {
          return this.set('y', app.constants.canvasY - app.constants.monsterSizeY - floorHeight);
        }
      },
      fall: function() {
        var floorHeight;
        floorHeight = _.max(_.map(this.blockX(), function(corner) {
          return app.rounds.height(corner) * app.constants.playerSizeX;
        }));
        if (this.get('y') !== app.constants.canvasY - app.constants.monsterSizeY - floorHeight) {
          this.set('y', this.get('y') + this.get('fallSpeed'));
          return this.set('fallSpeed', app.constants.monsterFallMultipler * this.get('fallSpeed'));
        } else {
          return this.set('fallSpeed', app.constants.monsterFallSpeed);
        }
      },
      radius: function() {
        return app.constants.monsterSizeY / 2;
      },
      blockX: function() {
        return [Math.floor((this.get('x') + 1) / app.constants.playerSizeX), Math.floor((this.get('x') + app.constants.playerSizeX - 1) / app.constants.playerSizeX)];
      }
    });
    app.MonsterView = Backbone.View.extend({
      el: "#gameCanvas",
      initialize: function() {
        _.bindAll(this, "render");
        return this.model.view = this;
      },
      render: function(ctx) {
        var canvas;
        if (this.model.get('active')) {
          canvas = ($(this.el)[0]);
          ctx = canvas.getContext("2d");
          ctx.fillStyle = app.constants.monsterFillStyle;
          if (this.model.get('color')) {
            ctx.fillStyle = this.model.get('color');
          }
          return ctx.fillRect(this.model.get('x'), this.model.get('y'), app.constants.monsterSizeX, app.constants.monsterSizeY);
        }
      }
    });
    return app.Monsters = Backbone.Collection.extend({
      model: app.MonsterView,
      renderAll: function() {
        return this.forEach(function(monster) {
          if (monster.get('active')) {
            return monster.view.render();
          }
        });
      },
      moveAll: function() {
        return this.forEach(function(monster) {
          if (monster.get('active')) {
            monster.move();
            return monster.fall();
          }
        });
      },
      allDead: function() {
        return this.all(function(monster) {
          return !monster.get('active');
        });
      },
      spawnMonster: function(color) {
        var direction, monster, monsterView, startX;
        startX = Math.floor((Math.random() * app.constants.canvasX) + 1);
        direction = Math.floor(Math.random() * 2);
        monster = new app.MonsterModel({
          x: startX,
          y: 0,
          fallSpeed: 1,
          direction: app.constants.directions[direction],
          active: true
        });
        if (color) {
          monster.set('color', color);
        }
        monsterView = new app.MonsterView({
          model: monster
        });
        return this.add(monster);
      },
      alive: function() {
        return this.filter(function(monster) {
          return monster.get('active');
        }).length;
      }
    });
  });

}).call(this);
