import "dome" for Process, Log
import "graphics" for Canvas, Color
import "input" for Keyboard, Mouse
import "math" for Vec
import "parcel" for
  DIR_EIGHT,
  Scene,
  State,
  World,
  Entity,
  TurnEvent,
  Line,
  GameEndEvent

import "./palette" for INK
import "./inputs" for VI_SCHEME as INPUT
import "./messages" for MessageLog
import "./ui" for TextComplete, TextChanged, TargetEvent, TargetBeginEvent, TargetEndEvent, HoverEvent
import "./renderer" for
  AsciiRenderer,
  HealthBar,
  LineViewer,
  LogViewer,
  HistoryViewer,
  CharacterViewer,
  HoverText


import "./actions" for BumpAction, RestAction, DescendAction
import "./entities" for Player
import "./events" for Events,RestEvent, PickupEvent, UseItemEvent, LightningEvent
import "./systems" for VisionSystem, DefeatSystem, InventorySystem, ConditionSystem, ExperienceSystem
import "./generator" for WorldGenerator
import "./combat" for AttackEvent, DefeatEvent, HealEvent
import "./items" for ItemAction, PickupAction, Items,  Equipment

class InventoryWindowState is State {
  construct new(scene) {
    super()
    _scene = scene
  }
  onEnter() {
    var border = 24
    var world = _scene.world
    var worldItems = world["items"]

    var player = _scene.world.getEntityByTag("player")
    var playerItems = player["inventory"]
    var i = 0
    var label = ""
    var items = playerItems.map {|entry|
      i = i + 1
      var letter = getKey(i)
      if (worldItems[entry.id] is Equipment) {
        var item = worldItems[entry.id]
        if (player["equipment"][item.slot] == entry.id) {
          label = "(equipped)"
        }
      }
      return "%(letter)) %(entry.qty)x %(worldItems[entry.id].name) %(label)"
    }.toList
    items.insert(0, "")
    var max = 0
    for (line in items) {
      if (line.count > max) {
        max = line.count
      }
    }

    var title = ""
    max = max.max(13)
    var width = ((max - 7) / 2).ceil
    for (i in 0...width) {
      title = "%(title)-"
    }
    title = "%(title) ITEMS %(title)"
    items.insert(0, title)
    var x = Canvas.width - (max * 8 + 8)
    _window = LineViewer.new(Vec.new(x, border), Vec.new(Canvas.width - border*2, Canvas.height - border*2), items.count, items)
    _scene.addElement(_window)
  }
  onExit() {
    _scene.removeElement(_window)
  }
  getKey(i) {
    var letter = i.toString
    if (i > 9) {
      letter = String.fromByte(97 + i)
    }
    if (i > 9 + 26) {
      Fiber.abort("inventory is huge")
    }
    return letter
  }
  update() {
    var player = _scene.world.getEntityByTag("player")
    var playerItems = player["inventory"]

    var i = 1
    for (entry in playerItems) {
      var letter = getKey(i)
      var item = _scene.world["items"][entry.id]
      if (Keyboard[letter].justPressed) {
        var query = item.query("use")
        if (!query["target"]) {
          //player.pushAction(item.default(player, []))
          player.pushAction(ItemAction.new(entry.id))
          return PlayerInputState.new(_scene)
        } else {
          query["item"] = entry.id
          return TargetQueryState.new(_scene, query)
        }
      }
      i = i + 1
    }
    if (INPUT["reject"].firing || INPUT["confirm"].firing) {
      return PlayerInputState.new(_scene)
    }
    return this
  }
}

class TargetQueryState is State {
  construct new(scene, query) {
    super()
    _scene = scene
    var player = scene.world.getEntityByTag("player")
    _origin = player.pos
    _cursorPos = player.pos
    _hoverPos = null

    _query = query
    _range = query["range"]
    _area = query["area"] || 1
    _allowSolid = query.containsKey("allowSolid") ? query["allowSolid"] : false
    _needEntity = query.containsKey("needEntity") ? query["needEntity"] : true
    _needSight = query.containsKey("needSight") ? query["needSight"] : true
  }

  onEnter() {
    _scene.process(TargetBeginEvent.new(_cursorPos, _area))
  }
  onExit() {
    _scene.process(TargetEndEvent.new())
  }
  process(event) {
    if (event is HoverEvent &&
        event.target &&
        event.target is Entity &&
        cursorValid(_origin, event.target.pos)) {
      _hoverPos = event.target.pos
    }
  }
  targetValid(origin, position) {
      // check next
    var map = _scene.world.zone.map
    if (!_allowSolid && map[position]["solid"]) {
      return false
    }
    if (_needSight && map[position]["visible"] != true) {
      return false
    }
    if (_range && Line.chebychev(position, origin) > _range) {
      return false
    }

    if (_needEntity && _scene.world.getEntitiesAtPosition(position).isEmpty) {
      return false
    }

    return true
  }
  cursorValid(origin, position) {
      // check next
    var map = _scene.world.zone.map
    if (!_allowSolid && map[position]["solid"]) {
      return false
    }
    if (_needSight && map[position]["visible"] != true) {
      return false
    }
    if (_range && Line.chebychev(position, origin) > _range) {
      return false
    }

    return true
  }
  update() {
    if (INPUT["reject"].firing) {
      return PlayerInputState.new(_scene)
    }
    if ((INPUT["confirm"].firing || Mouse["left"].justPressed) && targetValid(_origin, _cursorPos)) {
      var player = _scene.world.getEntityByTag("player")
      player.pushAction(ItemAction.new(_query["item"], [ _cursorPos, _area ]))
      return PlayerInputState.new(_scene)
    }

    // TODO handle mouse targeting

    var i = 0
    var next = null
    for (input in INPUT.list("dir")) {
      if (input.firing) {
        next = _cursorPos + DIR_EIGHT[i]
      }
      i = i + 1
    }

    if (_hoverPos) {
      _cursorPos = _hoverPos
      _scene.process(TargetEvent.new(_cursorPos))
    }
    if (next && cursorValid(_origin, next)) {
      _cursorPos = next
      _scene.process(TargetEvent.new(_cursorPos))
    }

    return this
  }
}

class ConfirmState is State {
  construct new(scene) {
    super()
    _scene = scene
  }
  onEnter() {
  }
  onExit() {
  }
  update() {
    if (INPUT["confirm"].firing) {
      Process.exit()
      return
    } else if (INPUT["reject"].firing) {
      return PlayerInputState.new(_scene)
    }
    return this
  }
}
class ModalWindowState is State {
  construct new(scene, window) {
    super()
    _scene = scene
    _window = window
  }
  onEnter() {
    var border = 24
    if (_window == "history") {
      _window = HistoryViewer.new(Vec.new(border, border), Vec.new(Canvas.width - border*2, Canvas.height - border*2), _scene.messages)
    } else if (_window == "character") {
      _window = CharacterViewer.new(Vec.new(border, border), Vec.new(Canvas.width - border*2, Canvas.height - border*2))
    }
    _scene.addElement(_window)
  }
  onExit() {
    _scene.removeElement(_window)
  }
  update() {
    if (INPUT["reject"].firing || INPUT["confirm"].firing) {
      return PlayerInputState.new(_scene)
    }
    return this
  }
}

class PlayerInputState is State {

  construct new(scene) {
    super()
    _scene = scene
    _world = scene.world
  }

  update() {
     /* TODO temp */
    if (INPUT["inventory"].firing) {
      return InventoryWindowState.new(_scene)
    }
    if (INPUT["log"].firing) {
      return ModalWindowState.new(_scene, "history")
    }
    if (INPUT["info"].firing) {
      return ModalWindowState.new(_scene, "character")
    }
    if (INPUT["exit"].firing) {
      return ConfirmState.new(_scene)
    }

    if (_world.complete) {
      if (INPUT["confirm"].firing) {
        _scene.game.push(GameScene)
      }
      return this
    }

    var player = _world.getEntityByTag("player")
    var i = 0
    for (input in INPUT.list("dir")) {
      if (input.firing) {
        player.pushAction(BumpAction.new(DIR_EIGHT[i]))
      }
      i = i + 1
    }
    if (INPUT["rest"].firing) {
      player.pushAction(RestAction.new())
    }
    if (INPUT["pickup"].firing) {
      player.pushAction(PickupAction.new())
    }
    if (INPUT["descend"].justPressed) {
      player.pushAction(DescendAction.new())
    }

    return this
  }
}

class GameScene is Scene {
  construct new(args) {
    super(args)
    _t = 0
    _messages = MessageLog.new()
    _messages.add("Welcome, acolyte, to the catacombs. It's time to decend.", INK["welcome"], false)

    var world = _world = World.new()
    _world.generator = WorldGenerator
    _world.systems.add(InventorySystem.new())
    _world.systems.add(ExperienceSystem.new())
    _world.systems.add(ConditionSystem.new())
    _world.systems.add(DefeatSystem.new())
    _world.systems.add(VisionSystem.new())
    _world["items"] = {
      "sword": Items.sword,
      "potion": Items.healthPotion,
      "scroll": Items.lightningScroll,
      "wand": Items.confusionScroll,
      "fireball": Items.fireballScroll
    }
    var zone = world.loadZone(0)
    world.addEntity("player", Player.new())
    var player = world.getEntityByTag("player")
    player.pos = zone["start"]

    _name = ""
    _currentText = ""

    world.start()
    _state = PlayerInputState.new(this)
    addElement(AsciiRenderer.new(Vec.new(0, 9)))
    addElement(HealthBar.new(Vec.new(0, 0), player.ref))
    addElement(HoverText.new(Vec.new(Canvas.width, 0)))
    addElement(LogViewer.new(Vec.new(0, Canvas.height - 60), _messages))
    //addElement(LogViewer.new(Vec.new(0, Canvas.height - 12 * 7), _messages))
  }

  world { _world }
  messages { _messages }
  events { _state.events }

  process(event) {
    _state.process(event)
    super.process(event)
  }

  update() {
    super.update()
    // Global animation timer
    _t = _t + 1

    _state.events.clear()
    var nextState = _state.update()
    for (event in _state.events) {
      if (event is TextComplete) {
        _currentText = ""
        _name = event.text
      }
      if (event is TextChanged) {
        _currentText = event.text
      }
    }

    if (nextState != _state) {
      _state.onExit()
      nextState.onEnter()
      _state = nextState
    }

    _world.advance()
    for (event in _world.events) {
      if (event is GameEndEvent) {
        _messages.add("The game has ended", INK["playerDie"], false)
      }
      if (event is AttackEvent) {
        _messages.add("%(event.src.name) attacked %(event.target.name) for %(event.result) damage.", INK["enemyAtk"], true)
      }
      if (event is LightningEvent) {
        _messages.add("%(event.target) was struck by lightning.", INK["playerAtk"], false)
      }
      if (event is DefeatEvent) {
        _messages.add("%(event.target) was defeated.", INK["text"], false)
      }
      if (event is HealEvent) {
        _messages.add("%(event.target) was healed for %(event.amount)", INK["healthRecovered"], false)
      }
      if (event is RestEvent) {
        _messages.add("%(event.src) rests.", INK["text"], true)
      }
      if (event is Events.unequipItem) {
        var itemName = _world["items"][event.item]["name"]
        _messages.add("%(event.src) removed the %(itemName)", INK["text"], false)
      }
      if (event is Events.equipItem) {
        var itemName = _world["items"][event.item]["name"]
        _messages.add("%(event.src) equipped the %(itemName)", INK["text"], false)
      }
      if (event is PickupEvent) {
        var itemName = _world["items"][event.item]["name"]
        _messages.add("%(event.src) picked up %(event.qty) %(itemName)", INK["text"], false)
      }
      if (event is UseItemEvent) {
        var itemName = _world["items"][event.item]["name"]
        _messages.add("%(event.src) used %(itemName)", INK["text"], false)
      }
      if (event is Events.inflictCondition) {
        _messages.add("%(event.target) became confused.", INK["text"], false)
      }
      if (event is Events.extendCondition) {
        _messages.add("%(event.target)'s confusion was extended.", INK["text"], false)
      }
      if (event is Events.clearCondition) {
        _messages.add("%(event.target) recovered from %(event.condition).", INK["text"], false)
      }
      if (event is Events.descend) {
        _messages.add("You descend down the stairs.", INK["text"], false)
      }
    }
  }

  draw() {
    var color = INK["black"]
    Canvas.cls(color)
    super.draw()

    Canvas.print(_name, 0, Canvas.height - 17, Color.white)
  }
}
