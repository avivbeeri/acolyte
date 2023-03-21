import "parcel" for Stateful, GameSystem, Event, Line, ChangeZoneEvent, RNG
import "entities" for Player
import "combat" for Modifier

class OathSystem is GameSystem {
  construct new() {
    super()
  }

  start(ctx) {
    var player = ctx.getEntityByTag("player")
    if (!player) {
      return null
    }
    var oaths = [
      Pacifism,
      SelfDefense,
      Quietus,
      Poverty,
      Piety
    ]
    player["brokenOaths"] = []
    player["oaths"] = RNG.sample(oaths, 2).map {|oath| oath.new() }.toList
    for (oath in player["oaths"]) {
      oath.boon.onGrant(player)
      ctx.addEvent(OathTaken.new(oath))
    }
  }

  process(ctx, event) {
    var player = ctx.getEntityByTag("player")
    if (player == null) {
      return
    }
    var events = []
    for (oath in player["oaths"]) {
      var extras = testOath(ctx, oath, "process", event)
      events.addAll(extras)
    }
    events.each {|event| ctx.addEvent(event) }
  }

  postUpdate(ctx, actor) {
    if (!(actor is Player)) {
      return
    }
    var events = []
    for (oath in actor["oaths"]) {
      var extras = testOath(ctx, oath, "postUpdate", null)
      events.addAll(extras)
    }
    events.each {|event| ctx.addEvent(event) }
  }

  testOath(ctx, oath, hook, event) {
    var events = []
    var player = ctx.getEntityByTag("player")
    var count = oath.strikes
    if (hook == "process") {
      oath.process(ctx, event)
    } else if (hook == "postUpdate") {
      oath.postUpdate(ctx)
    } else {
      Fiber.abort("Invalid OathSystem hook")
    }
    if (oath.broken) {
      player["stats"].decrease("piety", 1)
      oath.boon.onBreak(player)
      player["oaths"].remove(oath)
      player["brokenOaths"].add(oath)
      events.add(OathBroken.new(oath))
    } else if (count != oath.strikes) {
      ctx.addEvent(OathStrike.new(oath))
    }
    return events
  }
}

var OathTaken = Event.create("oathTaken", ["oath"])
var OathBroken = Event.create("oathBroken", ["oath"])
var OathStrike = Event.create("oathStrike", ["oath"])

class Oath is Stateful {
  construct new(name, strikes, boon, grace) {
    super()
    init_(name, strikes, boon, grace)
  }
  construct new(name, strikes, boon) {
    super()
    init_(name, strikes, 0, boon)
  }

  init_(name, strikes, grace, boon) {
    data["name"] = name
    data["grace"] = grace
    data["strikes"] = strikes
    data["boon"] = boon
    boon.oath = this
  }

  name { data["name"] }
  broken { strikes <= 0 }
  grace { data["grace"] }
  strikes { data["strikes"] }
  boon { data["boon"] }

  strike() {
    if (data["grace"] > 0) {
      data["grace"] = (data["grace"]  - 1).max(0)
    } else {
      data["strikes"] = (strikes  - 1).max(0)
    }
  }
  hardStrike() { data["strikes"] = 0 }
  shouldHardStrike(ctx, event) { false }
  shouldStrike(ctx, event) { false }
  postUpdate(ctx) {}
  process(ctx, event) {
    if (shouldHardStrike(ctx, event)) {
      hardStrike()
    } else if (shouldStrike(ctx, event)) {
      strike()
    }
  }
}

class Boon is Stateful {
  construct new() {
    super()
    _oath = null
  }
  oath=(v) { _oath = v }
  oath { _oath }
  onGrant(actor) {}
  onBreak(actor) {}
}

class Favor is Boon {
  construct new() {
    super()
  }
  onGrant(actor) {
    actor["stats"].addModifier(Modifier.add(oath.name, { "pietyMax": 1 }, true))
    actor["stats"].increase("piety", 1)
  }
  onBreak(actor) {
    actor["stats"].removeModifier(oath.name)
  }
}
class Vitality is Boon {
  construct new() {
    super()
  }
  onGrant(actor) {
    actor["stats"].addModifier(Modifier.add(oath.name, { "hpMax": 1 }, true))
    actor["stats"].increase("hp", 1)
  }
  onBreak(actor) {
    actor["stats"].removeModifier(oath.name)
  }
}

class StatModifierBoon is Boon {
  construct new(stat, amount) {
    super()
    _stat = stat
    _amount = amount
  }
  onGrant(actor) {
    var statMap = {
      _stat: _amount
    }
    actor["stats"].addModifier(Modifier.add(oath.name, statMap, true))
  }
  onBreak(actor) {
    actor["stats"].removeModifier(oath.name)
  }
}

class Piety is Oath {
  construct new() {
    super("piety", 1, 0, Boon.new())
    data["currentFloor"] = 0
    data["floors"] = 0
  }
  shouldStrike(ctx, event) {
    if (event is ChangeZoneEvent) {
      if (event.floor > data["currentFloor"]) {
        data["floors"] = data["floors"] + 1
      }

      data["currentFloor"] = event.floor
      if (data["floors"] > 2) {
        return true
      }
    }
  }

  process(ctx, event) {
    if (event is Components.events.pray) {
      data["floors"] = 0
    }
    super.process(ctx, event)
  }

}

class Quietus is Oath {
  construct new() {
    super("quietus", 3, 0, StatModifierBoon.new("def", 1))
    data["attacked"] = {}
  }
  shouldHardStrike(ctx, event) { false }
  shouldStrike(ctx, event) { false }
  process(ctx, event) {

    if (event is ChangeZoneEvent) {
      if (!data["attacked"].isEmpty) {
        strike()
      }
      data["attacked"].clear()
    } else if (event is Components.events.defeat && event.src is Player) {
      data["attacked"][event.target.id] = 4
    } else if (event is Components.events.kill && event.src is Player) {
      data["attacked"].remove(event.target.id)
    }
    super.process(ctx, event)
  }
  postUpdate(ctx) {
    var index = data["attacked"]
    for (id in index.keys) {
      var target = ctx.getEntityById(id)
      if (!target) {
        index.remove(id)
        continue
      }
      if (!target["killed"]) {
        index.remove(id)
        strike()
      } else {
        index[id] = index[id] - 1
        if (index[id] <= 0) {
          index.remove(id)
          strike()
        }
      }
    }
  }
}
class SelfDefense is Oath {
  construct new() {
    super("self defense", 3, 0, Boon.new())
    data["attackedBy"] = {}
  }
  shouldHardStrike(ctx, event) {
    return (event is Components.events.kill && event.src is Player) &&
      !(data["attackedBy"][event.target.id])
  }
  shouldStrike(ctx, event) {
    return (event is Components.events.attack && event.src is Player) &&
      !(data["attackedBy"][event.target.id])
  }
  process(ctx, event) {
    if (event is Components.events.attack && event.target is Player) {
      data["attackedBy"][event.src.id] = (data["attackedBy"][event.src.id] || 0) + 1
    }
    super.process(ctx, event)
  }
}
class Pacifism is Oath {
  construct new() {
    super("pacifism", 3, 0, Boon.new())
  }
  shouldHardStrike(ctx, event) {
    return (event is Components.events.kill && event.src is Player)
  }
  shouldStrike(ctx, event) {
    return (event is Components.events.defeat && event.src is Player)
  }
}

class Poverty is Oath {
  construct new() {
    super("poverty", 1, Favor.new())
  }
  shouldStrike(ctx, event) {
    return (event is Components.events.equipItem && event.src is Player)
  }
}

class Indomitable is Oath {
  construct new() {
    super("indomitable", 3, StatModifierBoon.new("atk", 1))
    data["nearby"] = {}
  }
  shouldStrike(ctx, event) {
    if (event is Components.events.move) {
      if (event.src is Player) {
        for (id in data["nearby"].keys) {
          var enemy = ctx.getEntityById(id)
          if (enemy == null || enemy["killed"]) {
            data["nearby"].remove(id)
            continue
          }
          var range = Line.chebychev(enemy.pos, event.src.pos)
          if (range > data["nearby"][id]) {
            data["nearby"][id] = Num.infinity // mark for uniqueness?
            return true
          }
        }
      }
    }
    return false
  }
  process(ctx, event) {
    // player moves to enemy - engage
    // enemy moves to player - engage
    // player moves away from enemy - strike
    // Enemy moves away from player - fine
    if (event is Components.events.defeat || event is Components.events.kill) {
      data["nearby"].remove(event.target.id)
    } else if (event is Components.events.move) {
      var player = ctx.getEntityByTag("player")
      if (event.src is Player) {
        var enemies = ctx.entities().where {|entity| entity.pos }
        for (enemy in enemies) {
          var range = Line.chebychev(enemy.pos, player.pos)
          if (!data["nearby"].containsKey(enemy.id) || range <= 1) {
            data["nearby"][enemy.id] = range
          }
        }
      } else {
        var range = Line.chebychev(event.src.pos, player.pos)
        if (range <= 1) {
          // enemy is close now
          data["nearby"][event.src.id] = range
        } else if (data["nearby"].containsKey(event.src.id)) {
          // enemy we care about runs away
          data["nearby"][event.src.id] = Num.infinity
        }
      }
    }
    super.process(ctx, event)
  }
}

import "groups" for Components
