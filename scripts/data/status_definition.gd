class_name ZooStatusDefinition
extends Resource

## Shared immutable definition. Runtime stores expiry/source separately.
@export var id: String = "weakened"
@export var duration: float = 3.0
@export var multiplier: float = 0.75

func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty() or duration <= 0.0 or multiplier < 0.0 or multiplier > 1.0:
		errors.append("Invalid status: %s" % id)
	return errors
