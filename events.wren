import "parcel" for Event
//import "combat" for HealEvent, DefeatEvent, AttackEvent, KillEvent
import "meta" for Meta

var ApplyModifier = Event.create("applyModifier", ["target", "modifierName"])
var ConditionEvent = Event.create("condition", ["target", "condition"])
var ClearConditionEvent = Event.create("clearCondition", ["target", "condition"])
var ExtendConditionEvent = Event.create("extendCondition", ["target", "condition"])
var InflictConditionEvent = Event.create("inflictCondition", ["target", "condition"])
var LightningEvent = Event.create("lightning", ["target"])
var UnequipItemEvent = Event.create("unequipItem", ["src", "item"])
var EquipItemEvent = Event.create("equipItem", ["src", "item"])
var UseItemEvent = Event.create("useItem", ["src", "item"])
var DropEvent = Event.create("drop", ["src", "item", "qty", "pos"])
var PickupEvent = Event.create("pickup", ["src", "item", "qty"])
var MoveEvent = Event.create("move", ["src", "origin"])
var StatueAwakenEvent = Event.create("statueAwaken", ["src"])
var PrayEvent = Event.create("pray", ["src"])
var RestEvent = Event.create("rest", ["src"])
var DescendEvent = Event.create("descend", [])
var StoryEvent = Event.create("story", ["moment"])
var HealEvent = Event.create("heal", ["target", "amount"])
var KillEvent = Event.create("kill", ["src", "target"])
var DefeatEvent = Event.create("defeat", ["src", "target"])
var AttackEvent = Event.create("attack", ["src", "target", "attack", "result", "damage"])

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
