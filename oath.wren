import "parcel" for Stateful, GameSystem, Event
import "events" for Events
import "entities" for Player

class OathSystem is GameSystem {
  construct new() {
    super()
  }

  start(ctx) {
    var player = ctx.getEntityByTag("player")
    player["brokenOaths"] = []
    player["oaths"] = [
//      Pacifism.new(),
      Quietus.new(),
      Poverty.new()
    ]
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

class OathEvent is Event {
  construct new(oath) {
    super()
    data["oath"] = oath
  }
  oath { data["oath"] }
}
class OathStrike is OathEvent {
  construct new(oath) {
    super(oath)
  }
}

class OathTaken is OathEvent {
  construct new(oath) {
    super(oath)
  }
}

class OathBroken is OathEvent {
  construct new(oath) {
    super(oath)
  }
}

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

class Quietus is Oath {
  construct new() {
    super("succor", 3, 0, Boon.new())
    data["attacked"] = {}
  }
  shouldHardStrike(ctx, event) { false }
  shouldStrike(ctx, event) { false }
  process(ctx, event) {
    if (event is Events.defeat && event.src is Player) {
      data["attacked"][event.target.id] = 4
    }
    super.process(ctx, event)
  }
  postUpdate(ctx) {
    var index = data["attacked"]
    for (id in index.keys) {
      var target = ctx.getEntityById(id)
      if (target && !target["killed"]) {
        index.remove(id)
      } else if (target && target["killed"]) {
        index[id] = index[id] - 1
        if (index[id] <= 0) {
          index.remove(id)
          strike()
        }
      }
    }
  }
}
class Pacifism is Oath {
  construct new() {
    super("pacifism", 3, 0, Boon.new())
    data["attackedBy"] = {}
  }
  shouldHardStrike(ctx, event) {
    return (event is Events.kill && event.src is Player)
  }
  shouldStrike(ctx, event) {
    return (event is Events.defeat && event.src is Player) && !data["attackedBy"][event.target.id]
  }
  process(ctx, event) {
    if (event is Events.attack && event.target is Player) {
      System.print("attacked by %(event.src.id)")
      data["attackedBy"][event.src.id] = true
    }
    super.process(ctx, event)
  }
}

class Poverty is Oath {
  construct new() {
    super("poverty", 1, Boon.new())
  }
  shouldStrike(ctx, event) {
    return (event is Events.equipItem && event.src is Player)
  }
}
