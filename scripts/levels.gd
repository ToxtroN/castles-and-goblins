class_name Levels
## 15 уровней: у каждого своя карта (дороги), места под башни расставляются автоматически
## вдоль дорог, 3 волны собираются по сложности уровня. Прогресс (звёзды) хранится в user://progress.cfg.

const WAVES_PER_LEVEL := 3
const SAVE_PATH := "user://progress.cfg"

static var current := 1          # какой уровень сейчас играется

# Все дороги заканчиваются у ворот замка вверху (640, 30).
# Входы: слева x<0, справа x>1280, снизу y>720 (левый нижний угол занят кнопками).
const MAPS := [
	# 1 — нарисованная карта (assets/maps/level1.png), замок справа вверху
	[[Vector2(-40, 193), Vector2(72, 198), Vector2(188, 201), Vector2(265, 222), Vector2(310, 295),
		Vector2(346, 373), Vector2(423, 403), Vector2(500, 400), Vector2(577, 362), Vector2(633, 285),
		Vector2(710, 249), Vector2(788, 273), Vector2(823, 350), Vector2(870, 428), Vector2(947, 463),
		Vector2(1024, 476), Vector2(1101, 463), Vector2(1148, 425), Vector2(1155, 363), Vector2(1145, 290),
		Vector2(1160, 243), Vector2(1200, 216), Vector2(1228, 203)]],
	# 2 — справа, змейкой
	[[Vector2(1320, 300), Vector2(1080, 300), Vector2(960, 420), Vector2(760, 470), Vector2(620, 400),
		Vector2(640, 250), Vector2(640, 110), Vector2(640, 30)]],
	# 3 — снизу, длинный зигзаг
	[[Vector2(900, 770), Vector2(900, 600), Vector2(1080, 480), Vector2(1000, 350), Vector2(760, 340),
		Vector2(520, 300), Vector2(500, 190), Vector2(600, 140), Vector2(640, 30)]],
	# 4 — слева петлёй через всю карту
	[[Vector2(-40, 300), Vector2(200, 300), Vector2(380, 460), Vector2(640, 520), Vector2(900, 460),
		Vector2(960, 300), Vector2(800, 200), Vector2(660, 150), Vector2(640, 30)]],
	# 5 — справа снизу большой дугой
	[[Vector2(1320, 600), Vector2(1100, 600), Vector2(900, 560), Vector2(700, 600), Vector2(460, 520),
		Vector2(380, 360), Vector2(500, 230), Vector2(620, 150), Vector2(640, 30)]],
	# 6 — две дороги: слева и справа
	[[Vector2(-40, 420), Vector2(220, 420), Vector2(380, 300), Vector2(540, 200), Vector2(640, 120), Vector2(640, 30)],
	 [Vector2(1320, 420), Vector2(1060, 420), Vector2(900, 300), Vector2(740, 200), Vector2(640, 120), Vector2(640, 30)]],
	# 7 — снизу и слева
	[[Vector2(700, 770), Vector2(700, 560), Vector2(560, 440), Vector2(620, 300), Vector2(640, 150), Vector2(640, 30)],
	 [Vector2(-40, 250), Vector2(180, 250), Vector2(340, 340), Vector2(480, 300), Vector2(620, 300)]],
	# 8 — две дороги справа, сливаются
	[[Vector2(1320, 250), Vector2(1100, 250), Vector2(920, 330), Vector2(760, 300), Vector2(660, 200), Vector2(640, 30)],
	 [Vector2(1320, 560), Vector2(1080, 560), Vector2(880, 500), Vector2(780, 400), Vector2(760, 300)]],
	# 9 — слева и снизу длинные
	[[Vector2(-40, 520), Vector2(160, 520), Vector2(260, 400), Vector2(240, 260), Vector2(400, 180),
		Vector2(560, 160), Vector2(640, 110), Vector2(640, 30)],
	 [Vector2(1000, 770), Vector2(1000, 620), Vector2(820, 560), Vector2(760, 420), Vector2(860, 300),
		Vector2(760, 180), Vector2(660, 140), Vector2(640, 110)]],
	# 10 — две встречные змейки
	[[Vector2(-40, 360), Vector2(140, 360), Vector2(260, 470), Vector2(440, 470), Vector2(520, 330),
		Vector2(600, 200), Vector2(640, 30)],
	 [Vector2(1320, 360), Vector2(1140, 360), Vector2(1020, 470), Vector2(840, 470), Vector2(760, 330),
		Vector2(680, 200), Vector2(640, 110)]],
	# 11 — три дороги (классика)
	[[Vector2(-40, 560), Vector2(150, 560), Vector2(260, 500), Vector2(300, 380), Vector2(300, 285),
		Vector2(380, 205), Vector2(520, 172), Vector2(600, 150), Vector2(640, 105), Vector2(640, 30)],
	 [Vector2(1320, 560), Vector2(1130, 560), Vector2(1020, 500), Vector2(980, 380), Vector2(980, 285),
		Vector2(900, 205), Vector2(760, 172), Vector2(680, 150), Vector2(640, 105), Vector2(640, 30)],
	 [Vector2(640, 770), Vector2(640, 640), Vector2(740, 560), Vector2(780, 460), Vector2(720, 370),
		Vector2(640, 320), Vector2(640, 200), Vector2(640, 105), Vector2(640, 30)]],
	# 12 — две змейки по краям и нижняя
	[[Vector2(-40, 520), Vector2(160, 520), Vector2(240, 380), Vector2(200, 240), Vector2(360, 190),
		Vector2(500, 230), Vector2(580, 150), Vector2(640, 30)],
	 [Vector2(1320, 520), Vector2(1120, 520), Vector2(1040, 380), Vector2(1080, 240), Vector2(920, 190),
		Vector2(780, 230), Vector2(700, 150), Vector2(640, 30)],
	 [Vector2(820, 770), Vector2(820, 600), Vector2(640, 520), Vector2(520, 400), Vector2(600, 260), Vector2(640, 150)]],
	# 13 — три, нижняя петляет
	[[Vector2(-40, 440), Vector2(200, 440), Vector2(360, 340), Vector2(500, 230), Vector2(620, 140), Vector2(640, 30)],
	 [Vector2(1320, 200), Vector2(1100, 200), Vector2(920, 260), Vector2(760, 200), Vector2(660, 140)],
	 [Vector2(1100, 770), Vector2(1100, 620), Vector2(900, 560), Vector2(700, 600), Vector2(600, 480),
		Vector2(720, 380), Vector2(860, 300)]],
	# 14 — две слева, одна справа
	[[Vector2(-40, 200), Vector2(200, 200), Vector2(380, 240), Vector2(540, 180), Vector2(640, 110), Vector2(640, 30)],
	 [Vector2(-40, 480), Vector2(200, 480), Vector2(380, 420), Vector2(480, 320), Vector2(420, 250)],
	 [Vector2(1320, 460), Vector2(1100, 460), Vector2(940, 360), Vector2(820, 240), Vector2(680, 160), Vector2(640, 110)]],
	# 15 — финал: четыре дороги
	[[Vector2(-40, 300), Vector2(180, 300), Vector2(340, 220), Vector2(520, 170), Vector2(640, 110), Vector2(640, 30)],
	 [Vector2(1320, 300), Vector2(1100, 300), Vector2(940, 220), Vector2(760, 170), Vector2(640, 110)],
	 [Vector2(-40, 540), Vector2(200, 540), Vector2(340, 440), Vector2(380, 320), Vector2(340, 220)],
	 [Vector2(980, 770), Vector2(980, 600), Vector2(1060, 460), Vector2(1000, 330), Vector2(940, 220)]],
]

# Нарисованные карты: картинка + дороги + места под башни (каменные круги), снятые с рисунка.
# Чтобы добавить карту: положить PNG 1280×720 в assets/maps и дописать сюда.
const ART_MAPS := {
	"bc170802": {"image": "res://assets/maps/map_bc170802.webp",
		"paths": [
			[Vector2(-40, 158), Vector2(29, 187), Vector2(63, 196), Vector2(97, 202), Vector2(131, 202), Vector2(165, 201), Vector2(199, 202), Vector2(233, 208), Vector2(267, 223), Vector2(296, 254), Vector2(308, 288), Vector2(318, 322), Vector2(332, 356), Vector2(363, 385), Vector2(397, 399), Vector2(431, 405), Vector2(465, 405), Vector2(499, 400), Vector2(533, 390), Vector2(567, 370), Vector2(598, 338), Vector2(619, 304), Vector2(648, 271), Vector2(682, 253), Vector2(716, 248), Vector2(750, 252), Vector2(784, 270), Vector2(808, 304), Vector2(820, 338), Vector2(832, 372), Vector2(851, 406), Vector2(883, 437), Vector2(917, 456), Vector2(951, 465), Vector2(985, 474), Vector2(1019, 476), Vector2(1053, 474), Vector2(1087, 468), Vector2(1121, 455), Vector2(1151, 425), Vector2(1158, 391), Vector2(1155, 357), Vector2(1148, 323), Vector2(1143, 289), Vector2(1148, 255), Vector2(1173, 223), Vector2(1190, 221)]],
		"slots": [Vector2(351, 191), Vector2(208, 329), Vector2(722, 334), Vector2(1067, 384)]},
	"9e6e579e": {"image": "res://assets/maps/map_9e6e579e.webp",
		"paths": [
			[Vector2(-40, 206), Vector2(26, 180), Vector2(59, 195), Vector2(93, 207), Vector2(127, 209), Vector2(161, 206), Vector2(195, 202), Vector2(229, 199), Vector2(263, 202), Vector2(297, 211), Vector2(331, 230), Vector2(364, 262), Vector2(385, 296), Vector2(401, 330), Vector2(412, 364), Vector2(424, 398), Vector2(436, 432), Vector2(455, 466), Vector2(486, 498), Vector2(520, 520), Vector2(554, 533), Vector2(588, 540), Vector2(622, 543), Vector2(656, 539), Vector2(690, 531), Vector2(724, 514), Vector2(755, 483), Vector2(773, 449), Vector2(780, 415), Vector2(785, 381), Vector2(789, 347), Vector2(796, 313), Vector2(811, 279), Vector2(842, 250), Vector2(876, 241), Vector2(910, 241), Vector2(944, 250), Vector2(978, 271), Vector2(1012, 290), Vector2(1046, 295), Vector2(1080, 289), Vector2(1114, 270), Vector2(1148, 242), Vector2(1178, 228)]],
		"slots": [Vector2(911, 163), Vector2(254, 284), Vector2(1040, 405), Vector2(615, 439), Vector2(316, 458)]},
	"ca985285": {"image": "res://assets/maps/map_ca985285.webp",
		"paths": [
			[Vector2(-40, 484), Vector2(35, 473), Vector2(69, 480), Vector2(103, 484), Vector2(137, 483), Vector2(171, 473), Vector2(205, 458), Vector2(239, 431), Vector2(266, 397), Vector2(295, 363), Vector2(329, 343), Vector2(363, 337), Vector2(397, 339), Vector2(431, 352), Vector2(462, 383), Vector2(482, 417), Vector2(504, 451), Vector2(538, 474), Vector2(572, 480), Vector2(606, 477), Vector2(640, 460), Vector2(657, 426), Vector2(656, 392), Vector2(648, 358), Vector2(642, 324), Vector2(643, 290), Vector2(657, 256), Vector2(690, 229), Vector2(724, 219), Vector2(758, 218), Vector2(792, 222), Vector2(826, 229), Vector2(860, 238), Vector2(894, 245), Vector2(928, 252), Vector2(962, 255), Vector2(996, 256), Vector2(1030, 253), Vector2(1064, 248), Vector2(1098, 238), Vector2(1132, 224), Vector2(1166, 205), Vector2(1197, 198)]],
		"slots": [Vector2(1021, 172), Vector2(371, 177), Vector2(890, 330), Vector2(184, 355), Vector2(573, 405), Vector2(1109, 456)]},
	"83856539": {"image": "res://assets/maps/map_83856539.webp",
		"paths": [
			[Vector2(-40, 194), Vector2(28, 166), Vector2(61, 178), Vector2(95, 185), Vector2(129, 187), Vector2(163, 190), Vector2(197, 195), Vector2(231, 204), Vector2(265, 220), Vector2(298, 248), Vector2(317, 282), Vector2(329, 316), Vector2(338, 350), Vector2(351, 384), Vector2(371, 418), Vector2(402, 452), Vector2(436, 474), Vector2(470, 485), Vector2(504, 488), Vector2(538, 485), Vector2(572, 471), Vector2(590, 438), Vector2(590, 404), Vector2(573, 370), Vector2(553, 336), Vector2(541, 302), Vector2(538, 268), Vector2(544, 234), Vector2(560, 200), Vector2(594, 173), Vector2(628, 160), Vector2(662, 155), Vector2(696, 157), Vector2(730, 165), Vector2(764, 182), Vector2(797, 212), Vector2(822, 246), Vector2(843, 280), Vector2(868, 314), Vector2(901, 341), Vector2(935, 356), Vector2(969, 362), Vector2(1003, 362), Vector2(1037, 355), Vector2(1071, 334), Vector2(1097, 300), Vector2(1122, 266), Vector2(1155, 235), Vector2(1189, 222), Vector2(1189, 222)]],
		"slots": [Vector2(394, 228), Vector2(678, 235), Vector2(991, 276), Vector2(945, 447), Vector2(288, 463)]},
	"41cbe906": {"image": "res://assets/maps/map_41cbe906.webp",
		"paths": [
			[Vector2(-40, 197), Vector2(24, 170), Vector2(58, 187), Vector2(92, 197), Vector2(126, 199), Vector2(160, 200), Vector2(194, 208), Vector2(226, 235), Vector2(241, 269), Vector2(249, 303), Vector2(259, 337), Vector2(276, 371), Vector2(307, 403), Vector2(341, 421), Vector2(375, 429), Vector2(409, 430), Vector2(443, 425), Vector2(477, 410), Vector2(510, 382), Vector2(533, 348), Vector2(551, 314), Vector2(572, 280), Vector2(603, 249), Vector2(637, 238), Vector2(671, 237), Vector2(705, 247), Vector2(737, 277), Vector2(756, 311), Vector2(772, 345), Vector2(791, 379), Vector2(819, 413), Vector2(853, 437), Vector2(887, 452), Vector2(921, 459), Vector2(955, 460), Vector2(989, 454), Vector2(1023, 438), Vector2(1056, 409), Vector2(1075, 375), Vector2(1087, 341), Vector2(1097, 307), Vector2(1109, 273), Vector2(1135, 240), Vector2(1169, 218), Vector2(1183, 216)]],
		"slots": [Vector2(622, 157), Vector2(286, 182), Vector2(970, 206), Vector2(960, 380), Vector2(185, 415), Vector2(535, 468)]},
	"4561bb06": {"image": "res://assets/maps/map_4561bb06.webp",
		"paths": [
			[Vector2(-40, 197), Vector2(24, 170), Vector2(58, 186), Vector2(92, 195), Vector2(126, 201), Vector2(160, 198), Vector2(194, 194), Vector2(228, 191), Vector2(262, 194), Vector2(296, 205), Vector2(328, 233), Vector2(347, 267), Vector2(358, 301), Vector2(370, 335), Vector2(393, 369), Vector2(427, 391), Vector2(461, 399), Vector2(495, 400), Vector2(529, 394), Vector2(563, 373), Vector2(587, 339), Vector2(607, 305), Vector2(632, 271), Vector2(666, 253), Vector2(700, 251), Vector2(734, 259), Vector2(768, 281), Vector2(793, 314), Vector2(811, 348), Vector2(829, 382), Vector2(860, 413), Vector2(894, 432), Vector2(928, 440), Vector2(962, 442), Vector2(996, 437), Vector2(1030, 427), Vector2(1063, 400), Vector2(1083, 366), Vector2(1092, 332), Vector2(1101, 298), Vector2(1114, 264), Vector2(1144, 234), Vector2(1178, 217), Vector2(1184, 217)]],
		"slots": [Vector2(391, 173), Vector2(998, 242), Vector2(695, 340), Vector2(280, 378), Vector2(998, 525)]},
	"e3211341": {"image": "res://assets/maps/map_e3211341.webp",
		"paths": [
			[Vector2(-40, 256), Vector2(26, 230), Vector2(58, 249), Vector2(89, 268), Vector2(123, 284), Vector2(157, 295), Vector2(191, 302), Vector2(225, 305), Vector2(259, 310), Vector2(286, 283), Vector2(317, 251), Vector2(350, 220), Vector2(384, 204), Vector2(418, 198), Vector2(452, 197), Vector2(486, 197), Vector2(520, 193), Vector2(554, 181), Vector2(588, 164), Vector2(622, 149), Vector2(656, 140), Vector2(690, 137), Vector2(724, 138), Vector2(758, 144), Vector2(792, 157), Vector2(826, 176), Vector2(860, 203), Vector2(894, 228), Vector2(928, 248), Vector2(962, 265), Vector2(996, 287), Vector2(1030, 314), Vector2(1063, 336), Vector2(1097, 329), Vector2(1131, 314), Vector2(1165, 292), Vector2(1183, 286)],
			[Vector2(-40, 256), Vector2(26, 230), Vector2(58, 249), Vector2(89, 268), Vector2(123, 284), Vector2(157, 295), Vector2(191, 302), Vector2(225, 305), Vector2(259, 310), Vector2(278, 342), Vector2(302, 376), Vector2(317, 410), Vector2(339, 444), Vector2(372, 472), Vector2(406, 486), Vector2(440, 492), Vector2(474, 495), Vector2(508, 498), Vector2(542, 506), Vector2(576, 520), Vector2(610, 539), Vector2(644, 555), Vector2(678, 564), Vector2(712, 567), Vector2(746, 566), Vector2(780, 558), Vector2(814, 543), Vector2(848, 527), Vector2(882, 516), Vector2(916, 502), Vector2(950, 477), Vector2(975, 443), Vector2(1004, 409), Vector2(1038, 381), Vector2(1060, 350), Vector2(1087, 332), Vector2(1121, 320), Vector2(1155, 298), Vector2(1183, 286)]],
		"slots": [Vector2(372, 119), Vector2(939, 154), Vector2(272, 513), Vector2(1017, 542), Vector2(522, 594)]},
	"12cdb9e2": {"image": "res://assets/maps/map_12cdb9e2.webp",
		"paths": [
			[Vector2(-40, 146), Vector2(32, 125), Vector2(66, 138), Vector2(100, 145), Vector2(134, 143), Vector2(168, 143), Vector2(202, 148), Vector2(236, 160), Vector2(270, 180), Vector2(304, 205), Vector2(338, 228), Vector2(372, 242), Vector2(406, 247), Vector2(440, 245), Vector2(474, 239), Vector2(508, 226), Vector2(542, 213), Vector2(576, 203), Vector2(610, 199), Vector2(644, 198), Vector2(678, 200), Vector2(712, 207), Vector2(746, 220), Vector2(780, 247), Vector2(807, 281), Vector2(835, 315), Vector2(869, 342), Vector2(894, 371), Vector2(928, 371), Vector2(962, 370), Vector2(996, 370), Vector2(1030, 370), Vector2(1064, 368), Vector2(1098, 361), Vector2(1132, 344), Vector2(1166, 318), Vector2(1189, 312)],
			[Vector2(-40, 579), Vector2(28, 552), Vector2(62, 566), Vector2(96, 573), Vector2(130, 571), Vector2(164, 567), Vector2(198, 558), Vector2(232, 544), Vector2(266, 523), Vector2(300, 497), Vector2(334, 471), Vector2(368, 456), Vector2(402, 450), Vector2(436, 452), Vector2(470, 460), Vector2(504, 475), Vector2(538, 495), Vector2(572, 511), Vector2(606, 522), Vector2(640, 528), Vector2(674, 529), Vector2(708, 525), Vector2(742, 516), Vector2(776, 499), Vector2(810, 469), Vector2(839, 435), Vector2(872, 404), Vector2(893, 371), Vector2(927, 371), Vector2(961, 370), Vector2(995, 370), Vector2(1029, 370), Vector2(1063, 368), Vector2(1097, 361), Vector2(1131, 345), Vector2(1165, 319), Vector2(1189, 312)]],
		"slots": [Vector2(382, 159), Vector2(850, 203), Vector2(996, 300), Vector2(995, 444), Vector2(887, 513), Vector2(394, 530)]},
	"9ab13e67": {"image": "res://assets/maps/map_9ab13e67.webp",
		"paths": [
			[Vector2(-40, 129), Vector2(31, 155), Vector2(63, 166), Vector2(97, 176), Vector2(131, 174), Vector2(165, 169), Vector2(199, 165), Vector2(233, 169), Vector2(267, 182), Vector2(301, 205), Vector2(335, 230), Vector2(369, 246), Vector2(403, 253), Vector2(437, 251), Vector2(471, 244), Vector2(505, 224), Vector2(539, 204), Vector2(573, 191), Vector2(607, 187), Vector2(641, 192), Vector2(675, 205), Vector2(709, 228), Vector2(743, 256), Vector2(777, 278), Vector2(811, 291), Vector2(845, 297), Vector2(879, 297), Vector2(913, 295), Vector2(947, 294), Vector2(981, 296), Vector2(1015, 303), Vector2(1049, 319), Vector2(1083, 344), Vector2(1117, 367), Vector2(1151, 370), Vector2(1185, 358), Vector2(1186, 358)],
			[Vector2(-40, 530), Vector2(35, 527), Vector2(69, 534), Vector2(102, 543), Vector2(136, 539), Vector2(170, 537), Vector2(204, 542), Vector2(238, 549), Vector2(272, 550), Vector2(306, 544), Vector2(340, 528), Vector2(374, 503), Vector2(408, 486), Vector2(442, 479), Vector2(476, 479), Vector2(510, 488), Vector2(544, 506), Vector2(578, 531), Vector2(612, 552), Vector2(646, 563), Vector2(680, 567), Vector2(714, 562), Vector2(748, 552), Vector2(782, 529), Vector2(816, 502), Vector2(850, 485), Vector2(884, 476), Vector2(918, 473), Vector2(952, 476), Vector2(986, 478), Vector2(1020, 476), Vector2(1054, 469), Vector2(1088, 453), Vector2(1119, 423), Vector2(1130, 389), Vector2(1157, 368), Vector2(1186, 358)]],
		"slots": [Vector2(368, 157), Vector2(794, 194), Vector2(985, 374), Vector2(434, 395), Vector2(908, 555), Vector2(450, 560)]},
	"cddba6f5": {"image": "res://assets/maps/map_cddba6f5.webp",
		"paths": [
			[Vector2(-40, 138), Vector2(30, 120), Vector2(62, 134), Vector2(95, 148), Vector2(129, 151), Vector2(163, 150), Vector2(197, 150), Vector2(231, 154), Vector2(265, 169), Vector2(298, 199), Vector2(332, 229), Vector2(366, 244), Vector2(400, 250), Vector2(434, 251), Vector2(468, 247), Vector2(502, 238), Vector2(536, 221), Vector2(570, 194), Vector2(598, 160), Vector2(631, 131), Vector2(665, 122), Vector2(699, 125), Vector2(733, 141), Vector2(767, 170), Vector2(801, 201), Vector2(835, 226), Vector2(869, 245), Vector2(903, 256), Vector2(937, 264), Vector2(971, 268), Vector2(1005, 271), Vector2(1039, 274), Vector2(1073, 282), Vector2(1107, 296), Vector2(1141, 305), Vector2(1171, 319), Vector2(1183, 319)],
			[Vector2(-40, 623), Vector2(33, 601), Vector2(67, 598), Vector2(101, 597), Vector2(135, 592), Vector2(169, 583), Vector2(203, 565), Vector2(237, 537), Vector2(271, 506), Vector2(305, 485), Vector2(339, 475), Vector2(373, 474), Vector2(407, 478), Vector2(441, 496), Vector2(471, 529), Vector2(493, 563), Vector2(527, 591), Vector2(561, 603), Vector2(595, 604), Vector2(629, 598), Vector2(663, 577), Vector2(693, 544), Vector2(726, 515), Vector2(760, 502), Vector2(794, 503), Vector2(828, 510), Vector2(862, 524), Vector2(896, 534), Vector2(930, 538), Vector2(964, 536), Vector2(998, 529), Vector2(1032, 517), Vector2(1066, 497), Vector2(1100, 468), Vector2(1129, 434), Vector2(1149, 400), Vector2(1162, 366), Vector2(1170, 332), Vector2(1183, 319)]],
		"slots": [Vector2(353, 143), Vector2(931, 182), Vector2(1008, 423), Vector2(366, 550), Vector2(791, 584)]},
	"15460778": {"image": "res://assets/maps/map_15460778.webp",
		"paths": [
			[Vector2(-40, 170), Vector2(27, 144), Vector2(60, 157), Vector2(94, 165), Vector2(128, 163), Vector2(162, 160), Vector2(196, 156), Vector2(230, 153), Vector2(264, 154), Vector2(298, 160), Vector2(332, 173), Vector2(366, 199), Vector2(399, 233), Vector2(433, 258), Vector2(467, 270), Vector2(501, 278), Vector2(535, 284), Vector2(569, 295), Vector2(603, 314), Vector2(634, 344), Vector2(668, 363), Vector2(699, 395), Vector2(733, 421), Vector2(767, 441), Vector2(801, 456), Vector2(835, 467), Vector2(869, 474), Vector2(903, 478), Vector2(937, 479), Vector2(971, 478), Vector2(1005, 472), Vector2(1039, 462), Vector2(1073, 447), Vector2(1107, 427), Vector2(1141, 405), Vector2(1175, 382), Vector2(1207, 370)],
			[Vector2(-40, 495), Vector2(23, 527), Vector2(56, 542), Vector2(90, 553), Vector2(124, 555), Vector2(158, 557), Vector2(192, 562), Vector2(226, 569), Vector2(260, 573), Vector2(294, 574), Vector2(328, 567), Vector2(362, 547), Vector2(392, 513), Vector2(423, 480), Vector2(457, 459), Vector2(491, 446), Vector2(525, 434), Vector2(559, 418), Vector2(593, 398), Vector2(623, 370), Vector2(656, 351), Vector2(690, 318), Vector2(724, 294), Vector2(758, 274), Vector2(792, 258), Vector2(826, 247), Vector2(860, 241), Vector2(894, 239), Vector2(928, 243), Vector2(962, 252), Vector2(996, 266), Vector2(1030, 284), Vector2(1064, 299), Vector2(1098, 311), Vector2(1132, 329), Vector2(1144, 332)]],
		"slots": [Vector2(452, 183), Vector2(758, 199), Vector2(474, 354), Vector2(801, 360), Vector2(507, 525), Vector2(767, 527)]},
	"821a045f": {"image": "res://assets/maps/map_821a045f.webp",
		"paths": [
			[Vector2(-40, 100), Vector2(35, 91), Vector2(69, 101), Vector2(102, 112), Vector2(136, 117), Vector2(170, 121), Vector2(204, 122), Vector2(238, 119), Vector2(272, 110), Vector2(306, 96), Vector2(340, 84), Vector2(374, 79), Vector2(408, 81), Vector2(442, 92), Vector2(476, 110), Vector2(510, 139), Vector2(544, 165), Vector2(578, 183), Vector2(612, 191), Vector2(646, 194), Vector2(680, 195), Vector2(714, 194), Vector2(748, 193), Vector2(782, 191), Vector2(816, 190), Vector2(850, 191), Vector2(884, 194), Vector2(918, 199), Vector2(952, 206), Vector2(986, 217), Vector2(1020, 233), Vector2(1054, 255), Vector2(1088, 285), Vector2(1122, 311), Vector2(1139, 340), Vector2(1167, 357), Vector2(1198, 366), Vector2(1211, 369)],
			[Vector2(-40, 322), Vector2(35, 307), Vector2(69, 315), Vector2(103, 322), Vector2(137, 321), Vector2(171, 320), Vector2(205, 318), Vector2(239, 321), Vector2(273, 327), Vector2(307, 336), Vector2(341, 348), Vector2(375, 359), Vector2(409, 367), Vector2(443, 372), Vector2(477, 372), Vector2(511, 369), Vector2(545, 363), Vector2(579, 357), Vector2(613, 353), Vector2(647, 353), Vector2(681, 357), Vector2(715, 368), Vector2(749, 386), Vector2(783, 407), Vector2(817, 422), Vector2(851, 431), Vector2(885, 436), Vector2(919, 435), Vector2(953, 430), Vector2(987, 420), Vector2(1021, 403), Vector2(1055, 385), Vector2(1089, 369), Vector2(1123, 359), Vector2(1157, 354), Vector2(1188, 368), Vector2(1211, 369)],
			[Vector2(-40, 539), Vector2(35, 518), Vector2(69, 518), Vector2(103, 511), Vector2(137, 488), Vector2(171, 465), Vector2(205, 453), Vector2(239, 448), Vector2(273, 448), Vector2(307, 456), Vector2(341, 469), Vector2(375, 494), Vector2(405, 528), Vector2(431, 562), Vector2(462, 594), Vector2(496, 617), Vector2(530, 632), Vector2(564, 640), Vector2(598, 646), Vector2(632, 650), Vector2(666, 652), Vector2(700, 650), Vector2(734, 646), Vector2(768, 638), Vector2(802, 621), Vector2(836, 597), Vector2(870, 577), Vector2(904, 564), Vector2(938, 558), Vector2(972, 556), Vector2(1006, 556), Vector2(1040, 554), Vector2(1074, 546), Vector2(1108, 525), Vector2(1131, 492), Vector2(1142, 458), Vector2(1153, 424), Vector2(1170, 390), Vector2(1189, 368), Vector2(1211, 369)]],
		"slots": [Vector2(735, 125), Vector2(941, 279), Vector2(589, 290), Vector2(1028, 494), Vector2(264, 524)]},
	"24e42ef7": {"image": "res://assets/maps/map_24e42ef7.webp",
		"paths": [
			[Vector2(-40, 112), Vector2(29, 139), Vector2(63, 151), Vector2(97, 159), Vector2(131, 163), Vector2(165, 168), Vector2(199, 173), Vector2(233, 175), Vector2(267, 172), Vector2(301, 163), Vector2(335, 142), Vector2(362, 110), Vector2(390, 81), Vector2(424, 73), Vector2(458, 73), Vector2(492, 76), Vector2(526, 83), Vector2(560, 96), Vector2(594, 115), Vector2(628, 136), Vector2(662, 155), Vector2(696, 169), Vector2(730, 179), Vector2(764, 186), Vector2(798, 190), Vector2(832, 191), Vector2(866, 191), Vector2(900, 191), Vector2(934, 195), Vector2(968, 204), Vector2(1002, 220), Vector2(1036, 247), Vector2(1064, 281), Vector2(1087, 315), Vector2(1106, 349), Vector2(1121, 382), Vector2(1150, 390), Vector2(1184, 383), Vector2(1207, 385)],
			[Vector2(-40, 332), Vector2(35, 355), Vector2(69, 359), Vector2(103, 361), Vector2(137, 361), Vector2(171, 361), Vector2(205, 361), Vector2(239, 362), Vector2(273, 360), Vector2(307, 358), Vector2(341, 353), Vector2(375, 343), Vector2(409, 324), Vector2(443, 300), Vector2(477, 277), Vector2(511, 262), Vector2(545, 246), Vector2(579, 242), Vector2(613, 240), Vector2(647, 240), Vector2(681, 245), Vector2(715, 249), Vector2(749, 262), Vector2(783, 276), Vector2(817, 295), Vector2(851, 321), Vector2(885, 347), Vector2(919, 365), Vector2(953, 372), Vector2(987, 376), Vector2(1021, 376), Vector2(1055, 378), Vector2(1089, 380), Vector2(1121, 384), Vector2(1152, 390), Vector2(1186, 383), Vector2(1207, 385)],
			[Vector2(-40, 627), Vector2(31, 600), Vector2(65, 598), Vector2(99, 592), Vector2(133, 582), Vector2(167, 566), Vector2(201, 548), Vector2(235, 527), Vector2(269, 509), Vector2(303, 499), Vector2(337, 493), Vector2(371, 492), Vector2(405, 497), Vector2(439, 504), Vector2(473, 517), Vector2(507, 534), Vector2(541, 555), Vector2(575, 578), Vector2(609, 593), Vector2(643, 602), Vector2(677, 603), Vector2(711, 597), Vector2(745, 583), Vector2(779, 563), Vector2(813, 548), Vector2(847, 540), Vector2(881, 537), Vector2(915, 537), Vector2(949, 539), Vector2(983, 535), Vector2(1017, 526), Vector2(1051, 502), Vector2(1077, 468), Vector2(1107, 435), Vector2(1122, 401), Vector2(1151, 390), Vector2(1185, 383), Vector2(1207, 385)]],
		"slots": [Vector2(415, 116), Vector2(816, 127), Vector2(482, 363), Vector2(835, 404), Vector2(365, 556), Vector2(847, 607), Vector2(580, 657)]},
	"0ab5a528": {"image": "res://assets/maps/map_0ab5a528.webp",
		"paths": [
			[Vector2(-40, 115), Vector2(28, 94), Vector2(62, 102), Vector2(96, 100), Vector2(130, 95), Vector2(164, 95), Vector2(198, 110), Vector2(227, 143), Vector2(258, 174), Vector2(292, 191), Vector2(326, 199), Vector2(360, 202), Vector2(394, 201), Vector2(428, 196), Vector2(462, 181), Vector2(496, 156), Vector2(530, 142), Vector2(564, 138), Vector2(598, 143), Vector2(632, 154), Vector2(666, 161), Vector2(700, 159), Vector2(734, 144), Vector2(767, 111), Vector2(801, 90), Vector2(835, 85), Vector2(869, 93), Vector2(903, 119), Vector2(928, 153), Vector2(962, 176), Vector2(996, 184), Vector2(1030, 192), Vector2(1064, 204), Vector2(1090, 237), Vector2(1100, 271), Vector2(1112, 305), Vector2(1134, 338), Vector2(1155, 371), Vector2(1189, 359), Vector2(1195, 358)],
			[Vector2(-40, 313), Vector2(33, 299), Vector2(67, 305), Vector2(101, 308), Vector2(135, 304), Vector2(169, 302), Vector2(203, 305), Vector2(237, 315), Vector2(271, 337), Vector2(305, 364), Vector2(339, 382), Vector2(373, 390), Vector2(407, 391), Vector2(441, 390), Vector2(475, 385), Vector2(509, 365), Vector2(537, 332), Vector2(567, 300), Vector2(601, 284), Vector2(635, 283), Vector2(669, 292), Vector2(703, 314), Vector2(737, 344), Vector2(771, 369), Vector2(805, 382), Vector2(839, 388), Vector2(873, 388), Vector2(907, 388), Vector2(941, 388), Vector2(975, 392), Vector2(1009, 397), Vector2(1043, 396), Vector2(1077, 389), Vector2(1111, 383), Vector2(1145, 386), Vector2(1173, 362), Vector2(1195, 358)],
			[Vector2(-40, 518), Vector2(33, 503), Vector2(66, 509), Vector2(100, 509), Vector2(134, 500), Vector2(168, 491), Vector2(202, 489), Vector2(236, 490), Vector2(270, 503), Vector2(302, 529), Vector2(326, 563), Vector2(352, 597), Vector2(386, 620), Vector2(420, 629), Vector2(454, 630), Vector2(488, 625), Vector2(522, 622), Vector2(556, 624), Vector2(590, 636), Vector2(624, 651), Vector2(658, 664), Vector2(692, 672), Vector2(726, 674), Vector2(760, 673), Vector2(794, 669), Vector2(828, 662), Vector2(862, 651), Vector2(896, 636), Vector2(930, 620), Vector2(964, 602), Vector2(998, 588), Vector2(1032, 574), Vector2(1066, 549), Vector2(1087, 515), Vector2(1099, 481), Vector2(1115, 447), Vector2(1134, 413), Vector2(1152, 380), Vector2(1180, 359), Vector2(1195, 358)]],
		"slots": [Vector2(418, 125), Vector2(827, 151), Vector2(370, 317), Vector2(1017, 328), Vector2(624, 347), Vector2(886, 555), Vector2(419, 556)]},
	"69c76ba7": {"image": "res://assets/maps/map_69c76ba7.webp",
		"paths": [
			[Vector2(-40, 115), Vector2(33, 99), Vector2(67, 105), Vector2(101, 110), Vector2(135, 113), Vector2(169, 119), Vector2(203, 129), Vector2(237, 145), Vector2(271, 162), Vector2(305, 177), Vector2(339, 188), Vector2(373, 194), Vector2(407, 197), Vector2(441, 198), Vector2(475, 196), Vector2(509, 191), Vector2(543, 182), Vector2(577, 170), Vector2(611, 156), Vector2(645, 144), Vector2(679, 136), Vector2(713, 131), Vector2(747, 133), Vector2(781, 142), Vector2(815, 160), Vector2(849, 182), Vector2(883, 199), Vector2(917, 209), Vector2(951, 212), Vector2(985, 214), Vector2(1019, 221), Vector2(1053, 237), Vector2(1086, 268), Vector2(1112, 302), Vector2(1145, 327), Vector2(1171, 351), Vector2(1204, 346)],
			[Vector2(-40, 349), Vector2(33, 332), Vector2(67, 338), Vector2(101, 340), Vector2(135, 338), Vector2(169, 338), Vector2(203, 343), Vector2(237, 355), Vector2(271, 374), Vector2(305, 397), Vector2(339, 415), Vector2(373, 427), Vector2(407, 435), Vector2(441, 438), Vector2(475, 437), Vector2(509, 432), Vector2(543, 421), Vector2(577, 406), Vector2(611, 389), Vector2(645, 371), Vector2(679, 356), Vector2(713, 344), Vector2(747, 337), Vector2(781, 333), Vector2(815, 336), Vector2(849, 343), Vector2(883, 354), Vector2(917, 366), Vector2(951, 381), Vector2(985, 392), Vector2(1019, 398), Vector2(1053, 399), Vector2(1087, 395), Vector2(1121, 390), Vector2(1154, 381), Vector2(1173, 351), Vector2(1204, 346)],
			[Vector2(-40, 565), Vector2(33, 546), Vector2(67, 552), Vector2(101, 557), Vector2(135, 563), Vector2(169, 575), Vector2(203, 591), Vector2(237, 609), Vector2(271, 625), Vector2(305, 635), Vector2(339, 643), Vector2(373, 645), Vector2(407, 644), Vector2(441, 639), Vector2(475, 628), Vector2(509, 611), Vector2(543, 590), Vector2(577, 570), Vector2(611, 557), Vector2(645, 551), Vector2(679, 549), Vector2(713, 554), Vector2(747, 563), Vector2(781, 573), Vector2(815, 580), Vector2(849, 580), Vector2(883, 574), Vector2(917, 562), Vector2(951, 547), Vector2(985, 537), Vector2(1019, 531), Vector2(1053, 519), Vector2(1087, 500), Vector2(1118, 469), Vector2(1138, 435), Vector2(1145, 401), Vector2(1163, 369), Vector2(1186, 347), Vector2(1204, 346)]],
		"slots": [Vector2(854, 98), Vector2(407, 103), Vector2(312, 299), Vector2(742, 436), Vector2(345, 549), Vector2(1000, 607)]},
	"9d7f608f": {"image": "res://assets/maps/map_9d7f608f.webp",
		"paths": [
			[Vector2(-40, 79), Vector2(29, 106), Vector2(63, 117), Vector2(97, 129), Vector2(131, 137), Vector2(165, 148), Vector2(199, 158), Vector2(233, 166), Vector2(267, 172), Vector2(301, 175), Vector2(335, 174), Vector2(369, 169), Vector2(403, 159), Vector2(437, 146), Vector2(471, 135), Vector2(505, 127), Vector2(539, 124), Vector2(573, 123), Vector2(607, 126), Vector2(641, 133), Vector2(675, 145), Vector2(709, 160), Vector2(743, 183), Vector2(777, 214), Vector2(811, 246), Vector2(845, 266), Vector2(879, 276), Vector2(913, 281), Vector2(947, 282), Vector2(981, 282), Vector2(1015, 283), Vector2(1049, 284), Vector2(1083, 294), Vector2(1117, 315), Vector2(1133, 348), Vector2(1161, 366), Vector2(1189, 380), Vector2(1203, 378)],
			[Vector2(-40, 334), Vector2(32, 359), Vector2(66, 366), Vector2(100, 374), Vector2(134, 375), Vector2(168, 373), Vector2(202, 370), Vector2(236, 361), Vector2(270, 352), Vector2(304, 343), Vector2(338, 338), Vector2(372, 343), Vector2(406, 350), Vector2(440, 358), Vector2(458, 387), Vector2(481, 421), Vector2(515, 444), Vector2(549, 455), Vector2(583, 460), Vector2(617, 462), Vector2(651, 460), Vector2(685, 455), Vector2(719, 440), Vector2(749, 410), Vector2(763, 376), Vector2(789, 361), Vector2(823, 361), Vector2(857, 361), Vector2(891, 362), Vector2(925, 362), Vector2(959, 362), Vector2(993, 362), Vector2(1027, 363), Vector2(1061, 364), Vector2(1095, 364), Vector2(1129, 362), Vector2(1162, 368), Vector2(1191, 379), Vector2(1203, 378)],
			[Vector2(-40, 598), Vector2(150, 590), Vector2(300, 556), Vector2(370, 550), Vector2(404, 545), Vector2(438, 551), Vector2(472, 567), Vector2(506, 589), Vector2(540, 608), Vector2(574, 617), Vector2(608, 620), Vector2(642, 615), Vector2(676, 603), Vector2(710, 578), Vector2(741, 546), Vector2(775, 523), Vector2(809, 511), Vector2(843, 510), Vector2(877, 515), Vector2(911, 527), Vector2(945, 538), Vector2(979, 543), Vector2(1013, 543), Vector2(1047, 535), Vector2(1080, 509), Vector2(1098, 475), Vector2(1118, 441), Vector2(1149, 412), Vector2(1172, 383), Vector2(1206, 378), Vector2(1212, 376)]],
		"slots": [Vector2(414, 78), Vector2(895, 208), Vector2(599, 351), Vector2(324, 409), Vector2(943, 434), Vector2(571, 543), Vector2(932, 612)]},
}


## Список уровней: нарисованные и сгенерированные карты, отсортированные по числу дорог
## (сначала одна дорога). У каждого уровня свой id — по нему сохраняются звёзды.
static var _defs: Array = []


static func defs() -> Array:
	if not _defs.is_empty():
		return _defs
	var list: Array = []
	var order := 0
	for id in ART_MAPS:
		var a: Dictionary = ART_MAPS[id]
		var ps: Array = a.paths if a.has("paths") else MAPS[0]
		var starts := {}
		for pth in ps:
			starts[int(pth[0].y / 40)] = true
		list.append({"id": "art:" + id, "paths": ps, "art": a, "entries": starts.size(), "n": ps.size(), "o": order})
		order += 1
	list.sort_custom(func(x, y):
		if x.entries != y.entries: return x.entries < y.entries
		if x.n != y.n: return x.n < y.n
		return x.o < y.o)
	_defs = list
	return _defs


static func count() -> int:
	return defs().size()


static func def(level: int) -> Dictionary:
	return defs()[clampi(level, 1, count()) - 1]


## Сложность уровня по шкале 1..15 (кривая сложности не зависит от того, сколько всего уровней).
static func diff(level: int) -> float:
	return 1.0 + (level - 1) * 14.0 / maxf(1.0, count() - 1)


static func art_map(level: int) -> Dictionary:
	return def(level).art


# Типы гоблинов и уровень, с которого они появляются
const UNLOCK := {"grunt": 1, "spearman": 2, "mage": 4, "crow": 5, "rock": 6, "brute": 8, "cart": 10}
# «Стоимость» гоблина для бюджета волны
const COST := {"grunt": 1.0, "spearman": 1.8, "mage": 2.2, "crow": 2.0, "rock": 2.8, "brute": 14.0, "cart": 9.0}


static func start_gold(level: int) -> int:
	# больше дорог — больше золота на старте, чтобы прикрыть все направления
	return 260 + int(diff(level) * 25) + (paths(level).size() - 1) * 90


static func hp_mult(level: int, wave: int) -> float:
	return 1.0 + (diff(level) - 1) * 0.08 + wave * 0.06


static func paths(level: int) -> Array:
	return def(level).paths


## Три волны уровня: список групп [тип, количество, путь, интервал, задержка].
## Три волны уровня: список групп [тип, количество, путь, интервал, задержка].
## Состав считается по «бюджету», затем враги разбиваются на маленькие пачки (1–3 одинаковых)
## и чередуются по типам, чтобы не было толпы из одних и тех же гоблинов.
static func waves(level: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = level * 7919
	var n_paths: int = paths(level).size()
	var dl := diff(level)
	var dprev := diff(level - 1) if level > 1 else 0.0
	var types: Array = []
	for k in UNLOCK:
		if UNLOCK[k] <= dl:
			types.append(k)
	var small: Array = types.filter(func(t): return t != "brute" and t != "cart")
	var res: Array = []
	for w in WAVES_PER_LEVEL:
		var budget := (0.7 + 0.3 * minf(1.0, (dl - 1.0) / 3.0) + 0.65 * clampf((dl - 3.0) / 8.0, 0.0, 1.0)) * (13.0 + dl * 1.9) * (1.0 + w * 0.55) * (1.0 - 0.08 * (n_paths - 1))
		# --- состав волны: веса — слабых больше, новинку уровня показываем обязательно
		var counts := {}
		var bosses: Array = []
		if w == WAVES_PER_LEVEL - 1:
			var bp := ["brute", "cart"].filter(func(b): return types.has(b))
			if not bp.is_empty():
				var boss: String = bp[(level + rng.randi()) % bp.size()]
				for i in 1 + int(dl >= 13):
					bosses.append(boss)
					budget -= COST[boss]
		for k in UNLOCK:
			if w == 0 and UNLOCK[k] <= dl and UNLOCK[k] > dprev and small.has(k):
				counts[k] = 2
				budget -= COST[k] * 2
		var guard := 0
		while budget > 0.9 and guard < 200:
			guard += 1
			var tot := 0.0
			for t in small:
				tot += 1.0 / COST[t]
			var r := rng.randf() * tot
			var pick: String = small[0]
			for t in small:
				r -= 1.0 / COST[t]
				if r <= 0.0:
					pick = t
					break
			if COST[pick] > budget:
				pick = "grunt"
			counts[pick] = counts.get(pick, 0) + 1
			budget -= COST[pick]
		# --- пачки по 1–3 и чередование типов
		var packs: Array = []
		var left := counts.duplicate()
		var last := ""
		while not left.is_empty():
			var keys: Array = left.keys().filter(func(t): return t != last)
			if keys.is_empty():
				keys = left.keys()
			keys.sort_custom(func(x, y): return left[x] > left[y])
			var tp: String = keys[0] if rng.randf() < 0.6 else keys[rng.randi() % keys.size()]
			var n := mini(left[tp], 1 + rng.randi() % (3 if tp == "grunt" else 2))
			packs.append([tp, n])
			left[tp] -= n
			if left[tp] <= 0:
				left.erase(tp)
			last = tp
		if w == WAVES_PER_LEVEL - 1 and level == count():
			bosses = ["king"]
		# босс — ближе к середине волны
		for i in bosses.size():
			packs.insert(mini(packs.size(), packs.size() / 2 + i), [bosses[i], 1])
		var groups: Array = []
		var delay := 0.0
		var base_gap := clampf(1.5 - dl * 0.04, 0.8, 1.4)
		for i in packs.size():
			var tp2: String = packs[i][0]
			var n2: int = packs[i][1]
			var interval := base_gap * sqrt(COST.get(tp2, 14.0)) * 0.55
			groups.append([tp2, n2, 0 if tp2 == "king" else (i + w) % n_paths, interval, delay])
			delay += interval * n2 + rng.randf_range(0.4, 1.1) * (1.6 if tp2 == "brute" or tp2 == "cart" else (6.0 if tp2 == "king" else 1.0))
		res.append(groups)
	return res


## Места под башни: точки на расстоянии 55–80 px от дороги, не ближе 82 px друг к другу.
static func make_slots(curves: Array) -> Array:
	var cands: Array = []
	for c in curves:
		var pts: PackedVector2Array = c.get_baked_points()
		for i in range(0, pts.size() - 1, 6):
			var p: Vector2 = pts[i]
			var q: Vector2 = pts[mini(i + 3, pts.size() - 1)]
			var dir := (q - p).normalized()
			var nrm := Vector2(-dir.y, dir.x)
			for side in [-1.0, 1.0]:
				cands.append(p + nrm * side * 66.0)
	var res: Array = []
	for p in cands:
		if p.x < 50 or p.x > 1230 or p.y < 130 or p.y > 690:
			continue
		if Rect2(0, 600, 340, 120).has_point(p) or Rect2(1100, 0, 180, 110).has_point(p):
			continue
		var rd := INF
		for c in curves:
			rd = minf(rd, c.get_closest_point(p).distance_to(p))
		if rd < 54.0 or rd > 90.0:
			continue
		var ok := true
		for s in res:
			if s.distance_to(p) < 98.0:
				ok = false
				break
		if ok:
			res.append(p)
		if res.size() >= 18:
			break
	return res


# ---------------------------------------------------------------- ПРОГРЕСС
static func load_stars() -> Array:
	var cf := ConfigFile.new()
	var stars: Array = []
	var ok := cf.load(SAVE_PATH) == OK
	for d in defs():
		stars.append(int(cf.get_value("stars", d.id, 0)) if ok else 0)
	return stars


static func save_stars(level: int, s: int) -> void:
	var cf := ConfigFile.new()
	cf.load(SAVE_PATH)
	var id: String = def(level).id
	var old: int = cf.get_value("stars", id, 0)
	if s > old:
		cf.set_value("stars", id, s)
		cf.save(SAVE_PATH)


static func unlocked(level: int, stars: Array) -> bool:
	return level == 1 or stars[level - 2] > 0


# ---------------------------------------------------------------- МЕХАНИКИ КАРТ
# swamp — топь на дороге (враги и герои медленнее), high — возвышенность (башня +25% дальности),
# shrine — святилище (герои рядом лечатся), mine — золотая шахта (+золото, пока рядом нет врагов).
const MECHANICS := {}   # механики карт отключены
const MECH_INFO := {
	"swamp": "Топь: враги и герои идут по ней медленнее",
	"high": "Флажок — возвышенность: башня бьёт на 25% дальше",
	"shrine": "Святилище: герои рядом с ним лечатся",
	"mine": "Шахта: +6 золота каждые 10 с, если рядом нет врагов",
}


static func mechanics(level: int) -> Array:
	return MECHANICS.get(level, [])


static func is_boss_level(level: int) -> bool:
	return level == count()


static func stars_for_lives(lives: int) -> int:
	if lives >= 18:
		return 3
	if lives >= 10:
		return 2
	return 1
