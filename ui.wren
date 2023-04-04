import "parcel" for
  State,
  Event
import "inputs" for VI_SCHEME as INPUT

class Animation {
  static ease(x) {
    return -((Num.pi * x).cos - 1) / 2
  }
}

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


