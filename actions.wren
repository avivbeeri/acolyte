import "collections" for HashMap
import "parcel" for Action, ActionResult, MAX_TURN_SIZE, JPS, Line, RNG
import "math" for Vec
import "./combat" for AttackEvent, Damage, Condition, CombatProcessor
import "./events" for Events, RestEvent, LightningEvent

class PrayAction is Action {
  construct new() {
    super()
  }

  cost() { super.cost() * 3 }

  evaluate() {
    return ActionResult.valid
  }

  perform() {
    var positions = ctx.zone.map.allNeighbours(src.pos)
    var heard = false
    var success = 0.5 - 0.1 * src["brokenOaths"].count
    if (positions.any {|position| ctx.zone.map[position]["altar"]}) {
      if (RNG.float() <= success) {
        heard = true
        var pietyMax = src["stats"].get("pietyMax")
        var piety = src["stats"].get("piety")
        var amount = 1.clamp(0, pietyMax - piety)
        src["stats"].increase("piety", amount)
      }
    }
    if (!heard && src["stats"]["hp"] == 1) {
      var success = (0.2 - 0.1 * src["brokenOaths"].count).max(0.05)
      if (RNG.float() <= success) {
        heard = true
        System.print("your prayers were heard")
      }
    }
    ctx.addEvent(Events.pray.new(src))
    return ActionResult.success
  }
}
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

    /*
    target["stats"].decrease("hp", _damage)
    if (target["stats"].get("hp") <= 0) {
      ctx.addEvent(Events.defeat.new(src, target))
      // TODO remove entity elsewhere?
      ctx.removeEntity(target)
    }
    */
    var result = CombatProcessor.calculate(src, target, _damage)
    ctx.addEvent(LightningEvent.new(target))
    if (result[0]) {
      ctx.addEvent(Events.defeat.new(src, target))
    }
    if (result[1]) {
      ctx.addEvent(Events.kill.new(src, target))
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
    var kills = []
    var dist = _range - 1
    var targets = HashMap.new()
    for (dy in (-dist)..(dist)) {
      for (dx in (-dist)..(dist)) {
        var x = (_origin.x + dx)
        var y = (_origin.y + dy)
        var tileEntities = ctx.getEntitiesAtPosition(x, y)
        for (target in tileEntities) {
          targets[target.id] = target
        }
      }
    }

    for (target in targets.values) {
      var result = CombatProcessor.calculate(src, target, _damage)
      if (result[0]) {
        defeats.add(Events.defeat.new(src, target))
      }
      if (result[1]) {
        kills.add(Events.kill.new(src, target))
      }
    }
    for (event in defeats + kills) {
      ctx.addEvent(event)
    }

    return ActionResult.success
  }
}
class StrikeAttackAction is Action {
  construct new() {
    super()
  }
  evaluate() {
    if (!ctx.entities().any{|other| other != src && other.occupies(src.pos) && other["conditions"]["unconscious"] }) {
      return ActionResult.invalid
    }

    return ActionResult.valid
  }

  perform() {
    var targets = ctx.getEntitiesAtPosition(src.pos)
    for (target in targets) {
      if (target == src) {
        continue
      }
      var result = CombatProcessor.calculate(src, target)
      if (result[1]) {
        ctx.zone.map[src.pos]["blood"] = true
        ctx.addEvent(Events.kill.new(src, target))
      }
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
      var result = CombatProcessor.calculate(src, target)
      if (result[0]) {
        ctx.addEvent(Events.defeat.new(src, target))
      }
      if (result[1]) {
        ctx.addEvent(Events.kill.new(src, target))
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

  getArea(start, size) {
    var corner = start + size
    var maxX = corner.x - 1
    var maxY = corner.y - 1
    var area = []
    for (y in start.y..maxY) {
      for (x in start.x..maxX) {
        area.add(Vec.new(x, y))
      }
    }
    return area
  }

  evaluate() {
    var area = getArea(src.pos + _dir, src.size)
    for (spot in area) {
      if (!ctx.zone.map.neighbours(src.pos).contains(spot)) {
        return ActionResult.invalid
      }
      if (ctx.entities().any{|other| other.occupies(spot) && other["solid"] }) {
        return ActionResult.invalid
      }
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
    var zone = ctx.loadZone(ctx.zoneIndex + 1, src.pos)
    src.pos = zone["start"]
    ctx.skipTo(Player)
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
import "./entities" for Player
