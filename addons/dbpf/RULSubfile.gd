extends DBPFSubfile

class_name RULSubfile

"""
Individual Network RULs:
	use edge-shape definitions to define what object to render there, 
	it doesn't specify wether it is an FSH or an S3D or an Exemplar

my approach will be to store the RUL information in nested dicts
	dict[W = dict[N = dict[E = dict[S = IID]]]]
This data is then used to add the FSH's to texturearray(s)
	for S3D objects I'd need to initialize them and get their FSH's
	when adding FSH's to the array I ofcourse need to keep track of what layer is what FSH
	that record should also allow me to not load duplicate FSH's since they are reused
This data is then used to define a dict of the same shape with TransitTile objects 
	that store path and texarrlayer data
	
Edge definitions come in the following forms:
	per side w, n, e, s:
 - 00 = disconnected
 - 01 = diagonal 45deg left (as viewed from edge to center)
 - 02 = straight
 - 03 = diagonal 45deg right
 - 04 = shared median for 2-tile networks
 - 11 = transition from 01 to 02, diag to straight
 - 13 = transition as 11 but other diagonal
rails also use:
 - 21: N-0x03187F00,0,0
 - 22: S-0x03002200,0,0
 - 23: E-0x03001C00,0,0

 - 32: S-0x03031700,0,0
 - 42: S-0x03034b00,0,0
 - 52: N-0x0306BD00,0,0
 - 62: E-0x03014E00,0,0
 - 72: N-0x0312FF00,0,0
21 to 52 describe sides with in-between diagonals where 62 and 72 describe sides with double diagonals from two directions with 72 including a straight aswell
 - ?: specifies edges that are irrelevant to tiles being defined.

My observation:
Network Instances starting hex wnes_keys
							example id of straight piece
0d - monorail				0x0d031500 - FSH & S3D	-dat2 & dat1
0c - bridges
0b - bridges
0a - ground highway			0x0a001500 - S3D [FSH is reused and stretched between parts]
09 - one way road			0x09004B00 - FSH		-dat3
08 - el-train or monorail	0x08031500 - FSH & S3D	-dat3 & dat1 & mask in dat2
07 - subway					0x07004B00 - S3D 		-dat1	[needs translating]
06 - water-pipes			0x06004B00 - S3D 		-dat1	[needs translating]
05 - street					0x05004B00 - FSH 		-dat3	[needs translating for advanced rul or doesn't use it]
04 - avenue					0x04006100 - FSH 		-dat4
03 - rail					0x03031500 - FSH 		-dat4
02 - El Highway				0x02001500 - FSH & S3D	-dat4 & dat1 [FSH isn't used, insead does what ground does]
00 - road					0x00004B00 - FSH 		-dat5

from the wiki:
0x0000001 - Elevated Highway Basic RUL
0x0000002 - Elevated Highway Advanced RUL
0x0000003 - Pipe Basic RUL
0x0000004 - Pipe Advanced RUL
0x0000005 - Rail Basic RUL
0x0000006 - Rail Advanced RUL
0x0000007 - Road Basic RUL
0x0000008 - Road Advanced RUL
0x0000009 - Street Basic RUL
0x000000A - Street Advanced RUL
0x000000B - Subway Basic RUL
0x000000C - Subway Advanced RUL
0x000000D - Avenue Basic RUL
0x000000E - Avenue Advanced RUL
0x000000F - Elevated Rail Basic RUL
0x0000010 - Elevated Rail Advanced RUL
0x0000011 - One-Way Road Basic RUL
0x0000012 - One-Way Road Advanced RUL
0x0000013 - RHW ("Dirt Road") Basic RUL
0x0000014 - RHW ("Dirt Road") Advanced RUL
0x0000015 - Monorail Basic RUL
0x0000016 - Monorail Advanced RUL
0x0000017 - Ground Highway Basic RUL
0x0000018 - Ground Highway Advanced RUL
"""

var RUL_wnes = {}
var num_ids = 0

func _init(index).(index):
	pass

func load(file, dbdf=null):
	"""
	stores RUL lines with 1-lines functioning as dict-keys
	2 and 3 lines are stored as arrays in an 'entry-array' 
	this is because there can be multiple entries with the same -tile edge-vals
	in order to handle that I will need to use the whole neighbor-grid as described below
	and evaluate the options and from the ones that fit use the one with the larges number of tiles that fit
	I'm hoping draw-cases would describe the same tile anyway
	
		neighbor location numbers (0 is base location described by 1-line):
			11	12	13	14	15
			10	2	3	4	16
			9	1	0	5	17
			24	8	7	6	18
			23	22	21	20	19
	"""
	.load(file, dbdf)
	file.seek(index.location)
	var ind = 0
	assert(len(raw_data) > 0, "DBPFSubfile.load: no data")
	var ini_str = raw_data.get_string_from_ascii()
	var i = 0
	var raw_split = ini_str.split('\n')
	var ids_found = []
	while i < len(raw_split)-1:
		var line = raw_split[i].strip_edges(true, true)
		if len(line) > 1 and line[0] == '1':
			var wnes_keys = line.split(",")
			var w = int(wnes_keys[1])
			var n = int(wnes_keys[2])
			var e = int(wnes_keys[3])
			var s = int(wnes_keys[4])
			if not self.RUL_wnes.keys().has(w):
				self.RUL_wnes[w] = {}
			if not self.RUL_wnes[w].keys().has(n):
				self.RUL_wnes[w][n] = {}
			if not self.RUL_wnes[w][n].keys().has(e):
				self.RUL_wnes[w][n][e] = {}
			if not self.RUL_wnes[w][n][e].keys().has(s):
				self.RUL_wnes[w][n][e][s] = []
			i+=1
			line = raw_split[i].strip_edges(true, true)
			var entry = []
			while line[0] != '1' and i < len(raw_split)-1:
				if line[0] == '2':
					var wnes2_keys = line.split(",")
					entry.append([
						int(wnes2_keys[0]), 
						int(wnes2_keys[1]),
						int(wnes2_keys[2]),
						int(wnes2_keys[3]),
						int(wnes2_keys[4]),
						int(wnes2_keys[5])
						])
				elif line[0] == '3':
					var wnes3_keys = line.split(",")
					var string = wnes3_keys[2].split("x")[1]
					# needed to split hex strings because godots hex_to_int is bugged for large numbers
					var hexstr_to_int = 0
					if len(string) > 4:
						hexstr_to_int = ("0x00" + string.substr(0, len(string)-4)).hex_to_int()<<16
					hexstr_to_int += ("0x00" + string.substr(len(string)-4, len(string))).hex_to_int()
					entry.append([
						int(wnes3_keys[0]), 
						int(wnes3_keys[1]),
						hexstr_to_int,
						int(wnes3_keys[3]),
						int(wnes3_keys[4])
						])
					if not ids_found.has(hexstr_to_int):
						ids_found.append(hexstr_to_int)
						num_ids += 1
				i+=1
				while len(raw_split[i]) < 9 and i < len(raw_split)-1:
					i+=1
				if len(raw_split[i]) > 8:
					line = raw_split[i].strip_edges(true, true)
			self.RUL_wnes[w][n][e][s].append(entry)
		else:
			i+=1
	return OK
