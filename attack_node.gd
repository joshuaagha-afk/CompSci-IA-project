extends Node

var Skills:Array = []
var Cooldowns:Array = []

signal AttackSig

func Attack(skill):
	var index = Skills.find(skill)
	if Cooldowns[index] == 0:
		var character = get_parent()

		if character.CurrentMP < skill.MPCost:
			print("Not enough MP!")
			return

		character.CurrentMP -= skill.MPCost
		var Targets: Array = character.CurrentTargets

		if skill.targeting == "All":
			var battle = character.get_parent()
			Targets = battle.GetOpponents(character)
		var Damage = CalculateDamage(skill)
		for target in Targets:
			if target == null or not is_instance_valid(target):
				continue

			var attacker = get_parent()
			var dex_difference: int = attacker.Dex - target.Dex

			var hit_chance: float = skill.Accuracy + dex_difference * 0.01
			hit_chance = clampf(hit_chance, 0.0, 1.0)

			var hit: bool = hit_chance >= 1.0 or randf() < hit_chance

			if not hit:
				target.ShowCombatText("MISS", Color.GRAY)
				continue

			target.ReceiveDamage(Damage, skill.Element)
			
		RefreshCooldowns()
		Cooldowns[index] = Skills[index].SkillCooldown
		AttackSig.emit()

func MobAttack():
	var available: Array = []

	for i in range(Skills.size()):
		if (
			Cooldowns[i] == 0
			and get_parent().CurrentMP >= Skills[i].MPCost
		):
			available.append(Skills[i])

	if available.is_empty():
		PassTurn()
	else:
		Attack(available.pick_random())

func PassTurn():
	RefreshCooldowns()
	AttackSig.emit()
func CalculateDamage(skill):
	var Damage:float = get_parent().get(skill.SkillType)
	Damage = (Damage/100)*skill.SkillPower
	return Damage

func LoadSkills(skills):
	for skill in skills:
		Skills.append(skill)
		Cooldowns.append(skill.SkillCooldown)

func RefreshCooldowns():
	for i in len(Cooldowns):
		Cooldowns[i] = max(Cooldowns[i]-1,0)
