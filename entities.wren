import "parcel" for Entity, BehaviourEntity, GameSystem, JPS, Stateful, DIR_EIGHT, RNG, Action, Set
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
      "hpMax": 5,
      "hp": 5,
      "piety": 5,
      "pietyMax": 5
    })
    this["symbol"] = "@"
    this["inventory"] = [
      InventoryEntry.new("fireball", 1)
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
}


class Hound is Creature {
 construct new() {
    super({
      "hpMax": 3,
      "hp": 3,
      "dex": 0
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
class Demon is Creature {
 construct new() {
    super({
      "hpMax": 10,
      "hp": 10
    })
    this["size"] = Vec.new(2, 2)
    this["symbol"] = "D"
    this["boss"] = true // allow multiple boss types

    behaviours.add(Behaviours.boss.new())
  }
  name { "Demon" }
  pronoun { Pronoun.they }
}


class Creatures {
  // Non-boss
  static standard { [ Rat, Hound ]}
  // With bosses
  static all { standard + [ Demon ]}

  static rat { Rat }
  static hound { Hound }
  static demon { Demon }

  /*
  static gargoyle { Gargoyle }
  static vampire { Vampire }
  */
}

import "behaviour" for Behaviours
import "items" for InventoryEntry
import "combat" for StatGroup
import "messages" for Pronoun
