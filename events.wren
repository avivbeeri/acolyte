import "parcel" for Event
import "combat" for HealEvent, DefeatEvent, AttackEvent, KillEvent
import "meta" for Meta

var ApplyModifier = Event.create("ApplyModifier", ["target", "modifierName"])
var ConditionEvent = Event.create("Condition", ["target", "condition"])
var ClearConditionEvent = Event.create("ClearCondition", ["target", "condition"])
var ExtendConditionEvent = Event.create("ExtendCondition", ["target", "condition"])
var InflictConditionEvent = Event.create("InflictCondition", ["target", "condition"])
var LightningEvent = Event.create("Lightning", ["target"])
var UnequipItemEvent = Event.create("UnequipItem", ["src", "item"])
var EquipItemEvent = Event.create("EquipItem", ["src", "item"])
var UseItemEvent = Event.create("UseItem", ["src", "item"])
var DropEvent = Event.create("Drop", ["src", "item", "qty", "pos"])
var PickupEvent = Event.create("Pickup", ["src", "item", "qty"])

class MoveEvent is Event {
  construct new(src, origin) {
    super()
    data["src"] = src
    data["origin"] = origin
  }

  src { data["src"] }
  origin { data["origin"] }
}
class StatueAwakenEvent is Event {
  construct new(src) {
    super()
    data["src"] = src
  }

  src { data["src"] }
}
class PrayEvent is Event {
  construct new(src) {
    super()
    data["src"] = src
  }

  src { data["src"] }
}
class RestEvent is Event {
  construct new(src) {
    super()
    data["src"] = src
  }

  src { data["src"] }
}
class DescendEvent is Event {
  construct new() {
    super()
  }
}
class StoryEvent is Event {
  construct new(moment) {
    super()
    data["moment"] = moment
  }

  moment { data["moment"] }
}

class Events {
  static story { StoryEvent }
  static rest { RestEvent }
  static pray { PrayEvent }
  static pickup { PickupEvent }
  static drop { DropEvent }
  static useItem { UseItemEvent }
  static equipItem { EquipItemEvent }
  static unequipItem { UnequipItemEvent }
  static extendCondition { ExtendConditionEvent }
  static inflictCondition { InflictConditionEvent }
  static clearCondition { ClearConditionEvent }
  static lightningCondition { LightningEvent }
  static descend { DescendEvent }
  static attack { AttackEvent }
  static heal { HealEvent }
  static defeat { DefeatEvent }
  static kill { KillEvent }
  static move { MoveEvent }
  static statueAwaken { StatueAwakenEvent }
}
