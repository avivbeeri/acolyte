import "parcel" for Event
import "combat" for HealEvent, DefeatEvent, AttackEvent, KillEvent

class ConditionEvent is Event {
  construct new(target, condition) {
    super()
    data["src"] = target
    data["condition"] = condition
  }
  target { data["src"] }
  condition { data["condition"] }
}
class ClearConditionEvent is ConditionEvent {
  construct new(target, condition) {
    super(target, condition)
  }
}
class ExtendConditionEvent is ConditionEvent {
  construct new(target, condition) {
    super(target, condition)
  }
}
class InflictConditionEvent is ConditionEvent {
  construct new(target, condition) {
    super(target, condition)
  }
}

class LightningEvent is Event {
  construct new(target) {
    super()
    data["src"] = target
  }
  target { data["src"] }
}

class UnequipItemEvent is Event {
  construct new(src, itemId) {
    super()
    data["src"] = src
    data["item"] = itemId
  }

  src { data["src"] }
  item { data["item"] }
}
class EquipItemEvent is Event {
  construct new(src, itemId) {
    super()
    data["src"] = src
    data["item"] = itemId
  }

  src { data["src"] }
  item { data["item"] }
}

class UseItemEvent is Event {
  construct new(src, itemId) {
    super()
    data["src"] = src
    data["item"] = itemId
  }

  src { data["src"] }
  item { data["item"] }
}

class PickupEvent is Event {
  construct new(src, itemId, qty) {
    super()
    data["src"] = src
    data["item"] = itemId
    data["qty"] = qty
  }

  src { data["src"] }
  item { data["item"] }
  qty { data["qty"] }
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

class Events {
  static rest { RestEvent }
  static pray { PrayEvent }
  static pickup { PickupEvent }
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
}
