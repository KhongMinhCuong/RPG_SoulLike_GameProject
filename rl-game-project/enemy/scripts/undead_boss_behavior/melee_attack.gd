@tool
extends ActionLeaf

@onready var animation_player: AnimationPlayer = $"../../../../../AnimationPlayer"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../../../../../AnimatedSprite2D"
@onready var hitbox: Hitbox = $"../../../../../Hitbox"


var started := false
# Use a per-actor cooldown field `attack_cooldown_remaining` to prevent immediate re-attacks

func tick(actor: Node, blackboard: Blackboard) -> int:
	if not actor or not actor.player:
		return FAILURE

	# Per-actor cooldown: if present and >0, decrement and don't start a new attack
	if "attack_cooldown_remaining" in actor and actor.attack_cooldown_remaining > 0.0:
		actor.attack_cooldown_remaining -= get_process_delta_time()
		return FAILURE
	
	if not started:
		started = true
		# Face player
		actor.face_target(actor.player)
		# Play attack animation
		animation_player.play("attack")
		return RUNNING
	
	# Wait for animation to finish
	if animation_player.is_playing():
		return RUNNING
	
	# Animation done
	started = false
	# Set per-actor cooldown so we don't immediately attack again
	var cd: float = 1.5
	if "attack_cooldown" in actor:
		cd = float(actor.attack_cooldown)
	actor.attack_cooldown_remaining = cd
	return SUCCESS
