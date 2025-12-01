extends Node
class_name FX

static func hit_stop(duration: float = 0.06, time_scale: float = 0.2) -> void:
	Engine.time_scale = time_scale
	var tree := Engine.get_main_loop() as SceneTree
	await tree.create_timer(duration, true).timeout
	Engine.time_scale = 1.0

static func screenshake(host: Node2D, intensity: float = 10.0, dur: float = 0.12) -> void:
	var t := 0.0
	var orig := host.position
	while t < dur:
		await host.get_tree().process_frame
		t += host.get_process_delta_time()
		host.position = orig + Vector2(randf() - 0.5, randf() - 0.5) * intensity
	host.position = orig
