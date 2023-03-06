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
import "./actions" for BumpAction, RestAction
import "./events" for RestEvent
import "./systems" for VisionSystem, DefeatSystem
import "./generator" for Generator
import "./combat" for AttackEvent
import "./renderer" for
  AsciiRenderer,
  HealthBar,
  LogViewer,
  HistoryViewer,
  HoverText
import "./palette" for INK
import "./inputs" for
  OPEN_LOG,
  DIR_INPUTS,
  REST_INPUT,
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

class ModalWindowState is State {
  construct new(scene) {
    super()
    _scene = scene
  }
  onEnter() {
    var border = 24
    _window = HistoryViewer.new(Vec.new(border, border), Vec.new(Canvas.width - border*2, Canvas.height - border*2), _scene.messages)
    _scene.addElement(_window)
  }
  onExit() {
    _scene.removeElement(_window)
  }
  update() {
    if (CONFIRM.firing) {
      return PlayerInputState.new(_scene)
    }
    return this
  }
}
class TextInputState is State {

  construct new(scene) {
    super()
    _scene = scene
    _world = scene.world
    _kb = TextInputReader.new()
    _kb.enable()
  }

  update() {
    _kb.update()
    if (Keyboard["return"].justPressed) {
      _kb.disable()
      events.add(TextComplete.new(_kb.text))
      return PlayerInputState.new(_scene)
    }
    if (Keyboard["escape"].justPressed) {
      _kb.disable()
      return PlayerInputState.new(_scene)
    }
    events.add(TextChanged.new(_kb.text))
    return this
  }
}

class PlayerInputState is State {

  construct new(scene) {
    super()
    _scene = scene
    _world = scene.world
  }

  update() {
     /* TODO temp */
    if (OPEN_LOG.firing) {
      return ModalWindowState.new(_scene)
    }
    if (ESC_INPUT.firing) {
      Process.exit()
      return
    }
    if (Keyboard["return"].justPressed) {
      return TextInputState.new(_scene)
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
    if (REST_INPUT.firing) {
      player.pushAction(RestAction.new())
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
    _state = PlayerInputState.new(this)
    addElement(AsciiRenderer.new(Vec.new(0, 20)))
    addElement(HealthBar.new(Vec.new(0, 0), player.ref))
    addElement(HoverText.new(Vec.new(Canvas.width - 64, 0)))
    addElement(LogViewer.new(Vec.new(0, Canvas.height - 60), _messages))
    //addElement(LogViewer.new(Vec.new(0, Canvas.height - 12 * 7), _messages))
  }

  world { _world }
  messages { _messages }
  events { _state.events }

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
        _messages.add("An attack occurred", INK["enemyAtk"], false)
      }
      if (event is RestEvent) {
        _messages.add("%(event.src) rests.", INK["text"], false)
      }
    }
  }

  draw() {
    var color = INK["black"]
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
