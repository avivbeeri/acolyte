import "entities" for Creature
import "math" for Vec
import "messages" for Pronoun
import "combat" for Condition
import "behaviour" for Behaviours

var ratData = {
  "kind": "rat",
  "name": "Rat",
  "symbol": "r",
  "behaviours": [
    ["wander"]
  ],
  "stats": {
    "hpMax": 1,
    "hp": 1
  },
  "pronoun": "it"
}
var houndData = {
  "kind": "hound",
  "name": "Hound",
  "symbol": "d",
  "behaviours": [
    ["seek", 7]
  ],
  "stats": {
    "hpMax": 4,
    "hp": 4,
    "dex": 2,
    "atk": 2
  },
  "pronoun": "it"
}
var zombieData = {
  "kind": "zombie",
  "name": "Zombie",
  "symbol": "z",
  "behaviours": [
    ["localSeek", 7]
  ],
  "stats": {
    "hpMax": 2,
    "hp": 2,
    "spd": 0.5,
    "dex": 1,
    "atk": 3
  },
  "pronoun": "it"
}
var statueData = {
  "kind": "statue",
  "name": "Statue",
  "symbol": "£",
  "behaviours": [
    ["statue"]
  ],
  "stats": {
    "def": 10, // make this absurdly high
  },
  "pronoun": "it"
}
var gargoyleData = {
  "kind": "gargoyle",
  "name": "Statue",
  "symbol": "?",
  "behaviours": [
    ["statue"]
  ],
  "stats": {
    "hpMax": 5,
    "hp": 5,
    "dex": 4,
    "str": 3
  },
  "butter": true,
  "pronoun": "it",
  "frozen": true
}
var demonData = {
  "kind": "demon",
  "boss": true,
  "name": "????",
  "symbol": "?",
  "behaviours": [
    ["boss"]
  ],
  "conditions": [
    ["invulnerable", null, null]
  ],
  "stats": {
    "hpMax": 5,
    "hp": 5,
    "dex": 3,
    "str": 3
  },
  "size": [3, 3],
  "butter": true,
  "pronoun": "they"
}

var CreatureData = {
  "rat": ratData,
  "hound": houndData,
  "demon": demonData,
  "gargoyle": gargoyleData,
  "statue": statueData,
  "zombie": zombieData
}

class CreatureFactory {
  static spawn(kindId, zoneIndex, position) {
    var data = CreatureData[kindId]
    var creature = Creature.new(data["stats"])
    creature["pronoun"] = Pronoun[data["pronoun"]]
    creature["name"] = data["name"]
    creature["kind"] = data["kind"]
    creature["symbol"] = data["symbol"]
    creature["butter"] = data["butter"]
    creature["frozen"] = data["frozen"]
    creature["boss"] = data["boss"]
    if (creature["frozen"]) {
      creature["frozenTimer"] = 0
    }

    creature.pos = position * 1
    creature.zone = zoneIndex
    var size = data["size"]
    creature.size = size ? Vec.new(size[0], size[1]) : Vec.new(1, 1)

    creature["conditions"] = {}
    for (condition in (data["conditions"] || [])) {
      System.print(condition)
      creature["conditions"][condition[0]] = Condition.new(condition[0], condition[1], condition[2])
    }
    var behaviours = data["behaviours"] || []
    for (behaviour in behaviours) {
      var id = behaviour[0]
      var args = behaviour.count > 1 ? behaviour[1..-1] : []
      creature.behaviours.add(Behaviours.get(id).new(args))
    }


    return creature
  }
}
