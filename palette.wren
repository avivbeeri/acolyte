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
INK.setPurpose("text", "lilac")
INK.setPurpose("barText", "white")
INK.setPurpose("barFilled", "purple")
INK.setPurpose("barEmpty", "red")
INK.setPurpose("border", "burgandy")
INK.setPurpose("invalid", "burgandy")
INK.setPurpose("impossible", "lilac")
INK.setPurpose("error", "red")
INK.setPurpose("healthRecovered", "white")

