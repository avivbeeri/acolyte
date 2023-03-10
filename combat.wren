import "math" for M
import "parcel" for Action, ActionResult, Event, Stateful

class HealEvent is Event {
  construct new(entity, amount) {
    super()
    _src = entity
    _amount = amount
  }
  target { _src }
  amount { _amount }
}

class KillEvent is Event {
  construct new(src, target) {
    super()
    _src = src
    _target = target
  }
  src { _src }
  target { _target }
}

class DefeatEvent is Event {
  construct new(src, target) {
    super()
    _src = src
    _target = target
  }
  src { _src }
  target { _target }
}
class AttackEvent is Event {
  construct new(src, target, attack, result) {
    super()
    data["src"] = src
    data["target"] = target
    data["attack"] = attack
    data["result"] = result
  }

  src { data["src"] }
  target { data["target"] }
  attack { data["attack"] }
  result { data["result"] }
}

class Damage {
  static calculate(atk, def) {
    var o1 = atk * 2 - def
    var o2 = (atk * atk) / def
    if (atk > def) {
      return o1.round
    }
    if (!o2.isNan) {
      return o2.round
    }
    return 0
  }
}

class AttackResult {
  static success { "success" }
  static blocked { "blocked" }
  static missed { "missed" }
  static inert { "inert" }
}

class AttackType {
  static melee { "basic" }

  static verify(text) {
    if (text == "basic") {
      return text
    }
    Fiber.abort("unknown AttackType: %(text)")
  }
}

class Attack {
  construct new(damage, attackType) {
    _damage = damage
    _attackType = AttackType.verify(attackType)
  }

  damage { _damage }
  attackType { _attackType }

  static melee(entity) {
    return Attack.new(entity["stats"].get("atk"), AttackType.melee)
  }
}

class StatGroup {
  construct new(statMap) {
    _base = statMap
    _mods = {}
  }

  modifiers { _mods }

  addModifier(mod) {
    _mods[mod.id] = mod
  }
  hasModifier(id) {
    return _mods.containsKey(id)
  }
  getModifier(id) {
    return _mods[id]
  }
  removeModifier(id) {
    _mods.remove(id)
  }

  base(stat) { _base[stat] }
  set(stat, value) { _base[stat] = value }
  decrease(stat, by) { _base[stat] = _base[stat] - by }
  increase(stat, by) { _base[stat] = _base[stat] + by }
  increase(stat, by, maxStat) { _base[stat] = M.mid(0, _base[stat] + by, _base[maxStat]) }

  has(stat) { _base[stat] }
  [stat] { get(stat) }
  get(stat) {
    var value = _base[stat]
    if (value == null) {
      Fiber.abort("Stat %(stat) does not exist")
    }
    var multiplier = 0
    var total = value || 0
    for (mod in _mods.values) {
      total = total + (mod.add[stat] || 0)
      multiplier = multiplier + (mod.mult[stat] || 0)
    }
    return M.max(0, total + total * multiplier)
  }

  print(stat) {
    return "%(stat)>%(base(stat)):%(get(stat))"
  }

  tick() {
    for (modifier in _mods.values) {
      if (modifier.done) {
        removeModifier(modifier.id)
      }
    }
  }
}

/**
  Represent a condition
 */

class Condition is Stateful {
  construct new(id, duration, curable) {
    super()
    data["id"] = id
    data["duration"] = duration
    data["curable"] = curable
  }

  id { data["id"] }
  duration { data["duration"] }
  duration=(v) { data["duration"] = v }
  curable { data["curable"] }

  tick() {
    duration = duration ? duration - 1 : null
  }
  done { duration && duration <= 0 }
  hash() { id }

  extend(n) {
    if (duration != null) {
      duration = (duration  || 0) + n
    }
  }
}

/**
  Represent arbitrary modifiers to multiple stats at once
  Modifiers can be additive or multiplicative.
  Multipliers are a "percentage change", so +0.5 adds 50% of base to the value.
*/
class Modifier {
  construct new(id, add, mult, duration, positive) {
    _id = id
    _add = add || {}
    _mult = mult || {}
    _duration = duration || null
    _positive = positive || false
  }

  id { _id }
  add { _add }
  mult { _mult }
  duration { _duration }
  positive { _positive }

  tick() {
    _duration = _duration ? _duration - 1 : null
  }
  done { _duration && _duration <= 0 }

  extend(n) {
    if (_duration != null) {
      _duration = (_duration  || 0) + n
    }
  }
}


class CombatProcessor {
  static calculate(src, target) { calculate(src, target, null) }
  static calculate(src, target, damage) {
    if (damage == null) {
      var srcStats = src["stats"]
      var targetStats = target["stats"]
      srcStats.set("atk", srcStats["str"])
      targetStats.set("def", srcStats["dex"])
      var atk = srcStats.get("atk")
      var def = targetStats.get("def")
      damage = Damage.calculate(atk, def)
    }
    var defeat = false
    var kill = false
    var ctx = src.ctx
    var killThreshold = target["stats"]["hpMax"] * 2
    if (damage >= killThreshold || target["conditions"].containsKey("unconscious")) {
      kill = true
      ctx.removeEntity(target)
    } else {
      target["stats"].decrease("hp", damage)
      if (target["stats"].get("hp") <= 0) {
        target["stats"].set("hp", 0)
        defeat = true
      }
    }
    ctx.addEvent(AttackEvent.new(src, target, "area", damage))
    return [defeat, kill]
  }

}
