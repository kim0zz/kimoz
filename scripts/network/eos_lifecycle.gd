extends Node
## First autoload, therefore freed after the game, peers and EOS helper nodes.
var initialized := false

func _exit_tree() -> void:
	if not initialized or not Engine.has_singleton("IEOS"):
		return
	var sdk: Object = Engine.get_singleton("IEOS")
	sdk.platform_interface_release()
	sdk.platform_interface_shutdown()
	initialized = false
