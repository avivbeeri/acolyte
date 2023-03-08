import "input" for Keyboard, Mouse, InputGroup

var KEY_SET_1 = [
  [ Keyboard["up"] ],
  [ Keyboard["right"] ],
  [ Keyboard["down"] ],
  [ Keyboard["left"] ],
  [ Keyboard["page up"] ],
  [ Keyboard["page down"] ],
  [ Keyboard["home"] ],
  [ Keyboard["end"] ]
]

var KEY_SET_2 = [
  [ Keyboard["k"] ],
  [ Keyboard["l"] ],
  [ Keyboard["j"] ],
  [ Keyboard["h"] ],
  [ Keyboard["y"] ],
  [ Keyboard["u"] ],
  [ Keyboard["n"] ],
  [ Keyboard["b"] ]
]
var KEY_SET_3 = [
  [ Keyboard["8"] ],
  [ Keyboard["6"] ],
  [ Keyboard["2"] ],
  [ Keyboard["4"] ],
  [ Keyboard["7"] ],
  [ Keyboard["9"] ],
  [ Keyboard["3"] ],
  [ Keyboard["1"] ]
]
var KEY_SET_4 = [
  [ Keyboard["keypad 8"] ],
  [ Keyboard["keypad 6"] ],
  [ Keyboard["keypad 2"] ],
  [ Keyboard["keypad 4"] ],
  [ Keyboard["keypad 7"] ],
  [ Keyboard["keypad 9"] ],
  [ Keyboard["keypad 3"] ],
  [ Keyboard["keypad 1"] ]
]
var KEY_SET_5 = [
  [ Keyboard["w"] ],
  [ Keyboard["d"] ],
  [ Keyboard["s"] ],
  [ Keyboard["a"] ],
  [ Keyboard["q"] ],
  [ Keyboard["e"] ],
  [ Keyboard["c"] ],
  [ Keyboard["z"] ]
]

var KEY_SET = []
for (i in 0...KEY_SET_1.count) {
  KEY_SET.add(KEY_SET_1[i] + KEY_SET_2[i] + KEY_SET_5[i])
}

var DIR_INPUTS = KEY_SET.map {|keys| InputGroup.new(keys) }.toList

/*
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
*/

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
