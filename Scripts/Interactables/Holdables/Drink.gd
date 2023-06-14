extends Holdable
class_name Drink

enum FillState {
	EMPTY,
	PARTIAL_FILLED,
	FILLED,
	OVERFILLING,
}

@export var mesh_to_color : MeshInstance3D
@export var surface_index_to_color = 1

var fill_state : FillState = FillState.EMPTY
var fill_amount = 0.0
## Mixed drinks!
var beverage_amounts = {}

## Less than these thresholds means it is at that state
var empty_threshold = 0.2
var partial_fill_threshold = 0.7
var filled_threshold = 1.0

func set_sync_state(reader: ByteReader) -> void:
	super(reader)
	fill_amount = reader.read_small_float()
	var dict_size = reader.read_int()
	for i in range(dict_size):
		var resource_id = reader.read_int()
		var beverage_filled_amount = reader.read_small_float()
		beverage_amounts[NetworkedResources.get_resource_by_id(resource_id)] = beverage_filled_amount
	
	evaluate_fill_state()

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	super(writer)
	writer.write_small_float(fill_amount)
	writer.write_int(beverage_amounts.size())
	for beverage in beverage_amounts:
		writer.write_int(beverage.RESOURCE_ID)
		writer.write_small_float(beverage_amounts[beverage])
	return writer

func _ready():
	super()
	mesh_to_color.get_surface_override_material(surface_index_to_color).albedo_color.a = 0.0

func _exit_tree():
	Utils.cleanup_material_overrides(self, mesh_to_color)

func fill(fill_rate: float, beverage: Beverage):
	if fill_state == FillState.OVERFILLING:
		return
	
	fill_amount += fill_rate
	if beverage_amounts.has(beverage):
		beverage_amounts[beverage] += fill_rate
	else:
		beverage_amounts[beverage] = fill_rate
	
	evaluate_fill_state()

func gulp():
	fill_amount = 0.0
	fill_state = FillState.EMPTY
	beverage_amounts.clear()

func evaluate_fill_state():
	# Mix drink colors based on the filled amount
	var iterations = 0
	var drink_color = Color.WHITE
	for beverage in beverage_amounts:
		if iterations == 0:
			drink_color = beverage.color
		else:
			drink_color = drink_color.lerp(beverage.color, beverage_amounts[beverage])
		iterations += 1
	
	if fill_amount < empty_threshold:
		fill_state = FillState.EMPTY
		drink_color.a = empty_threshold
	elif fill_amount < partial_fill_threshold:
		fill_state = FillState.PARTIAL_FILLED
		drink_color.a = partial_fill_threshold
	elif fill_amount < filled_threshold:
		fill_state = FillState.FILLED
		drink_color.a = filled_threshold
	else:
		fill_state = FillState.OVERFILLING
		drink_color.a = filled_threshold
	
	mesh_to_color.get_surface_override_material(surface_index_to_color).albedo_color = drink_color
