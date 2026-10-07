extends SceneTree
func _init():
	for L in [1, 5, 12]:
		var ws = Levels.waves(L)
		var seq = []
		for g in ws[2]: seq.append("%s×%d" % [g[0], g[1]])
		print(L, " wave3: ", " ".join(seq))
	quit()
