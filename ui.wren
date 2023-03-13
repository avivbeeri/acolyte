import "parcel" for
  TextInputReader,
  State,
  Event
import "inputs" for VI_SCHEME as INPUT

class SceneState is State {
  construct new() {
    super()
    _scene = null
    _previous = null
    _args = []
  }
  scene { _scene }
  previous { _previous }
  with(args) { withArgs(args) }
  withArgs(args) {
    if (!(args is List)) {
      args = [ args ]
    }
    _args = args
    return this
  }
  from(previous) {
    _previous = previous
    return this
  }
  withScene(scene) {
    _scene = scene
    _previous = scene.previous
    return this
  }
  arg(n) {
    if (n < _args.count) {
      return _args[n]
    }
    return null
  }
  onEnter() {}
  onExit() {}
  update() {
    return this
  }
}

class HoverEvent is Event {
  construct new(target) {
    super()
    _src = target
  }
  target { _src }
}

class TargetEvent is Event {
  construct new(pos) {
    super()
    data["pos"] = pos
  }
  pos { data["pos"] }
}
class TargetBeginEvent is TargetEvent {
  construct new(pos) {
    super(pos)
    data["range"] = 1
  }
  construct new(pos, range) {
    super(pos)
    data["range"] = range
  }
  range { data["range"] }
}

class TargetEndEvent is Event {
  construct new() {
    super()
  }
}

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

  construct new(scene) {
    super()
    _scene = scene
    _world = scene.world
    _kb = TextInputReader.new()
    _kb.enable()
  }

  update() {
    _kb.update()
    if (INPUT["confirm"].firing) {
      _kb.disable()
      events.add(TextComplete.new(_kb.text))
      return PlayerInputState.new(_scene)
    }
    if (INPUT["reject"].firing) {
      _kb.disable()
      return PlayerInputState.new(_scene)
    }
    events.add(TextChanged.new(_kb.text))
    return this
  }
}


/*------- Text rendering code
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
----------*/

import "scene" for PlayerInputState
