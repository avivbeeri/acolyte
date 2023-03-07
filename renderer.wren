import "graphics" for Color, Canvas
import "math" for Vec
import "input" for Mouse
import "./parcel" for
  Element,
  Event,
  Entity,
  Palette
import "./palette" for INK
import "./items" for Item

import "./inputs" for SCROLL_UP, SCROLL_DOWN, SCROLL_BEGIN, SCROLL_END


var DEBUG = false

class HoverText is Element {
  construct new(pos) {
    super()
    _pos = pos
    _align = "right"
    _text = ""
  }

  update() {
    _world = parent.world
  }

  process(event) {
    if (event is HoverEvent) {
      if (event.target && event.target is Entity) {
        _text = event.target.name
      } else if (event.target is Item) {
        _text = event.target.name
      } else if (event.target is String) {
        _text = event.target
      } else {
        _text = ""
      }
    }
    super.process(event)
  }

  draw() {
    var offset = Canvas.offset
    Canvas.offset(_pos.x,_pos.y)

    var start = 0
    if (_align == "right") {
      start = - (_text.count * 8)
    }
    if (_text) {
      Canvas.print(_text, start, 0, INK["text"])
    }

    Canvas.offset(offset.x, offset.y)
  }
}

class ScrollEvent is Event {
  construct new(start) {
    super()
    _start = start
  }
  start { _start }
}

class HistoryViewer is Element {
  construct new(pos, size, log) {
    super()
    _pos = pos
    _size = size
    _scroll = 0
    _log = log
    _height = (size.y / 12).floor
    _viewer = addElement(LogViewer.new(pos + Vec.new(4, 4), log, _height))
    _viewer.full = true
  }

  update() {
    if (SCROLL_BEGIN.firing) {
      _scroll = 0
    }
    if (SCROLL_END.firing) {
      _scroll = _log.count - 1
    }
    if (SCROLL_UP.firing) {
      _scroll = _scroll - 1
    }
    if (SCROLL_DOWN.firing) {
      _scroll = _scroll + 1
    }
    _scroll = _scroll.clamp(0, _log.count - _height)
    _viewer.start = _scroll
    super.update()
    _scroll = _viewer.start
  }
  draw() {
    Canvas.rectfill(_pos.x, _pos.y, _size.x, _size.y, INK["bg"])
    Canvas.rect(_pos.x, _pos.y, _size.x, _size.y, INK["border"])
    super.draw()
  }
}

class LineViewer is Element {
  construct new(pos, log, size, lines) {
    super()
    _pos = pos
    _messageLog = log
    _max = size
    _lines = lines
  }

  draw() {
    var offset = Canvas.offset
    Canvas.offset(_pos.x,_pos.y)

    var dir = 1
    var start = 0

    var startLine = 0
    var endLine = _lines.count

    var line = 0
    var width = Canvas.width
    var glyphWidth = 8
    var lineHeight = 12
    for (i in startLine...endLine) {
      var text = _lines[i]
      var x = 0
      var words = text.split(" ")
      for (word in words) {
        if (width - x * glyphWidth < word.count * glyphWidth) {
          x = 0
          line = line + 1
        }
        var y = start + dir * lineHeight * line
        if (y >= 0 && y + lineHeight <= Canvas.height) {
          Canvas.print(word, x * glyphWidth, start + dir * lineHeight * line, INK["text"])
        } else {
          break
        }
        x = x + (word.count + 1)
      }

      line = line + 1
      x = 0
    }

    Canvas.offset(offset.x, offset.y)
  }
}
class LogViewer is Element {
  construct new(pos, log) {
    super()
    init(pos, log, 5)
  }
  construct new(pos, log, size) {
    super()
    init(pos, log, size)
  }

  init(pos, log, size)  {
    _full = false
    _pos = pos
    _messageLog = log
    _max = size
    _start = 0
    _messages = _messageLog.previous(_max) || []
  }

  start { _start }
  start=(v) { _start = v }
  full=(v) { _full = v }
  full { _full }

  update() {
    _start = _start.clamp(0, _messageLog.count - _max)
    if (_messageLog.count < _max) {
      _start = 0
    }
    if (_full) {
      _messages = _messageLog.history(_start, _max) || []
    } else {
      _messages = _messageLog.previous(_max) || []
    }
  }

  draw() {
    var offset = Canvas.offset
    Canvas.offset(_pos.x,_pos.y)

    var dir = 1
    var start = 0

    var startLine = 0
    var endLine = _messages.count

    var line = 0
    var width = Canvas.width
    var glyphWidth = 8
    var lineHeight = 12
    for (i in startLine...endLine) {
      var message = _messages[i]
      var x = 0
      var text = message.text
      if (message.count > 1) {
        text = "%(text) (x%(message.count))"
      }
      var words = text.split(" ")
      for (word in words) {
        if (width - x * glyphWidth < word.count * glyphWidth) {
          x = 0
          line = line + 1
        }
        var y = start + dir * lineHeight * line
        if (y >= 0 && y + lineHeight <= Canvas.height) {
          Canvas.print(word, x * glyphWidth, start + dir * lineHeight * line, message.color)
        } else {
          break
        }
        x = x + (word.count + 1)
      }

      line = line + 1
      x = 0
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

class HoverEvent is Event {
  construct new(target) {
    super()
    _src = target
  }
  target { _src }
}

class AsciiRenderer is Element {
  construct new(pos) {
    super()
    _pos = pos
  }

  update() {
    _world = parent.world
    var hover = (Mouse.pos - _pos) / 16
    hover.x = hover.x.floor
    hover.y = hover.y.floor
    var found = false
    var tile = _world.zone.map[hover]
    if (tile["visible"] == true) {
      for (entity in _world.entities()) {
        if (entity.pos == null) {
          continue
        }
        if (hover == entity.pos) {
          found = true
          top.process(HoverEvent.new(entity))
        }
      }
      if (!found && tile["items"] && !tile["items"].isEmpty) {
        found = true
        var itemId = tile["items"][0].id
        var item = _world["items"][itemId]
        top.process(HoverEvent.new(item))
      }
    }
    if (!found) {
      top.process(HoverEvent.new(null))
    }
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
          var items = map[x, y]["items"]
          if (items && items.count > 0) {
            if (items[0].id == "potion") {
              Canvas.print("!", x * 16 + 4, y * 16 + 4, INK["treasure"])
            }
          } else {
            Canvas.print(".", x * 16 + 4, y * 16 + 4, color)
          }
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
