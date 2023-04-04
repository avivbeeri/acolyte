import "graphics" for Canvas
import "math" for Vec
import "parcel" for
  State,
  Event
import "inputs" for VI_SCHEME as INPUT

// Dictates where a UI will be positioned relative to.
class Anchor {
  static point(anchor) {
    var border = 8
    if (anchor == Anchor.center) {
      return Vec.new(Canvas.width / 2, Canvas.height / 2)
    }
    if (anchor == Anchor.left) {
      return Vec.new(border, Canvas.height / 2)
    }
    if (anchor == Anchor.right) {
      return Vec.new(Canvas.width - border, Canvas.height / 2)
    }
    if (anchor == Anchor.top) {
      return Vec.new(Canvas.width / 2, border)
    }
    if (anchor == Anchor.bottom) {
      return Vec.new(Canvas.width / 2, Canvas.height - border)
    }
    if (anchor == Anchor.topLeft) {
      return Vec.new(border, border)
    }
    if (anchor == Anchor.topRight) {
      return Vec.new(Canvas.width - border, border)
    }
    if (anchor == Anchor.bottomLeft) {
      return Vec.new(border, Canvas.height - border)
    }
    if (anchor == Anchor.bottomRight) {
      return Vec.new(Canvas.width - border, Canvas.height - border)
    }
    return null
  }
  static center { "center" }
  static left { "left" }
  static right { "right" }
  static top { "top" }
  static bottom { "bottom" }
  static topLeft { "top-left" }
  static topRight { "top-right" }
  static bottomLeft { "bottom-left" }
  static bottomRight { "bottom-right" }
  static absolute { "absolute" }
}


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


