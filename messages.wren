import "dome" for Log
class Message {

  construct new(text, color) {
    _text = text
    _color = color
    _count = 1
  }
  text { _text }
  color { _color }
  count { _count }

  stack() {
    _count = _count + 1
  }
}

class MessageLog {
  construct new() {
    _messages = []
  }
  count { _messages.count }
  add(text, color, stack) {
    if (stack && _messages.count > 0) {
      var last = _messages[0]
      if (last.text == text) {
        last.stack()
        return
      }
    }

    _messages.insert(0, Message.new(text, color))
    Log.i(text)
  }

  history(start, length) {
    start = start.clamp(0, _messages.count)
    var end = (start + length).clamp(0, _messages.count)
    return _messages[start...end]
  }
  previous(count) {
    count = count.clamp(0, _messages.count)
    return _messages[0...count]
  }

}
