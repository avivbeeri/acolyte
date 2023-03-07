import "input" for Keyboard, Mouse, InputGroup

var DIR_INPUTS = [
  InputGroup.new([Keyboard["up"], Keyboard["k"], Keyboard["keypad 8"], Keyboard["8"]]),
  InputGroup.new([Keyboard["right"], Keyboard["l"], Keyboard["keypad 6"], Keyboard["6"] ]),
  InputGroup.new([Keyboard["down"], Keyboard["j"], Keyboard["keypad 2"], Keyboard["2"] ]),
  InputGroup.new([Keyboard["left"], Keyboard["h"], Keyboard["keypad 4"] , Keyboard["4"]]),
  InputGroup.new([Keyboard["y"], Keyboard["keypad 7"], Keyboard["7"] ]),
  InputGroup.new([Keyboard["u"], Keyboard["keypad 9"], Keyboard["9"] ]),
  InputGroup.new([Keyboard["n"], Keyboard["keypad 3"], Keyboard["3"] ]),
  InputGroup.new([Keyboard["b"], Keyboard["keypad 1"], Keyboard["1"] ])
]

var SCROLL_UP = InputGroup.new([ Keyboard["up"], Keyboard["page up"], Keyboard["k"] ])
var SCROLL_DOWN = InputGroup.new([ Keyboard["down"], Keyboard["page down"], Keyboard["j"]] )
var SCROLL_BEGIN = InputGroup.new(Keyboard["home"])
var SCROLL_END = InputGroup.new(Keyboard["end"])
var ESC_INPUT = InputGroup.new(Keyboard["escape"])
var OPEN_LOG = InputGroup.new(Keyboard["v"])
var OPEN_INVENTORY = InputGroup.new(Keyboard["i"])
var CONFIRM = InputGroup.new(Keyboard["return"])
var REJECT = InputGroup.new(Keyboard["escape"])
var REST_INPUT = InputGroup.new([Keyboard["space"], Keyboard["."], Keyboard["keypad ."]])
var PICKUP_INPUT = InputGroup.new([ Keyboard["g"] ])
