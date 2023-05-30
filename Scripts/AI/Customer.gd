extends AIBody
class_name Customer

var sitting_chair : Chair = null
var order : Array[SceneIds.SCENES]

func set_sync_state(reader: ByteReader) -> void:
	super(reader)
	(get_parent() as CustomerParty).sync_customer(self)
	var has_order = reader.read_bool()
	if has_order:
		var to_be_order : Array[int] = reader.read_int_array()
		order = []
		for item in to_be_order:
			order.push_back(item)

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	super(writer)
	var has_order = order.size() > 0
	writer.write_bool(has_order)
	if has_order:
		writer.write_int_array(order as Array[int])
	return writer

func order_from(menu: Menu):
	if not is_multiplayer_authority():
		return
	
	order = menu.main_items[0].dish
	#print("Order is %s" % [order])
	
	var writer = ByteWriter.new()
	writer.write_int_array(order as Array[int])
	notify_peers_of_order.rpc(writer.data)

@rpc("authority")
func notify_peers_of_order(order_data: PackedByteArray):
	var reader = ByteReader.new(order_data)
	var to_be_order : Array[int] = reader.read_int_array()
	order = []
	for item in to_be_order:
		order.push_back(item)
	#print("%s sent me (%s) an order %s" % [multiplayer.get_remote_sender_id(), multiplayer.get_unique_id(), order])
