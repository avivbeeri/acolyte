import "math" for Vec
import "parcel" for TileMap8, Tile, Zone, Line, RNG, Entity, DIR_FOUR, Dijkstra, World

class GeneratorUtils {
  static isValidTileLocation(zone, position) {
    var tile = zone.map[position]
    var entities = zone["entities"]
    return !(tile["solid"] || tile["stairs"] || tile["altar"])
  }
  static isValidEntityLocation(zone, position) {
    var tile = zone.map[position]
    var entities = zone["entities"]
    return isValidTileLocation(zone, position) &&
      (entities.isEmpty || !entities.any{|entity| entity.pos == pos })
  }

  static findFurthestPoint(map, startPos) {
    var dMap = Dijkstra.map(map, startPos)
    var maxEntry = null
    for (entry in dMap[0]) {
      if (maxEntry == null || entry.value > maxEntry.value) {
        maxEntry = entry
      }
    }
    return maxEntry.key
  }
  static findPockets(map) {
    var list = []
    for (y in 0...32) {
      for (x in 0...32) {
        if (map[x, y]["stairs"] || map[x, y]["solid"]) {
          continue
        }
        var count = 0
        for (i in 0...4) {
          var dir = DIR_FOUR[i]
          if (map[x + dir.x, y + dir.y]["solid"]) {
            count = count + 1
          }
        }
        if (count == 3) {
          list.add(Vec.new(x, y))
        }
      }
    }
    return list
  }

}

class WorldGenerator {
  static create() {
    var world = World.new()
    world.generator = WorldGenerator
    world.systems.add(InventorySystem.new())
    world.systems.add(ExperienceSystem.new())
    world.systems.add(ConditionSystem.new())
    world.systems.add(DefeatSystem.new())
    world.systems.add(VisionSystem.new())
    world.systems.add(InventorySystem.new())
    world.systems.add(OathSystem.new())

    world["items"] = {
      "sword": Items.sword,
      "potion": Items.healthPotion,
      "scroll": Items.lightningScroll,
      "wand": Items.confusionScroll,
      "fireball": Items.fireballScroll
    }

    // Add the player first so that they act first
    world.addEntity("player", Player.new())
    var zone = world.loadZone(0)

    var player = world.getEntityByTag("player")
    player.pos = zone["start"]
    world.skipTo(Player)
    world.start()

    return world
  }
  static generate(world, args) {
    var level = args[0]
    var startPos = args.count > 1 ? args[1] : null

    var zone = null

    if (level < 1) {
      zone = BasicZoneGenerator.generate(args)
    } else if (level < 2) {
      zone = RandomZoneGenerator.generate(args)
    } else {
      zone = BossRoomGenerator.generate(args)
    }
    for (entity in zone["entities"]) {
      world.addEntity(entity)
      entity.zone = level
    }
    zone.data.remove("entities")
    zone["title"] = "The Courtyard"
    return zone
  }
}

class RandomZoneGenerator {
  static generate(args) {
    var level = args[0]
    var startPos = args.count > 1 ? args[1] : null
    var map = TileMap8.new()
    var zone = Zone.new(map)
    zone["entities"] = []
    zone["level"] = level
    zone["start"] = startPos

    for (y in 0...32) {
      for (x in 0...32) {
        map[x,y] = Tile.new({
          "solid": true,
          "blocking": true
        })
      }
    }
    var current = Vec.new(RNG.int(1, 31), RNG.int(1, 31))
    if (startPos) {
      current = startPos
    }
    zone["start"] = startPos = current
    zone.map[current]["stairs"] = "up"
    map[current]["solid"] = false
    map[current]["blocking"] = false
    var dist = 1000
    for (i in 0...dist) {
      var next = null
      while (next == null || next.x == 0 || next.y == 0 || next.x == 31 || next.y == 31) {
        var dir = DIR_FOUR[RNG.int(4)]
        next = current + dir
      }
      current = next
      map[current]["solid"] = false
      map[current]["blocking"] = false
    }
    var exit = GeneratorUtils.findFurthestPoint(map, startPos)
    zone.map[exit]["stairs"] = "down"
    // place item somewhere
    var pockets = RNG.shuffle(GeneratorUtils.findPockets(map))
    if (!pockets.isEmpty) {
      var pos = pockets[0]
      var r = RNG.float()
      var itemId = "potion"
      if (r < 0.8) {
        itemId = "scroll"
      }
      if (r < 0.6) {
        itemId = "wand"
      }
      if (r < 0.2) {
        itemId = "fireball"
      }
      if (r < 1) {
        itemId = "sword"
      }
      zone.map[pos]["items"] = [ InventoryEntry.new(itemId, 1) ]
    }
      // place enemy
    var x = current.x
    var y = current.y
    var pos = Vec.new(x, y)

    var valid = false
    while (!valid) {
      pos.x = RNG.int(room.p0.x + 1, room.p1.x - 1)
      pos.y = RNG.int(room.p0.y + 1, room.p1.y - 1)
      var valid = GeneratorUtils.isValidEntityLocation(zone, pos)
    }
    var entity = Rat.new()
    entity.pos = pos
    zone["entities"].add(entity)

    return zone
  }
}

class BasicZoneGenerator {
  static tunnelBetweenWide(map, a, b) {
    var corner
    if (RNG.float() <= 0.5) {
      corner = Vec.new(b.x, a.y)
    } else {
      corner = Vec.new(a.x, b.y)
    }
    var d = Vec.new(1, 1)
    var dx = Vec.new(1, 0)
    var dy = Vec.new(0, 1)
    for (pos in Line.walk(a, corner) + Line.walk(b, corner)) {
      map[pos] = Tile.new({
        "solid": false
      })
      map[pos + d] = Tile.new({
        "solid": false
      })
      map[pos + dx] = Tile.new({
        "solid": false
      })
      map[pos + dy] = Tile.new({
        "solid": false
      })
    }
  }
  static tunnelBetween(map, a, b) {
    var corner
    if (RNG.float() <= 0.5) {
      corner = Vec.new(b.x, a.y)
    } else {
      corner = Vec.new(a.x, b.y)
    }
    for (pos in Line.walk(a, corner) + Line.walk(b, corner)) {
      map[pos] = Tile.new({
        "solid": false
      })
    }
  }

  static generate(args) {
    var maxRooms = 18
    var minSize = 5
    var maxSize = 10
    var monstersPerRoom = 2
    var itemsPerRoom = 1

    var map = TileMap8.new()
    var level = args[0]
    var startPos = args.count > 1 ? args[1] : null
    var zone = Zone.new(map)
    zone["entities"] = []
    zone["level"] = level
    zone["start"] = startPos

    for (y in 0...32) {
      for (x in 0...32) {
        map[x,y] = Tile.new({
          "solid": true,
          "blocking": true
        })
      }
    }

    var rooms = []
    for (i in 0...maxRooms) {
      var w = RNG.int(minSize, maxSize + 1)
      var h = RNG.int(minSize, maxSize + 1)
      var x = RNG.int(0, 32 - w - 1)
      var y = RNG.int(0, 32 - h - 1)
      if (rooms.count == 0 && startPos) {
        // ensure start position is contained in first room
        x = (startPos.x - RNG.int(1, w - 1)).max(0)
        y = (startPos.y - RNG.int(1, h - 1)).max(0)
      }

      var room = RectangularRoom.new(x, y, w, h)
      if (!rooms.isEmpty && rooms.any{|existing| room.intersects(existing) }) {
        continue
      }
      for (pos in room.inner) {
        map[pos] = Tile.new({
          "solid": false
        })
      }
      if (rooms.count > 0) {
        BasicZoneGenerator.tunnelBetween(map, room.center, rooms[-1].center)
      } else if (!startPos) {
        startPos = room.center
        zone["start"] = startPos
      }
      rooms.add(room)

    }

    // USE THIS IF WE DON'T WANT TO START ON STAIRS
    // startPos = RNG.shuffle(map.neighbours(startPos))[0]
    zone["start"] = startPos
    // Add a cycle
    if (rooms.count > 3) {
      var start = RNG.int(0, rooms.count - 3)
      var end = start + 3
      BasicZoneGenerator.tunnelBetween(map, rooms[start].center, rooms[end].center)
    }
    var finalRoom = rooms[-1]
    //BasicZoneGenerator.placeStairs(zone, finalRoom)
    zone.map[startPos]["stairs"] = "up"

    var altarRoom = rooms[RNG.int(rooms.count)]
    //BasicZoneGenerator.placeAltar(zone, altarRoom)

    for (room in rooms) {
      BasicZoneGenerator.placeEntities(zone, room, monstersPerRoom, itemsPerRoom)
    }

    return zone
  }
  static placeAltar(zone, room) {
    var beforeMap = Dijkstra.map(zone.map, room.center)
    var entities = zone["entities"]
    var pos = Vec.new()

    var valid = false
    while (!valid) {
      pos.x = RNG.int(room.p0.x + 1, room.p1.x - 1)
      pos.y = RNG.int(room.p0.y + 1, room.p1.y - 1)
      zone.map[pos]["solid"] = true
      var afterMap = Dijkstra.map(zone.map, room.center)
      valid = GeneratorUtils.isValidEntityLocation(zone, pos)
      valid = valid && afterMap[0].count == beforeMap[0].count
      zone.map[pos]["solid"] = valid
    }

    zone.map[pos]["altar"] = true
  }
  static placeStairs(zone, room) {
    var pos = Vec.new()
    pos.x = RNG.int(room.p0.x + 1, room.p1.x - 1)
    pos.y = RNG.int(room.p0.y + 1, room.p1.y - 1)

    while (!GeneratorUtils.isValidTileLocation(zone, pos)) {
      pos.x = RNG.int(room.p0.x + 1, room.p1.x - 1)
      pos.y = RNG.int(room.p0.y + 1, room.p1.y - 1)
    }

    zone.map[pos]["stairs"] = "down"
  }


  static placeEntities(zone, room, maxMonsters, maxItems) {
    var totalMonsters = RNG.int(maxMonsters + 1)
    var startPos = zone["start"]
    var totalItems = RNG.int(maxItems + 1)
    var entities = zone["entities"]
    for (i in 0...totalMonsters) {
      var x = RNG.int(room.p0.x + 1, room.p1.x - 1)
      var y = RNG.int(room.p0.y + 1, room.p1.y - 1)

      var pos = Vec.new(x, y )

      if ((entities.isEmpty || !entities.any{|entity| entity.pos == pos }) && pos != startPos) {
        var entity = Rat.new()
        entity.pos = pos
        entities.add(entity)
      }
    }
    for (i in 0...totalItems) {
      var x = RNG.int(room.p0.x + 1, room.p1.x - 1)
      var y = RNG.int(room.p0.y + 1, room.p1.y - 1)

      var pos = Vec.new(x, y)

      if ((entities.isEmpty || !entities.any{|entity| entity.pos == pos }) && pos != startPos) {
        var r = RNG.float()
        var itemId = "potion"
        if (r < 0.8) {
          itemId = "scroll"
        }
        if (r < 0.6) {
          itemId = "wand"
        }
        if (r < 0.2) {
          itemId = "fireball"
        }
        zone.map[pos]["items"] = [ InventoryEntry.new(itemId, 1) ]
      }
    }
  }
}

class BossRoomGenerator {
  static generate(args) {
    var map = TileMap8.new()
    for (y in 0...32) {
      for (x in 0...32) {
        map[x,y] = Tile.new({
          "solid": true
        })
      }
    }
    for (y in 11...22) {
      for (x in 11...22) {
        map[x,y] = Tile.new({
          "solid": false
        })
      }
    }

    var level = args[0]
    var zone = Zone.new(map)
    zone["level"] = level
    zone["entities"] = [ Demon.new() ]
    zone["entities"][0].pos = Vec.new(15, 13)
    zone["start"] = Vec.new(15, 21)
    zone.map[zone["start"]]["stairs"] = "up"
    return zone
  }
}

class RectangularRoom {
  construct new(x, y, w, h) {
    _p0 = Vec.new(x, y)
    _size = Vec.new(w, h)
    _p1 = _p0 + _size
  }

  center {
    var c = (_p0 + (_size / 2))
    c.x = c.x.floor
    c.y = c.y.floor
    return c
  }

  inner {
    var inside = []
    for (y in (_p0.y+1)..._p1.y) {
      for (x in (_p0.x+1)..._p1.x) {
        inside.add(Vec.new(x, y))
      }
    }
    return inside
  }

  p0 { _p0 }
  p1 { _p1 }

  intersects(other) {
     return _p0.x <= other.p1.x &&
            _p1.x >= other.p0.x &&
            _p0.y <= other.p1.y &&
            _p1.y >= other.p0.y

  }
}

import "./items" for InventoryEntry
import "./entities" for Rat, Demon, Player
import "./systems" for VisionSystem, DefeatSystem, InventorySystem, ConditionSystem, ExperienceSystem
import "./items" for Items
import "./oath" for OathSystem
