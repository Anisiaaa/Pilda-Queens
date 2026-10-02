extends Node2D

@onready var generator: Node = $LevelGenerator

func _ready() -> void:
	print("[test] calling generate_full_level")
	generator.generate_full_level()
	print("[test] returned. regions size: %d" % generator.level_regions.size())
	if generator.level_regions.size() > 0:
		for row in generator.level_regions:
			var line := ""
			for v in row:
				line += str(v) + " "
			print(line)
