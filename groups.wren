import "registry" for ClassRegistry
import "parcel" for DataFile, Parcel, Reflect

var componentGroups = {
  "modules": [
    "parcel",
    "actions",
    "behaviours",
    "items",
    "oath",
    "events"
  ],
  "groups": {
    "events": "event",
    "actions": "action",
    "behaviours": "behaviour"
  }
}
// Create a data class
var Components = Parcel.create("Components", ["events", "actions", "behaviours"], false).new()

for (module in componentGroups["modules"]) {
  ClassRegistry.scanModule(module)
}
ClassRegistry.buildImports()

for (registry in componentGroups["groups"]) {
  var id = registry.key
  var kind = registry.value
  Reflect.set(Components, id, ClassRegistry.create(id, kind))
}
