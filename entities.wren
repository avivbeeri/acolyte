import "parcel" for BehaviourEntity, DIR_EIGHT, RNG, Action, Dijkstra
import "math" for M

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
    this["pronoun"] = Pronoun.it
  }
  pronoun { this["pronoun"] }
  speed { 1 / this["stats"]["spd"] }
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
      InventoryEntry.new("book", 1),
      InventoryEntry.new("slow", 1),
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

import "items" for InventoryEntry, EquipmentSlot
import "combat" for StatGroup, Condition
import "messages" for Pronoun
