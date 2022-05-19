extends Node

var INILoader = load("res://INILoader.gd")
var DBPFLoader = load("res://DBPFLoader.gd")
var SubfileTGI = load("res://SubfileTGI.gd")
var SC4City__WriteRegionViewThumbnail = load("res://SC4City__WriteRegionViewThumbnail.gd")

# Read the INI file
var INI_location = "./Apps/SimCity 4.ini"

var simcity_dat_files = []
var sounds_file
var intro_file
var ep1_file 


# UI resources

func _init():
	# Read the INI file
	var _ini = INILoader.new(INI_location)
	# Load the intro
	intro_file = DBPFLoader.new("Intro.dat")
	print("=== Intro.dat === ")
	#intro_file.dbg_subfile_types()
	var png = intro_file.get_subfile(SubfileTGI.TYPE_PNG, SubfileTGI.GROUP_UI_IMAGE, 0xea7f0eae)
	png.sprite.name = "intro_png"
	add_child(png.sprite, true)
	print("=== Sounds.dat ===")
	sounds_file = DBPFLoader.new("Sounds.dat")
	# Get the sounds file
	sounds_file = DBPFLoader.new("Sound.dat")
	print("=== Sound.dat === ")
	ep1_file = DBPFLoader.new("EP1.dat")
	print("=== EP1.dat === ")
	ep1_file.dbg_show_all_subfiles()

	# Open the .dat files
	for i in range(1,6):
		simcity_dat_files.append(DBPFLoader.new("SimCity_%d.dat" % i))
	for i in range(5):
		print(" === Simcity_%d.dat === " % [i+1])

func img_info(index):
	# Interpret the ID
	var main_group = (0xff000000 & index.instance_id) >> 24
	var family =     (0x00fff000 & index.instance_id) >> 12
	var img_id =     (0x00000fff & index.instance_id)
	return '%02x %03x %03x' % [main_group, family, img_id]

func load_ui_images():
	var REGION_VIEW_UI = 0x14416300
	var REGION_INFO_BASE = REGION_VIEW_UI | 0x00
	var REGION_TOP_REGIONS = REGION_VIEW_UI | 0x01
	var REGION_TOP_INTERNET =  REGION_VIEW_UI | 0x02
	var REGION_TOP_EXIT = REGION_VIEW_UI | 0x03
	var REGION_TOP_RIGHT = REGION_VIEW_UI | 0x04
	var REGION_TOP_REGIONS_POPUP_BG = REGION_VIEW_UI | 0x07
	var REGION_TOP_INTERNET_POPUP_BG = REGION_VIEW_UI | 0x08
	var REGION_TOP_RIGHT_UI = REGION_VIEW_UI | 0x0d
	var REGION_TOP_UI = REGION_VIEW_UI | 0x0f
	var REGION_DELETE_REGION = REGION_VIEW_UI | 0x12
	var REGION_OPEN_FOLDER = REGION_VIEW_UI | 0x13
	var REGION_NEW_REGION = REGION_VIEW_UI | 0x14
	var REGION_CHECKBOX = REGION_VIEW_UI | 0x15
	var REGION_RADIOBUTTON = REGION_VIEW_UI | 0x16
	var REGION_EMPTY_CITY_DIALOG = REGION_VIEW_UI | 0x21
	var REGION_CITY_DIALOG = REGION_VIEW_UI | 0x22
	var REGION_CLOSE_DIALOG = REGION_VIEW_UI | 0x23
	var REGION_DELETE_CITY = REGION_VIEW_UI | 0x24
	var REGION_IMPORT_CITY = REGION_VIEW_UI | 0x25
	var REGION_OPEN_CITY = REGION_VIEW_UI | 0x26
	print("== UI images ==")
	var ui_indices = simcity_dat_files[0].indices_by_type_and_group[[SubfileTGI.TYPE_PNG, SubfileTGI.GROUP_UI_IMAGE]]
	for img_index in ui_indices:
		pass
	ui_indices = simcity_dat_files[0].indices_by_type_and_group[[SubfileTGI.TYPE_PNG, 0x1ABE787D]]
	var region_info_ui_sprite = simcity_dat_files[0].get_subfile(SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_INFO_BASE)
	$RegionView/UICanvas/UI/Background.texture = region_info_ui_sprite.sprite.texture
	$RegionView/UICanvas/UI/TopUI.texture = simcity_dat_files[0].get_subfile(SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_UI).sprite.texture
	$RegionView/UICanvas/UI/TopButtons/RegionManagement.set_texture(simcity_dat_files[0].get_subfile(SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_REGIONS).sprite.texture)
	$RegionView/UICanvas/UI/TopButtons/RegionManagement/RegionPopupBackground.texture = simcity_dat_files[0].get_subfile(SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_REGIONS_POPUP_BG).sprite.texture
	$RegionView/UICanvas/UI/TopButtons/Internet.set_texture(simcity_dat_files[0].get_subfile(SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_INTERNET).sprite.texture)
	$RegionView/UICanvas/UI/TopButtons/Internet/InternetPopupBackground.texture = simcity_dat_files[0].get_subfile(SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_INTERNET_POPUP_BG).sprite.texture
	$RegionView/UICanvas/UI/TopButtons/Exit.set_texture(simcity_dat_files[0].get_subfile(SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_EXIT).sprite.texture)
	$RegionView/UICanvas/UI/TopRight.set_texture(simcity_dat_files[0].get_subfile(SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_RIGHT).sprite.texture)
	if true:
		$RegionView/UICanvas/SpritesDBG.set_visible(false)
		return
	else:
		$RegionView/UICanvas/UI.set_visible(false)
	for img_index in ui_indices:
		if (img_index.instance_id & 0xffffff00) == 0x14416300:
			var sprite = simcity_dat_files[0].get_subfile(img_index.type_id, img_index.group_id, img_index.instance_id)
			$RegionView/UICanvas/SpritesDBG.add_item(img_info(img_index), sprite.sprite.texture)

func _ready():
	load_ui_images()
