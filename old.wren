import "dome" for Platform
import "combat"
import "graphics" for Canvas, Color
import "math" for Vec
import "fov" for Vision, Vision2
import "input" for Keyboard, Mouse, InputGroup
import "parcel" for
  TextInputReader,
  DIR_EIGHT,
  MAX_TURN_SIZE,
  ParcelMain,
  GameSystem,
  TextUtils,
  TurnEvent,
  Scene,
  Element,
  World,
  Entity,
  FastAction,
  FakeAction,
  Log,
  TileMap8,
  TileMap4,
  Tile,
  Zone,
  Action,
  ActionResult,
  BreadthFirst,
  Dijkstra,
  Line,
  Palette,
  JPS,
  AStar

var Search = BreadthFirst
var Target = Vec.new(16, 11)
var Pal = Palette.new()
Pal.addColor("white", Color.new(255, 255, 255))
Pal.addColor("gray", Color.darkgray)
Pal.addColor("black", Color.new(0, 0, 0))
Pal.addColor("red", Color.new(255, 0, 0))
Pal.addColor("green", Color.new(0, 255, 0))
Pal.addColor("blue", Color.new(0, 255, 255))

Pal.setPurpose("floor", "gray")
Pal.setPurpose("wall", "white")


class Box is Element {
  construct new(pos, size, color) {
    super()
    _pos = pos
    _size = size
    _color = color || Color.red
  }
  pos { _pos }
  size { _size }
  color { _color }
  draw() {
    Canvas.rect(pos.x, pos.y, size.x, size.y, color)
  }
}
class Button is Box {
  construct new(pos, size, text, color) {
    super(pos, size, color)
    _text = text
  }

  text { _text }

  update() {
    if (Mouse["left"].justPressed) {
      System.print("click")
      System.print(Mouse.pos)
      if (Mouse.x >= pos.x &&
          Mouse.y >= pos.y &&
          Mouse.x < pos.x + size.x &&
          Mouse.y < pos.y + size.y) {
        System.print("close")
        removeSelf()
        return
      }
    }
    super.update()
  }

  draw() {
    var offset = (size.y / 2) - 4
    var location = pos + Vec.new(0, offset)
    location = pos
    TextUtils.print(text, {
      "position": location,
      "size": size,
      "color": color,
      "align":"left"
    })
    super.draw()
  }
}



var Game = ParcelMain.new(TestScene)

