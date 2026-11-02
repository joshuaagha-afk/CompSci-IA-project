extends Node

var MaxHP:float = 100
var MaxMP: int = 70
var CurrentHP:float
var Str:int = 2
var Magic:int = 10
var Dex:int = 5
var Endurance:int = 5
var Luck:int = 2
var Skills:Array[Resource]

var PhysElement: String = "Normal"
var FireElement: String = "Normal"
var IceElement: String = "Normal"
var WindElement: String = "Normal"
var ElecElement: String = "Normal"
var LightElement: String = "Normal"
var DarkElement: String = "Normal"

var Experience:int
var Level:int

func _ready():
	for skill_path in [
		"res://rsc/skills/Attack.tres",
		"res://rsc/skills/Pierce.tres",
		"res://rsc/skills/Bufu.tres",
		"res://rsc/skills/Garu.tres",
		
		"res://rsc/skills/Megidolaon.tres",
		"res://rsc/skills/Agi.tres"
	]:
		var skill = load(skill_path)

		if skill == null:
			push_error("Could not load skill: " + skill_path)
			continue

		Skills.append(skill)
