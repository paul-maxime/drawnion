extends Node

var entity_scene: PackedScene = preload("res://scenes/TestEntity.tscn")

var _rng = RandomNumberGenerator.new()
var _entities = {};

func _ready():
	$Network.game_joined.connect(_on_game_joined)
	$Network.entity_summoned.connect(_on_entity_summoned)
	$Network.entity_moved.connect(_on_entity_moved)
	$Network.entity_damaged.connect(_on_entity_damaged)
	$Network.entity_despawned.connect(_on_entity_despawned)

func _on_game_joined(player_id: int):
	print("Joined the game, player id: %d" % [player_id])
	$Network.sendSummon(_rng.randi() % 512, 0 if player_id % 2 == 0 else 511, (_rng.randi() % 4 + 1) * 16)

func _on_entity_summoned(entity_id: int, owner_id: int, x: int, y: int, size: int):
	print("Entity %d summoned at (%d, %d), owner %d, size %d" % [entity_id, x, y, owner_id, size])
	var entity: Node2D = entity_scene.instantiate()
	entity.position = Vector2(x, y)
	entity.set_entity_size(size)
	_entities[entity_id] = entity
	$Entities.add_child(entity)

func _on_entity_moved(entity_id: int, x: int, y: int):
	print("Entity %d moved to (%d, %d)" % [entity_id, x, y])
	var entity = _entities.get(entity_id)
	if entity == null:
		print("Unknown entity")
		return
	entity.position = Vector2(x, y)

func _on_entity_damaged(entity_id: int, attacker_id: int, new_size: int):
	print("Entity %d attacked by %d, new size %d" % [entity_id, attacker_id, new_size])
	var entity = _entities.get(entity_id)
	if entity == null:
		print("Unknown entity")
		return
	entity.set_entity_size(new_size)

func _on_entity_despawned(entity_id: int):
	print("Entity %d despawned" % [entity_id])
	var entity = _entities.get(entity_id)
	if entity == null:
		print("Unknown entity")
		return
	entity.queue_free()
	_entities.erase(entity_id)
