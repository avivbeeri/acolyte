import "parcel" for Event

class LightningEvent is Event {
  construct new(target) {
    super()
    data["src"] = target
  }
  target { data["src"] }
}

class UseItemEvent is Event {
  construct new(src, itemId) {
    super()
    data["src"] = src
    data["item"] = itemId
  }

  src { data["src"] }
  item { data["item"] }
}

class PickupEvent is Event {
  construct new(src, itemId, qty) {
    super()
    data["src"] = src
    data["item"] = itemId
    data["qty"] = qty
  }

  src { data["src"] }
  item { data["item"] }
  qty { data["qty"] }
}

class RestEvent is Event {
  construct new(src) {
    super()
    data["src"] = src
  }

  src { data["src"] }
}

