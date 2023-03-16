import "math" for M, Vec
import "collections" for PriorityQueue, HashMap,Set
import "parcel" for TileMap, Zone, Line, TileMap8

class JPS2 {
  construct new(zone, self) {
    _zone = zone
    _map = zone
    _self = self
    if (!(map is TileMap8) && !(map is Zone && map.map is TileMap8)) {
      Fiber.abort("JPS only works with TileMap8")
    }
    if (zone is TileMap) {
      _map = zone
    } else if (zone is Zone) {
      _map = zone.map
    }
    _zoneEntities = zone.ctx.entities()
    _occupation = HashMap.new()
    for (entity in _zoneEntities) {
      if (entity != self && entity["solid"]) {
        _occupation[entity.pos] = true
      }
    }
  }
  map { _map }
  zone { _zone }
  self { _self }
  isFloor(x, y) {
    // _zoneEntities.where{|other| other.id != self.id && other.occupies(x, y) && other["solid"] }
    var occupied = _occupation[Vec.new(x, y)]
    return (_map.isFloor(x, y) && occupied)
  }
  isFloor(v) { isFloor(v.x, v.y) }

  heuristic(a, b) {
    var cardinal = 5
    var diagonal = 7

    var dMinus = diagonal - cardinal
    var dx = (a.x - b.x).abs
    var dy = (a.y - b.y).abs
    if (dx > dy) {
      return cardinal * dx + dMinus * dy
    }
    return cardinal * dy + dMinus * dx
  }

  search(start, goal) {

    if (goal == null) {
      Fiber.abort("JPS doesn't work without a goals")
    }
    var goals = map.neighbours(goal)

    // Cost maps
    var fMap = HashMap.new()
    var gMap = HashMap.new()
    var hMap = HashMap.new()

    // visitation structures
    var open = PriorityQueue.min()
    var parentMap = HashMap.new()
    var closed = Set.new()

    if (start is Sequence) {
      Fiber.abort("JPS doesn't support multiple goals")
    }

    open.add(start, 0)
    parentMap[start] = null

    while (!open.isEmpty) {
      var node = open.remove()
      closed.add(node)
      if (goals.contains(node)) {
        parentMap[goal] = node
        return backtrace(node, parentMap)
      }
      identifySuccessors(node, goal, goals, open, closed, parentMap, fMap, gMap, hMap)
    }
    System.print("failed")
    return null
  }

  findNeighbours(node, parentMap) {
    var neighbours = Set.new()
    var parent = parentMap[node]
    if (parent != null) {
      var x = node.x
      var y = node.y
      var dx = M.mid(-1, x - parent.x, 1)
      var dy = M.mid(-1, y - parent.y, 1)
      if (dx != 0 && dy != 0) {
        if (map.isFloor(x, y + dy)) {
          neighbours.add(Vec.new(x, y + dy))
        }
        if (map.isFloor(x + dx, y)) {
          neighbours.add(Vec.new(x + dx, y))
        }
        if ((map.isFloor(x, y + dy) && map.isFloor(x + dx, y))) {
          neighbours.add(Vec.new(x + dx, y + dy))
        }
      } else {
        if (dx != 0) {
          var nextWalkable = map.isFloor(x + dx, y)
          var topWalkable = map.isFloor(x, y + 1)
          var bottomWalkable = map.isFloor(x, y - 1)
          if (nextWalkable) {
            neighbours.add(Vec.new(x + dx, y))
            if (topWalkable) {
              neighbours.add(Vec.new(x + dx, y + 1))
            }
            if (bottomWalkable) {
              neighbours.add(Vec.new(x + dx, y - 1))
            }
          }
          if (topWalkable) {
            neighbours.add(Vec.new(x, y + 1))
          }
          if (bottomWalkable) {
            neighbours.add(Vec.new(x, y - 1))
          }
        } else if (dy != 0) {
          var nextWalkable = map.isFloor(x, y + dy)
          var rightWalkable = map.isFloor(x + 1, y)
          var leftWalkable = map.isFloor(x - 1, y)
          if (nextWalkable) {
            neighbours.add(Vec.new(x, y + dy))
            if (rightWalkable) {
              neighbours.add(Vec.new(x + 1, y + dy))
            }
            if (leftWalkable) {
              neighbours.add(Vec.new(x - 1, y + dy))
            }
          }
          if (rightWalkable) {
            neighbours.add(Vec.new(x + 1, y))
          }
          if (leftWalkable) {
            neighbours.add(Vec.new(x - 1, y))
          }
        }
      }
    } else {
      for (next in map.neighbours(node)) {
        neighbours.add(next)
      }
    }

    return neighbours
  }

  identifySuccessors(node, goal, goals, open, closed, parentMap, fMap, gMap, hMap) {
    var neighbours = findNeighbours(node, parentMap)
    var d
    var ng
    for (neighbour in neighbours) {
      var jumpNode = jump(neighbour, node, goals)
      if (jumpNode == null || closed.contains(jumpNode)) {
        continue
      }
      d = Line.chebychev(jumpNode, node)
      ng = (gMap[node] || 0) + d
      if (!open.contains(jumpNode) || ng < (gMap[jumpNode] || 0)) {
        var g = ng
        var h = heuristic(jumpNode, goal)
        gMap[jumpNode] = g
        hMap[jumpNode] = h
        var f = g + h
        fMap[jumpNode] = f
        parentMap[jumpNode] = node
        if (!open.contains(jumpNode)) {
          open.add(jumpNode, f)
        }
      }
    }
  }

  jump(neighbour, current, goals) {
    if (neighbour == null || !map.isFloor(neighbour)) {
      return null
    }
    if (goals.contains(neighbour)) {
      return neighbour
    }

    var dx = neighbour.x - current.x
    var dy = neighbour.y - current.y

    if (dx != 0 && dy != 0) {
      if ((jump(Vec.new(neighbour.x + dx, neighbour.y), neighbour, goals) != null) ||
          (jump(Vec.new(neighbour.x, neighbour.y + dy), neighbour, goals) != null)) {
        return neighbour
      }
    } else {
      if (dx != 0) {
        if ((map.isFloor(neighbour.x, neighbour.y - 1) && !map.isFloor(neighbour.x - dx, neighbour.y - 1)) ||
           (map.isFloor(neighbour.x, neighbour.y + 1) && !map.isFloor(neighbour.x - dx, neighbour.y + 1))) {
          return neighbour
        }
      } else if (dy != 0) {
        if ((map.isFloor(neighbour.x - 1, neighbour.y) && !map.isFloor(neighbour.x - 1, neighbour.y - dy)) ||
           (map.isFloor(neighbour.x + 1, neighbour.y) && !map.isFloor(neighbour.x + 1, neighbour.y - dy))) {
          return neighbour
        }

      }
    }

    if (map.isFloor(neighbour.x + dx, neighbour.y) && map.isFloor(neighbour.x, neighbour.y + dy)) {
      return jump(Vec.new(neighbour.x + dx, neighbour.y + dy), neighbour, goals)
    } else {
      return null
    }
  }

  backtrace(goal, parentMap) {
    var current = goal
    if (!parentMap) {
      Fiber.abort("There is no valid path")
      return
    }
    if (parentMap[goal] == null) {
      return null // There is no valid path
    }

    var path = []
    var next = null
    while (current != null) {
      path.add(current)
      next = parentMap[current]
      if (next == null) {
        break
      }
      var dx = M.mid(-1, next.x - current.x, 1)
      var dy = M.mid(-1, next.y - current.y, 1)
      var unit = Vec.new(dx, dy)

      var intermediate = current
      while (intermediate != next) {
        path.insert(0, intermediate)
        intermediate = intermediate + unit
      }
      current = next
    }
    path.insert(0, current)
    for (pos in path) {
      map[pos]["seen"] = true
    }
    return path
  }
}
