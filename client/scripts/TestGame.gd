extends Node

var entity_scene: PackedScene = preload("res://scenes/TestEntity.tscn")

var _rng = RandomNumberGenerator.new()
var _entities = {};

func _ready():
	$Network.game_joined.connect(_on_game_joined)
	$Network.entity_summoned.connect(_on_entity_summoned)
	$Network.entity_moved.connect(_on_entity_moved)
	$Network.entity_despawned.connect(_on_entity_despawned)

func _on_game_joined(player_id: int):
	print("Joined the game, player id: %d" % [player_id])
	$Network.sendSummon(_rng.randi() % 512, 0 if player_id % 2 == 0 else 511)

func _on_entity_summoned(entity_id: int, owner_id: int, x: int, y: int):
	print("Entity %d summoned at (%d, %d), owner %d" % [entity_id, x, y, owner_id])
	var entity: Node2D = entity_scene.instantiate()
	entity.position = Vector2(x, y)
	_entities[entity_id] = entity
	$Entities.add_child(entity)

func _on_entity_moved(entity_id: int, x: int, y: int):
	print("Entity %d moved to (%d, %d)" % [entity_id, x, y])
	var entity = _entities[entity_id]
	if entity == null:
		print("Unknown entity")
		return
	entity.position = Vector2(x, y)

func _on_entity_despawned(entity_id: int):
	print("Entity %d despawned" % [entity_id])
	var entity = _entities[entity_id]
	if entity == null:
		print("Unknown entity")
		return
	entity.queue_free()
	_entities.erase(entity_id)
