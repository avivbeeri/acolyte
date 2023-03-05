import "graphics" for Color, Canvas
import "parcel" for
  Element,
  Palette

var DEBUG = false

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
        var color = Color.white
        if (map[x, y]["visible"] == "maybe") {
          color = Color.darkgray
        }
        if (DEBUG) {
          if (map[x, y]["seen"]) {
            color = Color.red
          }
          if (map[x, y]["cost"]) {
            Canvas.rectfill(x * 16, y*16, 16, 16, Color.darkgray)
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
