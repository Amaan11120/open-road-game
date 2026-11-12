extends Node3D

# Shows the frame rate so we can check performance on the phone.
@onready var fps_label: Label = $FpsLabel


func _ready() -> void:
    # Tilt the sun and point the camera at the center of the world.
    $Sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
    $Camera.look_at(Vector3.ZERO)


func _process(_delta: float) -> void:
    fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
