import "parcel" for Entity, BehaviourEntity, GameSystem, JPS, Stateful, DIR_EIGHT, RNG, Action, Set
import "math" for Vec, M

class Creature is BehaviourEntity {
  construct new() {
    super()
    this["symbol"] = "?"
    this["solid"] = true
    this["inventory"] = [
    ]
    this["stats"] =  StatGroup.new({
      "hpMax": 1,
      "hp": 1,
      "str": 1,
      "dex": 0
    })
    this["conditions"] = {}
  }
  name { "Creature" }
  pronoun { Pronoun.it }
}

class Player is Creature {
  construct new() {
    super()
    this["symbol"] = "@"
    this["inventory"] = [
      InventoryEntry.new("potion", 1)
    ]
    this["stats"] =  StatGroup.new({
      "hpMax": 5,
      "hp": 5,
      "str": 1,
      "dex": 1
    })
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
    super()
    this["symbol"] = "r"
    this["stats"] =  StatGroup.new({
      "hpMax": 1,
      "hp": 1,
      "str": 1,
      "dex": 1
    })

    behaviours.add(SeekBehaviour.new())
  }
  name { "Rat" }
  pronoun { Pronoun.it }
}

import "behaviour" for SeekBehaviour
import "items" for InventoryEntry
import "combat" for StatGroup
import "messages" for Pronoun
