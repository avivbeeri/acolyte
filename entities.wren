import "parcel" for Entity, BehaviourEntity, GameSystem, JPS,  AStar
import "math" for Vec, M
import "combat" for StatGroup
import "actions" for BumpAction

class Player is Entity {
  construct new() {
    super()
    this["symbol"] = "@"
    this["solid"] = true
    this["stats"] =  StatGroup.new({
      "hpMax": 5,
      "hp": 5,
      "str": 1,
      "dex": 1
    })
  }
  name { "Player" }
  pushAction(action) {
    if (hasActions()) {
      return
    }
    super.pushAction(action)
  }
  getAction() {
    if (hasActions()) {
      return super.getAction()
    }
    return null
  }
}

class Behaviour is GameSystem {
  construct new() {
    super()
  }
  pathTo(ctx, start, end) {
    var map = ctx.zone.map
    var search = JPS.search(map, start, end)
    var path = JPS.buildPath(map, start, end, search)
    return path
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
    actor.pushAction(BumpAction.new(Vec.new(dx, dy)))
    return true
  }
}

class Rat is BehaviourEntity {
 construct new() {
    super()
    this["symbol"] = "r"
    this["solid"] = true
    this["stats"] =  StatGroup.new({
      "hpMax": 1,
      "hp": 1,
      "str": 1,
      "dex": 1
    })

    behaviours.add(SeekBehaviour.new())
  }
}
