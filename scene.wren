import "graphics" for Canvas, Color
import "input" for Keyboard, Mouse, InputGroup
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
  Palette

import "./entities" for Player
import "./actions" for SimpleMoveAction
import "./systems" for VisionSystem
import "./generator" for Generator
import "./renderer" for AsciiRenderer

var DIR_INPUTS = [
  InputGroup.new([Keyboard["up"], Keyboard["k"], Keyboard["keypad 8"], Keyboard["8"]]),
  InputGroup.new([Keyboard["right"], Keyboard["l"], Keyboard["keypad 6"], Keyboard["6"] ]),
  InputGroup.new([Keyboard["down"], Keyboard["j"], Keyboard["keypad 2"], Keyboard["2"] ]),
  InputGroup.new([Keyboard["left"], Keyboard["h"], Keyboard["keypad 4"] , Keyboard["4"]]),
  InputGroup.new([Keyboard["y"], Keyboard["keypad 7"], Keyboard["7"] ]),
  InputGroup.new([Keyboard["u"], Keyboard["keypad 9"], Keyboard["9"] ]),
  InputGroup.new([Keyboard["n"], Keyboard["keypad 3"], Keyboard["3"] ]),
  InputGroup.new([Keyboard["b"], Keyboard["keypad 1"], Keyboard["1"] ])
]

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
    if (Keyboard["return"].justPressed) {
      return TextInputState.new(_world)
    }

    var player = _world.getEntityByTag("player")
    var i = 0
    for (input in DIR_INPUTS) {
      if (input.firing) {
        player.pushAction(SimpleMoveAction.new(DIR_EIGHT[i]))
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

    var world = _world = World.new()
    var zone = Generator.generate([ 1 ])
    _world.systems.add(VisionSystem.new())
    world.addZone(zone)
    world.addEntity("player", Player.new())
    // world.addEntity(Entity.new())
    _name = ""
    _currentText = ""

    world.start()
    _state = PlayerInputState.new(_world)
    addElement(AsciiRenderer.new(Vec.new(50, 0)))
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
      if (event is TurnEvent) {
        var t = event["turn"]
      }
    }
  }

  draw() {
    Canvas.cls()
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
