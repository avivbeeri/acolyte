import "parcel" for TileMap8, Tile, Zone, Line
import "math" for Vec

class Generator {
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
