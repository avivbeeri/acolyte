import "graphics" for Color, Canvas, SpriteSheet, ImageData
import "math" for Vec
import "input" for Mouse
import "messages" for Pronoun
import "./parcel" for
  Config,
  Scheduler,
  Element,
  Event,
  Entity,
  ChangeZoneEvent,
  Palette
import "./palette" for INK
import "./items" for Item, EquipmentSlot
import "./ui" for
  Animation,
  HoverEvent,
  TargetEvent,
  TargetBeginEvent,
  TargetEndEvent
import "events" for Events

import "./inputs" for VI_SCHEME as INPUT
import "./entities" for Player, Demon
import "./text" for TextSplitter

var DEBUG = false

class HintText is Element {
  construct new(pos) {
    super()
    _pos = pos
    _text = "press '/' for help"
    _t = 0
  }
  construct new(pos, message) {
    _pos = pos
    _text = message
    _t = 0
  }

  update() {
    _t = _t + 1
    if (_t > 10 * 60) {
      removeSelf()
    }
  }

  process(event) {
    if (event is ChangeZoneEvent && event.floor > 0) {
      removeSelf()
    }
    super.process(event)
  }

  draw() {
    var offset = Canvas.offset
    Canvas.offset(_pos.x,_pos.y)

    var left = -(_text.count * 4)

    if (_text) {
      Canvas.print(_text, left, 0, INK["text"])
    }

    Canvas.offset(offset.x, offset.y)
  }
}
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
        if (event.target is Player) {
          _text = TextSplitter.capitalize(Pronoun.you.subject)
        }
        if (event.target["killed"]) {
          _text = "Body of %(event.target.name)"
        }
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

class Pane is Element {
  construct new() {
    super()
    _pos = Vec.new()
    _size = Vec.new()
  }
  construct new(pos, size) {
    super()
    _pos = pos
    _size = size
  }

  content() {}
  size { _size }
  size=(v) {
    _size = v
  }
  pos { _pos }
  pos=(v) {
    _pos = v
  }

  draw() {
    var border = 4
    var offset = Canvas.offset
    Canvas.offset(_pos.x,_pos.y)

    Canvas.rectfill(0, 0, _size.x, _size.y, INK["bg"])
    for (i in 1..border) {
      Canvas.rect(-i, -i, _size.x + 2 * i, _size.y + 2 * i, INK["border"])
    }
    content()
    super.draw()
    Canvas.offset(offset.x, offset.y)
  }
}

class Dialog is Pane {
  construct new(message) {
    super()
    _center = true
    _height = 10
    setMessage(message)
  }

  center=(v) { _center = v }
  center { _center }

  setMessage(message) {
    if (!(message is List)) {
      message = [ message ]
    }
    var width = TextSplitter.getWidth(message)
    var maxWidth = ((Canvas.width / 2)).ceil
    _message = TextSplitter.split(message, maxWidth)
    size = Vec.new(((width + 4) * 8).min(maxWidth), (2 + _message.count) * _height)
    pos = (Vec.new(Canvas.width, Canvas.height) - size) / 2
  }

  content() {
    for (i in 0..._message.count) {
      var x = _center ? (size.x - (_message[i].count * 8)) / 2: 8
      Canvas.print(_message[i], x, ((size.y - _message.count * _height) / 2) + i * _height, INK["gameover"])
    }
  }
}

class CharacterViewer is Element {
  construct new(pos, size) {
    super()
    _pos = pos
    _size = size
    _height = (size.y / 10).floor
    _lines = null
    _width = size.x
    _viewer = addElement(LineViewer.new(pos + Vec.new(8, 8), _size, _height, _lines))
  }

  update() {
    super.update()
    _world = parent.world
    if (!_lines) {
      var player = _world.getEntityByTag("player")
      _lines = []
      _lines.add("--- Character Information ---")
      _lines.add("")
      _lines.add("Name: %(player.name)")
      var hp = player["stats"]["hp"]
      var hpMax = player["stats"]["hpMax"]
      _lines.add("HP: %(hp)/%(hpMax)")
      _lines.add("")
      if (!player["oaths"].isEmpty) {
        _lines.add("Oaths Sworn:")
        for (oath in player["oaths"]) {
          _lines.add("  %(TextSplitter.capitalize(oath.name))")
        }
      }
      if (!player["brokenOaths"].isEmpty) {
        _lines.add("Oaths Broken:")
        for (oath in player["brokenOaths"]) {
          _lines.add("  %(TextSplitter.capitalize(oath.name))")
        }
      }
      if (!player["oaths"].isEmpty || !player["brokenOaths"].isEmpty) {
        _lines.add("")
      }


      var str = player["stats"]["str"] + 10
      var dex = player["stats"]["dex"] + 10
      var atk = TextSplitter.leftPad(player["stats"]["atk"], 2)
      var def = TextSplitter.leftPad(player["stats"]["def"], 2)
      _lines.add("Strength: %(str)   Dexterity: %(dex)")
      _lines.add("Attack:   %(atk)   Defence:   %(def)")

      _lines.add("")
      _lines.add("Conditions:")
      if (!player["conditions"].isEmpty) {
        for (condition in player["conditions"].keys) {
          _lines.add("  %(condition)")
        }
      } else {
        _lines.add("  None")
      }

      _width = (LineViewer.getWidth(_lines) + 2) * 8
      _height = (_lines.count + 2) * 10
      _size.x = _width
      _size.y = _height

      _viewer.lines = _lines
    }
  }
  draw() {
    var offset = Canvas.offset
    Canvas.offset(_pos.x,_pos.y)

    Canvas.rectfill(0, 0, _size.x, _size.y, INK["bg"])
    Canvas.rect(0, 0, _size.x, _size.y, INK["border"])

    Canvas.offset(offset.x, offset.y)
    super.draw()
  }
}
class HistoryViewer is Element {
  construct new(pos, size, log) {
    super()
    _pos = pos
    _size = size
    _scroll = 0
    _log = log
    _height = (size.y / 10).floor
    _viewer = addElement(LogViewer.new(pos + Vec.new(4, 4), log, _height))
    _viewer.full = true
  }

  update() {
    /*
    if (SCROLL_BEGIN.firing) {
      _scroll = 0
    }
    if (SCROLL_END.firing) {
      _scroll = _log.count - 1
    }
    */
    if (INPUT["scrollUp"].firing) {
      _scroll = _scroll - 1
    }
    if (INPUT["scrollDown"].firing) {
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
    _lines = lines || []
  }
  lines=(v) { _lines = v }
  lines { _lines }

  static getWidth(lines) {
    var max = 0
    for (line in lines) {
      if (line.count > max) {
        max = line.count
      }
    }
    return max
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
    var lineHeight = 10
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
    var lineHeight = 10
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

class Cursor is Element {
  construct new(pos, cursor, range) {
    super()
    _pos = pos
    _cursor = cursor
    _range = range
  }

  process(event) {
    if (event is TargetEvent) {
      _cursor = event.pos
    } else if (event is TargetEndEvent) {
      removeSelf()
    }
  }

  draw() {
    var offset = Canvas.offset
    Canvas.offset(_pos.x,_pos.y)

    var dist = _range - 1
    for (dy in (-dist)..(dist)) {
      for (dx in (-dist)..(dist)) {
        var x = (_cursor.x + dx) * 16
        var y = (_cursor.y + dy) * 16
        if (dx == dy && dx == 0) {
          Canvas.rectfill(x, y, 16, 16, INK["targetCursor"])
          continue
        }
        Canvas.rectfill(x, y, 16, 16, INK["targetArea"])
      }
    }

    Canvas.offset(offset.x, offset.y)
  }

}

class Gauge is Element {
  construct new(pos, label, value, maxValue, segments) {
    super()
    _pos = pos
    _label = label
    _segments = segments
    _value = value
    _maxValue = maxValue
    _targetValue = value
    _changing = false
  }

  animateValues(value, maxValue) {
    _maxValue = maxValue
    _targetValue = value
    if (_targetValue != _value && !_changing) {
      _changing = true
      Scheduler.defer {
        var t = 0
        var start = _value
        var target = _targetValue
        var diff = target - start

        while ((target - _value).abs > 0.1) {
          _value = start + diff * Animation.ease(t / 15)
          t = t + 1
          Fiber.yield()
        }
        _value = target
        _changing = false
        // If value changed during fiber defer, recurse
        if (_value != _targetValue) {
          animateValues(_targetValue, maxValue)
        }
      }
    }
  }

  value { _targetValue }
  value=(v) {
    _targetValue = v
    _value = v
  }
  maxValue { _maxValue }
  maxValue=(v) { _maxValue = v }

  update() {
    super.update()
  }

  draw() {
    var offset = Canvas.offset
    Canvas.offset(_pos.x,_pos.y)
    var width = _segments
    var current = _value / _maxValue * width

    Canvas.rectfill(0, 2, width * 16, 12, INK["barEmpty"])
    Canvas.rectfill(0, 2, current * 16, 12, INK["barFilled"])
    Canvas.print("%(_label): %(_targetValue) / %(_maxValue)", 4, 4, INK["barText"])

    Canvas.offset(offset.x, offset.y)
  }
}
class PietyBar is Element {
  construct new(pos, entity) {
    super()
    _pos = pos
    _entity = entity
    _gauge = addElement(Gauge.new(_pos, "Piety", 4, 5, 7))
  }

  update() {
    super.update()
    _world = parent.world
    var stats = _world.getEntityById(_entity)["stats"]
    var piety = stats.get("piety")
    var pietyMax = stats.get("pietyMax")
    _gauge.value = piety
    _gauge.maxValue = pietyMax
  }

  draw() {
    super.draw()
  }
}
class HealthBar is Element {
  construct new(pos, entity) {
    super()
    _pos = pos
    _entity = entity
    _gauge = addElement(Gauge.new(_pos, "HP", 5, 5, 10))
  }

  process(event) {
    if (event is Events.attack && event.target.id == _entity.id) {
      updateValue()
    }
    if (event is Events.heal && event.target.id == _entity.id) {
      updateValue()
    }
  }

  updateValue() {
    var stats = _world.getEntityById(_entity)["stats"]
    var hp = stats.get("hp")
    var hpMax = stats.get("hpMax")
    _gauge.animateValues(hp, hpMax)
  }

  update() {
    super.update()
    if (!_world) {
      _world = parent.world
      var stats = _world.getEntityById(_entity)["stats"]
      var hp = stats.get("hp")
      var hpMax = stats.get("hpMax")
      _gauge.maxValue = hpMax
      _gauge.value = hp
    }
  }

  draw() {
    var offset = Canvas.offset
    Canvas.offset(_pos.x,_pos.y)
    super.draw()

    var floor = _world.zoneIndex + 1
    Canvas.print("Floor: %(floor)", (10 + 1) * 16, 4, INK["barText"])

    Canvas.offset(offset.x, offset.y)
  }
}

class Renderer is Element {
  construct new(pos) {
    super()
    _renderers = [
      AsciiRenderer.new(pos),
      TileRenderer.new(pos)
    ]
    _index = Config["tiles"] ? 1 : 0
  }
  parent=(v) {
    for (renderer in _renderers) {
      renderer.parent = v
    }
  }
  next() {
    _index = (_index + 1) % _renderers.count
  }
  update() {
    _renderers[_index].update()
  }
  process(event) {
    _renderers[_index].process(event)
  }
  draw() {
    _renderers[_index].draw()
  }


}
class AsciiRenderer is Element {
  construct new(pos) {
    super()
    _pos = pos
    _bg = INK["bg"] * 1
    _bg.a = 128
  }
  process(event) {
    if (event is TargetBeginEvent) {
      addElement(Cursor.new(_pos, event.pos, event.range))
    }
    super.process(event)
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
    }
    if (!found && tile["visible"]) {
      if (!found && tile["items"] && !tile["items"].isEmpty) {
        found = true
        var itemId = tile["items"][0].id
        var item = _world["items"][itemId]
        top.process(HoverEvent.new(item))
      }
      if (!found && tile["statue"]) {
        found = true
        top.process(HoverEvent.new("Statue"))
      }
      if (!found && tile["altar"]) {
        found = true
        top.process(HoverEvent.new("Altar"))
      }
      if (!found && tile["stairs"]) {
        found = true
        top.process(HoverEvent.new(tile["stairs"] == "down" ? "Stairs Down" : "Stairs Up"))
      }
      if (!found && tile["blood"]) {
        found = true
        top.process(HoverEvent.new("Pool of blood"))
      }
    }
    if (!found) {
      top.process(HoverEvent.new(null))
    }
  }

  world { _world }
  pos { _pos }

  draw() {
    var offset = Canvas.offset
    Canvas.offset(_pos.x,_pos.y)
    var map = _world.zone.map
    super.draw()
    var player = _world.getEntityByTag("player")

    for (y in map.yRange) {
      for (x in map.xRange) {
        if (!map[x, y]["visible"]) {
          continue
        }
        var color = INK["wall"]
        if (map[x, y]["blood"]) {
          color = INK["blood"]
        }
        if (map[x, y]["visible"] == "maybe") {
          color = INK["obscured"]
        }
        if (DEBUG) {
          if (map[x, y]["seen"]) {
            color = Color.red
          }
          if (map[x, y]["cost"]) {
            printSymbolBg(map[x, y]["cost"].toString, x, y, INK["burgandy"])
            printSymbol(map[x, y]["cost"].toString, x, y, color)
          }
        }
        if (map[x, y]["void"]) {
        } else if (map[x, y]["solid"]) {
          if (map[x, y]["altar"]) {
            printSymbolBg("^", x, y, INK["altarBg"])
            printSymbol("^", x, y, INK["altar"])
          } else if (map[x, y]["statue"]) {
            var bg = INK["lilac"] * 1
            bg.a = 128
            printSymbolBg("£", x, y, bg)
            printSymbol("£", x, y, color)
          } else {
            printSymbol("#", x, y, color)
          }
        } else if (map[x, y]["stairs"]) {
          if (map[x, y]["stairs"] == "down") {
            printSymbol(">", x, y, INK["downstairs"])
          }
          if (map[x, y]["stairs"] == "up") {
            printSymbol("<", x, y, INK["upstairs"])
          }
        } else {
          printSymbol(".", x, y, color)
        }

        var items = map[x, y]["items"]
        if (items && items.count > 0) {
          var bg = INK["bg"] * 1
          bg.a = 64
          Canvas.rectfill(x * 16, y * 16, 16, 16, bg)
          var color = INK["treasure"]
          var symbolMap = {
            "potion": "!",
            "scroll": "~",
            "wand": "~",
            "sword": "/",
            "shield": "}",
            "armor": "[",
          }
          var kind = _world["items"][items[0].id].kind
          printSymbol(symbolMap[kind], x, y, color)
        }
      }
    }

    var tileEntities = _world.entities().sort {|a, b|
      if (a["killed"] && !b["killed"]) {
        return true
      }
      if (!a["killed"] && b["killed"]) {
        return false
      }
      return a["killed"]
    } + [ player ]

    for (entity in tileEntities) {
      if (!entity.pos) {
        continue
      }

      entity.spaces.where {|space| map[space]["visible"] == true }.each {|space|
        var symbol = entity["symbol"] || entity.name && entity.name[0] || "?"
        var color = INK["creature"]
        if (entity["killed"]) {
          color = (color * 1)
          color.a = 192
          symbol = "\%"
        }
        if (entity["frozen"]) {
          color = INK["wall"]
          symbol = "£"
          var bg = INK["bg"] * 1
          bg.a = 128
          printSymbolBg("£", space.x, space.y, bg)
        }
        //Canvas.print(symbol, space.x * 16 + 4, space.y * 16 + 4, Color.white)
        printEntity(symbol, space, color)
      }
    }

    Canvas.offset(offset.x, offset.y)
  }

  printSymbolBg(symbol, x, y, bg) {
    Canvas.rectfill(x * 16 + 2, y * 16 + 2, 12, 12, bg)
  }
  printSymbol(symbol, x, y, color) {
    Canvas.print(symbol, x * 16 + 4, y * 16 + 4, color)
  }

  printEntity(symbol, pos, color) {
    printSymbol(symbol, pos.x, pos.y, color)
  }

  // TODO: is this still needed?
  printArea(symbol, start, size, color, bg) {
    var corner = start + size
    var maxX = corner.x - 1
    var maxY = corner.y - 1
    for (y in start.y..maxY) {
      for (x in start.x..maxX) {
        printEntity(symbol, Vec.new(x, y), color, bg)
      }
    }
  }
}

class TileRenderer is AsciiRenderer {
  construct new(pos) {
    super(pos)
    _sheet = SpriteSheet.load("res/img/tiles-1bit.png", 16)
    _caves = SpriteSheet.load("res/img/caves.png", 16)
    _crystal = ImageData.load("res/img/crystal.png")
    _protag = SpriteSheet.load("res/img/protagonist.png", 16)
    _bg = INK["bg"] * 1
    _bg.a = 128
    _sheet.bg = _bg
  }

  drawPlayer(x, y, color) {
    Canvas.rectfill(x * 16, y * 16, 16, 16, _bg)
    var player = world.getEntityByTag("player")
    if (!player) {
      return
    }
    var sx = x * 16
    var sy = y * 16
    _protag.fg = color
    var armor = player["equipment"][EquipmentSlot.armor]
    var weapon = player["equipment"][EquipmentSlot.weapon]
    var shield = player["equipment"][EquipmentSlot.offhand]

    // Head (armor)
    if (!armor) {
      _protag.draw(12, sx, sy)
    } else if (armor == "leather armor") {
      _protag.draw(15, sx, sy)
    } else if (armor == "chainmail") {
      _protag.draw(13, sx, sy)
    } else if (armor == "platemail") {
      _protag.draw(14, sx, sy)
    }

    // right arm
    if (!weapon) {
      _protag.draw(5, sx, sy)
    } else if (weapon == "dagger") {
      _protag.draw(4, sx, sy)
    } else if (weapon == "shortsword") {
      _protag.draw(8, sx, sy)
    } else if (weapon == "longsword") {
      _protag.draw(9, sx, sy)
    }
    // Left arm
    if (!shield) {
      _protag.draw(0, sx, sy)
    } else {
      _protag.draw(2, sx, sy)
    }
  }

  printSymbolBg(symbol, x, y, color) {}
  printSymbol(symbol, x, y, color) {
    _sheet.fg = color
    _caves.fg = color
    var sx = x * 16
    var sy = y * 16
    var sheetWidth = 49
    if (symbol == "@") {
      drawPlayer(x, y, color)
    } else if (symbol == "z") {
      _sheet.drawFrom(28, 6, sx, sy)
    } else if (symbol == "r") {
      _sheet.drawFrom(31, 8, sx, sy)
    } else if (symbol == "d") {
      _sheet.drawFrom(31, 7, sx, sy)
    } else if (symbol == "G") {
      _sheet.drawFrom(27, 3, sx, sy)
    } else if (symbol == "D") {
      _sheet.drawFrom(31, 6, sx, sy)
    } else if (symbol == "£") {
      _sheet.drawFrom(26, 3, sx, sy)
    } else if (symbol == "\%") {
      _sheet.drawFrom(0, 15, sx, sy)
    } else if (symbol == ">") {
      _sheet.drawFrom(3, 6, sx, sy)
    } else if (symbol == "<") {
      _sheet.drawFrom(2, 6, sx, sy)
    } else if (symbol == "^") {
      _sheet.drawFrom(4, 12, sx, sy,{ "background": Color.none })
    } else if (symbol == "~") {
      _sheet.drawFrom(34, 15, sx, sy)
    } else if (symbol == "!") {
      _sheet.drawFrom(33, 14, sx, sy)
    } else if (symbol == "/") {
      _sheet.drawFrom(32, 8, sx, sy)
    } else if (symbol == "[") {
      _sheet.drawFrom(32, 1, sx, sy)
    } else if (symbol == "}") {
      _sheet.drawFrom(37, 4, sx, sy)
    } else if (world.zoneIndex < 3) {
      if (symbol == ".") {
        _floor = color * 0.33
        _floor.a = 255
        _sheet.drawFrom(16, 0, sx, sy, { "foreground": _floor})
        if (color == INK["blood"]) {
          _sheet.drawFrom(5, 2, sx, sy)
        }
      } else if (symbol == "#") {
        _sheet.drawFrom(10, 17, sx, sy)
      }
    } else if (world.zoneIndex < 7) {
      if (symbol == ".") {
        _floor = color * 0.33
        _floor.a = 255
        _sheet.drawFrom(2, 0, sx, sy, { "foreground": _floor})
        if (color == INK["blood"]) {
          _sheet.drawFrom(5, 2, sx, sy)
        }
      } else if (symbol == "#") {
        var tileX = 0 // starts at (0, 20)
        var tileY = 0
        var map = world.zone.map
        var north = map[x, y - 1]["solid"] || map[x, y - 1]["void"] ? 0 : 1
        var south = map[x, y + 1]["solid"] || map[x, y + 1]["void"] ? 0 : 1
        var east = map[x + 1, y]["solid"] || map[x + 1, y]["void"] ? 0 : 1
        var west = map[x - 1, y]["solid"] || map[x - 1, y]["void"] ? 0 : 1
        var index = (west << 3) | (south << 2) | (east << 1) | north
        //Canvas.print(index, sx, sy, color)
        _caves.draw(index, sx, sy)
        //_sheet.drawFrom((17 * sheetWidth) + 10, sx, sy)
      }
    } else {
      return super.printSymbol(symbol, x, y, color)
    }
  }

  draw() {
    var sheetWidth = 49
    super.draw()
    var offset = Canvas.offset
    Canvas.offset(pos.x, pos.y)
    var demons = world.entities().where {|entity| entity is Demon }.toList
    if (!demons.isEmpty) {
      var color = INK["creature"]
      for (demon in demons) {
        var center = demon.pos + (demon.size) / 3
        _sheet.fg = color
        var sx = center.x * 16
        var sy = center.y * 16
        if (demon["conditions"].containsKey("invulnerable")) {
          _crystal.draw(demon.pos.x * 16, demon.pos.y*16)
          _sheet.fg = INK["deeppurple"]
        } else {
          printSymbolBg(demon["symbol"], center.x, center.y, INK["bg"])
          _sheet.drawFrom(31, 6, sx, sy)
        }
      }
    }
    Canvas.offset(offset.x, offset.y)
  }
}
