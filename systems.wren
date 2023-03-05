import "fov" for Vision, Vision2
import "parcel" for GameSystem, JPS

class VisionSystem is GameSystem {
  construct new() { super() }
  postUpdate(ctx, actor) {
    var player = ctx.getEntityByTag("player")
    if (!player) {
      return
    }
    var map = ctx.zone.map
    for (y in map.yRange) {
      for (x in map.xRange) {
        map[x, y]["seen"] = false
        map[x, y]["cost"] = null
        if (map[x, y]["visible"]) {
          map[x, y]["visible"] = "maybe"
        } else {
          map[x, y]["visible"] = false
        }
      }
    }
    Vision2.new(map, player.pos, 8).compute()
    // search(map, player.pos)
  }

  search(map, origin, target) {
    if (!origin) {
      return
    }
    for (y in map.yRange) {
      for (x in map.xRange) {
        map[x, y]["seen"] = false
        map[x, y]["cost"] = null
      }
    }
    var search = JPS.fastSearch(map, origin, target)
    JPS.buildFastPath(map, origin, target, search)
  }
}

