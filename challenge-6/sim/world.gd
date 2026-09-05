class_name World
extends RefCounted

# component_name: {entity_id: {component_value...}}
var component_map: Dictionary[String, Dictionary] = {}
var count: int = 0

var entities: Array[int] = []

# Setiap entity bakal punyya id numbernya, yang terafiliasi dengan id incremental.
func add_entity() -> int:
	var curr := count
	entities.append(curr)
	count+=1
	return curr

func remove_entity_by_id(id: int) -> void:
	entities.erase(id)
	for key in component_map:
		if component_map[key].has(id):
			component_map[key].erase(id)
		 	
	
# body sengaja Variant, bukan Dictionary. Komponen boleh Dictionary (yang
# belum dimigrasi) atau objek bertipe. World gapernah peduli isinya apa, itu
# yang bikin migrasi ke class bisa dicicil satu keluarga sekali jalan.
func attach_component(component_name: String, entity_id: int, body: Variant = {}) -> void:
	if (not component_map.has(component_name)):
		component_map[component_name] = {}
	component_map[component_name][entity_id] = body
	
func detach_component(component_name: String, entity_id: int) -> void:
	if(component_map.has(component_name)) :
		component_map[component_name].erase(entity_id)
		
func entity_have_component(component_name: String, entity_id: int) -> bool:
	if(component_map.has(component_name)):
		return component_map[component_name].has(entity_id)
	return false
	
func get_entities_with_comp(components: Array[String]) -> Array[int]:
	var d := {};
	for name in components:
		if not component_map.has(name): 
			continue
		for e in component_map[name]:
			if d.has(e):
				d[e] += 1
			else:
				d[e] = 1
	var result: Array[int] = []
	result.assign(d.keys().filter(func(key): return d[key] == components.size()))
	return result
	
	
func get_component_value(component_name: String, entity_id: int) -> Variant:
	# anggap component name itu udah selalu ada dan entity id juga selalu ada
	# dari caller di system bisa dibilamg udah ngecek duluan, jadi untuk sekarang 
	# pilih yang paling simpel aja dlu.
	
	return component_map[component_name][entity_id]

func clear_everything() -> void:
	component_map.clear()
	entities.clear()
	count = 0
	

	
