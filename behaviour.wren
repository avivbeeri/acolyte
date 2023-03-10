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
    // TODO should this do 4 or 8?
    if (!actor["conditions"].containsKey("confusion")) {
      event.target["solid"] = true
      actor.removeBehaviour(this)
      return false
    }
    System.print(actor["conditions"]["confusion"].duration)
    var dir = DIR_EIGHT[RNG.int(8)]
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
      actor.removeBehaviour(this)
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
    if (!destEntities.isEmpty && destEntities.any{|entity| !(entity is Player) && entity is Creature }) {
      // Stop swarms eating each other
      return false
    }
    actor.pushAction(BumpAction.new(dest))
    return true
  }
}

import "actions" for BumpAction, SimpleMoveAction
import "entities" for Player, Creature
