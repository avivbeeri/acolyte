import "dome" for Process, Log
import "graphics" for Canvas, Color
import "input" for Keyboard
import "math" for Vec
import "parcel" for
  TextInputReader,
  DIR_EIGHT,
  Scene,
  State,
  World,
  Entity,
  Event,
  Tile,
  TurnEvent,
  GameEndEvent,
  Palette

import "./messages" for MessageLog
import "./entities" for Player
import "./actions" for BumpAction
import "./systems" for VisionSystem, DefeatSystem
import "./generator" for Generator
import "./combat" for AttackEvent
import "./renderer" for AsciiRenderer, HealthBar, LogViewer
import "./palette" for INK
import "./inputs" for
  DIR_INPUTS,
  ESC_INPUT,
  CONFIRM,
  REJECT


class TextComplete is Event {
  construct new(text) {
    super()
    data["text"] = text
  }
  text { data["text"] }
}
class TextChanged is Event {
  construct new(text) {
    super()
    data["text"] = text
  }
  text { data["text"] }
}

class TextInputState is State {

  construct new(world) {
    super()
    _world = world
    _kb = TextInputReader.new()
    _kb.enable()
  }

  update() {
    _kb.update()
    if (Keyboard["return"].justPressed) {
      _kb.disable()
      events.add(TextComplete.new(_kb.text))
      return PlayerInputState.new(_world)
    }
    if (Keyboard["escape"].justPressed) {
      _kb.disable()
      return PlayerInputState.new(_world)
    }
    events.add(TextChanged.new(_kb.text))
    return this
  }
}

class PlayerInputState is State {

  construct new(world) {
    super()
    _world = world
  }

  update() {
     /* TODO temp */
    if (ESC_INPUT.firing) {
      Process.exit()
      return
    }
    if (Keyboard["return"].justPressed) {
      return TextInputState.new(_world)
    }

    if (_world.complete) {
      return this
    }

    var player = _world.getEntityByTag("player")
    var i = 0
    for (input in DIR_INPUTS) {
      if (input.firing) {
        player.pushAction(BumpAction.new(DIR_EIGHT[i]))
      }
      i = i + 1
    }

    return this
  }
}

class GameScene is Scene {
  construct new(args) {
    super(args)
    _t = 0
    _messages = MessageLog.new()
    _messages.add("Welcome, acolyte, to the catacombs. It's time to decend.", INK["welcomeText"], false)

    var world = _world = World.new()
    _world.systems.add(DefeatSystem.new())
    _world.systems.add(VisionSystem.new())

    var zone = Generator.generateDungeon([ 1 ])
    world.addZone(zone)
    for (entity in zone["entities"]) {
      world.addEntity(entity)
    }
    zone.data.remove("entities")
    world.addEntity("player", Player.new())
    var player = world.getEntityByTag("player")
    player.pos = zone["start"]

    _name = ""
    _currentText = ""

    world.start()
    _state = PlayerInputState.new(_world)
    addElement(AsciiRenderer.new(Vec.new(0, 10)))
    addElement(HealthBar.new(Vec.new(0, 0), player.ref))
    addElement(LogViewer.new(Vec.new(0, 32), _messages))
    //addElement(LogViewer.new(Vec.new(0, Canvas.height - 12 * 7), _messages))
  }

  world { _world }

  update() {
    super.update()
    // Global animation timer
    _t = _t + 1

    _state.events.clear()
    var nextState = _state.update()
    for (event in _state.events) {
      if (event is TextComplete) {
        _currentText = ""
        _name = event.text
      }
      if (event is TextChanged) {
        _currentText = event.text
      }
    }

    if (nextState != _state) {
      _state.onExit()
      nextState.onEnter()
      _state = nextState
    }

    _world.advance()
    for (event in _world.events) {
      if (event is GameEndEvent) {
        _messages.add("The game has ended", INK["playerDie"], false)
      }
      if (event is AttackEvent) {
        _messages.add("An attack occurred", INK["enemyAtk"], true)
      }
    }
  }

  draw() {
    var color = INK["dark"]
    Canvas.cls(color)
    super.draw()

    Canvas.print(_name, 0, Canvas.height - 17, Color.white)
    /*
    TODO: Needs to be in its own UI widget
    if (_currentText) {
      var x = _kb.pos * 8
      var y = Canvas.height - 10
      if ((_t / 30).floor % 2 == 0) {
        Canvas.rectfill(x, y, 8, 10, Color.white)
      }
      Canvas.print(_currentText, 0, Canvas.height - 9, Color.white)
    }
     */
  }
}
