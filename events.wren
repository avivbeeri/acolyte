import "parcel" for Event

class ConditionEvent is Event {
  construct new(target, condition) {
    super()
    data["src"] = target
    data["condition"] = condition
  }
  target { data["src"] }
  condition { data["condition"] }
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

class RestEvent is Event {
  construct new(src) {
    super()
    data["src"] = src
  }

  src { data["src"] }
}

class Events {
  static rest { RestEvent }
  static pickup { PickupEvent }
  static useItem { UseItemEvent }
  static extendCondition { ExtendConditionEvent }
  static inflictCondition { InflictConditionEvent }
  static lightningCondition { LightningEvent }
}
