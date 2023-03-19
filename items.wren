import "parcel" for Action, ActionResult, Stateful, Log
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
  evaluate() {
    if (src["inventory"].isEmpty || !src["inventory"].any {|entry| entry.id == _itemId } ) {
      return ActionResult.invalid
    }
    return ActionResult.valid
  }

  perform() {
    var tile = ctx.zone.map[src.pos]
    var inventory = src["inventory"]
    var existing = inventory.where {|entry| entry.id == _itemId }.toList

    existing[0].subtract(1)

    var found = false
    for (entry in (tile["items"] || [])) {
      if (entry.id == _itemId) {
        entry.add(1)
        found = true
        break
      }
    }
    if (!found) {
      tile["items"] = tile["items"] || []
      tile["items"].add(InventoryEntry.new(_itemId, 1))
    }

    ctx.addEvent(Events.drop.new(src, _itemId, 1, src.pos))
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
      ctx.addEvent(Events.pickup.new(src, item.id, item.qty))
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
    if (!(item is Equipment)) {
      return ActionResult.invalid
    }

    return ActionResult.valid
  }

  perform() {
    var existingItemId = src["equipment"][_slot]
    var item = ctx["items"][existingItemId]
    item.onUnequip(src)
    ctx.addEvent(Events.unequipItem.new(src, _itemId))
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
    if (!(item is Equipment)) {
      return ActionResult.invalid
    }

    return ActionResult.valid
  }

  perform() {
    var item = ctx["items"][_itemId]
    var existingItemId = src["equipment"][item.slot]
    if (existingItemId != null) {
      var existingItem = ctx["items"][existingItemId]
      existingItem.onUnequip(src)
      ctx.addEvent(Events.unequipItem.new(src, existingItemId))
    }

    src["equipment"][item.slot] = _itemId
    ctx.addEvent(Events.equipItem.new(src, _itemId))
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
    ctx.addEvent(Events.useItem.new(src, _itemId))
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

  query(action) { data["actions"][action] || {} }

  default(actor, args) { use(args) }
  use(args) { Fiber.abort("%(name) doesn't support action 'use'") }
  equip(args) { Fiber.abort("%(name) doesn't support action 'equip'") }
  unequip(args) { Fiber.abort("%(name) doesn't support action 'equip'") }
  attack(args) { Fiber.abort("%(name) doesn't support action 'attack'") }
  defend(args) { Fiber.abort("%(name) doesn't support action 'defend'") }
  drink(args) { Fiber.abort("%(name) doesn't support action 'drink'") }
  throw(args) { Fiber.abort("%(name) doesn't support action 'throw'")}
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

class Equipment is Item {
  construct new(id, kind, slot, stats) {
    super(id, kind)
    data["slot"] = slot
    data["stats"] = stats
  }

  slot { data["slot"] }
  consumable { false }

  default(actor, args) {
    if (actor["equipment"][slot] == id) {
      return unequip(args)
    } else {
      return equip(args)
    }
  }
  equip(args) { EquipItemAction.new(id) }
  unequip(args) { UnequipItemAction.new(slot) }
}

class StatBoostEquipment is Equipment {
  construct new(id, kind, slot, stats) {
    super(id, kind, slot, stats)
    data["name"] = TextSplitter.capitalize(id)
  }

  onEquip(actor) {
    actor["stats"].addModifier(Modifier.new(
      slot,
      data["stats"]["add"],
      data["stats"]["mult"],
      null,
      true
    ))
  }
  onUnequip(actor) {
    actor["stats"].removeModifier(slot)
  }
}

class Shield is StatBoostEquipment {
  construct new(name, value) {
    super(name, "shield", EquipmentSlot.offhand, {
      "add": {
        "def": value
      }
    })
  }
}

class Armor is StatBoostEquipment {
  construct new(name, value) {
    super(name, "armor", EquipmentSlot.armor, {
      "add": {
        "def": value
      }
    })
  }
}

class Sword is StatBoostEquipment {
  construct new(name, value) {
    super(name, "sword", EquipmentSlot.weapon, {
      "add": {
        "atk": value
      }
    })
  }
}

class HealthPotion is Item {
  construct new() {
    super("potion", "potion")
    data["name"] = "Health Potion"
  }

  default(actor, args) { drink(args) }
  drink(args) { HealAction.new(null, 0.25) }
}
class LightningScroll is Item {
  construct new() {
    super("scroll", "scroll")
    data["name"] = "Lightning Scroll"
  }

  use(args) { LightningAttackAction.new(8, 2) }
}

class ConfusionScroll is Item {
  construct new() {
    super("wand", "scroll")
    data["name"] = "Confusion Scroll"
  }

  use(args) { InflictConfusionAction.new(args[0]) }
  query(action) {
    if (action == "use") {
      return {
        "target": true,
        "range": 8,
        "area": 1,
        "needEntity": true
      }
    }
    return null
  }

}
class FireballScroll is Item {
  construct new() {
    super("fireball", "scroll")
    data["name"] = "Fireball Scroll"
  }

  // (origin, range, damage)
  use(args) { AreaAttackAction.new(args[0], args[1], 5) }
  query(action) {
    if (action == "use") {
      return {
        "target": true,
        "range": 8,
        "area": 2,
        "needEntity": false
      }
    }
    return null
  }
}

class Items {
  static findable {
    return [
      healthPotion,
      lightningScroll,
      confusionScroll,
      fireballScroll,
      shortsword,
      longsword,
      chainmail,
      platemail,
      buckler
    ]
  }
  static all {
    return findable + [
      dagger,
      leatherArmor
    ]
  }

  static healthPotion { HealthPotion.new() }
  static lightningScroll { LightningScroll.new() }
  static confusionScroll { ConfusionScroll.new() }
  static fireballScroll { FireballScroll.new() }
  static dagger { Sword.new("dagger", 1) }
  static shortsword { Sword.new("shortsword", 2) }
  static longsword { Sword.new("longsword", 3) }
  static leatherArmor { Armor.new("leather armor", 1) }
  static chainmail { Armor.new("chainmail", 2) }
  static platemail { Armor.new("platemail", 3) }
  static buckler { Shield.new("buckler", 1) }
}

import "./actions" for HealAction, LightningAttackAction, InflictConfusionAction, AreaAttackAction
import "./events" for Events
import "./combat" for Modifier
