import "math" for Vec
import "fov" for Vision2 as Vision
import "parcel" for GameSystem, GameEndEvent, ChangeZoneEvent, Dijkstra
import "./entities" for Player
import "combat" for Condition
import "behaviour" for UnconsciousBehaviour, SeekBehaviour

class StorySystem is GameSystem {
  construct new() { super() }
  process(ctx, event) {
    if (event is ChangeZoneEvent && event.floor == 6) {
      ctx["fightBegan"] = true
      ctx.addEvent(Components.events.story.new("dialogue:beforeBoss"))
    }
    if (ctx["fightBegan"] && event is Components.events.kill && event.target["kind"] == "gargoyle") {
      var stillGargoyles = ctx.entities().any {|entity| entity["kind"] == "gargoyle" }

      if (!event.target["frozen"] && stillGargoyles) {
        ctx.addEvent(Components.events.story.new("bossWeaken"))
      }
      if (!stillGargoyles) {
        var demon = ctx.entities().where {|entity| entity["kind"] == "demon" }.toList[0]
        demon["conditions"].remove("invulnerable")
        demon["name"] = "Demon?"
        demon["symbol"] = "D"
        demon["size"] = Vec.new(1, 1)
        demon["pos"] = demon["pos"] + Vec.new(1, 1)
        demon.behaviours.add(SeekBehaviour.new(null))
        ctx.addEvent(Components.events.story.new("bossVulnerable"))
      }
    }
  }
}

class ExperienceSystem is GameSystem {
  construct new() { super() }
  process(ctx, event) {
    if (event is Components.events.defeat) {
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
        var itemEquipmentA = (itemA.slot)
        var itemEquipmentB = (itemB.slot)
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
    if (actor["stats"]) {
      actor["stats"].tick()
    }
    if (actor.has("conditions")) {
      for (entry in actor["conditions"]) {
        var condition = entry.value
        condition.tick()
        if (condition.done) {
          actor["conditions"].remove(condition.id)
          ctx.addEvent(Components.events.clearCondition.new(actor, condition.id))
        }
      }
    }
  }
}
class DefeatSystem is GameSystem {
  construct new() { super() }
  process(ctx, event) {
    if (event is Components.events.defeat || event is Components.events.kill) {
      if (event.target["boss"]) {
        ctx.addEvent(GameEndEvent.new(true))
      }
    }
    if (event is Components.events.defeat) {
      event.target["killed"] = true
      event.target["solid"] = false
      event.target.behaviours.add(UnconsciousBehaviour.new(null))
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
    if (!player) {
      return
    }
    postUpdate(ctx, player)
  }

  process(ctx, event) {
    if (event is ChangeZoneEvent) {
      var player = ctx.getEntityByTag("player")
      if (!player) {
        return
      }
      ctx["map"] = Dijkstra.map(ctx.zone.map, player.pos)
    }
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
    Vision.new(map, player.pos, 8).compute()
  }
}

import "groups" for Components
