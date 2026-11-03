extends HBoxContainer

var PlayerEntity
var Buttons: Array = []


func ClearMenu():
	for child in get_children():
		remove_child(child)
		child.queue_free()

	Buttons.clear()


func AddButton(
	text: String,
	action: Callable,
	disabled: bool = false
):
	var button = Button.new()
	button.text = text
	button.disabled = disabled
	button.pressed.connect(action)

	add_child(button)
	Buttons.append(button)


func ShowCharacter(player, _targets: Array):
	PlayerEntity = player

	ShowMessage(
		"%s | MP: %d\nChoose a skill:" % [
			player.name,
			player.CurrentMP
		]
	)

	for i in range(player.AttackNode.Skills.size()):
		var skill = player.AttackNode.Skills[i]

		var unavailable: bool = (
			player.AttackNode.Cooldowns[i] > 0
			or player.CurrentMP < skill.MPCost
		)

		AddButton(
			"%s (%d MP)" % [skill.SkillName, skill.MPCost],
			ChooseSkill.bind(skill),
			unavailable
		)

	AddButton("Pass", player.AttackNode.PassTurn)


func ChooseSkill(skill):
	# All-target skills don't need an individual target.
	if skill.targeting == "All":
		PlayerEntity.AttackNode.Attack(skill)
		return

	var battle = get_parent()
	var targets: Array

	if skill.Effect == "Heal":
		targets = battle.GetAllies(PlayerEntity)
		ShowMessage(skill.SkillName + ": choose an ally")
	else:
		targets = battle.GetOpponents(PlayerEntity)
		ShowMessage(skill.SkillName + ": choose an enemy")

	for target in targets:
		AddButton(
			str(target.name),
			UseSkill.bind(skill, target)
		)

	AddButton("Back", BackToSkills)


func UseSkill(skill, target):
	PlayerEntity.CurrentTargets = [target]
	PlayerEntity.AttackNode.Attack(skill)


func BackToSkills():
	ShowCharacter(PlayerEntity, [])


func DisableButtons(disabled: bool):
	for button in Buttons:
		button.disabled = disabled


func ShowMessage(message: String):
	ClearMenu()

	var label = Label.new()
	label.text = message
	add_child(label)
