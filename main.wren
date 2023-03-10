import "parcel" for ParcelMain, Scene
import "graphics" for Canvas, Font, ImageData
import "inputs" for VI_SCHEME as INPUT
import "palette" for INK
import "./scene" for GameScene

class StartScene is Scene {
  construct new(args) {
    super(args)
    Font.load("nightmare", "res/fonts/nightmare.ttf", 128)
    _area = [
      Font["nightmare"].getArea("Acolyte's"),
      Font["nightmare"].getArea("PLedge"),
    ]
    _book = ImageData.load("res/img/book.png")
  }

  update() {
    if (INPUT["confirm"].firing) {
      game.push(GameScene)
    }
  }

  draw() {
    Canvas.cls(INK["bg"])
    _book.draw((Canvas.width - _book.width) / 2, (Canvas.height - _book.height) / 2)
    var filter = INK["bg"] * 1
    filter.a = 128
    Canvas.rectfill(0, 0, Canvas.width, Canvas.height, filter)
    var height = _area.reduce(0) {|acc, area| acc + area.y }
    var top = (Canvas.height - height) / 2
    var x0 = (Canvas.width - _area[0].x) / 2
    var x1 = (Canvas.width - _area[1].x) / 2
    var thick = 4
    for (y in -thick..thick) {
      for (x in -thick..thick) {
        Font["nightmare"].print("Acolyte's", x0 + x, top + y, INK["red"])
        Font["nightmare"].print("Pledge", x1 + x, top + 128 + y, INK["red"])
      }
    }
    Font["nightmare"].print("Acolyte's", x0, top, INK["title"])
    Font["nightmare"].print("Pledge", x1, top + 128, INK["title"])

    var x = (Canvas.width - 30 * 8)/ 2
    Canvas.print("Press SPACE or ENTER to begin", x, top + 256 + 32, INK["title"])
  }
}

var Game = ParcelMain.new(StartScene)
