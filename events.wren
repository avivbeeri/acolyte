import "parcel" for Event
//import "combat" for HealEvent, DefeatEvent, AttackEvent, KillEvent
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
var MoveEvent = Event.create("Move", ["src", "origin"])
var StatueAwakenEvent = Event.create("StatueAwaken", ["src"])
var PrayEvent = Event.create("Pray", ["src"])
var RestEvent = Event.create("Rest", ["src"])
var DescendEvent = Event.create("Descend", [])
var StoryEvent = Event.create("Story", ["moment"])
var HealEvent = Event.create("Heal", ["target", "amount"])
var DefeatEvent = Event.create("Defeat", ["src", "target"])
var AttackEvent = Event.create("Attack", ["src", "target", "attack", "result", "damage"])

/*
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
*/
