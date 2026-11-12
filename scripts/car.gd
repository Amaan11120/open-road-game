extends VehicleBody3D

# Simple rear-wheel-drive car built entirely in code.
# Stage 5 values are a starting point; we tune them in Stage 6.

const MAX_ENGINE_FORCE := 40.0
const REVERSE_FORCE := 20.0
const BRAKE_FORCE := 20.0
const MAX_SPEED := 40.0   # meters per second (about 144 km/h)
const MAX_STEER := 0.5    # radians

var _steer_in := 0.0
var _throttle_in := 0.0
var _brake_in := 0.0
var _camera: Camera3D


func _ready() -> void:
    mass = 800.0
    center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
    center_of_mass = Vector3(0.0, 0.1, 0.0)
    _build_body()
    _build_wheel(Vector3(-0.9, 0.35, -1.3), true, false)
    _build_wheel(Vector3(0.9, 0.35, -1.3), true, false)
    _build_wheel(Vector3(-0.9, 0.35, 1.3), false, true)
    _build_wheel(Vector3(0.9, 0.35, 1.3), false, true)
    _build_camera()


# Called by main.gd every physics frame with values from -1 to 1 (0 to 1 for pedals).
func set_inputs(steer: float, throttle: float, brake_pedal: float) -> void:
    _steer_in = steer
    _throttle_in = throttle
    _brake_in = brake_pedal


func _physics_process(delta: float) -> void:
    var forward_speed: float = -global_basis.z.dot(linear_velocity)
    var speed: float = absf(forward_speed)

    # Steer less at high speed so the car stays stable.
    var max_steer: float = MAX_STEER / (1.0 + speed * 0.06)
    steering = move_toward(steering, -_steer_in * max_steer, 3.0 * delta)

    engine_force = 0.0
    brake = 0.5  # light engine braking when coasting

    if _throttle_in > 0.0:
        brake = 0.0
        engine_force = _throttle_in * MAX_ENGINE_FORCE * clampf(1.0 - speed / MAX_SPEED, 0.0, 1.0)

    if _brake_in > 0.0:
        if forward_speed > 1.0:
            brake = _brake_in * BRAKE_FORCE
        else:
            brake = 0.0
            if forward_speed > -8.0:
                engine_force = -_brake_in * REVERSE_FORCE


func _process(delta: float) -> void:
    var target: Vector3 = _camera_target()
    _camera.global_position = _camera.global_position.lerp(target, 1.0 - exp(-5.0 * delta))
    _camera.look_at(global_position + Vector3.UP * 1.0, Vector3.UP)


func _camera_target() -> Vector3:
    var back: Vector3 = global_basis.z
    back.y = 0.0
    back = back.normalized()
    return global_position + back * 7.0 + Vector3.UP * 3.0


func _build_body() -> void:
    var paint := StandardMaterial3D.new()
    paint.albedo_color = Color(0.8, 0.1, 0.1)

    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(1.8, 0.6, 4.0)
    shape.shape = box
    shape.position = Vector3(0.0, 0.5, 0.0)
    add_child(shape)

    var body_mesh := MeshInstance3D.new()
    var body_box := BoxMesh.new()
    body_box.size = Vector3(1.8, 0.6, 4.0)
    body_mesh.mesh = body_box
    body_mesh.material_override = paint
    body_mesh.position = Vector3(0.0, 0.5, 0.0)
    add_child(body_mesh)

    var cabin := MeshInstance3D.new()
    var cabin_box := BoxMesh.new()
    cabin_box.size = Vector3(1.6, 0.5, 2.0)
    cabin.mesh = cabin_box
    cabin.material_override = paint
    cabin.position = Vector3(0.0, 1.05, 0.3)
    add_child(cabin)


func _build_wheel(pos: Vector3, steer: bool, drive: bool) -> void:
    var wheel := VehicleWheel3D.new()
    wheel.position = pos
    wheel.use_as_steering = steer
    wheel.use_as_traction = drive
    wheel.wheel_radius = 0.35
    wheel.wheel_rest_length = 0.2
    wheel.suspension_travel = 0.3
    wheel.suspension_stiffness = 35.0
    wheel.wheel_friction_slip = 3.0
    wheel.damping_compression = 1.5
    wheel.damping_relaxation = 2.0
    add_child(wheel)

    var tire_mat := StandardMaterial3D.new()
    tire_mat.albedo_color = Color(0.05, 0.05, 0.05)
    var tire := MeshInstance3D.new()
    var cyl := CylinderMesh.new()
    cyl.top_radius = 0.35
    cyl.bottom_radius = 0.35
    cyl.height = 0.3
    tire.mesh = cyl
    tire.material_override = tire_mat
    tire.rotation_degrees = Vector3(0.0, 0.0, 90.0)
    wheel.add_child(tire)


func _build_camera() -> void:
    _camera = Camera3D.new()
    _camera.top_level = true
    add_child(_camera)
    _camera.global_position = _camera_target()
    _camera.make_current()
