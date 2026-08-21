class_name Move
extends Resource

@export var id: String
@export var display_name: String
@export var type_id: String
@export var power: int
@export_enum("physical", "special") var damage_class: String = "physical"
@export var accuracy: int = 100
@export var priority: int = 0
