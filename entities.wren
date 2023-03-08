import "parcel" for Entity, BehaviourEntity, GameSystem, JPS, Stateful, DIR_EIGHT, RNG, Action, Set
import "math" for Vec, M
import "combat" for StatGroup
import "actions" for BumpAction
import "messages" for Pronoun
import "items" for InventoryEntry

class Creature is BehaviourEntity {
  construct new() {
    super()
    this["symbol"] = "?"
    this["solid"] = true
    this["inventory"] = [
    ]
    this["stats"] =  StatGroup.new({
      "hpMax": 1,
      "hp": 1,
      "str": 1,
      "dex": 0
    })
    this["conditions"] = {}
  }
  name { "Creature" }
  pronoun { Pronoun.it }
}

class Player is Creature {
  construct new() {
    super()
    this["symbol"] = "@"
    this["inventory"] = [
      InventoryEntry.new("potion", 1)
    ]
    this["stats"] =  StatGroup.new({
      "hpMax": 5,
      "hp": 5,
      "str": 1,
      "dex": 1
    })
  }
  name { data["name"] || "Player" }
  pronoun { Pronoun.you }
  pushAction(action) {
    if (hasActions()) {
      return
    }
    super.pushAction(action)
  }
  getAction() {
    var action = super.getAction()
    if (action == Action.none) {
      return null
    }
    return action
  }
}

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
      actor.removeBehaviour(this)
      System.print("removed")
      return false
    }
    var dir = DIR_EIGHT[RNG.int(8)]
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
    actor.pushAction(BumpAction.new(Vec.new(dx, dy)))
    return true
  }
}

class Rat is Creature {
 construct new() {
    super()
    this["symbol"] = "r"
    this["stats"] =  StatGroup.new({
      "hpMax": 1,
      "hp": 1,
      "str": 1,
      "dex": 1
    })

    behaviours.add(SeekBehaviour.new())
  }
  name { "Rat" }
  pronoun { Pronoun.it }
}
