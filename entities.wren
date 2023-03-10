import "parcel" for Entity, BehaviourEntity, GameSystem, JPS, Stateful, DIR_EIGHT, RNG, Action, Set
import "math" for Vec, M

class Creature is BehaviourEntity {
  construct new(stats) {
    super()
    this["symbol"] = "?"
    this["solid"] = true
    this["inventory"] = [
    ]
    this["equipment"] = {}
    this["stats"] =  StatGroup.new({
      "hpMax": 1,
      "hp": 1,
      "atk": 0,
      "def": 0,
      "str": 1,
      "dex": 1,
      "xp": 0
    })
    for (entry in stats) {
      this["stats"].set(entry.key, entry.value)
    }
    this["conditions"] = {}
  }
  name { "Creature" }
  pronoun { Pronoun.it }
}

class Player is Creature {
  construct new() {
    super({
      "hpMax": 5,
      "hp": 5
    })
    this["symbol"] = "@"
    this["inventory"] = [
      InventoryEntry.new("potion", 1)
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


class Rat is Creature {
 construct new() {
    super({
      "hpMax": 1,
      "hp": 1
    })
    this["symbol"] = "r"

    behaviours.add(SeekBehaviour.new())
  }
  name { "Rat" }
  pronoun { Pronoun.it }
}

import "behaviour" for SeekBehaviour
import "items" for InventoryEntry
import "combat" for StatGroup
import "messages" for Pronoun
