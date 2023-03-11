import "jukebox" for Jukebox
import "parcel" for ParcelMain, Scene
import "graphics" for Canvas, Font, ImageData
import "inputs" for VI_SCHEME as INPUT
import "palette" for INK

class StartScene is Scene {
  construct new(args) {
    super(args)
    Jukebox.register("soundTrack", "res/audio/soundtrack.ogg")
    Font.load("nightmare", "res/fonts/nightmare.ttf", 128)
    _area = [
      Font["nightmare"].getArea("Acolyte's"),
      Font["nightmare"].getArea("PLedge"),
    ]
    _book = ImageData.load("res/img/book.png")
    _t = 0
    _i = 0
    _a = 0
  }

  update() {
    _t = _t + 1
    if (_t == 15) {
      Jukebox.playMusic("soundTrack")
    }
    if (INPUT["confirm"].firing) {
      game.push(GameScene)
    }
    if (INPUT["volUp"].firing) {
      Jukebox.volumeUp()
    }
    if (INPUT["volDown"].firing) {
      Jukebox.volumeDown()
    }
    if (INPUT["mute"].firing) {
      if (Jukebox.playing) {
        Jukebox.stopMusic()
      } else {
        Jukebox.playMusic("soundTrack")
      }
    }
    var start = 2 * 60
    if (_t > 2 * 60) {
      _i = _i + 1
      var max = (5 * 60)
      _a = ((_i - start) / max).clamp(0, 1)
    }
  }


  ease(x) {
    return -((Num.pi * x).cos - 1) / 2
  }
  draw() {
      Canvas.cls(INK["mainBg"])
      _book.draw((Canvas.width - _book.width) / 2, (Canvas.height - _book.height) / 2)
      var filter = (_t > 28 && _t < 30 ? INK["white"] : INK["bg"]) * 1
      //var filter = INK["bg"] * 1
      filter.a = 255 - 192 * ease(_a)
      Canvas.rectfill(0, 0, Canvas.width, Canvas.height, filter)

    if (_t > 30) {
      var height = _area.reduce(0) {|acc, area| acc + area.y }
      var top = (Canvas.height - height) / 2
      var x0 = (Canvas.width - _area[0].x) / 2
      var x1 = (Canvas.width - _area[1].x) / 2
      var thick = 4
      for (y in -thick..thick) {
        for (x in -thick..thick) {
          Font["nightmare"].print("Acolyte's", x0 + x, top + y, INK["titleBg"])
          Font["nightmare"].print("Pledge", x1 + x, top + 128 + y, INK["titleBg"])
        }
      }
      Font["nightmare"].print("Acolyte's", x0, top, INK["titleFg"])
      Font["nightmare"].print("Pledge", x1, top + 128, INK["titleFg"])

      var x = (Canvas.width - 30 * 8)/ 2
      Canvas.print("Press SPACE or ENTER to begin", x, Canvas.height * 0.90, INK["title"])
    }
  }
}

import "./scene" for GameScene
var Game = ParcelMain.new(StartScene)
