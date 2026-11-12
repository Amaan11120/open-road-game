extends Node3D

# Main world script. Builds the sky, fog, road and trees in code.

@onready var fps_label: Label = $FpsLabel


func _ready() -> void:
    $Sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
    $Camera.look_at(Vector3(0.0, 1.0, -30.0))
    _setup_environment()
    _build_road()
    _build_trees()
    _spawn_car()


func _process(_delta: float) -> void:
    fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


# Sky color and fog so the horizon fades out instead of cutting off.
func _setup_environment() -> void:
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.55, 0.75, 0.95)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.8, 0.85, 0.95)
    env.ambient_light_energy = 0.6
    env.fog_enabled = true
    env.fog_light_color = Color(0.7, 0.82, 0.95)
    env.fog_density = 0.008
    var world_env := WorldEnvironment.new()
    world_env.environment = env
    add_child(world_env)


# One long gray road with a dashed center line.
func _build_road() -> void:
    var road_mat := StandardMaterial3D.new()
    road_mat.albedo_color = Color(0.18, 0.18, 0.2)
    var road := MeshInstance3D.new()
    var road_mesh := PlaneMesh.new()
    road_mesh.size = Vector2(8.0, 400.0)
    road.mesh = road_mesh
    road.material_override = road_mat
    road.position = Vector3(0.0, 0.02, -150.0)
    add_child(road)

    var line_mat := StandardMaterial3D.new()
    line_mat.albedo_color = Color(0.95, 0.9, 0.3)
    var line_mesh := PlaneMesh.new()
    line_mesh.size = Vector2(0.2, 2.0)
    for i in range(60):
        var dash := MeshInstance3D.new()
        dash.mesh = line_mesh
        dash.material_override = line_mat
        dash.position = Vector3(0.0, 0.04, 40.0 - i * 6.0)
        add_child(dash)


# Simple trees (brown trunk + green cone) placed on both sides of the road.
func _build_trees() -> void:
    var trunk_mat := StandardMaterial3D.new()
    trunk_mat.albedo_color = Color(0.4, 0.25, 0.12)
    var leaf_mat := StandardMaterial3D.new()
    leaf_mat.albedo_color = Color(0.12, 0.4, 0.15)

    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.25
    trunk_mesh.bottom_radius = 0.3
    trunk_mesh.height = 2.0
    var leaf_mesh := CylinderMesh.new()
    leaf_mesh.top_radius = 0.0
    leaf_mesh.bottom_radius = 1.6
    leaf_mesh.height = 4.0

    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    for i in range(80):
        var side := -1.0 if i % 2 == 0 else 1.0
        var x := side * rng.randf_range(7.0, 30.0)
        var z := 40.0 - rng.randf_range(0.0, 300.0)

        var trunk := MeshInstance3D.new()
        trunk.mesh = trunk_mesh
        trunk.material_override = trunk_mat
        trunk.position = Vector3(x, 1.0, z)
        add_child(trunk)

        var leaves := MeshInstance3D.new()
        leaves.mesh = leaf_mesh
        leaves.material_override = leaf_mat
        leaves.position = Vector3(x, 4.0, z)
        add_child(leaves)


var _car
var _controls


# Adds invisible ground collision, the car, and the touch buttons.
func _spawn_car() -> void:
    var ground := StaticBody3D.new()
    var ground_shape := CollisionShape3D.new()
    var ground_box := BoxShape3D.new()
    ground_box.size = Vector3(400.0, 1.0, 800.0)
    ground_shape.shape = ground_box
    ground.add_child(ground_shape)
    ground.position = Vector3(0.0, -0.5, -150.0)
    add_child(ground)

    _car = load("res://scripts/car.gd").new()
    _car.position = Vector3(0.0, 1.0, 30.0)
    add_child(_car)

    _controls = load("res://scripts/touch_controls.gd").new()
    add_child(_controls)


func _physics_process(_delta: float) -> void:
    if _car and _controls:
        _car.set_inputs(_controls.steer, _controls.throttle, _controls.brake)
