extends Node

var Skills:Array = []
var Cooldowns:Array = []
var LastResult: String = "Normal"
var KnownWeaknesses: Dictionary = {}
var NulledAoE: Dictionary = {}
var NulledSingle: Dictionary = {}

signal AttackSig

func Attack(skill):
	var index = Skills.find(skill)

	if Cooldowns[index] == 0:
		var character = get_parent()
		var battle = character.get_parent()
		var is_player: bool = character.get_parent().PlayerTeam.has(character)
		var eligible: Array
		if skill.Effect == "Heal":
			eligible = battle.GetAllies(character)
		else:
			eligible = battle.GetOpponents(character)
			
		var Targets: Array = []

		if skill.targeting == "All":
			Targets = eligible
		else:
			for target in character.CurrentTargets:
				if eligible.has(target):
					Targets.append(target)
		if Targets.is_empty():
			character.ShowCombatText("No valid target")
			return


		if is_player:
			if character.CurrentMP < skill.MPCost:
				print("Not enough MP!")
				return

			character.CurrentMP -= skill.MPCost

		

		
		var Damage = CalculateDamage(skill)
		LastResult = "Normal"
		for target in Targets:
			if target == null or not is_instance_valid(target):
				continue
			if skill.Effect == "Heal":
				target.ReceiveHeal(Damage)
				continue

			var attacker = get_parent()
			var dex_difference: int = attacker.Dex - target.Dex

			var hit_chance: float = skill.Accuracy + dex_difference * 0.01
			hit_chance = clampf(hit_chance, 0.0, 1.0)

			var hit: bool = hit_chance >= 1.0 or randf() < hit_chance

			if not hit:
				LastResult = "Penalty"
				target.ShowCombatText("MISS", Color.GRAY)
				continue

			var affinity: String = target.Affinities.get(
				skill.Element, "Normal"
			)
			if not is_player and affinity == "Null" and skill.targeting == "All":
				var target_id = target.get_instance_id()

				if not NulledAoE.has(skill):
					NulledAoE[skill] = []

				if not NulledAoE[skill].has(target_id):
					NulledAoE[skill].append(target_id)
			if not is_player and affinity == "Null" and skill.targeting == "Single":
				var target_id = target.get_instance_id()

				if not NulledSingle.has(skill):
					NulledSingle[skill] = []

				if not NulledSingle[skill].has(target_id):
					NulledSingle[skill].append(target_id)
					
			if not is_player and affinity == "Weak":
				var target_id = target.get_instance_id()

				if not KnownWeaknesses.has(target_id):
					KnownWeaknesses[target_id] = []

				if not KnownWeaknesses[target_id].has(skill.Element):
					KnownWeaknesses[target_id].append(skill.Element)
					print(character.name, " discovered ", target.name,
						" is weak to ", skill.Element)

			if affinity == "Null":
				LastResult = "Penalty"
			elif affinity == "Weak" and LastResult != "Penalty":
				LastResult = "Bonus"

			target.ReceiveDamage(Damage, skill.Element)
			
		RefreshCooldowns()
		Cooldowns[index] = Skills[index].SkillCooldown
		AttackSig.emit()

func MobAttack():
	var available: Array = []
	var character = get_parent()
	var injured: Array = []
	var finish_target = null
	var lowest_ratio: float = 0.35
	
	for ally in character.get_parent().GetAllies(character):
		if ally.HealthNode.CurrentHP < ally.HealthNode.MaxHP * 0.25 :
			injured.append(ally)

	for i in range(Skills.size()):
		if Cooldowns[i] == 0:
			if Skills[i].Effect == "Heal" and injured.is_empty():
				continue

			available.append(Skills[i])

	var opponents = character.get_parent().GetOpponents(character)
	for skill in available.duplicate():
		for target in opponents:
			
			if NulledAoE.get(skill, []).has(target.get_instance_id()):
				available.erase(skill)
				break

		
	#1 prio- just press turn extension
	if character.get_parent().FullTurns > 0:
		for skill in available:
			if skill.Effect != "Damage":
				continue

			for target in opponents:
				if NulledSingle.get(skill, []).has(target.get_instance_id()):
					continue
				var target_id = target.get_instance_id()
				var weaknesses = KnownWeaknesses.get(target_id, [])

				if weaknesses.has(skill.Element):
					character.CurrentTargets = [target]
					Attack(skill)
					return
	#prio 2- Healing if allies are low HP
	if not injured.is_empty():
		for skill in available:
			if skill.Effect == "Heal" and skill.targeting == "All":
				Attack(skill)
				return
		for skill in available:
			
			if skill.Effect != "Heal":
				continue
				
			var target = injured[0]

			for ally in injured:
				var ally_ratio = float(ally.HealthNode.CurrentHP) / ally.HealthNode.MaxHP
				var target_ratio = float(target.HealthNode.CurrentHP) / target.HealthNode.MaxHP

				if ally_ratio < target_ratio:
					target = ally

			character.CurrentTargets = [target]
			Attack(skill)
			return
	#prio 3- Deal the most possible Damage to low health enemies
	for target in opponents:
		var ratio = float(target.HealthNode.CurrentHP) / target.HealthNode.MaxHP

		if ratio < lowest_ratio:
			lowest_ratio = ratio
			finish_target = target

	if finish_target != null:
		var best_skill = null
		var best_damage: float = 0.0
		var weaknesses = KnownWeaknesses.get(
			finish_target.get_instance_id(), []
		)

		for skill in available:
			if skill.Effect != "Damage":
				continue
			if NulledSingle.get(skill, []).has(finish_target.get_instance_id()):
				continue
			var damage = CalculateDamage(skill)

			if weaknesses.has(skill.Element):
				damage *= 1.5

			if damage > best_damage:
				best_damage = damage
				best_skill = skill

		if best_skill != null:
			character.CurrentTargets = [finish_target]
			Attack(best_skill)
			return
	available.shuffle()
	#random skill targeting, uncovering weakneses
	for skill in available:
		if skill.Effect != "Damage":
			continue

		var targets: Array = []

		for target in opponents:
			if not NulledSingle.get(skill, []).has(target.get_instance_id()):
				targets.append(target)

		if not targets.is_empty():
			character.CurrentTargets = [targets.pick_random()]
			Attack(skill)
			return

	PassTurn()
	
		
	
		


func PassTurn():
	LastResult = "Bonus"
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
