extends Node2D

func _ready():
	await $DeathAudio.finished
	queue_free()
