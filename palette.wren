import "graphics" for Color
import "parcel" for Palette


var INK = Palette.new()
INK.addColor("white", Color.hex("#e4dbba"))
INK.addColor("lilac", Color.hex("#a4929a"))
INK.addColor("purple", Color.hex("#4f3a54"))
INK.addColor("dark", Color.hex("#1b0326"))

INK.addColor("red", Color.hex("#9c173b"))
INK.addColor("burgandy", Color.hex("#450327"))

INK.setPurpose("white", "white")
INK.setPurpose("wall", "lilac")
INK.setPurpose("obscured", "purple")
INK.setPurpose("black", "dark")
INK.setPurpose("bg", "dark")
INK.setPurpose("playerAtk", "white")
INK.setPurpose("enemyAtk", "red")
INK.setPurpose("welcome", "lilac")
INK.setPurpose("barText", "white")
INK.setPurpose("barFilled", "purple")
INK.setPurpose("barEmpty", "red")
INK.setPurpose("border", "burgandy")



/*
owhite = (0xFF, 0xFF, 0xFF)
black = (0x0, 0x0, 0x0)

player_atk = (0xE0, 0xE0, 0xE0)
enemy_atk = (0xFF, 0xC0, 0xC0)

player_die = (0xFF, 0x30, 0x30)
enemy_die = (0xFF, 0xA0, 0x30)

welcome_text = (0x20, 0xA0, 0xFF)

bar_text = white
bar_filled = (0x0, 0x60, 0x0)
bar_empty = (0x40, 0x10, 0x10)

*/
