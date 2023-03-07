import "parcel" for Action, ActionResult, MAX_TURN_SIZE, JPS
import "./combat" for AttackEvent, Damage, DefeatEvent, HealEvent
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

class HealAction is Action {
  construct new(target, amount) {
    super()
    _target = target
    _amount = amount
  }
  target { _target || src }
  evaluate() {
    // Check if it's sensible to heal?
    var hpMax = target["stats"].get("hpMax")
    var hp = target["stats"].get("hp")
    if (hpMax == hp) {
      return ActionResult.invalid
    }

    return ActionResult.valid
  }

  perform() {
    var hpMax = target["stats"].get("hpMax")
    var hp = target["stats"].get("hp")
    var amount = _amount.min(hpMax - hp)
    target["stats"].increase("hp", amount)
    ctx.addEvent(HealEvent.new(target, amount))

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
    src.pos = src.pos + _dir
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
