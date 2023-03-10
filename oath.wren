import "parcel" for Stateful, GameSystem
import "entities" for Player

class OathSystem is GameSystem {
  construct new() {
    super()
  }

  start(ctx) {
    var player = ctx.getEntityByTag("player")
    player["oaths"] = [
      Oath.new("pacifism", 3, "stealth")
    ]
  }

  process(ctx, event) {
    var player = ctx.getEntityByTag("player")
    for (oath in player["oaths"]) {
      oath.process(ctx, event)
    }
  }
}

class OathBroken is Event {
  construct new(oath) {
    data["oath"] = oath
  }
  oath { data["oath"] }
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
  onGrant(actor) {}
  onBreak(actor) {}
}

class Pacifism is Oath {
  construct new() {
    super("pacifism", 3, "stealth")
  }
  process(ctx, event) {
    if (event is DefeatEvent && event.src is Player) {
      strike()
      if (broken) {
        ctx.addEvent(OathBrokenEvent.new(this))
      }
    }
  }
}
