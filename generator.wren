import "math" for Vec
import "parcel" for TileMap8, Tile, Zone, Line, RNG, Entity, DIR_FOUR, Dijkstra, World, DIR_EIGHT

// Which tier am I in? (beginner, middle, endgame)
// Items
//

var TierMap = {
  0 :1,
  1: 1,
  2: 1,
  3: 2,
  4: 2,
  5: 3,
  6:3
}

class GeneratorUtils {
  static pickEnemy(level) {
    var tier = TierMap[level]
    var table = Distribution[tier - 1]
    var enemyTable = table["enemies"]

    var total = 0
    var weighted = enemyTable.reduce([]) {|acc, entry|
      total = total + entry[1]
      acc.add([entry[0], total])
      return acc
    }
    var r = RNG.float()
    var i = 0
    var entry = null
    var result = null
    while (i < weighted.count) {
      entry = weighted[i]
      i = i + 1
      if (r < entry[1]) {
        result = entry[0]
        break
      }
    }
    return result
  }
  static pickItem(level) {
    var tier = TierMap[level]
    var table = Distribution[tier - 1]
    var itemTable = table["items"]

    var total = 0
    var weighted = itemTable.reduce([]) {|acc, entry|
      total = total + entry[1]
      acc.add([entry[0], total])
      return acc
    }
    var r = RNG.float()
    var i = 0
    var entry = null
    var result = null
    while (i < weighted.count) {
      entry = weighted[i]
      i = i + 1
      if (r < entry[1]) {
        result = entry[0]
        break
      }
    }
    return result
  }

  static isValidTileLocation(zone, position) {
    var tile = zone.map[position]
    var entities = zone["entities"]
    return !tile["solid"] && !tile["stairs"] && !tile["altar"]
  }
  static isValidEntityLocation(zone, position) {
    var entities = zone["entities"]
    return isValidTileLocation(zone, position) &&
      (entities.isEmpty || !entities.any{|entity| entity.pos == position })
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
    world.systems.add(StorySystem.new())
    world.systems.add(OathSystem.new())
    world.systems.add(InventorySystem.new())
    world.systems.add(ExperienceSystem.new())
    world.systems.add(ConditionSystem.new())
    world.systems.add(InventorySystem.new())
    world.systems.add(VisionSystem.new())
    // Must come last
    world.systems.add(DefeatSystem.new())

    world.addEntity("player", Player.new())
    var level = 0
    var player = world.getEntityByTag("player")
    player.zone = level

    /*
     Debug power armor
    player["equipment"] = {
      EquipmentSlot.weapon: "longsword",
      EquipmentSlot.armor: "platemail"
    }
    player["inventory"] = [
      InventoryEntry.new("longsword", 1),
      InventoryEntry.new("platemail", 1),
    ]
    */

    var zone = world.loadZone(level)

    player.pos = zone["start"]
    world["items"] = {}
    Items.all.each {|item| world["items"][item.id] = item }
    for (id in player["equipment"].values) {
      world["items"][id].onEquip(player)
    }
    world.skipTo(Player)
    world.start()

    return world
  }
  static generate(world, args) {
    var level = args[0]
    var startPos = args.count > 1 ? args[1] : null

    var zone = null

    if (level < 1) {
      zone = StartRoomGenerator.generate(args)
    } else if (level < 3) {
      zone = BasicZoneGenerator.generate(args)
    } else if (level < 6) {
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
    RandomZoneGenerator.placeAltar(zone)
    // place item somewhere
    var pockets = RNG.shuffle(GeneratorUtils.findPockets(map))
    if (!pockets.isEmpty) {
      for (i in 1..(RNG.int(2, ((level/2).floor + 1).min(pockets.count)))) {
        var pos = pockets[0]
        var itemId = GeneratorUtils.pickItem(level) //RNG.sample(Items.findable).id
        if (itemId == null) {
          continue
        }
        zone.map[pos]["items"] = [ InventoryEntry.new(itemId, 1) ]
      }
    }
    var x = current.x
    var y = current.y
    for (i in 1..(RNG.int(2, level))) {
      var pos = Vec.new(x, y)
      // place enemy

      var valid = false
      var attempts = 0
      while (!valid && attempts < 30) {
        pos.x = RNG.int(zone.map.xRange.from + 1, zone.map.xRange.to - 1)
        pos.y = RNG.int(zone.map.yRange.from + 1, zone.map.yRange.to - 1)
        valid = GeneratorUtils.isValidEntityLocation(zone, pos)
        attempts = attempts + 1
      }
      var entity = GeneratorUtils.pickEnemy(level)
      if (!valid || entity == null) {
        continue
      }
      entity = entity.new()
      entity.pos = pos
      zone["entities"].add(entity)
    }


    return zone
  }
  static placeAltar(zone) {
    var map = zone.map
    var pos = Vec.new()

    var valid = false
    var attempts = 0
    while (!valid && attempts < 30) {
      pos.x = RNG.int(zone.map.xRange.from + 1, zone.map.xRange.to - 1)
      pos.y = RNG.int(zone.map.yRange.from + 1, zone.map.yRange.to - 1)
      valid = GeneratorUtils.isValidTileLocation(zone, pos) && zone.map.allNeighbours(pos).all {|tile| zone.map.isFloor(tile) }
      attempts = attempts + 1
    }
    if (valid) {
      zone.map[pos]["solid"] = true
      zone.map[pos]["altar"] = true
    }
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
        "solid": false,
        "blocking": true
      })
      map[pos + d] = Tile.new({
        "solid": false,
        "blocking": true
      })
      map[pos + dx] = Tile.new({
        "solid": false,
        "blocking": true
      })
      map[pos + dy] = Tile.new({
        "solid": false,
        "blocking": true
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
        "solid": false,
        "blocking": false
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
    BasicZoneGenerator.placeStairs(zone, finalRoom)
    zone.map[startPos]["stairs"] = "up"

    var altarRoom = rooms[RNG.int(rooms.count)]
    BasicZoneGenerator.placeAltar(zone, altarRoom)

    for (i in 0...RNG.int(rooms.count)) {
      var statueRoom = rooms[RNG.int(rooms.count)]
      BasicZoneGenerator.placeStatue(zone, statueRoom)
    }

    for (room in rooms) {
      BasicZoneGenerator.placeEntities(zone, room, monstersPerRoom, itemsPerRoom)
    }

    return zone
  }
  static placeAltar(zone, room) {
    var pos = Vec.new()

    var valid = false
    var attempts = 0
    while (!valid && attempts < 30) {
      pos.x = RNG.int(room.p0.x + 1, room.p1.x - 1)
      pos.y = RNG.int(room.p0.y + 1, room.p1.y - 1)
      valid = GeneratorUtils.isValidTileLocation(zone, pos) && zone.map.allNeighbours(pos).all {|tile| zone.map.isFloor(tile) }
      attempts = attempts + 1
    }
    if (valid) {
      zone.map[pos]["solid"] = true
      zone.map[pos]["altar"] = true
    }
  }
  static placeStatue(zone, room) {
    var map = zone.map
    var pos = Vec.new()

    var valid = false
    var attempts = 0
    while (!valid && attempts < 30) {
      pos.x = RNG.int(room.p0.x + 1, room.p1.x - 1)
      pos.y = RNG.int(room.p0.y + 1, room.p1.y - 1)
      valid = GeneratorUtils.isValidTileLocation(zone, pos) && zone.map.allNeighbours(pos).all {|tile| zone.map.isFloor(tile) }
      valid = valid && (!map[pos]["items"] || map[pos]["items"].isEmpty)
      attempts = attempts + 1
    }
    if (valid) {
      zone.map[pos]["solid"] = true
      zone.map[pos]["statue"] = true
      zone.map[pos]["blocking"] = false
    }
  }
  static placeStairs(zone, room) {
    var pos = Vec.new()
    var valid = false
    var attempts = 0
    while (!valid && attempts < 30) {
      pos.x = RNG.int(room.p0.x + 1, room.p1.x - 1)
      pos.y = RNG.int(room.p0.y + 1, room.p1.y - 1)
      valid = GeneratorUtils.isValidTileLocation(zone, pos)
      attempts = attempts + 1
    }
    zone.map[pos]["stairs"] = "down"
  }

  static placeEntities(zone, room, maxMonsters, maxItems) {
    var totalMonsters = RNG.int(maxMonsters + 1)
    var startPos = zone["start"]
    var level = zone["level"]
    var totalItems = RNG.int(maxItems + 1)
    var entities = zone["entities"]
    for (i in 0...totalMonsters) {
      var x = RNG.int(room.p0.x + 1, room.p1.x - 1)
      var y = RNG.int(room.p0.y + 1, room.p1.y - 1)

      var pos = Vec.new(x, y )

      if ((entities.isEmpty || !entities.any{|entity| entity.pos == pos }) && pos != startPos) {
        var entity = GeneratorUtils.pickEnemy(level)
        if (entity == null) {
          continue
        }
        entity = entity.new()
        entity.pos = pos
        entities.add(entity)
      }
    }
    for (i in 0...totalItems) {
      var x = RNG.int(room.p0.x + 1, room.p1.x - 1)
      var y = RNG.int(room.p0.y + 1, room.p1.y - 1)

      var pos = Vec.new(x, y)

      if ((entities.isEmpty || !entities.any{|entity| entity.pos == pos }) && pos != startPos) {
        //var itemId = RNG.sample(Items.findable).id
        var itemId = GeneratorUtils.pickItem(level) //RNG.sample(Items.findable).id
        if (itemId == null) {
          continue
        }
        zone.map[pos]["items"] = [ InventoryEntry.new(itemId, 1) ]
      }
    }
  }
}

class StartRoomGenerator {
  static generate(args) {
    var map = TileMap8.new()
    var center = Vec.new(15, 15)
    var range = 5
    for (y in 0...32) {
      for (x in 0...32) {
        var dist = (center - Vec.new(x, y)).manhattan
        var clear = (dist < range)
        //var clear = (x >= range && x < 32 - range && y >= range && y < 32 - range)
        map[x,y] = Tile.new({
          "blocking": !clear,
          "solid": !clear,
          "visible": (dist < range + 2) ? "maybe" : false
        })
      }
    }

    var level = args[0]
    var zone = Zone.new(map)
    zone["entities"] = []
    zone["level"] = level
    zone.map[Vec.new(15, 13)]["stairs"] = "down"
    zone["start"] = Vec.new(15, 17)

    var pos = Vec.new(12, 15)
    zone.map[pos]["solid"] = true
    zone.map[pos]["altar"] = true
    zone.map[pos]["blocking"] = false
    return zone
  }
}
class BossRoomGenerator {
  static generate(args) {
    var map = TileMap8.new()
    var center = Vec.new(15.50, 15.50)
    var range = 9
    for (y in 0...32) {
      for (x in 0...32) {
        var dist = (center - Vec.new(x, y)).length.round
        var clear = (dist < range)
        map[x,y] = Tile.new({
          "blocking": !clear,
          "solid": !clear,
          "visible": (dist < range + 2) ? "maybe" : false
        })
      }
    }

    var level = args[0]
    var zone = Zone.new(map)
    zone["level"] = level
    zone["entities"] = [ Creatures.demon.new() ]
    zone["entities"][0].pos = Vec.new(15, 13)

    for (i in 0...4) {
      var pos = (center + DIR_EIGHT[4 + i] * 3.5)
      zone["entities"].add(Creatures.gargoyle.new())
      pos.x = pos.x.floor
      pos.y = pos.y.floor
      zone["entities"][-1].pos = pos
    }
    zone.map[Vec.new(14, 20)]["statue"] = true
    zone.map[Vec.new(14, 20)]["solid"] = true
    zone.map[Vec.new(14, 20)]["blocking"] = false

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

import "./entities" for Player, Creatures
var Distribution = [
  {
    "items": [
      ["shortsword", 0.2],
      ["scroll", 0.3],
      ["wand", 0.4]
    ],
    "enemies": [
      [Creatures.rat, 0.4],
      [Creatures.zombie, 0.3],
      [Creatures.hound, 0.1]
    ]
  },
  {
    "items": [
      ["fireball", 0.05],
      ["chainmail", 0.2],
      ["longsword", 0.2],
      ["scroll", 0.2],
      ["potion", 0.3]
    ],
    "enemies": [
      [Creatures.rat, 0.2],
      [Creatures.zombie, 0.5],
      [Creatures.hound, 0.2]
    ]
  },
  {
    "items": [
      ["longsword", 0.05],
      ["potion", 0.05],
      ["platemail", 0.1],
      ["fireball", 0.1],
      ["wand", 0.15],
      ["scroll", 0.15]
    ],
    "enemies": [
      [Creatures.rat, 0.1],
      [Creatures.hound, 0.8]
    ]
  }
]
import "./items" for InventoryEntry, EquipmentSlot
import "./systems" for VisionSystem, DefeatSystem, InventorySystem, ConditionSystem, ExperienceSystem, StorySystem
import "./items" for Items
import "./oath" for OathSystem
