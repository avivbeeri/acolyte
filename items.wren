import "parcel" for Action, ActionResult, Stateful, Log, Reflect
import "text" for TextSplitter

class EquipmentSlot {
  static weapon { "WEAPON" }
  static armor { "ARMOR" }
  static offhand { "OFF_HAND" }
  static trinket { "TRINKET" }
}

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

#!component(id="drop", group="action")
class DropAction is Action {
  construct new(id) {
    super()
    _itemId = id
  }

  itemId { data["id"] }

  evaluate() {
    if (src["inventory"].isEmpty || !src["inventory"].any {|entry| entry.id == itemId } ) {
      return ActionResult.invalid
    }
    return ActionResult.valid
  }

  perform() {
    var tile = ctx.zone.map[src.pos]
    var inventory = src["inventory"]
    var existing = inventory.where {|entry| entry.id == itemId }.toList

    existing[0].subtract(1)

    var found = false
    for (entry in (tile["items"] || [])) {
      if (entry.id == itemId) {
        entry.add(1)
        found = true
        break
      }
    }
    if (!found) {
      tile["items"] = tile["items"] || []
      tile["items"].add(InventoryEntry.new(itemId, 1))
    }

    ctx.addEvent(Components.events.drop.new(src, itemId, 1, src.pos))
    return ActionResult.success
  }
}
#!component(id="pickup", group="action")
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
        existing[0].add(item.qty)
      }
      ctx.addEvent(Components.events.pickup.new(src, item.id, item.qty))
    }
    items.clear()
    return ActionResult.success
  }
}

#!component(id="unequipItem", group="action")
class UnequipItemAction is Action {
  construct new(slot) {
    super()
    _slot = slot
  }

  evaluate() {
    _itemId = src["equipment"][_slot]
    var item = ctx["items"][_itemId]
    if (!item.slot) {
      return ActionResult.invalid
    }

    return ActionResult.valid
  }

  perform() {
    var existingItemId = src["equipment"][_slot]
    var item = ctx["items"][existingItemId]
    item.onUnequip(src)
    ctx.addEvent(Components.events.unequipItem.new(src, _itemId))
    src["equipment"][_slot] = null
    return ActionResult.success
  }
}

#!component(id="equipItem", group="action")
class EquipItemAction is Action {
  construct new(id) {
    super()
    _itemId = id
  }
  withArgs(args) {
    _itemId = args["id"] || _itemId
    return this
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
    var item = ctx["items"][_itemId]
    if (!item.slot) {
      return ActionResult.invalid
    }
    if (src["equipment"][item.slot] == item.id) {
      return ActionResult.alternate(UnequipItemAction.new(item.slot))
    }

    return ActionResult.valid
  }

  perform() {
    var item = ctx["items"][_itemId]
    var existingItemId = src["equipment"][item.slot]
    if (existingItemId != null) {
      var existingItem = ctx["items"][existingItemId]
      existingItem.onUnequip(src)
      ctx.addEvent(Components.events.unequipItem.new(src, existingItemId))
    }

    src["equipment"][item.slot] = _itemId
    ctx.addEvent(Components.events.equipItem.new(src, _itemId))
    item.onEquip(src)
    return ActionResult.success
  }
}

#!component(id="item", group="action")
class ItemAction is Action {
  construct new(id) {
    super()
    _itemId = id
    _itemAction = null
    _args = null
  }
  construct new(id, args) {
    super()
    _itemId = id
    _itemAction = null
    _args = args
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
    if (!ctx["items"][_itemId]["default"]) {
      return ActionResult.invalid
    }
    var action = ctx["items"][_itemId].default(src, _args)
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
    ctx.addEvent(Components.events.useItem.new(src, _itemId))
    return _itemAction.bind(src).perform()
  }
}

class GenericItem is Stateful {
  construct new(id, kind) {
    super()
    data["id"] = id
    data["kind"] = kind
  }

  static inflate(data) {
    var item = GenericItem.new(data["id"], data["kind"])
    for (entry in data) {
      item[entry.key] = entry.value
    }
    return item
  }

  id { data["id"] }
  kind { data["kind"] }

  slot { data["slot"] }
  consumable { data["consumable"] }

  name { data["name"] || kind || this.type.name }
  toString { name }

  query(action) { data["actions"][action] }

  default(actor, args) {
    var action = data["default"]
    System.print("default action is %(action)")
    return Reflect.call(this, action, args)
  }
  use(args) { data["actions"]["use"]["action"].new().withArgs(args) }
  drink(args) { data["actions"]["drink"]["action"].new().withArgs(args) }
  throw(args) { data["actions"]["throw"]["action"].new().withArgs(args) }
  attack(args) { data["actions"]["attack"]["action"].new().withArgs(args) }
  defend(args) { data["actions"]["defend"]["action"].new().withArgs(args) }

  equip(args) {
    return EquipItemAction.new(id)
  }
  unequip(args) {
    return UnequipItemAction.new(slot)
  }

  onEquip(actor) {
    var action = data["actions"]["equip"]
    var stats = action["stats"]
    actor["stats"].addModifier(Modifier.new(
      slot,
      stats["add"],
      stats["mult"],
      null,
      true
    ))
  }
  onUnequip(actor) {
    actor["stats"].removeModifier(slot)
  }
}

class Item is Stateful {
  construct new(id, kind) {
    super()
    data["id"] = id
    data["kind"] = kind
  }

  id { data["id"] }
  kind { data["kind"] }

  slot { data["slot"] }
  consumable { data["consumable"] }

  name { data["name"] || this.type.name }
//  toString { name }
  query(action) { {} }

  default(actor, args) { use(args) }

  use(args) { Fiber.abort("%(name) doesn't support action 'use'") }
  equip(args) { Fiber.abort("%(name) doesn't support action 'equip'") }
  unequip(args) { Fiber.abort("%(name) doesn't support action 'equip'") }
  attack(args) { Fiber.abort("%(name) doesn't support action 'attack'") }
  defend(args) { Fiber.abort("%(name) doesn't support action 'defend'") }
  drink(args) { Fiber.abort("%(name) doesn't support action 'drink'") }
  throw(args) { Fiber.abort("%(name) doesn't support action 'throw'")}
}

import "./actions" for HealAction, LightningAttackAction, InflictConfusionAction, AreaAttackAction
//import "./events" for Components
import "./groups" for Components
import "./combat" for Modifier
