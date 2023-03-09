import "parcel" for TileMap8, Tile, Zone, Line, RNG, Entity
import "math" for Vec

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

class Generator {
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
    zone["title"] = "The Courtyard"
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
        Generator.tunnelBetween(map, room.center, rooms[-1].center)
      } else if (!startPos) {
        startPos = room.center
      }
      rooms.add(room)

      Generator.placeEntities(zone, room, monstersPerRoom, itemsPerRoom)
    }

    // USE THIS IF WE DON'T WANT TO START ON STAIRS
    // startPos = RNG.shuffle(map.neighbours(startPos))[0]
    zone["start"] = startPos
    // Add a cycle
    if (rooms.count > 3) {
      var start = RNG.int(0, rooms.count - 3)
      var end = start + 3
      Generator.tunnelBetween(map, rooms[start].center, rooms[end].center)
    }
    var finalRoom = rooms[-1]
    Generator.placeStairs(zone, finalRoom)
    zone.map[startPos]["stairs"] = "up"

    return zone
  }
  static placeStairs(zone, room) {
    var entities = zone["entities"]
    var pos = Vec.new()
    pos.x = RNG.int(room.p0.x + 1, room.p1.x - 1)
    pos.y = RNG.int(room.p0.y + 1, room.p1.y - 1)

    while (!entities.isEmpty && entities.any{|entity| entity.pos == pos }) {
      pos.x = RNG.int(room.p0.x + 1, room.p1.x - 1)
      pos.y = RNG.int(room.p0.y + 1, room.p1.y - 1)
    }

    zone.map[pos]["stairs"] = "down"
  }

  static placeEntities(zone, room, maxMonsters, maxItems) {
    var totalMonsters = RNG.int(maxMonsters + 1)
    var totalItems = RNG.int(maxItems + 1)
    var entities = zone["entities"]
    for (i in 0...totalMonsters) {
      var x = RNG.int(room.p0.x + 1, room.p1.x - 1)
      var y = RNG.int(room.p0.y + 1, room.p1.y - 1)

      var pos = Vec.new(x, y )

      if (entities.isEmpty || !entities.any{|entity| entity.pos == pos }) {
        var entity = Rat.new()
        entity.pos = pos
        entities.add(entity)
      }
    }
    for (i in 0...totalItems) {
      var x = RNG.int(room.p0.x + 1, room.p1.x - 1)
      var y = RNG.int(room.p0.y + 1, room.p1.y - 1)

      var pos = Vec.new(x, y)

      if (entities.isEmpty || !entities.any{|entity| entity.pos == pos }) {
        var r = RNG.float()
        var itemId = "potion"
        System.print(r)
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

  static generateTest(args) {

    var map = TileMap8.new()
    for (y in 0...32) {
      for (x in 0...32) {
        map[x,y] = Tile.new({
          "solid": false
        })
      }
    }
    map[12, 16]["solid"] = true
    map[13, 17]["solid"] = true
    for (point in Line.walk(Vec.new(4,19), Vec.new(17,19))) {
        map[point]["solid"] = true
        map[point]["blocking"] = true
    }
    for (point in Line.walk(Vec.new(4,21), Vec.new(17,21))) {
        map[point]["solid"] = true
        map[point]["blocking"] = true
    }

    var level = args[0]
    var zone = Zone.new(map)
    zone["level"] = level
    zone["title"] = "The Courtyard"
    return zone
  }
}

import "./items" for InventoryEntry
import "./entities" for Rat
