import "parcel" for Stateful, GameSystem, Event
import "events" for Events
import "entities" for Player

class OathSystem is GameSystem {
  construct new() {
    super()
  }

  start(ctx) {
    var player = ctx.getEntityByTag("player")
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
    for (oath in player["oaths"]) {
      oath.process(ctx, event)
      if (oath.broken) {
        oath.boon.onBreak(player)
        player["oaths"].remove(oath)
      }
    }
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
  construct new(name, strikes, boon) {
    super()
    data["name"] = name
    data["strikes"] = strikes
    // How to represent?
    data["boon"] = boon
  }

  name { data["name"] }
  broken { strikes <= 0 }
  strikes { data["strikes"] }
  boon { data["boon"] }

  strike() { data["strikes"] = (strikes  - 1).max(0) }
  process(ctx, event) {}
}

class Boon is Stateful {
  construct new() {
    super()
  }
  onGrant(actor) {}
  onBreak(actor) {}
}

class Pacifism is Oath {
  construct new() {
    super("pacifism", 3, Boon.new())
  }
  process(ctx, event) {
    if (event is Events.defeat && event.src is Player) {
      strike()
      if (broken) {
        ctx.addEvent(OathBroken.new(this))
      } else {
        ctx.addEvent(OathStrike.new(this))
      }
    }
  }
}

class Poverty is Oath {
  construct new() {
    super("poverty", 3, Boon.new())
  }
  process(ctx, event) {
    if (event is Events.equipItem && event.src is Player) {
      strike()
      if (broken) {
        ctx.addEvent(OathBroken.new(this))
      } else {
        ctx.addEvent(OathStrike.new(this))
      }
    }
  }
}
