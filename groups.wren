import "meta" for Meta
import "parcel" for Scheduler
var ImportedNames = []
var IGNORE_LIST = Meta.getModuleVariables("groups")
/* [
  "Object",
  "Meta",
  "Class",
  "Bool",
  "Fiber",
  "Fn",
  "Null",
  "Num",
  "Sequence",
  "MapSequence",
  "SkipSequence",
  "TakeSequence",
  "WhereSequence",
  "List",
  "String",
  "StringByteSequence",
  "StringCodePointSequence",
  "Map",
  "MapKeySequence",
  "MapValueSequence",
  "MapEntry",
  "Range",
  "System",
  "ClassAttributes"
]
*/

class ClassGroup {
  static imports {
    if (!__imports) {
      __imports = []
    }
    return __imports
  }
  static scanModule(module) {
    var moduleImports = []
    var members = {}
    for (variableName in Meta.getModuleVariables(module)) {
      if (variableName.contains(" ")) {
        continue
      }
      if (IGNORE_LIST.contains(variableName) || ImportedNames.contains(variableName)) {
        continue
      }
      ImportedNames.add(variableName)
      moduleImports.add(variableName)
    }
    var varList = moduleImports.join(", ")
  //  System.print("import \"%(module)\" for %(varList)")
    Meta.eval("import \"%(module)\" for %(varList)")
    for (variableName in moduleImports) {
      var closure = Meta.compileExpression(variableName)
      if (closure == null) {
        continue
      }
      var variable = Fiber.new(closure).try()
      if (variable is Class && variable.attributes && variable.attributes.self["component"]) {
        imports.add(variable)
      }
    }
  }

  static create(name, group) {
    if (name.type != String || name == "") Fiber.abort("Name must be a non-empty string.")

    var members = {}
    for (variable in imports) {
      var component = variable.attributes.self["component"]
      var id = variable.attributes.self["component"]["id"][0]
      var varGroup = variable.attributes.self["component"]["group"][0]
      if (varGroup == group) {
        members[id] = variable
      }
    }

    name = name +  "Group_"
    var s = "class %(name) {\n"
    for (entry in members) {
      var field = entry.key
      s = s + "  static %(field) { %(entry.value) }\n"
    }
    s = s + "}\n"
    // System.print(s)
    s = s + "return %(name)"
    return Meta.compile(s).call()
  }
}

class Components {
  static events { __events }
  static events=(v) { __events = v }

  static actions { __actions }
  static actions=(v) { __actions = v }

  static behaviour { __behaviour }
  static behaviour=(v) { __behaviour = v }
}

Scheduler.defer {

  ClassGroup.scanModule("parcel")
  ClassGroup.scanModule("behaviour")
  ClassGroup.scanModule("actions")
  ClassGroup.scanModule("items")

  Components.events = ClassGroup.create("Events", "event")
  Components.behaviours = ClassGroup.create("Behaviours", "behaviour")
  Components.actions = ClassGroup.create("Actions", "action")
}
