import "parcel" for Action, ActionResult, Stateful, Log
import "./actions" for HealAction, LightningAttackAction
import "./events" for PickupEvent, UseItemEvent

class InventoryEntry is Stateful {
  construct new(id, count) {
    super()
    data["id"] = id
    data["qty"] = count
  }

  subtract(i) {
    data["qty"] = (data["qty"] - i).max(0)
  }
  add(i) {
    data["qty"] = (data["qty"] + i).max(0)
  }

  id { data["id"] }
  qty { data["qty"] }
  qty=(v) { data["qty"] = v }
}

class PickupAction is Action {
  construct new() {
    super()
  }
  evaluate() {
    var items = ctx.zone.map[src.pos]["items"]
    if (!src["inventory"]) {
      return ActionResult.invalid
    }
    if (!items || items.count == 0) {
      return ActionResult.invalid
    }
    return ActionResult.valid
  }

  perform() {
    var items = ctx.zone.map[src.pos]["items"]
    var inventory = src["inventory"]
    for (item in items) {
      var existing = inventory.where {|entry| entry.id == item.id }.toList
      if (existing.isEmpty) {
        inventory.add(item)
      } else {
        System.print(item.qty)
        existing[0].add(item.qty)
      }
      ctx.addEvent(PickupEvent.new(src, item.id, item.qty))
    }
    items.clear()
    return ActionResult.success
  }
}

class ItemAction is Action {
  construct new(id) {
    super()
    _itemId = id
    _itemAction = null
  }

  evaluate() {
    var entries = src["inventory"].where {|entry| entry.id == _itemId }
    if (entries.count <= 0) {
      return ActionResult.invalid
    }

    var entry = entries.toList[0]
    if (entry.qty <= 0) {
      return ActionResult.invalid
    }

    var result = null
    var action = ctx["items"][_itemId].default
    while (true) {
      result = action.bind(src).evaluate()
      if (result.invalid) {
        break
      }
      if (!result.alternate) {
        break
      }
      action = result.alternate
    }
    _itemAction = action
    return result
  }

  perform() {
    var entries = src["inventory"].where {|entry| entry.id == _itemId }
    if (entries.count <= 0) {
      return ActionResult.failure
    }
    // subtract from inventory
    var entry = entries.toList[0]
    if (entry.qty <= 0) {
      return ActionResult.failure
    }
    var item = ctx["items"][_itemId]
    if (item.consumable) {
      entry.subtract(1)
    }

    Log.d("%(src) using %(item.name)")
    Log.d("%(src): performing %(_itemAction)")
    ctx.addEvent(UseItemEvent.new(src, _itemId))
    return _itemAction.bind(src).perform()
  }
}

class Item is Stateful {
  construct new() {
    super()
  }

  consumable { true }
  name { data["name"] || this.type.name }
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
    data["name"] = "Health Potion"
  }

  default { drink }
  drink { HealAction.new(null, 1) }
}
class LightningScroll is Item {
  construct new() {
    super()
    data["name"] = "Lightning Scroll"
  }

  default { use }
  use { LightningAttackAction.new(8, 2) }
}

class Items {
  static healthPotion { HealthPotion.new() }
  static lightningScroll { LightningScroll.new() }
}

