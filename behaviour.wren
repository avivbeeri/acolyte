import "math" for Vec, M
import "parcel" for
  Entity,
  BehaviourEntity,
  GameSystem,
  JPS,
  Stateful,
  DIR_EIGHT,
  RNG,
  Action,
  Set

class Behaviour is GameSystem {
  construct new() {
    super()
  }
  pathTo(ctx, start, end) {
    var map = ctx.zone
    var search = JPS.search(map, start, end)
    var path = JPS.buildPath(map, start, end, search)
    return path
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
      actor["stats"].set("hp", 1)
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
    if (actor.pos == previous || RNG.float() < 0.25) {
      while (dir == previousDir) {
        dir = RNG.sample(DIR_EIGHT)
      }
    } else {
      dir = actor.pos - previous
      dir.x = M.mid(-1, dir.x, 1)
      dir.y = M.mid(-1, dir.y, 1)
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
    var path = pathTo(ctx, actor.pos, player.pos)
    if (path == null || path.count < 2) {
      return false
    }
    var next = path[1]
    var dir = next - actor.pos
    var dx = M.mid(-1, dir.x, 1)
    var dy = M.mid(-1, dir.y, 1)
    var dest = Vec.new(dx, dy)

    var destEntities = ctx.getEntitiesAtPosition(next)
    if (!destEntities.isEmpty && destEntities.any{|entity| !(entity is Player) && entity is Creature && !entity["killed"] }) {
      // Stop swarms eating each other
      return false
    }
    actor.pushAction(BumpAction.new(dest))
    return true
  }
}

class Behaviours {
  static seek { SeekBehaviour }
  static randomWalk { RandomWalkBehaviour }
  static boss { BossBehaviour }
  static confused { ConfusedBehaviour }
  static unconscious { UnconsciousBehaviour }
  static wander { WanderBehaviour }
}

import "actions" for BumpAction, SimpleMoveAction
import "entities" for Player, Creature

