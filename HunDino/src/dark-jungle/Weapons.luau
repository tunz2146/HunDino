-- Training prototypes, not final hunting balance. Damage/cost/timing live here.
local function strike(damage,cost,windup,duration,range,extra)
	local a={Damage=damage,Cost=cost,Windup=windup,Duration=duration,Range=range}
	for k,v in extra or {} do a[k]=v end
	return a
end
return {
	Order={"Hammer","SwordShield","Katana","Glaive","DualDaggers","Bow","GreatAxe"},
	Hammer={Name="Búa tạ",Description="Đòn nặng • Thường → Mạnh → Kỹ năng",Skill="Đập chấn động",Combo=true,
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
