import "parcel" for Entity

class Player is Entity {
  construct new() {
    super()
    this["symbol"] = "@"
    this["solid"] = true
  }
  name { "Player" }
  pushAction(action) {
    if (hasActions()) {
      return
    }
    super.pushAction(action)
  }
  getAction() {
    if (hasActions()) {
      return super.getAction()
    }
    return null
  }
}

