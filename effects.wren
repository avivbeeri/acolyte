import "parcel" for Stateful
import "groups" for Components
import "combat" for Condition, Modifier, CombatProcessor

class Effect is Stateful {
  construct new(ctx, args) {
    super(args)
    _ctx = ctx
    _events = []
  }

  ctx { _ctx }
  events { _events }

  perform() { Fiber.abort("Abstract effect has no perform action") }
  addEvent(event) { _events.add(event) }
  addEvents(events) { _events.addAll(events) }
}

#!component(id="meleeDamage", group="effect")
class MeleeDamageEffect is Effect {
  construct new(ctx, args) {
    super(ctx, args)
  }

  damage { data["damage"] }
  target { data["target"] }
  src { data["src"] }

  perform() {
    var defeatEvents = []
    var killEvents = []
    var result = CombatProcessor.calculate(src, target)
    if (result[0]) {
      defeatEvents.add(Components.events.defeat.new(src, target))
    }
    if (result[1]) {
      ctx.zone.map[target.pos]["blood"] = true
      killEvents.add(Components.events.kill.new(src, target))
    }
    addEvents(defeatEvents + killEvents)
  }
}

#!component(id="directDamage", group="effect")
class DirectDamageEffect is Effect {
  construct new(ctx, args) {
    super(ctx, args)
  }

  damage { data["damage"] }
  target { data["target"] }
  src { data["src"] }

  perform() {
    var defeatEvents = []
    var killEvents = []
    var result = CombatProcessor.directDamage(src, target, damage)
    if (result[0]) {
      defeatEvents.add(Components.events.defeat.new(src, target))
    }
    if (result[1]) {
      ctx.zone.map[target.pos]["blood"] = true
      killEvents.add(Components.events.kill.new(src, target))
    }
    addEvents(defeatEvents + killEvents)
  }
}

// Heals <target> for <amount> (percentage of their total)
#!component(id="heal", group="effect")
class HealEffect is Effect {
  construct new(ctx, args) {
    super(ctx, args)
  }

  amount { data["amount"] }
  target { data["target"] }

  perform() {
    var hpMax = target["stats"].get("hpMax")
    var total = (amount * hpMax).ceil
    var amount = target["stats"].increase("hp", total, "hpMax")
    addEvent(Components.events.heal.new(target, amount))
  }
}

// Applies a stat modifier to <target>
#!component(id="applyModifier", group="effect")
class ApplyModifierEffect is Effect {
  construct new(ctx, args) {
    super(ctx, args)
  }

  src { data["src"] }
  target { data["target"] }
  modifier { data["modifier"] }

  perform() {
    System.print(modifier)
    var stats = target["stats"]
    var mod = Modifier.new(modifier["id"], modifier["add"], modifier["mult"], modifier["duration"], modifier["positive"])
    stats.addModifier(mod)
    addEvent(Components.events.applyModifier.new(src, target, modifier["id"]))
  }
}
// Applies a condition to <target>
#!component(id="applyCondition", group="effect")
class ApplyConditionEffect is Effect {
  construct new(ctx, args) {
    super(ctx, args)
  }

  src { data["src"] }
  target { data["target"] }
  condition { data["condition"] }
  curable { condition["curable"] }
  duration { condition["duration"] }
  id { condition["id"] }

  perform() {
    if (target["conditions"].containsKey(id)) {
      target["conditions"][id].extend(duration)
      addEvent(Components.events.extendCondition.new(target, id))
    } else {
      target["conditions"][id] = Condition.new(id, duration, curable)
      addEvent(Components.events.inflictCondition.new(target, id))
    }
  }
}
