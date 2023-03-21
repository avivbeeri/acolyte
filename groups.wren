import "registry" for ClassRegistry

class Components {
  static events { __events }
  static events=(v) { __events = v }

  static actions { __actions }
  static actions=(v) { __actions = v }

  static behaviours { __behaviours }
  static behaviours=(v) { __behaviours = v }
}

ClassRegistry.scanModule("parcel")
ClassRegistry.scanModule("actions")
ClassRegistry.scanModule("behaviours")
ClassRegistry.scanModule("items")
ClassRegistry.scanModule("oath")
ClassRegistry.scanModule("events")
ClassRegistry.buildImports()

Components.events = ClassRegistry.create("Events", "event")
Components.behaviours = ClassRegistry.create("Behaviours", "behaviour")
Components.actions = ClassRegistry.create("Actions", "action")
