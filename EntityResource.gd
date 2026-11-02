extends Resource
#Stats
@export var MobName:String
@export var MaxHP:float
@export var MaxMP: int
@export var Str:int
@export var Magic:int
@export var Dex:int
@export var Endurance:int
@export var Luck:int

#Affinities
@export_enum("Weak", "Normal", "Resist", "Null")
var PhysElement: String = "Normal"
@export_enum("Weak", "Normal", "Resist", "Null")
var FireElement: String = "Normal"
@export_enum("Weak", "Normal", "Resist", "Null")
var IceElement: String = "Normal"
@export_enum("Weak", "Normal", "Resist", "Null")
var WindElement: String = "Normal"
@export_enum("Weak", "Normal", "Resist", "Null")
var ElecElement: String = "Normal"
@export_enum("Weak", "Normal", "Resist", "Null")
var LightElement: String = "Normal"
@export_enum("Weak", "Normal", "Resist", "Null")
var DarkElement: String = "Normal"


@export var Skills:Array[Resource]
