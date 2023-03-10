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
      Pacifism.new(),
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
    var toRemove = []
    var events = []
    for (oath in player["oaths"]) {
      oath.process(ctx, event)
      if (oath.broken) {
        oath.boon.onBreak(player)
        player["oaths"].remove(oath)
        player["brokenOaths"].add(oath)
        events.add(OathBroken.new(oath))
      }
    }
    events.each {|event| ctx.addEvent(event) }
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
  process(ctx, event) {
    if (shouldHardStrike(ctx, event)) {
      hardStrike()
    } else if (shouldStrike(ctx, event)) {
      var count = strikes
      strike()
      if (count != strikes && !broken) {
        ctx.addEvent(OathStrike.new(this))
      }
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

class Pacifism is Oath {
  construct new() {
    super("pacifism", 3, 2, Boon.new())
  }
  shouldHardStrike(ctx, event) {
    return (event is Events.kill && event.src is Player)
  }
  shouldStrike(ctx, event) {
    return (event is Events.defeat && event.src is Player)
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
