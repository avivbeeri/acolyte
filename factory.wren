import "meta" for Meta
import "json" for Json
import "entities" for Creature
import "math" for Vec
import "messages" for Pronoun
import "combat" for Condition
import "groups" for Behaviours, Actions
import "items" for GenericItem
import "parcel" for DataFile, Reflect, Stateful

var CreatureData = DataFile.load("creatures", "data/creatures.json")
var ItemData = DataFile.load("items", "data/items.json")

class CreatureFactory {
  static spawn(kindId, zoneIndex, position) {
    var data = CreatureData[kindId]
    var creature = Creature.new(data["stats"])
    creature["pronoun"] = Reflect.get(Pronoun, data["pronoun"])
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
      creature.behaviours.add(Reflect.get(Behaviours, id).new(args))
    }


    return creature
  }
}


class ItemFactory {
  static inflate(id) {
    var data = ItemData[id]

    var item = GenericItem.new(data["id"], data["kind"])

    item["kind"] = data["kind"]
    item["name"] = data["name"]
    item["slot"] = data["slot"]
    item["consumable"] = data["consumable"]

    item["default"] = data["default"]
    item["actions"] = Stateful.copyValue(data["actions"]) || {}
    for (entry in data["actions"]) {
      //item["actions"][entry.key] = Stateful.copyValue(entry.value)
      System.print(entry.value)
    }
    for (entry in item["actions"]) {
      var actionName = entry.value["action"]
      var action = Reflect.get(Actions, actionName)
      item["actions"][entry.key]["action"] = action
    }
    return item
  }

  static getAll() {
    var out = {}
    for (id in ItemData.keys) {
      out[id] = ItemFactory.inflate(id)
    }
    return out
  }
}
