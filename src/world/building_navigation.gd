extends NavigationRegion3D
## Navigation for the Olopsc building.
## The navmesh is baked from the building's collision shapes.
## In the editor: select this node and press "Bake NavigationMesh" to store it in
## olopsc_navmesh.tres. If it was never baked, it is baked once at startup so AI still works.

func _ready() -> void:
	if navigation_mesh and navigation_mesh.get_polygon_count() == 0:
		bake_navigation_mesh(false)
		print("Olopsc navmesh baked at runtime: %d polygons" % navigation_mesh.get_polygon_count())
