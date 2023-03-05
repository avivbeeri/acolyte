import "graphics" for Canvas, Color
import "input" for Keyboard, Mouse, InputGroup
import "math" for Vec
import "parcel" for
  TextInputReader,
  TextUtils,
   DIR_EIGHT,
  Scene,
  World,
  Entity,
  TileMap8,
  Tile,
  Zone,
  Line,
  TurnEvent,
  Palette

import "./entities" for Player
import "./actions" for SimpleMoveAction
import "./systems" for VisionSystem


class GameScene is Scene {
  construct new(args) {
    super(args)
    _t = 0
    _kb = TextInputReader.new()

    _inputs = [
      InputGroup.new([ Keyboard["up"], Keyboard["k"], Keyboard["keypad 8"], Keyboard["8"]]),
      InputGroup.new([ Keyboard["right"], Keyboard["l"], Keyboard["keypad 6"], Keyboard["6"] ]),
      InputGroup.new([ Keyboard["down"], Keyboard["j"], Keyboard["keypad 2"], Keyboard["2"] ]),
      InputGroup.new([ Keyboard["left"], Keyboard["h"], Keyboard["keypad 4"] , Keyboard["4"]]),
      InputGroup.new([ Keyboard["y"], Keyboard["keypad 7"], Keyboard["7"] ]),
      InputGroup.new([ Keyboard["u"], Keyboard["keypad 9"], Keyboard["9"] ]),
      InputGroup.new([ Keyboard["n"], Keyboard["keypad 3"], Keyboard["3"] ]),
      InputGroup.new([ Keyboard["b"], Keyboard["keypad 1"], Keyboard["1"] ])
    ]

//  TODO: Outsource to a generator
    var map = _map = TileMap8.new()
    for (y in 0...32) {
      for (x in 0...32) {
        map[x,y] = Tile.new({
          "solid": false
        })
      }
    }
    map[12, 16]["solid"] = true
    map[13, 17]["solid"] = true
    for (point in Line.walk(Vec.new(4,19), Vec.new(17,19))) {
        map[point]["solid"] = true
    }
    for (point in Line.walk(Vec.new(4,21), Vec.new(17,21))) {
        map[point]["solid"] = true
    }

    var world = _world = World.new()
    _world.systems.add(VisionSystem.new())
    world.addZone(Zone.new(map))
    world.addEntity("player", Player.new())
    world.addEntity(Entity.new())
    _name = ""

    world.start()
  }

  update() {
    super.update()
    if (_kb.enabled) {
      _t = _t + 1
      _kb.update()
      _text = _kb.text || ""
      if (Keyboard["return"].justPressed) {
        _kb.disable()
        _name = _kb.text
      }
      if (Keyboard["escape"].justPressed) {
        _kb.disable()
      }
      return
    }
    var player = _world.getEntityByTag("player")
    var i = 0
    for (input in _inputs) {
      if (input.firing) {
        player.pushAction(SimpleMoveAction.new(DIR_EIGHT[i]))
      }
      i = i + 1
    }

    if (Keyboard["return"].justPressed) {
      _kb.clear()
      _kb.enable()
    }

    _world.advance()
    for (event in _world.events) {
      if (event is TurnEvent) {
        var t = event["turn"]
      }
    }
  }

  draw() {
    Canvas.cls()
    var player = _world.getEntityByTag("player")
    var map = _world.zone.map

    for (y in map.yRange) {
      for (x in map.xRange) {
        if (!map[x, y]["visible"]) {
          continue
        }
        var color = Color.white
        if (map[x, y]["visible"] == "maybe") {
          color = Color.darkgray
        }
        if (map[x, y]["seen"]) {
          color = Color.red
        }
        if (map[x, y]["void"]) {
        } else if (map[x, y]["solid"]) {
          Canvas.print("#", x * 16 + 4, y * 16 + 4, color)
        } else if (map[x, y]["cost"]) {
          Canvas.rectfill(x * 16, y*16, 16, 16, Color.darkgray)
          Canvas.print(map[x, y]["cost"], x * 16 + 4, y * 16 + 4, color)

        } else {
          Canvas.print(".", x * 16 + 4, y * 16 + 4, color)
        }
      }
    }
    super.draw()
    if (player) {
      Canvas.print("@", player.pos.x * 16 + 4, player.pos.y * 16 + 4, Color.white)
    }

    Canvas.print(_name, 0, Canvas.height - 17, Color.white)
    if (_kb.enabled) {
      var x = _kb.pos * 8
      var y = Canvas.height - 10
      if ((_t / 30).floor % 2 == 0) {
        Canvas.rectfill(x, y, 8, 10, Color.white)
      }
      Canvas.print(_kb.text, 0, Canvas.height - 9, Color.white)
    }
  }
}
