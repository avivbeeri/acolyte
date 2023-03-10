import "parcel" for Action, ActionResult, MAX_TURN_SIZE, JPS, Line
import "./combat" for AttackEvent, Damage, Condition
import "./events" for Events, RestEvent, LightningEvent

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

class InflictConfusionAction is Action {
  construct new(target) {
    super()
    _targetPos = target
  }

  evaluate() {
    if (ctx.getEntitiesAtPosition(_targetPos).isEmpty) {
      return ActionResult.invalid
    }
    return ActionResult.valid
  }

  perform() {
    ctx.getEntitiesAtPosition(_targetPos).each {|target|
      if (target["conditions"].containsKey("confusion")) {
        target["conditions"]["confusion"].extend(3)
        ctx.addEvent(Events.extendCondition.new(target, "confusion"))
      } else {
        target["conditions"]["confusion"] = Condition.new("confusion", 3, true)
        target.behaviours.add(ConfusedBehaviour.new())
        ctx.addEvent(Events.inflictCondition.new(target, "confusion"))
      }
    }

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
    ctx.addEvent(Events.heal.new(target, amount))

    return ActionResult.success
  }
}
class LightningAttackAction is Action {
  construct new(range, damage) {
    super()
    _range = range
    // Do we deal direct damage or should we treat this as an ATK value?
    _damage = damage
  }
  evaluate() {
    _nearby = ctx.entities().where {|entity|
      return entity != src &&
             entity.has("stats") &&
             distance(entity) <= _range &&
             ctx.zone.map[entity.pos]["visible"] == true
    }.toList

    if (_nearby.isEmpty) {
      return ActionResult.invalid
    }

    return ActionResult.valid
  }

  distance(entity) {
    if (entity == null) {
      return Num.infinity
    }
    return Line.chebychev(src.pos, entity.pos)
  }

  perform() {
    var target = _nearby.reduce(null) {|acc, item|
      if (item == src) {
        return acc
      }
      if (item == null || distance(acc) > distance(item)) {
        return item
      }
      return acc
    }

    target["stats"].decrease("hp", _damage)
    ctx.addEvent(LightningEvent.new(target))
    if (target["stats"].get("hp") <= 0) {
      ctx.addEvent(Events.defeat.new(src, target))
      // TODO remove entity elsewhere?
      ctx.removeEntity(target)
    }
    return ActionResult.success
  }
}

class AreaAttackAction is Action {
  construct new(origin, range, damage) {
    super()
    _origin = origin
    _range = range
    _damage = damage
  }
  evaluate() {
    // TODO: check if origin is solid and visible
    return ActionResult.valid
  }

  perform() {
    var targetPos = _origin
    var defeats = []
    var dist = _range - 1
    var targets = []
    for (dy in (-dist)..(dist)) {
      for (dx in (-dist)..(dist)) {
        var x = (_origin.x + dx)
        var y = (_origin.y + dy)
        targets.addAll(ctx.getEntitiesAtPosition(x, y))
      }
    }

    for (target in targets) {
      target["stats"].decrease("hp", _damage)
      ctx.addEvent(AttackEvent.new(src, target, "area", _damage))
      if (target["stats"].get("hp") <= 0) {
        defeats.add(Events.defeat.new(src, target))
        // TODO remove entity elsewhere?
        ctx.removeEntity(target)
      }
    }
    for (event in defeats) {
      ctx.addEvent(event)
    }

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
      var srcStats = src["stats"]
      srcStats.set("atk", srcStats["str"])
      var atk = srcStats.get("atk")
      var def = target["stats"].get("dex")
      var damage = Damage.calculate(atk, def)
      target["stats"].decrease("hp", damage)
      ctx.addEvent(AttackEvent.new(src, target, "melee", damage))
      if (target["stats"].get("hp") <= 0) {
        ctx.addEvent(Events.defeat.new(src, target))
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

class DescendAction is Action {
  construct new() {
  }
  evaluate() {
    return ctx.zone.map[src.pos]["stairs"] == "down" ? ActionResult.valid : ActionResult.invalid
  }
  perform() {
    src.zone = src.zone + 1
    ctx.addEvent(Events.descend.new())
    ctx.loadZone(ctx.zoneIndex + 1, src.pos)
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

import "./behaviour" for ConfusedBehaviour
