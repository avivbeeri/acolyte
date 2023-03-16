import "jps" for JPS import "math" for Vec, M
import "parcel" for
  Entity,
  BehaviourEntity,
  GameSystem,
  AStar,
  Stateful,
  DIR_EIGHT,
  RNG,
  Action,
  Set

class Behaviour is GameSystem {
  construct new() {
    super()
  }
  pathTo(ctx, actor, start, end) {
    var map = ctx.zone
    //var path = AStar.search(map, start, end)
    var path = JPS.new(map, actor).search(start, end)
    return path
  }

  static spaceAvailable(ctx, pos) {
    var destEntities = ctx.getEntitiesAtPosition(pos)
    return (destEntities.isEmpty || !destEntities.any{|entity| !(entity is Player) && entity is Creature && !entity["killed"] })
  }
}

class ConfusedBehaviour is Behaviour {
  construct new() {
    super()
  }
  update(ctx, actor) {
    if (!actor["conditions"].containsKey("confusion")) {
      actor.removeBehaviour(this)
      return false
    }
    var dir = RNG.sample(DIR_EIGHT)
    actor.pushAction(BumpAction.new(dir))
    return true
  }
}

class UnconsciousBehaviour is Behaviour {
  construct new() {
    super()
  }
  update(ctx, actor) {
    if (!actor["conditions"].containsKey("unconscious")) {
      if (ctx.getEntitiesAtPosition(actor.pos).where {|entity| !entity["killed"] }.count > 1) {
        // Wait til everyone else gets up
        actor.pushAction(Action.none)
        return true
      }
      actor.removeBehaviour(this)
      actor["solid"] = true
      actor["killed"] = false
      // What should we set this to?
      var maxHp = actor["stats"].get("hpMax")
      actor["stats"].set("hp", RNG.int(maxHp) + 1)
      return false
    }
    actor.pushAction(Action.none)
    return true
  }
}
class BossBehaviour is Behaviour {
  construct new() {
    super()
  }
  update(ctx, actor) {
    var player = ctx.getEntityByTag("player")
    if (!player) {
      return false
    }
    return false
    // Compute LoS to player
    // if in range, charge and target with a spell
  }
}
class RandomWalkBehaviour is Behaviour {
  construct new() {
    super()
  }
  update(ctx, actor) {
    var options= ctx.zone.map.neighbours(actor.pos)
    var next = RNG.sample(options)

    var dir = next - actor.pos
    var dx = M.mid(-1, dir.x, 1)
    var dy = M.mid(-1, dir.y, 1)
    dir.x = dx
    dir.y = dy
    actor.pushAction(BumpAction.new(dir))
    return true
  }
}
class WanderBehaviour is RandomWalkBehaviour {
  construct new() {
    super()
  }
  update(ctx, actor) {
    // Pick a random place
    // Calculate a path to it
    // follow that path to it
    // don't recalculate unless path is blocked
    // when arrive/ clear the path
    // repeat
    var previous = actor["previousPosition"] || actor.pos
    var previousDir = actor["previousDir"] || Vec.new()
    var dir = previousDir
    var options = RNG.shuffle(DIR_EIGHT[0..-1])
    var i = 0
    var fine = false
    while (!fine && i < options.count) {
      if (actor.pos == previous || RNG.float() < 0.25) {
        while (dir == previousDir) {
          dir = RNG.sample(options)
        }
      } else {
        dir = actor.pos - previous
        dir.x = M.mid(-1, dir.x, 1)
        dir.y = M.mid(-1, dir.y, 1)
      }
      var dest = actor.pos + dir
      fine = ctx.zone.map.isFloor(dest) && Behaviour.spaceAvailable(ctx, dest)
      i = i + 1
    }
    if (!fine) {
      dir = RNG.sample(DIR_EIGHT)
    }
    actor["previousDir"] = dir
    actor["previousPosition"] = actor.pos
    actor.pushAction(BumpAction.new(dir))
    return true
  }
}

class SeekBehaviour is Behaviour {
  construct new() {
    super()
  }
  update(ctx, actor) {
    var player = ctx.getEntityByTag("player")
    if (!player) {
      return false
    }
    var path = pathTo(ctx, actor, actor.pos, player.pos)
    if (path == null || path.count < 2) {
      return false
    }
    var next = path[1]
    var dir = next - actor.pos
    dir.x = M.mid(-1, dir.x, 1)
    dir.y = M.mid(-1, dir.y, 1)

    if (!Behaviour.spaceAvailable(ctx, next)) {
      // Stop swarms eating each other
      return false
    }
    actor.pushAction(BumpAction.new(dir))
    return true
  }
}

class StatueBehaviour is SeekBehaviour {
  construct new() {
    super()
  }

  update(ctx, actor) {
    var player = ctx.getEntityByTag("player")
    var power = (player["stats"]["atk"] / 2)
    var target = (12 - power).max(6)

    var frozenBefore = actor["frozen"]
    if (actor["frozen"]) {
      actor["frozenTimer"] = actor["frozenTimer"] + 1
      actor["frozen"] = actor["frozenTimer"] < 7
    }
    if (actor["frozen"]) {
      return false
    } else if (frozenBefore) {
      ctx.addEvent(Events.statueAwaken.new(actor))
    }
    return super.update(ctx, actor)
  }
}

class LocalSeekBehaviour is SeekBehaviour {
  construct new(range) {
    super()
    _range = range
  }
  update(ctx, actor) {
    var player = ctx.getEntityByTag("player")
    if (!player || player["map"] == null) {
      return false
    }
    var dpath = player["map"][0]
    if (!dpath[actor.pos] || dpath[actor.pos] > _range) {
      return false
    }
    return super.update(ctx, actor)
  }
}

class Behaviours {
  static seek { SeekBehaviour }
  static randomWalk { RandomWalkBehaviour }
  static boss { BossBehaviour }
  static confused { ConfusedBehaviour }
  static unconscious { UnconsciousBehaviour }
  static wander { WanderBehaviour }
  static statue { StatueBehaviour }
  static localSeek { LocalSeekBehaviour }
}

import "events" for Events
import "actions" for BumpAction, SimpleMoveAction
import "entities" for Player, Creature

