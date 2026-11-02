extends Control

const ENTITY = preload("res://entity.tscn")
const BLOB = preload("res://rsc/mobs/Blob.tres")

@onready var player_skill_box = $PlayerSkillBox

var PlayerTeam: Array = []
var EnemyTeam: Array = []
var Teams: Array = []

var ActiveSide: int = 0
var ActiveIndex: int = 0
var CurrentTurn
var FullTurns: int = 0
var HalfTurns: int = 0
var TurnLabel: Label
var BattleOver: bool = false


func _ready():
	var player_data = [
		PlayerStats,
		PlayerStats,
		PlayerStats,
		PlayerStats
	]

	var enemy_data = [
		BLOB,
		BLOB,
		BLOB,
		BLOB
	]

	PlayerTeam = SpawnTeam(player_data, false)
	EnemyTeam = SpawnTeam(enemy_data, true)

	Teams = [PlayerTeam, EnemyTeam]

	TurnLabel = Label.new()
	TurnLabel.position = Vector2(400, 25)
	TurnLabel.add_theme_font_size_override("font_size", 24)
	add_child(TurnLabel)

	FullTurns = LivingMembers(PlayerTeam).size()
	StartTurn()


func SpawnTeam(data: Array, is_enemy: bool) -> Array:
	var team: Array = []

	for i in range(4):
		var character = ENTITY.instantiate()

		character.name = (
			"Enemy" if is_enemy else "Player"
		) + str(i + 1)

		add_child(character)
		character.LoadEntity(data[i])
		character.entity_sprite.flip_h = is_enemy

		var start_x = 760 if is_enemy else 180

		character.position = Vector2(
			start_x + (i % 2) * 180,
			160 + floori(i / 2.0) * 220
		)

		character.AttackNode.AttackSig.connect(
			ActionFinished.bind(character)
		)

		team.append(character)

	return team


func IsAlive(character) -> bool:
	return (
		is_instance_valid(character)
		and character.HealthNode.CurrentHP > 0
	)


func LivingMembers(team: Array) -> Array:
	var living: Array = []

	for character in team:
		if IsAlive(character):
			living.append(character)

	return living


func AdvanceSlot():
	ActiveIndex = (ActiveIndex + 1) % Teams[ActiveSide].size()

	if ActiveIndex >= 4:
		ActiveIndex = 0
		ActiveSide = 1 - ActiveSide
func ConsumeIcon():
	if HalfTurns > 0:
		HalfTurns -= 1
	elif FullTurns > 0:
		FullTurns -= 1


func StartTurn():
	if BattleOver:
		return

	if LivingMembers(PlayerTeam).is_empty():
		EndBattle("Defeat!")
		return

	if LivingMembers(EnemyTeam).is_empty():
		EndBattle("Victory!")
		return

	while not IsAlive(Teams[ActiveSide][ActiveIndex]):
		AdvanceSlot()

	CurrentTurn = Teams[ActiveSide][ActiveIndex]
	
	TurnLabel.text = "%s | Full: %d | Half: %d" % [		"Players" if ActiveSide == 0 else "Enemies",
	FullTurns,
	HalfTurns
	]

	var targets = LivingMembers(Teams[1 - ActiveSide])

	if ActiveSide == 0:
		CurrentTurn.CurrentTargets = [targets[0]]
		player_skill_box.ShowCharacter(CurrentTurn, targets)

	else:
		CurrentTurn.CurrentTargets = [targets.pick_random()]

		player_skill_box.ShowMessage(
			str(CurrentTurn.name) + " is acting..."
		)

		var actor = CurrentTurn
		await get_tree().create_timer(1.0).timeout

		if not BattleOver and IsAlive(actor) and actor == CurrentTurn:
			actor.MobAttack()

func GetOpponents(character) -> Array:
	if PlayerTeam.has(character):
		return LivingMembers(EnemyTeam)

	if EnemyTeam.has(character):
		return LivingMembers(PlayerTeam)

	return []
	
func ActionFinished(actor):
	if BattleOver or actor != CurrentTurn:
		return

	player_skill_box.DisableButtons(true)

	var result: String = actor.AttackNode.LastResult
	CurrentTurn = null

	match result:
		"Bonus":
			if FullTurns > 0:
				FullTurns -= 1
				HalfTurns += 1
			else:
				ConsumeIcon()

		"Penalty":
			ConsumeIcon()
			ConsumeIcon()

		_:
			ConsumeIcon()

	if FullTurns + HalfTurns == 0:
		ActiveSide = 1 - ActiveSide
		ActiveIndex = 0

		FullTurns = LivingMembers(Teams[ActiveSide]).size()
		HalfTurns = 0
	else:
		AdvanceSlot()

	call_deferred("StartTurn")

func EndBattle(message: String):
	BattleOver = true
	CurrentTurn = null

	player_skill_box.ShowMessage(message)
