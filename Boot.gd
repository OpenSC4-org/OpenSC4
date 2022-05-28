extends Node2D
class_name Boot

# Read the INI file
var INI_location = "./Apps/SimCity 4.ini"

var simcity_dat_1 : DBPF
var simcity_dat_2 : DBPF
var simcity_dat_3 : DBPF
var simcity_dat_4 : DBPF
var simcity_dat_5 : DBPF
var sounds_file : DBPF
var intro_file : DBPF
var ep1_file : DBPF


# UI resources

func _init():
	# Read the INI file
	var _ini = INISubfile.new(INI_location)
	simcity_dat_1 = DBPF.new("res://SimCity_1.dat")
	simcity_dat_2 = DBPF.new("res://SimCity_2.dat")
	simcity_dat_3 = DBPF.new("res://SimCity_3.dat")
	simcity_dat_4 = DBPF.new("res://SimCity_4.dat")
	simcity_dat_5 = DBPF.new("res://SimCity_5.dat")
	sounds_file = DBPF.new("res://Sound.dat")
	intro_file = DBPF.new("res://Intro.dat")
	ep1_file = DBPF.new("res://EP1.dat")


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
	var region_info_ui_sprite = simcity_dat_1.get_subfile(SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_INFO_BASE, ImageSubfile)
	$RegionView/UICanvas/UI/Background.texture = region_info_ui_sprite.get_as_texture()
	$RegionView/UICanvas/UI/TopUI.texture = simcity_dat_1.get_subfile(SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_UI, ImageSubfile).get_as_texture()
	$RegionView/UICanvas/UI/RegionManagement.from_dbpf(simcity_dat_1, SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_REGIONS)
	$RegionView/UICanvas/UI/Internet.from_dbpf(simcity_dat_1, SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_INTERNET)
	$RegionView/UICanvas/UI/Exit.from_dbpf(simcity_dat_1, SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_EXIT)
	$RegionView/UICanvas/UI/TopRight.from_dbpf(simcity_dat_1, SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_RIGHT)
	$RegionView/UICanvas/UI/RegionPopupBackground.texture = simcity_dat_1.get_subfile(SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_REGIONS_POPUP_BG, ImageSubfile).get_as_texture()
	$RegionView/UICanvas/UI/InternetPopupBackground.texture = simcity_dat_1.get_subfile(SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_INTERNET_POPUP_BG, ImageSubfile).get_as_texture()
	$RegionView/UICanvas/SpritesDBG.set_visible(false)

func _ready():
	load_ui_images()
