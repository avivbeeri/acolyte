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
  add(text, color, stack) {
    if (stack && _messages.count > 0) {
      var last = _messages[-1]
      if (last.text == text) {
        last.stack()
        return
      }
    }

    _messages.add(Message.new(text, color))
    Log.i(text)
  }

  history(count) {
    count = count.min(_messages.count)
    return _messages[(-count)..-1]
  }

}
