import "parcel" for Event

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

