class_name UnitInfo
extends RefCounted
## Polish draft and inspection copy for the current unit roster.

const ROLE_TEXT := {
 "front": "Przednia linia", "melee": "Walka wręcz", "ranged": "Strzelec",
 "diver": "Atak na tyły", "utility": "Kontrola obszaru", "mobile": "Mobilny wojownik"
}

const SUMMARIES := {
	"bear": "Zamaszystą łapą uderza przeciwników stojących przed nim.",
	"cheetah": "Wykonuje szybką serię trzech cięć w jeden cel.",
	"monkey": "Rzuca w przeciwnika mocnym bananem.",
	"eagle": "Nurkowaniem atakuje najdalszego żywego przeciwnika.",
	"hedgehog": "Rani kolcami każdego, kto trafi go bezpośrednim atakiem wręcz.",
	"hippo": "Po długim zamachu uderza i ogłusza pojedynczy cel.",
	"skunk": "Obiega przeciwników i zostawia ślad smrodu. Nie wykonuje zwykłych ataków.",
	"rabbit": "Skacze do zagrożonego sojusznika, daje mu tarczę i zrywa własne aggro. Sam osłania siebie.",
	"bear_cheetah": "Serią szerokich cięć trafia przeciwników przed sobą i krótko ich zachwiewa.",
	"bear_monkey": "Uderza szeroko łapą, a każdego trafionego przeciwnika obrzuca bananem.",
	"bear_hedgehog": "Łączy szerokie uderzenie łapą z pasywnymi kolcami.",
	"cheetah_eagle": "Trzykrotnie nurkuje na ten sam cel, zmieniając stronę ataku.",
	"cheetah_rabbit": "Po otrzymaniu trafienia przeskakuje za napastnika i zadaje mu serię ciosów.",
	"monkey_skunk": "Rzuca zgniłym bananem, który po trafieniu tworzy spowalniającą chmurę.",
	"monkey_hippo": "Rzuca ciężkim bananem, który zadaje duże obrażenia i ogłusza cel.",
	"eagle_hedgehog": "Nurkowaniem dopada najdalszego wroga, a kolcami karze ataki wręcz.",
	"eagle_hippo": "Ciężkim nurkowaniem uderza najdalszego wroga i ogłusza go.",
	"hedgehog_skunk": "Obiega wrogów, zostawiając kolczasty smród. Kolce karzą atakujących, chmury krótko zachwiewają.",
	"hippo_rabbit": "Po otrzymaniu trafienia skacze do najdalszego wroga i zadaje mu ogłuszający cios.",
	"skunk_rabbit": "Zostawia smród podczas obiegania wrogów i odskoku po trafieniu. Zrywa skupienie ataków.",
	"lvl3_01": "Trzykrotnym szerokim cięciem trafia wrogów przed sobą i obrzuca każdego zgniłym bananem. Chmury po trafieniu spowalniają przeciwników.",
	"lvl3_02": "Nurkowaniem dopada najdalszego wroga i zostawia chmurę przy lądowaniu. Rzuca zgniłymi bananami z dystansu, a kolce karzą ataki wręcz.",
	"lvl3_03": "Ogłuszający ciężki banan działa obok niezależnego nurkowania na najdalszego wroga. Pasywne kolce karzą bezpośrednie ataki wręcz.",
	"lvl3_04": "Rzuca trzy ciężkie banany; ostatni ogłusza. Po otrzymaniu trafienia skacze za napastnika, przerywając własną serię.",
	"lvl3_05": "Po trafieniu wykonuje trzy przeloty przez pole walki i zostawia zachwiewające chmury. Kolce zadają obrażenia zwrotne; forma nie ma bezpośredniej serii obrażeń.",
	"lvl3_06": "Szerokim zamachem trafia wielu wrogów i wystrzeliwuje w każdego banana tworzącego chmurę, która krótko zachwiewa trafionych. Kolce karzą ataki wręcz.",
	"lvl3_07": "Ciężkim nurkowaniem ogłusza cel, a następnie szerokim zamachem rozrzuca banany wśród wrogów.",
	"lvl3_08": "Ciężkie nurkowanie ogłusza najdalszego wroga, po czym obiega przeciwników ze śladem smrodu. Po trafieniu osobno odskakuje w bok.",
	"lvl3_09": "Podczas obiegania zostawia smród, a po trafieniu odskakuje w bok. Po krótkim zamachu szeroko uderza; kolce karzą ataki wręcz.",
	"lvl3_10": "Trzykrotnie nurkuje na ten sam cel. Każde lądowanie wywołuje szeroki stożek uderzenia; kolce karzą ataki wręcz.",
	"lvl3_11": "Po trafieniu skacze do najdalszego wroga, a potem wykonuje trzy nurkowe ciosy z naprzemiennych stron. Ostatnie trafienie ogłusza.",
	"lvl3_12": "Po trafieniu skacze do najdalszego przeciwnika. Po zamachu uderza szerokim stożkiem trzy razy; ostatnie trafienie ogłusza."
}

static func role_text(definition: Resource) -> String:
	if definition == null:
		return ""
	if definition.id == "rabbit": return "Mobilny obrońca"
	if not definition.attack_enabled: return "Smród w ruchu"
	return str(ROLE_TEXT.get(str(definition.role), "Walcząca jednostka w drużynie."))

static func summary(definition: Resource) -> String:
	if definition == null:
		return ""
	return str(SUMMARIES.get(str(definition.id), role_text(definition)))

static func details(definition: Resource) -> String:
	if definition == null:
		return ""
	var lines: PackedStringArray = []
	lines.append("HP: %s" % _number(float(definition.max_hp)))
	if definition.attack_enabled:
		lines.append("Atak podstawowy: %s obrażeń co %s s; zasięg %s px." % [_number(definition.attack_damage), _number(definition.attack_interval), _number(definition.attack_range)])
	else:
		var has_thorns := false
		var has_cloud_damage := false
		for skill: Resource in definition.skills:
			if str(skill.behavior) == "thorns": has_thorns = true
			if str(skill.behavior) in ["cloud", "trail"] or bool(skill.get("impact_cloud")) or bool(skill.get("landing_cloud")):
				has_cloud_damage = true
		var damage_sources: Array[String] = []
		if has_cloud_damage: damage_sources.append("chmur")
		if has_thorns: damage_sources.append("kolców")
		lines.append("Bez zwykłych ataków — obrażenia z " + " i ".join(damage_sources) + "." if not damage_sources.is_empty() else "Bez zwykłych ataków.")
	for skill: Resource in definition.skills:
		lines.append(_skill_details(skill, definition))
	lines.append("Gotowość skilla wymaga także celu, zasięgu i spełnienia warunku. Ogłuszenie blokuje działanie.")
	return "\n\n".join(lines)

static func _skill_details(skill: Resource, unit: Resource, is_followup: bool = false) -> String:
	var text := ""
	var behavior: String = str(skill.behavior)
	match behavior:
		"shield_jump":
			text = "Skok z osłoną: %s tarczy na %s s. Bez kumulacji. Samotny Królik osłania siebie." % [_number(skill.shield_amount), _number(skill.shield_duration)]
		"cone":
			var hit_count: int = int(skill.hits)
			text = "Stożek %s°: %s obrażeń%s" % [
				_number(float(skill.cone_angle)), _number(float(skill.damage)),
				" × %d" % hit_count if hit_count > 1 else ""
			]
			if float(skill.cone_projectile_damage) > 0.0:
				text += " oraz banan za %s obrażeń w każdego trafionego" % _number(float(skill.cone_projectile_damage))
			if float(skill.stagger_duration) > 0.0:
				text += "; zachwianie %s s" % _number(float(skill.stagger_duration))
			if float(skill.stun_duration) > 0.0:
				text += "; ogłuszenie %s s" % _number(float(skill.stun_duration))
			text += "; zasięg %s px" % _number(float(unit.radius + skill.range))
			if bool(skill.impact_cloud):
				text += "; trafienie banana tworzy chmurę: %s obrażeń co %s s przez %s s, promień %s px" % [_number(float(skill.cloud_damage)), _number(_cloud_tick(skill)), _number(float(skill.duration)), _number(float(skill.area_radius))]
				if float(skill.cloud_stagger) > 0.0:
					text += "; zachwianie w chmurze %s s" % _number(float(skill.cloud_stagger))
				if float(skill.slow_multiplier) < 1.0:
					text += "; spowolnienie ruchu o %s%%" % _number((1.0 - float(skill.slow_multiplier)) * 100.0)
		"multi":
			text = "Seria: %d trafienia po %s obrażeń w jeden cel, co %s s" % [
				int(skill.hits), _number(float(skill.damage)), _number(float(skill.hit_interval))
			]
			text += "; zasięg %s px" % _number(float(skill.range))
		"projectile":
			if int(skill.hits) > 1:
				text = "Seria pocisków: %d × %s obrażeń co %s s; zasięg %s px" % [int(skill.hits), _number(float(skill.damage)), _number(float(skill.hit_interval)), _number(float(skill.range))]
			else:
				text = "Pocisk: %s obrażeń; zasięg %s px" % [_number(float(skill.damage)), _number(float(skill.range))]
			if float(skill.stun_duration) > 0.0:
				text += ", ogłuszenie %s s" % _number(float(skill.stun_duration))
			if bool(skill.impact_cloud):
				var impact_tick := _cloud_tick(skill)
				text += "; po trafieniu chmura: %s obrażeń co %s s przez %s s, promień %s px" % [
					_number(float(skill.cloud_damage)), _number(impact_tick),
					_number(float(skill.duration)), _number(float(skill.area_radius))
				]
				if float(skill.slow_multiplier) < 1.0:
					text += "; spowolnienie ruchu o %s%%" % _number((1.0 - float(skill.slow_multiplier)) * 100.0)
				if float(skill.cloud_stagger) > 0.0:
					text += "; zachwianie w chmurze %s s" % _number(float(skill.cloud_stagger))
		"dive":
			var target_text := "pierwotny cel" if str(skill.target_rule) == "current" else "najdalszy żywy przeciwnik"
			if int(skill.airborne_hits) > 1:
				text = "Seria nurkowań: %d × %s obrażeń w %s, z naprzemiennych stron" % [int(skill.airborne_hits), _number(float(skill.damage)), target_text]
			else:
				text = "Nurkowanie na %s: %s obrażeń" % [target_text, _number(float(skill.damage))]
			if bool(skill.get("landing_cone")):
				text = "Seria nurkowań: %d × lądowanie przy %s; każde lądowanie uderza stożkiem %s° za %s obrażeń" % [int(skill.airborne_hits), target_text, _number(float(skill.cone_angle)), _number(float(skill.damage))]
			if float(skill.stun_duration) > 0.0:
				text += "; ogłuszenie %s s" % _number(float(skill.stun_duration))
			if bool(skill.get("landing_cloud")):
				text += "; przy lądowaniu chmura zadaje %s obrażeń co %s s przez %s s" % [_number(float(skill.cloud_damage)), _number(_cloud_tick(skill)), _number(float(skill.cloud_duration))]
		"thorns":
			text = "Kolce pasywne: %s obrażeń zwrotnych za każde trafienie bezpośrednim atakiem wręcz; bez cooldownu" % _number(float(skill.damage))
		"heavy":
			text = "Ciężki cios: %s obrażeń w jeden cel; zasięg %s px" % [_number(float(skill.damage)), _number(float(skill.range))]
			if float(skill.stun_duration) > 0.0:
				text += "; ogłuszenie %s s" % _number(float(skill.stun_duration))
		"trail":
			text = "Przez %s s obiega przeciwników i zostawia smród co %s s. Każda chmura trwa %s s, ma promień %s px i zadaje %s obrażeń co %s s. Podczas emisji przenika przez jednostki, ale nadal otrzymuje trafienia. Nakładające się własne chmury nie mnożą obrażeń" % [_number(skill.duration), _number(skill.puff_interval), _number(skill.cloud_duration), _number(skill.area_radius), _number(skill.cloud_damage), _number(_cloud_tick(skill))]
			if skill.cloud_stagger > 0.0: text += "; zachwianie %s s" % _number(skill.cloud_stagger)
		"cloud":
			text = "Chmura w położeniu celu zapamiętanym przy rozpoczęciu (aktywacja do %s px): %s obrażeń co %s s przez %s s, promień %s px" % [
				_number(float(skill.range)),
				_number(float(skill.damage)), _number(_cloud_tick(skill)),
				_number(float(skill.duration)), _number(float(skill.area_radius))
			]
			if float(skill.cloud_stagger) > 0.0:
				text += "; zachwianie %s s" % _number(float(skill.cloud_stagger))
			if float(skill.slow_multiplier) < 1.0:
				text += "; spowolnienie ruchu o %s%%" % _number((1.0 - float(skill.slow_multiplier)) * 100.0)
		"dash":
			if skill.puff_interval > 0.0 and (skill.cloud_damage > 0.0 or skill.cloud_stagger > 0.0):
				text = "Zostawia ślad smrodu również podczas odskoku. "
			var dash_text: String = "skok w bok" if str(skill.dash_mode) == "side" else ("skok do najdalszego przeciwnika" if str(skill.dash_mode) == "farthest" else "skok za napastnika")
			text += "Po otrzymaniu bezpośredniego trafienia: %s" % dash_text
			if int(skill.airborne_hits) > 1:
				text += " w %d przelotach przez pole walki" % int(skill.airborne_hits)
			if skill.cloud_stagger > 0.0:
				text += "; chmury zachwiewają trafionych na %s s" % _number(float(skill.cloud_stagger))
			elif skill.cloud_damage > 0.0:
				text += "; chmury zadają %s obrażeń" % _number(float(skill.cloud_damage))
			if float(skill.followup_damage) > 0.0 and int(skill.followup_hits) > 0:
				text += ", potem %d × %s obrażeń co %s s" % [int(skill.followup_hits), _number(float(skill.followup_damage)), _number(float(skill.followup_interval))]
				if float(skill.followup_stun) > 0.0:
					text += " i ogłuszenie %s s" % _number(float(skill.followup_stun))
			if float(skill.aggro_duration) > 0.0:
				text += "; przeciwnicy skupieni na tej jednostce zmieniają cel na %s s, jeśli mają alternatywę" % _number(float(skill.aggro_duration))
			text += "; bez niewrażliwości i bez cofania otrzymanych obrażeń"
			text += "; czas skoku %s s" % _number(float(skill.duration))
			if str(skill.dash_mode) == "side" and float(skill.distance) > 0.0:
				text += ", do %s px" % _number(float(skill.distance))
			if bool(skill.get("interrupt_on_hit")):
				text += "; reakcja na trafienie przerywa własną bieżącą akcję"
	if bool(skill.get("stun_last_hit_only")):
		text += "; ogłuszenie tylko przy ostatnim trafieniu serii"
	if behavior != "thorns" and not is_followup:
		text += ". Gotowość początkowa po %s s; potem odnowienie %s s" % [
			_number(float(skill.initial_cooldown)), _number(float(skill.cooldown))
		]
		text += "."
	else:
		text += "."
	if float(skill.windup) > 0.0:
		text += " Zamach %s s." % _number(float(skill.windup))
	if float(skill.recovery) > 0.0:
		text += " Odpoczynek po akcji %s s." % _number(float(skill.recovery))
	var followup: Resource = skill.get("followup_skill")
	if followup != null:
		text += " Następnie: " + _skill_details(followup, unit, true)
	return text

static func _cloud_tick(skill: Resource) -> float:
	var interval := float(skill.get("cloud_tick_interval"))
	return interval if interval > 0.0 else float(skill.get("hit_interval"))

static func _number(value: float) -> String:
	var result: String = String.num(value, 3)
	while result.ends_with("0") and result.contains("."):
		result = result.left(-1)
	if result.ends_with("."):
		result = result.left(-1)
	return result.replace(".", ",")
