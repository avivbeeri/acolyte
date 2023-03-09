import "fov" for Vision, Vision2
import "parcel" for GameSystem, JPS, GameEndEvent
import "./entities" for Player

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
      actor["inventory"] = actor["inventory"].where {|entry| entry.qty > 0 }.toList
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
  postUpdate(ctx, actor) {
    var player = ctx.getEntityByTag("player")
    if (!player) {
      ctx.complete = true
      ctx.addEvent(GameEndEvent.new())
    }
  }
}
class VisionSystem is GameSystem {
  construct new() { super() }

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
