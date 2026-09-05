class_name Component
extends RefCounted

# Base buat semua komponen yang isinya nilai.
# Cuma boleh ngasih mekanik umum kayak clone, jangan pernah kasih logic game
# disini, nanti komponennya balik megang kelakuan lagi.
#
# Syarat: semua subclass harus bisa dibuat tanpa argumen, soalnya clone manggil
# get_script().new(). Jadi semua parameter _init wajib ada default value.

func clone() -> Component:
	var c: Component = get_script().new()
	for p in get_property_list():
		if not (p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var v: Variant = get(p.name)
		if v is Dictionary or v is Array:
			v = v.duplicate(true)
		elif v is Component:
			v = v.clone()
		c.set(p.name, v)
	return c
