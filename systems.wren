import "fov" for Vision, Vision2
import "parcel" for GameSystem, JPS, GameEndEvent, ChangeZoneEvent
import "./entities" for Player, Creatures
import "items" for Equipment
import "combat" for Condition
import "behaviour" for UnconsciousBehaviour

class StorySystem is GameSystem {
  construct new() { super() }
  process(ctx, event) {
    if (event is ChangeZoneEvent && event.floor == 6) {
      ctx["fightBegan"] = true
      ctx.addEvent(Events.story.new("dialogue:beforeBoss"))
    }
    if (ctx["fightBegan"] && event is Events.kill && event.target is Creatures.gargoyle) {
      var stillGargoyles = ctx.entities().any {|entity| entity is Creatures.gargoyle }

      if (!event.target["frozen"] && stillGargoyles) {
        ctx.addEvent(Events.story.new("bossWeaken"))
      }
      if (!stillGargoyles) {
        var demon = ctx.entities().where {|entity| entity is Creatures.demon }.toList[0]
        demon["conditions"].remove("invulnerable")
        demon["name"] = "Demon?"
        demon["symbol"] = "D"
        ctx.addEvent(Events.story.new("bossVulnerable"))
      }
    }
  }
}

class ExperienceSystem is GameSystem {
  construct new() { super() }
  process(ctx, event) {
    if (event is Events.defeat) {
      // Count XP just in case
      event.src["stats"].increase("xp", 1)
    }
  }
}

class InventorySystem is GameSystem {
  construct new() { super() }
  postUpdate(ctx, actor) {
    if (actor.has("inventory")) {
      actor["inventory"] = actor["inventory"].where {|entry| entry.qty > 0 }.toList.sort{|a, b|
        var itemA = ctx["items"][a.id]
        var itemB = ctx["items"][b.id]
        var itemEquipmentA = (itemA is Equipment)
        var itemEquipmentB = (itemB is Equipment)
        var itemEquippedA = (itemEquipmentA && actor["equipment"][itemA.slot] == itemA.id)
        var itemEquippedB = (itemEquipmentB && actor["equipment"][itemB.slot] == itemB.id)
        if (itemEquippedA && !itemEquippedB) {
          return true
        } else if (!itemEquippedA && itemEquippedB) {
          return false
        } else if (itemEquipmentA && !itemEquipmentB) {
          return true
        } else if (!itemEquipmentA && itemEquipmentB) {
          return true
        } else {
          return true
        }
      }
    }
  }
}

class ConditionSystem is GameSystem {
  construct new() { super() }
  postUpdate(ctx, actor) {
    if (!actor.has("conditions")) {
      return
    }
    for (entry in actor["conditions"]) {
      var condition = entry.value
      condition.tick()
      if (condition.done) {
        actor["conditions"].remove(condition.id)
        ctx.addEvent(Events.clearCondition.new(actor, condition.id))
      }
    }
  }
}
class DefeatSystem is GameSystem {
  construct new() { super() }
  process(ctx, event) {
    if (event is Events.defeat) {
      if (event.target["boss"]) {
        ctx.addEvent(GameEndEvent.new(true))
      }
      event.target["killed"] = true
      event.target["solid"] = false
      event.target.behaviours.add(UnconsciousBehaviour.new())
      event.target["conditions"]["unconscious"] = Condition.new("unconscious", 10, true)
    }
    if (event is GameEndEvent) {
      ctx.complete = true
    }
  }
  postUpdate(ctx, actor) {
    var player = ctx.getEntityByTag("player")
    if (!player || player["killed"] || player["stats"]["hp"] <= 0) {
      ctx.addEvent(GameEndEvent.new(false))
    }
  }
}
class VisionSystem is GameSystem {
  construct new() { super() }
  start(ctx) {
    var player = ctx.getEntityByTag("player")
    postUpdate(ctx, player)
  }

  postUpdate(ctx, actor) {
    var player = ctx.getEntityByTag("player")
    if (!player) {
      return
    }
    var map = ctx.zone.map
    for (y in map.yRange) {
      for (x in map.xRange) {
        if (map[x, y]["visible"]) {
          map[x, y]["visible"] = "maybe"
        } else {
          map[x, y]["visible"] = false
        }
      }
    }
    Vision2.new(map, player.pos, 8).compute()
  }
}

import "events" for Events
