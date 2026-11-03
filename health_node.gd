extends Node

var MaxHP
var CurrentHP

signal Death

func TakeDamage(amount,type):
	CurrentHP = clampf(CurrentHP-amount,0,MaxHP)
	if CurrentHP <= 0:
		Death.emit()
func Heal(amount: float) -> float:
	if CurrentHP <= 0:
		return 0.0

	var before: float = CurrentHP

	CurrentHP = clampf(
		CurrentHP + maxf(amount, 0.0),
		0.0,
		MaxHP
	)

	return CurrentHP - before
