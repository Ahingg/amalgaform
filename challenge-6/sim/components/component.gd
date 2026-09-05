class_name Component
extends RefCounted

# Base bersama untuk semua komponen berbentuk nilai.
#
# GARIS YANG DIJAGA: base ini hanya boleh memberi MEKANIK umum (menyalin,
# membandingkan), tidak pernah MAKNA game. Begitu ada apply_to() atau
# semacamnya di sini, komponen kembali memegang kelakuan — persis yang
# dihindari sejak hari pertama.
#
# SYARAT: setiap subclass harus bisa dibuat tanpa argumen, karena clone()
# memanggil get_script().new(). Jadi semua parameter _init wajib punya nilai
# bawaan.

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
