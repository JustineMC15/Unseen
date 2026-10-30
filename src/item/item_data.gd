## One kind of item. Create .tres files from this (FileSystem > New Resource > ItemData).
class_name ItemData
extends Resource

## Used to match items to doors, e.g. &"key_classroom_201".
@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
