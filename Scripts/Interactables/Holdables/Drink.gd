extends Holdable
class_name Drink

#enum Beverage {
#	WATER,
#	COLA,
#	SLURM,
#}

enum FillState {
	EMPTY,
	PARTIAL_FILLED,
	FILLED,
	OVERFILLING,
}

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
	evaluate_fill_state()

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	super(writer)
	writer.write_small_float(fill_amount)
	return writer

func fill(fill_rate: float, beverage: Beverage):
	if fill_state == FillState.OVERFILLING:
		return
	
	fill_amount += fill_rate
	if beverage_amounts.has(beverage.display_name):
		beverage_amounts[beverage.display_name] += fill_rate
	else:
		beverage_amounts[beverage.display_name] = fill_rate
	evaluate_fill_state()

func gulp():
	fill_amount = 0.0
	fill_state = FillState.EMPTY

func evaluate_fill_state():
	if fill_amount < empty_threshold:
		fill_state = FillState.EMPTY
	elif fill_amount < partial_fill_threshold:
		fill_state = FillState.PARTIAL_FILLED
	elif fill_amount < filled_threshold:
		fill_state = FillState.FILLED
	else:
		fill_state = FillState.OVERFILLING