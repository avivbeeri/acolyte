import "graphics" for Color, Canvas
import "parcel" for
  Element,
  Palette

var DEBUG = false

import "./palette" for INK

class LogViewer is Element {
  construct new(pos, log) {
    super()
    _pos = pos
    _messageLog = log
    _max = 5
    _invert = (_pos.y + _max * 12) > (Canvas.height / 2)
    System.print(_invert)
  }

  update() {
    _world = parent.world
    _messages = _messageLog.history(_max)
  }

  draw() {
    var offset = Canvas.offset
    Canvas.offset(_pos.x,_pos.y)

    var dir = 1
    var start = 0

    var startLine = 0
    var endLine = _messages.count

    if (_invert) {
      var swap = endLine - 1
      endLine = startLine
      startLine = swap

      start = _max * 12
      dir = -1
    }
    var line = 0
    for (i in startLine...endLine) {
      var message = _messages[i]
      line = i
      if (message.count > 1) {
        Canvas.print("%(message.text) (x%(message.count))", 4, start + dir * 12 * line, message.color)
      } else {
        Canvas.print("%(message.text)", 4, start + dir * 12 * line, message.color)
      }
    }

    Canvas.offset(offset.x, offset.y)
  }
}

class HealthBar is Element {
  construct new(pos, entity) {
    super()
    _pos = pos
    _entity = entity
  }

  update() {
    _world = parent.world
  }

  draw() {
    var offset = Canvas.offset
    Canvas.offset(_pos.x,_pos.y)
    var stats = _world.getEntityById(_entity)["stats"]
    var hp = stats.get("hp")
    var hpMax = stats.get("hpMax")
    var width = 10
    var current = hp / hpMax * width

    Canvas.rectfill(0, 0, width * 16, 16, INK["barEmpty"])
    Canvas.rectfill(0, 0, current * 16, 16, INK["barFilled"])
    Canvas.print("HP: %(hp) / %(hpMax)", 4, 4, INK["barText"])

    Canvas.offset(offset.x, offset.y)
  }
}

class AsciiRenderer is Element {
  construct new(pos) {
    super()
    _pos = pos
  }

  update() {
    _world = parent.world
  }

  draw() {
    var offset = Canvas.offset
    Canvas.offset(_pos.x,_pos.y)
    var map = _world.zone.map

    for (y in map.yRange) {
      for (x in map.xRange) {
        if (!map[x, y]["visible"]) {
          continue
        }
        var color = INK["wall"]
        if (map[x, y]["visible"] == "maybe") {
          color = INK["obscured"]
        }
        if (DEBUG) {
          if (map[x, y]["seen"]) {
            color = Color.red
          }
          if (map[x, y]["cost"]) {
            Canvas.rectfill(x * 16, y*16, 16, 16, INK["burgandy"])
            Canvas.print(map[x, y]["cost"], x * 16 + 4, y * 16 + 4, color)
          }
        }
        if (map[x, y]["void"]) {
        } else if (map[x, y]["solid"]) {
          Canvas.print("#", x * 16 + 4, y * 16 + 4, color)
        } else {
          Canvas.print(".", x * 16 + 4, y * 16 + 4, color)
        }
      }
    }

    for (entity in _world.entities()) {
      if (!entity.pos) {
        continue
      }
      if (map[entity.pos]["visible"] != true) {
        continue
      }

      var symbol = entity["symbol"] || entity.name && entity.name[0] || "?"
      Canvas.print(symbol, entity.pos.x * 16 + 4, entity.pos.y * 16 + 4, Color.white)
    }

    Canvas.offset(offset.x, offset.y)
  }

}
