import "parcel" for Action, ActionResult, MAX_TURN_SIZE

class SimpleMoveAction is Action {
  construct new(dir) {
    super()
    _dir = dir
  }
  evaluate() {
    if (ctx.zone.map.neighbours(src.pos).contains(src.pos + _dir)) {
      return ActionResult.valid
    }
    return ActionResult.invalid
  }

  perform() {
    src.pos = src.pos + _dir
    return ActionResult.success
  }
  cost() { MAX_TURN_SIZE }
}