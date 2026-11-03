extends Resource
@export_enum("Damage", "Heal")
var Effect: String = "Damage"
@export var SkillName:String
@export var SkillPower:float
@export_enum("Str","Magic")
var SkillType = "Str"
@export var SkillCooldown:int
@export_enum("Physical", "Fire", "Ice", "Electric", "Force", "Light", "Dark", "Almighty")
var Element: String = "Physical"

@export var MPCost: int = 0
@export_range(0.0, 1.0) var Accuracy: float = 1.0
@export_enum("Single", "All")
var targeting:String =  "Single"
@export_multiline var Description: String = ""
