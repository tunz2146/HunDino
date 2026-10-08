-- Training prototypes, not final hunting balance. Damage/cost/timing live here.
local function strike(damage,cost,windup,duration,range,extra)
	local a={Damage=damage,Cost=cost,Windup=windup,Duration=duration,Range=range}
	for k,v in extra or {} do a[k]=v end
	return a
end
local weapons = {
	Order={"Hammer","SwordShield","Katana","Glaive","DualDaggers","Bow","GreatAxe"},
	Hammer={Name="Búa tạ",Description="Đòn nặng • Thường → Mạnh → Kỹ năng",Skill="Đập chấn động",
		Attacks={Light=strike(36,8,.18,.55,9),Heavy=strike(70,16,.45,1.1,10),Skill=strike(50,12,.3,.7,10),Finisher=strike(140,20,.5,1.2,12)}},
	SwordShield={Name="Kiếm & khiên",Description="Cân bằng • F: giữ thế đỡ",Skill="Húc khiên",
		Attacks={Light=strike(26,6,.14,.42,8),Heavy=strike(47,12,.3,.75,9),Skill=strike(58,16,.24,.9,8)}},
	Katana={Name="Katana",Description="Kiếm dài • Chém nhanh, tầm vừa",Skill="Nhất trảm",
		Attacks={Light=strike(31,7,.16,.46,10),Heavy=strike(59,14,.35,.85,11),Skill=strike(86,22,.4,1.05,13)}},
	Glaive={Name="Thương cán dài",Description="Lưỡi đao dài • Quét xa",Skill="Hoành tảo",
		Attacks={Light=strike(34,8,.22,.62,13),Heavy=strike(65,16,.45,1.05,15),Skill=strike(78,22,.35,1.15,15,{Arc=-.15})}},
	DualDaggers={Name="Song dao",Description="Hai lưỡi • Nhanh, sát thương mỗi hit thấp",Skill="Liên kích",
		Attacks={Light=strike(13,5,.09,.32,7,{Hits=2}),Heavy=strike(22,11,.2,.65,8,{Hits=2}),Skill=strike(17,20,.12,.85,8,{Hits=4})}},
	Bow={Name="Cung",Description="Giữ chuột phải để ngắm • Bắn theo tâm",Skill="Tam tiễn",Ranged=true,
		Attacks={Light=strike(29,7,.14,.5,180),Heavy=strike(66,15,.55,1.05,210),Skill=strike(24,19,.3,.9,180,{Shots=3})}},
	GreatAxe={Name="Rìu đại hai lưỡi",Description="Tầm quét rộng • Sát thương lớn",Skill="Bổ cuồng nộ",
		Attacks={Light=strike(43,10,.28,.7,11),Heavy=strike(83,19,.55,1.2,12),Skill=strike(104,26,.5,1.35,13,{Arc=0})}},
}
-- L = chuột trái, H = Q, S = E. Base costs are scaled once by TrainingRules.
weapons.Hammer.Combos = {
 {Input="LHS",Attack="Finisher"},
 {Input="LHLSS",Attack="Titan"},
}
weapons.Hammer.Attacks.Finisher = strike(140,20,0.5,1.2,12,{Name="Địa chấn",Style="Slam",Arc=0})
weapons.Hammer.Attacks.Titan = strike(92,32,0.38,1.35,14,{Name="Bão búa cổ đại",Hits=3,HitInterval=0.24,Arc=-1,Style="Spin"})
weapons.SwordShield.Combos = {
 {Input="LLH",Attack="Pierce"},
 {Input="HLS",Attack="Bastion"},
}
weapons.SwordShield.Attacks.Pierce = strike(38,15,0.18,0.85,10,{Name="Song kiếm đột phá",Hits=2,HitInterval=0.2,Arc=0.75,Style="Thrust"})
weapons.SwordShield.Attacks.Bastion = strike(30,22,0.22,1,9,{Name="Khiên mở đường",Hits=3,HitInterval=0.18,Arc=0,Style="Shield"})
weapons.Katana.Combos = {
 {Input="LLS",Attack="Moon"},
 {Input="HLH",Attack="Flash"},
}
weapons.Katana.Attacks.Moon = strike(35,24,0.16,0.85,11,{Name="Tam nguyệt trảm",Hits=3,HitInterval=0.16,Style="Flurry"})
weapons.Katana.Attacks.Flash = strike(118,25,0.48,1.12,16,{Name="Nhất tuyến phá",Arc=0.9,Style="Thrust"})
weapons.Glaive.Combos = {
 {Input="LHS",Attack="Cyclone"},
 {Input="HHL",Attack="Lance"},
}
weapons.Glaive.Attacks.Cyclone = strike(48,25,0.3,1.2,15,{Name="Lốc thương",Hits=2,HitInterval=0.28,Arc=-1,Style="Spin"})
weapons.Glaive.Attacks.Lance = strike(58,26,0.24,1.15,19,{Name="Song long kích",Hits=2,HitInterval=0.25,Arc=0.85,Style="Thrust"})
weapons.DualDaggers.Combos = {
 {Input="LLS",Attack="Flurry"},
 {Input="HLH",Attack="Cross"},
}
weapons.DualDaggers.Attacks.Flurry = strike(18,24,0.1,0.95,8,{Name="Vũ điệu sáu lưỡi",Hits=6,HitInterval=0.11,Style="Flurry"})
weapons.DualDaggers.Attacks.Cross = strike(32,21,0.18,0.9,9,{Name="Tam trảm giao thoa",Hits=3,HitInterval=0.18,Arc=0,Style="Sweep"})
weapons.Bow.Combos = {
 {Input="LLS",Attack="Fan"},
 {Input="HLS",Attack="Burst"},
}
weapons.Bow.Attacks.Fan = strike(28,25,0.3,1,190,{Name="Ngũ tiễn tỏa",Shots=5,Spread=3,Style="Volley"})
weapons.Bow.Attacks.Burst = strike(38,28,0.24,1.1,220,{Name="Tam tiễn truy kích",Shots=3,ShotInterval=0.2,Spread=0,Style="Burst"})
weapons.GreatAxe.Combos = {
 {Input="LHS",Attack="Rend"},
 {Input="HHS",Attack="Execution"},
}
weapons.GreatAxe.Attacks.Rend = strike(74,29,0.42,1.4,14,{Name="Song bổ khai sơn",Hits=2,HitInterval=0.32,Arc=0,Style="Slam"})
weapons.GreatAxe.Attacks.Execution = strike(195,34,0.7,1.55,15,{Name="Phán quyết rừng sâu",Arc=0.5,Style="Slam"})

return weapons
