extends HBoxContainer

var PlayerEntity
var Buttons: Array = []


func ClearMenu():
	for child in get_children():
		remove_child(child)
		child.queue_free()

	Buttons.clear()


func ShowCharacter(player, targets: Array):
	ClearMenu()
	PlayerEntity = player

	var heading = Label.new()
	heading.text = "%s | MP: %d\nTarget:" % [
		player.name,
		player.CurrentMP
	]
	add_child(heading)

	var target_menu = OptionButton.new()

	for target in targets:
		target_menu.add_item(str(target.name))

	target_menu.item_selected.connect(
		SelectTarget.bind(targets)
	)

	add_child(target_menu)

	for i in range(player.AttackNode.Skills.size()):
		var skill = player.AttackNode.Skills[i]
		var button = Button.new()

		button.text = "%s (%d MP)" % [
			skill.SkillName,
			skill.MPCost
		]

		button.disabled = (
			player.AttackNode.Cooldowns[i] > 0
			or player.CurrentMP < skill.MPCost
		)

		button.pressed.connect(
			player.AttackNode.Attack.bind(skill)
		)

		add_child(button)
		Buttons.append(button)

	var pass_button = Button.new()
	pass_button.text = "Pass"

	pass_button.pressed.connect(player.AttackNode.PassTurn)

	add_child(pass_button)
	Buttons.append(pass_button)


func SelectTarget(index: int, targets: Array):
	PlayerEntity.CurrentTargets = [targets[index]]


func DisableButtons(disabled: bool):
	for button in Buttons:
		button.disabled = disabled


func ShowMessage(message: String):
	ClearMenu()

	var label = Label.new()
	label.text = message
	add_child(label)
