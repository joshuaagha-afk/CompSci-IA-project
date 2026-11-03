extends Control

# Nodes
@export var HealthNode:Node
@export var AttackNode:Node
@onready var entity_sprite = $EntitySprite
@onready var health_bar = $HealthBar

# Target
var CurrentTargets:Array


# Stats
var Str:int
var Dex:int
var Magic:int
var Endurance: int
var MaxMP: int
var CurrentMP: int
var Affinities: Dictionary = {}


func _ready():
	entity_sprite.play("idle")
	AttackNode.AttackSig.connect(AttackAnim)

func _process(delta):
	health_bar.value = HealthNode.CurrentHP/HealthNode.MaxHP

func LoadEntity(TargetRes):
	Affinities = {
		"Physical": TargetRes.PhysElement,
		"Fire": TargetRes.FireElement,
		"Ice": TargetRes.IceElement,
		"Electric": TargetRes.ElecElement,
		"Force": TargetRes.WindElement,
		"Light": TargetRes.LightElement,
		"Dark": TargetRes.DarkElement
	}
	MaxMP = TargetRes.MaxMP
	CurrentMP = MaxMP
	Endurance = TargetRes.Endurance
	if TargetRes != PlayerStats:
		entity_sprite.flip_h = true
	Str = TargetRes.Str
	Dex = TargetRes.Dex
	Magic = TargetRes.Magic
	HealthNode.MaxHP = TargetRes.MaxHP
	HealthNode.CurrentHP = TargetRes.MaxHP
	
	AttackNode.LoadSkills(TargetRes.Skills)
	HealthNode.Death.connect(Death)

func ReceiveDamage(amount: float, element: String):
	var affinity: String = Affinities.get(element, "Normal")
	var affinity_multiplier: float = 1.0

	match affinity:
		"Weak":
			affinity_multiplier = 1.5
		"Resist":
			affinity_multiplier = 0.5
		"Null":
			ShowCombatText("NULL", Color.GRAY)
			return

	var defense: int = maxi(Endurance, 0)
	var defense_multiplier: float = 20.0 / (20.0 + defense)

	var final_damage: float = (
		amount
		* defense_multiplier
		* affinity_multiplier
	)

	var hp_before: float = HealthNode.CurrentHP
	HealthNode.TakeDamage(final_damage, element)
	var damage_dealt: float = hp_before - HealthNode.CurrentHP

	var message: String = "%.1f" % damage_dealt
	var text_color: Color = Color.WHITE

	match affinity:
		"Weak":
			message += "\nWEAK"
			text_color = Color.ORANGE
		"Resist":
			message += "\nRESIST"
			text_color = Color.LIGHT_BLUE

	ShowCombatText(message, text_color)
	entity_sprite.play("hurt")


func Death():
	queue_free()
func ShowCombatText(message: String, color: Color = Color.WHITE):
	var popup = Label.new()
	popup.text = message
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.size = Vector2(180, 60)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.z_index = 100

	popup.add_theme_font_size_override("font_size", 24)
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_color_override("font_outline_color", Color.BLACK)
	popup.add_theme_constant_override("outline_size", 6)

	get_parent().add_child(popup)
	popup.position = position + Vector2(-90, -110)

	var tween = popup.create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		popup,
		"position",
		popup.position + Vector2(0, -40),
		1.2
	)

	tween.tween_property(
		popup,
		"modulate:a",
		0.0,
		0.9
	).set_delay(0.3)

	tween.chain().tween_callback(popup.queue_free)
func ReceiveHeal(amount: float):
	var restored: float = HealthNode.Heal(roundi(amount))
	ShowCombatText("+%d" % roundi(restored), Color.GREEN)
func _on_entity_sprite_animation_finished():
	print_debug(HealthNode.CurrentHP)
	if HealthNode.CurrentHP > 0:
		print_debug("SHould Play")
		entity_sprite.play("idle")

func AttackAnim():
	entity_sprite.play("hit")

func MobAttack():
	AttackNode.MobAttack()
