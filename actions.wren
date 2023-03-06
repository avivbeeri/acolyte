import "parcel" for Action, ActionResult, MAX_TURN_SIZE, JPS
import "./combat" for AttackEvent, Damage, DefeatEvent
import "./events" for RestEvent

class RestAction is Action {
  construct new() {
    super()
  }
  evaluate() {
    return ActionResult.valid
  }

  perform() {
    ctx.addEvent(RestEvent.new(src))
    return ActionResult.success
  }
}

class MeleeAttackAction is Action {
  construct new(dir) {
    super()
    _dir = dir
  }
  evaluate() {
    if (!ctx.zone.map.neighbours(src.pos).contains(src.pos + _dir)) {
      return ActionResult.invalid
    }
    if (!ctx.entities().any{|other| other.occupies(src.pos  + _dir) && other["solid"] }) {
      return ActionResult.invalid
    }

    return ActionResult.valid
  }

  perform() {
    var targetPos = src.pos + _dir
    var targets = ctx.getEntitiesAtPosition(targetPos)
    for (target in targets) {
      var atk = src["stats"].get("str")
      var def = target["stats"].get("dex")
      var damage = Damage.calculate(atk, def)
      target["stats"].decrease("hp", damage)
      ctx.addEvent(AttackEvent.new())
      if (target["stats"].get("hp") <= 0) {
        ctx.addEvent(DefeatEvent.new(target))
        // TODO remove entity elsewhere?
        ctx.removeEntity(target)
      }
    }

    return ActionResult.success
  }
}

class SimpleMoveAction is Action {
  construct new(dir) {
    super()
    _dir = dir
  }
  evaluate() {
    if (!ctx.zone.map.neighbours(src.pos).contains(src.pos + _dir)) {
      return ActionResult.invalid
    }
    if (ctx.entities().any{|other| other.occupies(src.pos  + _dir) && other["solid"] }) {
      return ActionResult.invalid
    }

    return ActionResult.valid
  }

  perform() {
    ctx.zone.map[src.pos]["occupied"] = false
    src.pos = src.pos + _dir
    ctx.zone.map[src.pos]["occupied"] = true
    return ActionResult.success
  }
}

class BumpAction is Action {
  construct new(dir) {
    super()
    _dir = dir
  }
  evaluate() {
    if (ctx.entities().any{|other| other.occupies(src.pos  + _dir) && other["solid"] }) {
      return ActionResult.alternate(MeleeAttackAction.new(_dir))
    }

    return ActionResult.alternate(SimpleMoveAction.new(_dir))
  }
}
