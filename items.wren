import "parcel" for Action, ActionResult
import "./actions" for HealAction

class ItemAction is Action {
  construct new(item) {
    super()
    _item = item
  }

  evaluate() {
    return _item.default.bind(src).evaluate()
  }

  perform() {
    return _item.default.bind(src).perform()
  }
}

class Item {
  construct new() {
  }

  consumable { true }
  name { this.type.name }
  toString { name }

  default {}

  use {}
  attack {}
  defend {}
  drink {}
  throw {}
}

class HealthPotion is Item {
  construct new() {
    super()
  }

  default { HealAction.new(null, 1) }
  name { "Health Potion"}
}

