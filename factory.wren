import "json" for Json
import "entities" for Creature
import "math" for Vec
import "messages" for Pronoun
import "combat" for Condition
import "behaviour" for Behaviours
import "parcel" for DataFile, Reflect

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

    item["consumable"] = data["consumable"]
    item["kind"] = data["kind"]
    item["name"] = data["name"]
    item["default"] = data["default"]
    item["actions"] = data["actions"] || {}
    for (entry in data["actions"]) {
      item["actions"][entry.key] = Stateful.copyValue(entry.value)
    }
    for (action in item["actions"].values) {
      action["action"] = Actions.get(action["action"])
    }

    return item

  }
}
