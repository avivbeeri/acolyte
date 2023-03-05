import "parcel" for Entity

class Player is Entity {
  construct new() {
    super()
  }
  name { "Player" }
  getAction() {
    if (hasActions()) {
      return super.getAction()
    }
    return null
  }
}

