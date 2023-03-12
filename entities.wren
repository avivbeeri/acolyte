import "parcel" for Entity, BehaviourEntity, GameSystem, JPS, Stateful, DIR_EIGHT, RNG, Action, Set, Dijkstra
import "math" for Vec, M

class Creature is BehaviourEntity {
  construct new(stats) {
    super()
    this["symbol"] = "?"
    this["solid"] = true
    this["butter"] = false
    this["stats"] =  StatGroup.new({
      "hpMax": 1,
      "hp": 1,
      "spd": 1,
      "atk": 1,
      "def": 1,
      "str": 1,
      "dex": 1,
      "xp": 0
    }) {|stats, stat, value|
      if (stat == "str") {
        stats.set("atk", value)
      }
      if (stat == "dex") {
        stats.set("def", value)
      }
    }
    this["conditions"] = {}

    this["inventory"] = [
    ]
    this["equipment"] = {}
    for (entry in stats) {
      this["stats"].set(entry.key, entry.value)
    }
  }
  name { "Creature" }
  pronoun { Pronoun.it }
}

class Player is Creature {
  construct new() {
    super({
      "hpMax": 10,
      "hp": 10,
      "piety": 5,
      "pietyMax": 5
    })
    this["symbol"] = "@"
    this["equipment"] = {
      EquipmentSlot.weapon: "dagger",
      EquipmentSlot.armor: "leather armor"
    }
    this["inventory"] = [
      InventoryEntry.new("dagger", 1),
      InventoryEntry.new("leather armor", 1),
    ]
  }
  name { data["name"] || "Player" }
  pronoun { Pronoun.you }
  pushAction(action) {
    if (hasActions()) {
      return
    }
    super.pushAction(action)
  }
  getAction() {
    var action = super.getAction()
    if (action == Action.none) {
      return null
    }
    return action
  }
  endTurn() {
    data["map"] = Dijkstra.map(ctx.zone.map, pos)
  }
}


class Zombie is Creature {
 construct new() {
    super({
      "hpMax": 2,
      "hp": 2,
      "spd": 2,
      "dex": 1,
      "atk": 3
    })
    this["symbol"] = "z"

    behaviours.add(Behaviours.localSeek.new(7))
  }
  name { "Zombie" }
  pronoun { Pronoun.it }
}
class Hound is Creature {
 construct new() {
    super({
      "hpMax": 4,
      "hp": 4,
      "dex": 2,
      "atk": 2
    })
    this["symbol"] = "d"

    behaviours.add(Behaviours.seek.new())
  }
  name { "Hound" }
  pronoun { Pronoun.it }
}
class Rat is Creature {
 construct new() {
    super({
      "hpMax": 1,
      "hp": 1
    })
    this["symbol"] = "r"

    behaviours.add(Behaviours.wander.new())
  }
  name { "Rat" }
  pronoun { Pronoun.it }
}

class Gargoyle is Creature {
 construct new() {
    super({
      "hpMax": 5,
      "hp": 5,
      "dex": 4,
      "str": 3
    })
    this["symbol"] = "G"
    this["frozen"] = true
    this["frozenTimer"] = 0
    this["butter"] = true

    behaviours.add(Behaviours.statue.new())
  }
  name { this["frozen"] ? "Statue" : "Gargoyle" }
  pronoun { Pronoun.it }
}

class Demon is Creature {
 construct new() {
    super({
      "hpMax": 5,
      "hp": 5,
      "dex": 3,
      "str": 3
    })
    this["size"] = Vec.new(2, 2)
    this["symbol"] = "?"
    this["boss"] = true // allow multiple boss types
    this["conditions"] = {
      "invulnerable": Condition.new("invulnerable", null, null)
    }

    behaviours.add(Behaviours.boss.new())
  }
  name { "????" }
  pronoun { Pronoun.they }
}


class Creatures {
  // Non-boss
  static standard { [ Rat, Hound, Zombie ]}
  // With bosses
  static all { standard + [ Demon, Gargoyle ]}

  static rat { Rat }
  static hound { Hound }
  static demon { Demon }
  static gargoyle { Gargoyle }
  static zombie { Zombie }

  /*
  static vampire { Vampire }
  */
}

import "behaviour" for Behaviours
import "items" for InventoryEntry, EquipmentSlot
import "combat" for StatGroup, Condition
import "messages" for Pronoun
