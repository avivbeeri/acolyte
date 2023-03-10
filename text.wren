import "graphics" for Color, Canvas
import "palette" for INK

class TextSplitter {
  static getWidth(lines) {
    var max = 0
    for (line in lines) {
      if (line.count > max) {
        max = line.count
      }
    }
    return max
  }

  static split(lines) {
    var line = 0
    var width = Canvas.width
    var glyphWidth = 8
    var lineHeight = 10
    for (i in startLine...endLine) {
      var text = lines[i]
      var x = 0
      var words = text.split(" ")
      for (word in words) {
        if (width - x * glyphWidth < word.count * glyphWidth) {
          x = 0
          line = line + 1
        }
        var y = start + dir * lineHeight * line
        if (y >= 0 && y + lineHeight <= Canvas.height) {
          Canvas.print(word, x * glyphWidth, start + dir * lineHeight * line, INK["text"])
        } else {
          break
        }
        x = x + (word.count + 1)
      }

      line = line + 1
      x = 0
    }
  }
}
