import "jukebox" for Jukebox
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
  ChangeZoneEvent,
  Line,
  GameEndEvent

import "./palette" for INK
import "./inputs" for VI_SCHEME as INPUT
import "./messages" for MessageLog, Pronoun
import "./ui" for TextComplete, TextChanged, TargetEvent, TargetBeginEvent, TargetEndEvent, HoverEvent
import "./text" for TextSplitter
import "./renderer" for
  AsciiRenderer,
  HealthBar,
  PietyBar,
  LineViewer,
  LogViewer,
  HistoryViewer,
  CharacterViewer,
  HoverText,
  Pane,
  HintText,
  Dialog

import "./actions" for BumpAction, PrayAction, RestAction, DescendAction, StrikeAttackAction
import "./events" for Events,RestEvent, PickupEvent, UseItemEvent, LightningEvent
import "./generator" for WorldGenerator
import "./combat" for AttackEvent, DefeatEvent, HealEvent, AttackResult
import "./items" for ItemAction, PickupAction, Items, Equipment, DropAction
import "./oath" for OathBroken, OathTaken, OathStrike

class InventoryWindowState is State {
  construct new(scene) {
    super()
    _scene = scene
    _action = "use"
    _title = ""
  }
  construct new(scene, action) {
    super()
    _scene = scene
    _action = action

    _title = action == "drop" ? "(to drop)" : ""
  }
  onEnter() {
    var border = 24
    var world = _scene.world
    var worldItems = world["items"]

    var player = _scene.world.getEntityByTag("player")
    var playerItems = player["inventory"]
    var i = 0
    var items = playerItems.map {|entry|
      i = i + 1
      var label = ""
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
    if (_title) {
      items.insert(1, "%(_title)")
    }
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
        if (_action == "drop") {
          player.pushAction(DropAction.new(entry.id))
          return PlayerInputState.new(_scene)
        } else if (_action == "use") {
          var query = item.query("use")
          if (!query["target"]) {
              player.pushAction(ItemAction.new(entry.id))
            return PlayerInputState.new(_scene)
          } else {
            query["item"] = entry.id
            return TargetQueryState.new(_scene, query)
          }
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
  scene { _scene }
  window { _window }
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
class HelpState is ModalWindowState {
  construct new(scene) {
    var message = [
        "'Confirm' - Return, Space",
        "'Reject' - Escape, Backspace, Delete",
        "Move - HJKLYUNB, WASDQECZ, Arrow Keys, Numpad",
        "(Bump to attack)",
        "Rest - Space",
        "Coup-de-grace - 'x'",
        "Pick up item - 'g'",
        "Pray - 'p'",
        "Descend to next floor - ','",
        "",
        "Character Info - 't'",
        "Open Log - 'v'",
        "Inventory - 'i', then number to use/equip/unequip",
        "Drop from Inventory - 'r' then number"
      ]
    super(scene, Dialog.new(message))
    window.center = false
    _pane = scene.addElement(Pane.new(Vec.new(0, 0), Vec.new(Canvas.width, Canvas.height)))
  }
  onExit() {
    scene.removeElement(_pane)
    super.onExit()
  }
  update() {
    if (INPUT["reject"].firing || INPUT["confirm"].firing) {
      return PlayerInputState.new(scene)
    }
    return this
  }
}
class DialogueState is ModalWindowState {
  construct new(scene, moment) {
    var message = {
      "beforeBoss": [
        ["????: Well well, you made it..."],
        ["????: Yes, I've been expecting you."],
        ["????: I scarcely remember if any of your kind have made it this far before."],
        ["????: This ought to be amusing."]
      ],
      "freeBoss": [
        ["????: Ha-ha-ha-ha ha! Free at last."],
        ["????: Now My influence can truly spread..."],
        ["????: ...starting with you!"]
      ]
    }
    _dialogue = message[moment]
    _index = 0
    super(scene, Dialog.new(_dialogue[_index] + ["", "Press 'confirm' to continue..."]))
    //_pane = scene.addElement(Pane.new(Vec.new(0, 0), Vec.new(Canvas.width, Canvas.height)))
  }
  onExit() {
    super.onExit()
    //scene.removeElement(_pane)
  }
  update() {
    if (INPUT["reject"].firing || INPUT["confirm"].firing) {
      if (_index < _dialogue.count - 1) {
        _index = _index + 1
        window.setMessage(_dialogue[_index])
      } else {
        return PlayerInputState.new(scene)
      }
    }
    return this
  }
}
class GameEndState is ModalWindowState {
  construct new(scene, message, restart) {
    super(scene, Dialog.new(message))
    // scene.addElement(Pane.new(Vec.new(0, 0), Vec.new(Canvas.width, Canvas.height)))
    _restart = restart
  }
  update() {
    if (INPUT["inventory"].firing) {
      return InventoryWindowState.new(_scene, "readonly")
    }
    if (INPUT["log"].firing) {
      return ModalWindowState.new(_scene, "history")
    }
    if (INPUT["info"].firing) {
      return ModalWindowState.new(_scene, "character")
    }
    if (INPUT["help"].firing) {
      return HelpState.new(_scene)
    }
    if (INPUT["reject"].firing || INPUT["confirm"].firing) {
      scene.game.push(_restart ? GameScene : StartScene)
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
    if (INPUT["inventory"].firing) {
      return InventoryWindowState.new(_scene)
    }
    if (INPUT["log"].firing) {
      return ModalWindowState.new(_scene, "history")
    }
    if (INPUT["info"].firing) {
      return ModalWindowState.new(_scene, "character")
    }
    if (INPUT["help"].firing) {
      return HelpState.new(_scene)
    }
    /*
    if (INPUT["exit"].firing) {
      return ConfirmState.new(_scene)
    }
    */

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
    if (INPUT["strike"].firing) {
      player.pushAction(StrikeAttackAction.new())
    }
    if (INPUT["pray"].firing) {
      player.pushAction(PrayAction.new())
    }
    if (INPUT["drop"].firing) {
      return InventoryWindowState.new(_scene, "drop")
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

    var world = _world = WorldGenerator.create()

    _name = ""
    _currentText = ""

    var player = world.getEntityByTag("player")
    _state = PlayerInputState.new(this)
    addElement(AsciiRenderer.new(Vec.new((Canvas.width - (32 * 16))/2, 16)))
    addElement(HealthBar.new(Vec.new(4, 0), player.ref))
    //addElement(PietyBar.new(Vec.new(4, 16), player.ref))
    addElement(HoverText.new(Vec.new(Canvas.width - 8, 8)))
    addElement(LogViewer.new(Vec.new(4, Canvas.height - 5 * 10), _messages))
    addElement(HintText.new(Vec.new(Canvas.width / 2, Canvas.height * 0.75)))
    //addElement(LogViewer.new(Vec.new(0, Canvas.height - 12 * 7), _messages))

    for (event in _world.events) {
      process(event)
    }
  }

  world { _world }
  messages { _messages }
  events { _state.events }

  process(event) {
    _state.process(event)
    super.process(event)

    if (event is GameEndEvent) {
      var message
      var restart = true
      if (event.win) {
        restart = false
        message = "You have succeeded where others have failed. Return to your home, and reflect on your deeds."
      } else {
        message = "You have fallen, but perhaps others will take up your cause."
      }
      _messages.add(message, INK["playerDie"], false)
      changeState(GameEndState.new(this, [ message, "", "Press 'confirm' to try again" ], restart))
    }
    if (event is Events.story) {
      if (event.moment.startsWith("dialogue:")) {
        changeState(DialogueState.new(this, event.moment[9..-1]))
      } else if (event.moment == "bossWeaken") {
        _messages.add("As the gargoyle crumbles, ???? pulses with horrible energy.", INK["orange"], true)
      } else if (event.moment == "bossVulnerable") {
        _messages.add("The surface of ???? shatters, revealing a demon(?) encased within.", INK["orange"], true)
        changeState(DialogueState.new(this, "freeBoss"))
      }
    }
    if (event is ChangeZoneEvent && event.floor == 1) {
      _messages.add("Welcome, acolyte, to the catacombs.", INK["welcome"], false)
      _messages.add("The mission has begun.", INK["welcome"], false)
    }
    if (event is AttackEvent) {
      var srcName = event.src.name
      var noun = srcName
      if (event.src is Player) {
        noun = Pronoun.you.subject
        srcName = TextSplitter.capitalize(Pronoun.you.subject)
      }
      var targetName = event.target.name
      if (event.target is Player) {
        targetName = Pronoun.you.subject
      }
      if (event.result == AttackResult.invulnerable) {
        _messages.add("%(srcName) attacked %(targetName) but it seems unaffected.", INK["orange"], true)

      } else if (event.result == AttackResult.blocked) {
        _messages.add("%(srcName) hit %(targetName) but %(noun) wasn't powerful enough.", INK["orange"], true)
      } else if (event.src is Player && event.result == AttackResult.overkill) {
        _messages.add("%(targetName) is no more, by your hand.", INK["enemyAtk"], true)
      } else {
        _messages.add("%(srcName) attacked %(targetName) for %(event.damage) damage.", INK["enemyAtk"], true)
      }
    }
    if (event is Events.statueAwaken) {
      _messages.add("Stone cracks and flakes away as statues become %(event.src.name)s.", INK["orange"], true)
    }
    if (event is LightningEvent) {
      _messages.add("%(event.target) was struck by lightning.", INK["playerAtk"], false)
    }
    if (event is Events.kill) {
      _messages.add("%(event.target) was killed.", INK["text"], false)
    }
    if (event is DefeatEvent) {
      _messages.add("%(event.target) was knocked unconscious.", INK["text"], false)
    }
    if (event is HealEvent) {
      _messages.add("%(event.target) was healed for %(event.amount)", INK["healthRecovered"], false)
    }
    if (event is Events.pray) {
      _messages.add("%(event.src) prayed.", INK["text"], true)
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
      _messages.add("%(event.src) picked up %(event.qty) %(itemName)", INK["text"], true)
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
    if (event is OathTaken) {
      _messages.add("You have sworn an oath of \"%(event.oath.name)\".", INK["text"], false)
    }
    if (event is OathStrike) {
      _messages.add("You have violated your oath of \"%(event.oath.name)\".", INK["text"], false)
    }
    if (event is OathBroken) {
      _messages.add("You have broken your oath of \"%(event.oath.name)\".", INK["text"], false)
    }
  }

  update() {
    if (INPUT["volUp"].firing) {
      Jukebox.volumeUp()
    }
    if (INPUT["volDown"].firing) {
      Jukebox.volumeDown()
    }
    if (INPUT["mute"].firing) {
      if (Jukebox.playing) {
        Jukebox.stopMusic()
      } else {
        Jukebox.playMusic("soundTrack")
      }
    }
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
      changeState(nextState)
    }

    _world.advance()
    for (event in _world.events) {
      process(event)
    }
  }

  previous { _previousState }

  changeState(nextState) {
    _state.onExit()
    nextState.onEnter(this)
    _previousState = _state
    _state = nextState
  }

  draw() {
    var color = INK["black"]
    Canvas.cls(color)
    Canvas.offset()
    super.draw()

    Canvas.print(_name, 0, Canvas.height - 17, Color.white)
  }
}
import "./entities" for Player
import "./main" for StartScene
