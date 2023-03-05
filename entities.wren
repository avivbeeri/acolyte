import "parcel" for Entity

class Player is Entity {
  construct new() {
    super()
    this["symbol"] = "@"
  }
  name { "Player" }
  getAction() {
    if (hasActions()) {
      return super.getAction()
    }
    return null
  }
}

