import "parcel" for TileMap8, Tile, Zone, Line, RNG
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
  static generateDungeon(args) {
    var maxRooms = 18
    var minSize = 5
    var maxSize = 10

    var map = TileMap8.new()
    var level = args[0]
    var zone = Zone.new(map)
    zone["level"] = level
    zone["title"] = "The Courtyard"

    for (y in 0...32) {
      for (x in 0...32) {
        map[x,y] = Tile.new({
          "solid": true
        })
      }
    }

    var rooms = []
    for (i in 0...maxRooms) {
      var w = RNG.int(minSize, maxSize + 1)
      var h = RNG.int(minSize, maxSize + 1)
      var x = RNG.int(0, 32 - w - 1)
      var y = RNG.int(0, 32 - h - 1)

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
        var target = rooms[-1]
        if (rooms.count > 3 && i == maxRooms - 1) {
          target = rooms[-3]
        }
        Generator.tunnelBetween(map, room.center, target.center)
      } else {
        zone["start"] = room.center
      }
      rooms.add(room)
    }

    return zone
  }
  static generate(args) {

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
    }
    for (point in Line.walk(Vec.new(4,21), Vec.new(17,21))) {
        map[point]["solid"] = true
    }

    var level = args[0]
    var zone = Zone.new(map)
    zone["level"] = level
    zone["title"] = "The Courtyard"
    return zone
  }
}
