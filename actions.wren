import "math" for Vec
import "collections" for HashMap
import "parcel" for Action, ActionResult, MAX_TURN_SIZE, Line, RNG, TargetGroup, Reflect, Stateful
import "./combat" for Damage, Condition, CombatProcessor, Modifier

#!component(id="pray", group="action")
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
        var amount = src["stats"].increase("piety", 1, "pietyMax")
      }
    }
    if (!heard && src["stats"]["hp"] == 1) {
      var success = (0.2 - 0.1 * src["brokenOaths"].count).max(0.05)
      if (RNG.float() <= success) {
        heard = true
        System.print("your prayers were heard")
      }
    }
    ctx.addEvent(Components.events.pray.new(src))
    return ActionResult.success
  }
}

#!component(id="effect", group="action")
class EffectAction is Action {
  construct new() {
    super()
  }

  effects { data["effects"] }
  target { data["target"] }

  evaluate() {
    return ActionResult.valid
  }

  perform() {
    // Execute effects
    for (effectData in effects) {
      var args = {}
      Stateful.assign(args, data)
      if (effectData.count > 1) {
        Stateful.assign(args, effectData[1])
      }
      var targetGroup = TargetGroup.new(args)
      var effect = Reflect.get(Components.effects, effectData[0]).new(ctx, args)
      effect["src"] = src
      for (entity in targetGroup.entities(ctx, src)) {
        effect["target"] = entity
        effect.perform()
        ctx.addEvents(effect.events)
      }
    }

    return ActionResult.success
  }
}

#!component(id="rest", group="action")
class RestAction is Action {
  construct new() {
    super()
  }
  evaluate() {
    return ActionResult.valid
  }

  perform() {
    ctx.addEvent(Components.events.rest.new(src))
    return ActionResult.success
  }
}

#!component(id="areaAttack", group="action")
class AreaAttackAction is Action {
  construct new() {
    super()
  }

  damage { data["damage"] }

  evaluate() {
    // TODO: check if origin is solid and visible
    var target = TargetGroup.new(data)
    return ActionResult.valid
  }

  perform() {
    var target = TargetGroup.new(data)
    var attackEvents = []
    var resultEvents = []
    for (entity in target.entities(ctx, src)) {
      var effect = Components.effects.directDamage.new(ctx, {
        "src": src,
        "target": entity,
        "damage": damage
      })
      effect.perform()
      resultEvents.addAll(effect.events)
    }
    ctx.addEvents(attackEvents + resultEvents)
    return ActionResult.success
  }
}

#!component(id="strikeAttack", group="action")
class StrikeAttackAction is Action {
  construct new() {
    super()
  }
  evaluate() {
    var target = TargetGroup.new(data)
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
      var effect = Components.effects.meleeDamage.new(ctx, {
        "target": target,
        "src": src
      })
      effect.perform()
      ctx.addEvents(effect.events)
    }

    return ActionResult.success
  }
}
#!component(id="meleeAttack", group="action")
class MeleeAttackAction is Action {
  construct new(dir) {
    super()
    _dir = dir
  }
  withArgs(args) {
    _dir = args["dir"] || _dir
    return this
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
      var effect = Components.effects.meleeDamage.new(ctx, {
        "target": target,
        "src": src
      })
      effect.perform()
      ctx.addEvents(effect.events)
    }

    return ActionResult.success
  }
}

#!component(id="simpleMove", group="action")
class SimpleMoveAction is Action {
  construct new(dir) {
    super()
    data["dir"] = dir
  }

  dir { data["dir"] }

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
    var area = getArea(src.pos + dir, src.size)
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
    var origin = src.pos
    src.pos = src.pos + dir
    ctx.addEvent(Components.events.move.new(src, origin))
    return ActionResult.success
  }
}

#!component(id="descend", group="action")
class DescendAction is Action {
  construct new() {
  }
  evaluate() {
    return ctx.zone.map[src.pos]["stairs"] == "down" ? ActionResult.valid : ActionResult.invalid
  }
  perform() {
    src.zone = src.zone + 1
    ctx.addEvent(Components.events.descend.new())
    var zone = ctx.loadZone(ctx.zoneIndex + 1, src.pos)
    src.pos = zone["start"]
    ctx.skipTo(Player)
    return ActionResult.success
  }
}

#!component(id="bump", group="action")
class BumpAction is Action {
  construct new(dir) {
    super()
    _dir = dir
  }
  withArgs(args) {
    _dir = args["dir"] || _dir
    return this
  }
  evaluate() {
    if (ctx.entities().any{|other| other.occupies(src.pos  + _dir) && other["solid"] }) {
      return ActionResult.alternate(MeleeAttackAction.new(_dir))
    }

    return ActionResult.alternate(SimpleMoveAction.new(_dir))
  }
}

#!component(id="interact", group="action")
class InteractAction is Action {
  construct new() {
    super()
  }
  evaluate() {
    var tile = ctx.zone.map[src.pos]
    if (ctx.entities().any{|other| other.occupies(src.pos) && other["conditions"]["unconscious"] }) {
      return ActionResult.alternate(StrikeAttackAction.new())
    }
    if (tile["items"] && !tile["items"].isEmpty) {
      return ActionResult.alternate(Components.actions.pickup.new())
    }
    if (tile["stairs"] == "down") {
      return ActionResult.alternate(DescendAction.new())
    }

    return ActionResult.invalid
  }
}

import "./entities" for Player
import "./groups" for Components
