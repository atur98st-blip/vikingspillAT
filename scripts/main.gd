extends Control
## Høvdingen – et læringsspill om vikingsamfunnet (historie Vg2).
## Alt innhold ligger i data/:
##   hendelser.json – sakene folk kommer med      steder.json   – gården og byggetomtene
##   ressurser.json – infoboksene om ressursene   treller.json  – trellene og historiene deres
##   handel.json    – handelssteder og toktmål     tinget.json   – tingsaker og forslag
##   skip.json      – skipstyper og handelsvarer   gaver.json    – gaver og gilder
##   innovasjoner.json – redskaper og arbeidsmåter spilleren kan bruke sølv på

const Verden := preload("res://scripts/verden.gd")
const Kart := preload("res://scripts/kart.gd")

const DATA_PATH := "res://data/hendelser.json"
const STEDER_PATH := "res://data/steder.json"
const RESSURSER_PATH := "res://data/ressurser.json"
const TRELLER_PATH := "res://data/treller.json"
const HANDEL_PATH := "res://data/handel.json"
const TING_PATH := "res://data/tinget.json"
const SAGA_PATH := "res://data/saga.json"
const SKIP_PATH := "res://data/skip.json"
const INNO_PATH := "res://data/innovasjoner.json"
const GAVER_PATH := "res://data/gaver.json"
const SAMLING_PATH := "user://samling.cfg"
const ANTALL_VINTRE := 8
const SAKER_PER_VINTER := 2

## Støtte som ikke får gå til null – da er spillet tapt.
const STOTTE := ["aere", "gudene", "aetten", "bondene"]
const RESSURSER := ["solv", "aere", "gudene", "aetten", "bondene"]
const NAVN := {
	"solv": "Sølv",
	"aere": "Ære",
	"gudene": "Gudenes gunst",
	"aetten": "Ætten",
	"bondene": "Bøndene",
}
## Slik skrives ressursene når de er en pris.
const KOST_NAVN := {
	"solv": "sølv",
	"aere": "ære",
	"gudene": "gudenes gunst",
	"aetten": "støtte fra ætten",
	"bondene": "støtte fra bøndene",
}
const TAP_TEKST := {
	"aere": "Ingen har lenger respekt for deg. På vårtinget velger bøndene en annen høvding, og du må leve resten av livet i skam. For en viking var tapt ære nesten verre enn døden.",
	"gudene": "Tre uår på rad. Bøndene mener gudene har vendt seg bort fra deg. Snorre forteller at svearne ofret sin egen konge, Domalde, etter flere uår. Du flykter før det samme skjer med deg.",
	"aetten": "Slekta di vender deg ryggen. Uten ætten har du ingen som vil hevne deg eller stå sammen med deg på tinget. I vikingtiden var den som sto alene, nesten forsvarsløs.",
	"bondene": "Bøndene har fått nok. På tinget går de sammen mot deg og velger en ny høvding. En høvding var helt avhengig av støtte fra de frie bøndene.",
}

## Yngre futhark (16 runer). Flere lyder deler samme rune.
const RUNER := {
	"f": "ᚠ", "u": "ᚢ", "o": "ᚢ", "v": "ᚢ", "w": "ᚢ", "y": "ᚢ", "ø": "ᚢ",
	"þ": "ᚦ", "a": "ᛅ", "æ": "ᛅ", "å": "ᚬ", "r": "ᚱ",
	"k": "ᚴ", "g": "ᚴ", "c": "ᚴ", "q": "ᚴ", "h": "ᚼ", "n": "ᚾ",
	"i": "ᛁ", "e": "ᛁ", "j": "ᛁ", "s": "ᛋ", "z": "ᛋ", "x": "ᚴᛋ",
	"t": "ᛏ", "d": "ᛏ", "b": "ᛒ", "p": "ᛒ", "m": "ᛘ", "l": "ᛚ",
}

const C_BG := Color("1d1915")
const C_TOPP := Color("2b241e")
const C_PANEL := Color("ece2c9")
const C_FAKTA := Color("ddd0ad")
const C_INK := Color("2a2019")
const C_LYS := Color("ece2c9")
const C_ACCENT := Color("8e3420")
const C_MUTED := Color("6f6250")
const C_GULL := Color("c4923a")
const C_PLUSS := Color("2f6b33")
const C_STEIN := Color("8d8c84")
# Innovasjonstreet: mørk bakgrunn med gull, som et gammelt kart over kunnskap.
const C_TREE_BG := Color("1f1a15")
const C_TREE_NODE := Color("2f2721")
const C_TREE_GRONN := Color("a9cf86")
const C_TREE_ROD := Color("e48a6c")

var hendelser: Array = []
var steder := {}
var ressurser := {}
var trelldata := {}
var handeldata := {}
var tingdata := {}
var sagadata := {}
var skipdata := {}
var innodata := {}
var gavedata := {}
## Saker som bare kommer når noe bestemt har skjedd (f.eks. en ættefeide som er i gang).
var kjeder: Array = []
var samling := {}
## Det som skjedde i løpet av spillet, slik at sagaen kan fortelle om det til slutt.
var logg := {}

var stats := {}
var flagg := {}
var bygget := {}
var treller: Array = []
## Handelsbyer der du har handelsvenner. Der får du 1 sølv mer per lass.
var kontakter := {}
## Skipet du har nå (id fra skip.json). Tom tekst betyr at du ikke har skip.
var skip := ""
## Innovasjoner som er tatt i bruk (id -> true).
var inno := {}
## Innovasjonen som er valgt i treet (vises i detaljfeltet under). Tom tekst: velg automatisk.
var inno_valgt := ""
var inno_knapper := {}
var inno_detalj: VBoxContainer
## Hvem som skylder deg en gjengjeld etter en gave (id fra gaver.json -> true).
var gjengjeld := {}
## Gaver og gilder du allerede har gitt denne vinteren.
var gitt := {}
## Egne forslag tinget har vedtatt. De kan ikke legges fram på nytt.
var vedtatt := {}
## Kjedesaker som allerede har vært oppe.
var brukte_kjeder := {}
## Vennskap må holdes ved like: Støtten fra ætten og bøndene synker litt hver vinter.
const LOJAL_FORFALL := 3
## En høvding som sitter på mer sølv enn dette fra vinter til vinter, blir kalt gjerrig og taper ære.
const GJERRIG_GRENSE := 45
const GJERRIG_STRAFF := 5
## Så mye uro en ættefeide skaper blant bøndene hver vinter.
const FEIDE_URO := 3
## Kristne kjøpmenn kommer oftere til en høvding som er primsignet.
const KORS_HANDEL := 3
## Sjansen for at et tokt verken blir seier eller nederlag.
const TOKT_DELVIS := 0.3
## Så mye støtte Ottar gir på tinget når han skylder deg en gjengjeld.
const OTTAR_STOTTE := 10
## Fiender ved hvert toktmål (mål-id -> antall). Der du har plyndret,
## er kysten bedre forsvart neste gang, og nye tokt dit blir farligere.
var fiender := {}
const FIENDE_STRAFF := 0.08
const FIENDE_MAKS := 0.4
var skip_seilt := false
var skip_borte_til := 0
var ting_brukt := false
var hovding_navn := ""
var vinter := 1
var ko: Array = []
var aktive: Array = []
var skjerm := ""

# Tinget som er satt akkurat nå
var ting_sak: Dictionary = {}
var ting_valg: Dictionary = {}
var ting_h = null
var ting_bonus := 0
var ting_brukte := {}
## Gudene krever nye offer: Gunsten synker litt hver vinter.
const GUDER_FORFALL := 4
const GUDER_FORFALL_MED_OFFERLUND := 2
const GUDER_FORFALL_KRISTEN := 3
## Hvor mye gudenes gunst kan endre sjansen for å lykkes (ved gunst 0 eller 100).
const GUDER_MAKS_BONUS := 0.1

## Tinget er usikkert: Stemningen kan svinge, og en rival kan tale mot deg i siste liten.
const TING_SVING := 8
const TING_RIVAL_SJANSE := 0.3
const TING_RIVAL_MOTSTAND := 10

var valgt_mal := ""
var mal_detaljer: VBoxContainer
## Sant når spillet kjøres av en test. Da lagres ingenting.
var test_modus := false

var font_tekst: Font
var font_fet: Font
var font_kursiv: Font
var font_runer: Font

var topplinje: PanelContainer
var vinter_etikett: Label
var solv_etikett: Label
var hint: Label
var neste_knapp: Button
var trell_knapp: Button
var skip_knapp: Button
var ting_knapp: Button
var gave_knapp: Button
var inno_knapp: Button
var stat_barer := {}
var verden: Control
var overlegg: Control
var innhold: VBoxContainer
var rulle: ScrollContainer


func _ready() -> void:
	_last_data()
	_last_samling()
	_bygg_ramme()
	_vis_start()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--balanse"):
			_balanse(int(a.get_slice("=", 1)) if "=" in a else 200)
			return
	if "--autotest" in OS.get_cmdline_user_args():
		test_modus = true
		_autotest()


# ---------------------------------------------------------------- data

func _les_json(sti: String):
	var res = load(sti)
	var data = res.data if res is JSON else JSON.parse_string(FileAccess.get_file_as_string(sti))
	if data == null:
		push_error("Kunne ikke lese " + sti + " – sjekk at JSON-filen er gyldig.")
	return data


func _last_data() -> void:
	var data = _les_json(DATA_PATH)
	if data is Array:
		for h in data:
			if h.has("krever_flagg"):
				kjeder.append(h)
			else:
				hendelser.append(h)
	for par in [["steder", STEDER_PATH], ["ressurser", RESSURSER_PATH], ["trelldata", TRELLER_PATH], ["handeldata", HANDEL_PATH], ["tingdata", TING_PATH], ["sagadata", SAGA_PATH], ["skipdata", SKIP_PATH], ["innodata", INNO_PATH], ["gavedata", GAVER_PATH]]:
		var d = _les_json(par[1])
		if d is Dictionary:
			set(par[0], d)


func _last_samling() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAMLING_PATH) == OK:
		for id in cfg.get_value("kort", "funnet", []):
			samling[id] = true


func _lagre_samling() -> void:
	# Testene skal ikke fylle opp samlingen til den som sitter ved maskinen.
	if test_modus:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("kort", "funnet", samling.keys())
	cfg.save(SAMLING_PATH)


## Alle kunnskapskortene i spillet, i den rekkefølgen de vises i samlingen.
func _alle_kort() -> Array:
	var ut := []
	for h in hendelser + kjeder:
		ut.append({"id": h["id"], "fakta": h["fakta"]})
	ut.append({"id": "gaver", "fakta": gavedata["fakta"]})
	ut.append({"id": "seilet", "fakta": skipdata["fakta"]})
	ut.append({"id": "treller", "fakta": trelldata["fakta"]})
	ut.append({"id": "trell_rettigheter", "fakta": trelldata["fakta_rettigheter"]})
	for m in handeldata["mal"]:
		ut.append({"id": "handel_" + m["id"], "fakta": m["fakta"]})
	ut.append({"id": "plyndring", "fakta": handeldata["fakta_plyndring"]})
	ut.append({"id": "motangrep", "fakta": handeldata["fakta_motangrep"]})
	ut.append({"id": "ting_makt", "fakta": tingdata["fakta"]})
	for s in tingdata["faste"]:
		ut.append({"id": "ting_" + s["id"], "fakta": s["fakta"]})
	for s in tingdata["forslag"]:
		if s.has("fakta"):
			ut.append({"id": "ting_" + s["id"], "fakta": s["fakta"]})
	ut.append({"id": "sagaer", "fakta": sagadata["fakta"]})
	return ut


func _logg(hva: String, antall := 1) -> void:
	logg[hva] = int(logg.get(hva, 0)) + antall


func _finn_kort(id: String) -> void:
	samling[id] = true
	_lagre_samling()


# ---------------------------------------------------------------- priser og ressurser

## En pris kan være et tall (sølv) eller flere ressurser, for eksempel {"solv": 20, "bondene": 10}.
func _kost(v) -> Dictionary:
	if v is Dictionary:
		return v
	if v == null:
		return {}
	return {"solv": int(v)}


## Sølv kan brukes helt opp. Støtte (ære, ætten, bøndene, gudene) kan ikke brukes ned til null.
func _har_rad(kost: Dictionary) -> bool:
	for k in kost:
		var n := int(kost[k])
		if k == "solv":
			if int(stats["solv"]) < n:
				return false
		elif int(stats.get(k, 0)) <= n:
			return false
	return true


func _betal(kost: Dictionary) -> void:
	var minus := {}
	for k in kost:
		minus[k] = -int(kost[k])
	_endre(minus)


func _endre(effekter: Dictionary) -> void:
	for k in effekter:
		if not stats.has(k):
			continue
		var ny := int(stats[k]) + int(effekter[k])
		stats[k] = maxi(ny, 0) if k == "solv" else clampi(ny, 0, 100)
	_oppdater_topplinje()


func _kost_tekst(kost: Dictionary) -> String:
	var deler := []
	for k in RESSURSER:
		if kost.has(k) and int(kost[k]) > 0:
			deler.append("%d %s" % [int(kost[k]), KOST_NAVN[k]])
	return " og ".join(deler)


func _effekt_tekst(effekter: Dictionary) -> String:
	var deler := []
	for nokkel in RESSURSER:
		if not effekter.has(nokkel):
			continue
		var v := int(effekter[nokkel])
		if v == 0:
			continue
		var farge := C_PLUSS if v > 0 else C_ACCENT
		var tegn := "+" if v > 0 else "−"
		deler.append("[color=#%s][b]%s%d %s[/b][/color]" % [farge.to_html(false), tegn, abs(v), NAVN[nokkel]])
	return "     ".join(deler)


## Folk trodde gudene avgjorde om en ferd eller en kamp gikk godt.
## Gunst 50 gir ingen endring, 100 gir +20 prosentpoeng og 0 gir −20.
func _gudebonus() -> float:
	return clampf((float(stats["gudene"]) - 50.0) / 50.0 * GUDER_MAKS_BONUS, -GUDER_MAKS_BONUS, GUDER_MAKS_BONUS)


func _sjanse(grunnsjanse: float) -> float:
	return clampf(grunnsjanse + _gudebonus(), 0.05, 0.95)


## Hvor mye dårligere sjansen er fordi kysten ved målet er forsvart.
func _forsvar_straff(id: String) -> float:
	return minf(FIENDE_STRAFF * int(fiender.get(id, 0)), FIENDE_MAKS)


## Sjansen for å lykkes på en reise, med gudene og forsvaret ved målet.
func _reise_sjanse(m: Dictionary) -> float:
	var s := float(m["sjanse"]) + _gudebonus() + _inno_sum("sjanse_reise") + float(_skiptype().get("sjanse", 0.0))
	if m["type"] == "tokt":
		s += float(_skiptype().get("tokt_sjanse", 0.0)) + _inno_sum("sjanse_tokt") - _forsvar_straff(m["id"])
	return clampf(s, 0.05, 0.95)


func _fiender_totalt() -> int:
	var sum := 0
	for id in fiender:
		sum += int(fiender[id])
	return sum


func _tapt() -> String:
	for nokkel in STOTTE:
		if int(stats[nokkel]) <= 0:
			return nokkel
	return ""


## Summen av én virkning fra alle innovasjonene som er tatt i bruk.
## `under` brukes når virkningen gjelder ett sted eller én vare, f.eks. ("pris_vare", "jern").
func _inno_sum(nokkel: String, under := "") -> float:
	var sum := 0.0
	for i in innodata.get("innovasjoner", []):
		if not inno.has(i["id"]):
			continue
		var v = i.get("virkning", {}).get(nokkel, 0)
		if v is Dictionary:
			v = v.get(under, 0)
		sum += float(v)
	return sum


## Skipstypen med denne id-en, eller skipet du har nå.
func _skiptype(id := "") -> Dictionary:
	var sok := skip if id == "" else id
	for s in skipdata.get("typer", []):
		if s["id"] == sok:
			return s
	return {}


func _last() -> int:
	return int(_skiptype().get("last", 0))


## Prisen per lass for en vare ved et handelssted, med alt som legger noe til.
func _vare_pris(m: Dictionary, vare: String) -> int:
	return int(m["priser"].get(vare, 0)) + int(_inno_sum("pris_vare", vare)) + int(_inno_sum("pris_alle")) + (1 if kontakter.has(m["id"]) else 0)


## Forklarer prisen per lass, slik at eleven ser hvor hvert sølv kommer fra.
func _pris_forklaring(m: Dictionary, vare: String) -> String:
	var deler := ["%d (prisen i %s)" % [int(m["priser"].get(vare, 0)), m["navn"]]]
	if kontakter.has(m["id"]):
		deler.append("1 (du har handelsvenner her)")
	var ny := int(_inno_sum("pris_vare", vare)) + int(_inno_sum("pris_alle"))
	if ny > 0:
		deler.append("%d (innovasjonene dine)" % ny)
	return " + ".join(deler)


# ---------------------------------------------------------------- utseende

func _systemfont(navn: PackedStringArray, vekt := 400, kursiv := false) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = navn
	f.font_weight = vekt
	f.font_italic = kursiv
	return f


func _boks(farge: Color, kant := Color(0, 0, 0, 0), radius := 6, pad := 14.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = farge
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.75
	s.content_margin_bottom = pad * 0.75
	if kant.a > 0.0:
		s.set_border_width_all(2)
		s.border_color = kant
	return s


func _lag_tema() -> Theme:
	var serif := PackedStringArray(["Georgia", "Cambria", "serif"])
	font_tekst = _systemfont(serif)
	font_fet = _systemfont(serif, 700)
	font_kursiv = _systemfont(serif, 400, true)
	font_runer = _systemfont(PackedStringArray(["Segoe UI Historic", "Noto Sans Runic", "Segoe UI Symbol"]))

	var t := Theme.new()
	t.default_font = font_tekst
	t.default_font_size = 21
	t.set_color("font_color", "Label", C_INK)

	t.set_stylebox("normal", "Button", _boks(Color("f6efdc"), C_MUTED))
	t.set_stylebox("hover", "Button", _boks(Color("fffaf0"), C_ACCENT))
	t.set_stylebox("pressed", "Button", _boks(C_ACCENT, C_ACCENT))
	t.set_stylebox("disabled", "Button", _boks(Color("d9cfb8"), Color("b8ab90")))
	var fokus := _boks(Color(0, 0, 0, 0), C_ACCENT)
	fokus.draw_center = false
	t.set_stylebox("focus", "Button", fokus)
	t.set_color("font_color", "Button", C_INK)
	t.set_color("font_hover_color", "Button", C_ACCENT)
	t.set_color("font_pressed_color", "Button", C_LYS)
	t.set_color("font_focus_color", "Button", C_INK)
	t.set_color("font_disabled_color", "Button", C_MUTED)

	t.set_stylebox("normal", "LineEdit", _boks(Color("fffaf0"), C_MUTED))
	t.set_stylebox("focus", "LineEdit", _boks(Color("fffaf0"), C_ACCENT))
	t.set_color("font_color", "LineEdit", C_INK)
	t.set_color("font_placeholder_color", "LineEdit", C_MUTED)
	t.set_color("caret_color", "LineEdit", C_ACCENT)

	t.set_font("bold_font", "RichTextLabel", font_fet)
	t.set_font("italics_font", "RichTextLabel", font_kursiv)
	t.set_color("default_color", "RichTextLabel", C_INK)

	t.set_stylebox("panel", "PanelContainer", _boks(C_PANEL, Color(0, 0, 0, 0), 10, 30.0))

	# Infobokser når musa holdes over noe: mørke med gullkant.
	var tips := _boks(C_TREE_NODE, C_GULL, 4, 14.0)
	tips.shadow_color = Color(0, 0, 0, 0.5)
	tips.shadow_size = 8
	t.set_stylebox("panel", "TooltipPanel", tips)
	t.set_color("font_color", "TooltipLabel", C_LYS)
	t.set_font_size("font_size", "TooltipLabel", 17)
	return t


func _bygg_ramme() -> void:
	theme = _lag_tema()
	# Infoboksene ligger i et eget vindu over spillet, så temaet må også settes der.
	get_window().theme = theme
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var marg := MarginContainer.new()
	marg.set_anchors_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		marg.add_theme_constant_override("margin_" + side, 10)
	add_child(marg)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	marg.add_child(v)

	topplinje = _bygg_topplinje()
	v.add_child(topplinje)

	verden = Verden.new()
	verden.size_flags_vertical = SIZE_EXPAND_FILL
	verden.font_fet = font_fet
	verden.stedsnavn = {}
	for id in steder:
		verden.stedsnavn[id] = steder[id]["navn"]
		if _kan_bygges(id):
			verden.tomt_tekst[id] = "Byggetomt: %s (%s)" % [steder[id]["navn"], _kost_tekst(_kost(steder[id]["pris"]))]
	verden.sted_klikket.connect(_sted_klikket)
	v.add_child(verden)

	# Vinduet som legger seg over gården når en sak, et kart eller et kort vises.
	overlegg = Control.new()
	overlegg.set_anchors_preset(PRESET_FULL_RECT)
	overlegg.mouse_filter = MOUSE_FILTER_STOP
	add_child(overlegg)
	var dim := ColorRect.new()
	dim.color = Color(0.07, 0.05, 0.04, 0.55)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	overlegg.add_child(dim)
	var senter := CenterContainer.new()
	senter.set_anchors_preset(PRESET_FULL_RECT)
	overlegg.add_child(senter)
	var kort := PanelContainer.new()
	senter.add_child(kort)
	rulle = ScrollContainer.new()
	rulle.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rulle.custom_minimum_size = Vector2(820, 100)
	kort.add_child(rulle)
	innhold = VBoxContainer.new()
	innhold.size_flags_horizontal = SIZE_EXPAND_FILL
	innhold.add_theme_constant_override("separation", 18)
	innhold.minimum_size_changed.connect(_tilpass_hoyde)
	rulle.add_child(innhold)


func _tilpass_hoyde() -> void:
	var maks := maxf(size.y - 90.0, 200.0)
	rulle.custom_minimum_size.y = clampf(innhold.get_combined_minimum_size().y, 60.0, maks)


func _bygg_topplinje() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _boks(C_TOPP, Color(0, 0, 0, 0), 8, 12.0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)

	var venstre := VBoxContainer.new()
	vinter_etikett = _etikett("", 20, C_GULL, font_fet)
	venstre.add_child(vinter_etikett)
	solv_etikett = _etikett("", 19, C_LYS)
	venstre.add_child(_klikkbar(solv_etikett, "solv"))
	h.add_child(venstre)

	for nokkel in STOTTE:
		var boks := VBoxContainer.new()
		boks.mouse_filter = MOUSE_FILTER_IGNORE
		boks.add_child(_etikett(NAVN[nokkel] + "  (?)", 17, C_LYS))
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.mouse_filter = MOUSE_FILTER_IGNORE
		bar.custom_minimum_size = Vector2(140, 16)
		bar.max_value = 100
		bar.add_theme_stylebox_override("background", _boks(Color("4a3f35"), Color(0, 0, 0, 0), 4, 0.0))
		boks.add_child(bar)
		h.add_child(_klikkbar(boks, nokkel))
		stat_barer[nokkel] = bar

	neste_knapp = _knapp("Neste vinter  ›", _neste_vinter, true)
	neste_knapp.custom_minimum_size = Vector2(180, 46)
	neste_knapp.disabled = true
	neste_knapp.add_theme_stylebox_override("disabled", _boks(Color("4a4038"), Color("5a4f45")))
	neste_knapp.add_theme_color_override("font_disabled_color", Color("8a7d6c"))
	h.add_child(neste_knapp)

	var rad := HBoxContainer.new()
	rad.add_theme_constant_override("separation", 10)
	v.add_child(rad)
	trell_knapp = _liten_knapp("Trellene", _vis_treller)
	skip_knapp = _liten_knapp("Skipet: handel og tokt", _vis_skip)
	ting_knapp = _liten_knapp("Kall inn tinget", _vis_tinget)
	gave_knapp = _liten_knapp("Gaver og gilder", _vis_gaver)
	inno_knapp = _liten_knapp("Innovasjoner", _vis_innovasjoner)
	for b in [trell_knapp, skip_knapp, ting_knapp, gave_knapp, inno_knapp]:
		rad.add_child(b)
	hint = _etikett("", 17, C_GULL, font_kursiv)
	hint.size_flags_horizontal = SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rad.add_child(hint)
	p.visible = false
	return p


## Gjør en del av topplinjen klikkbar, slik at den åpner infoboksen om ressursen.
func _klikkbar(node: Control, nokkel: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _boks(Color(1, 1, 1, 0), Color(0, 0, 0, 0), 6, 6.0))
	p.mouse_filter = MOUSE_FILTER_STOP
	p.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	p.tooltip_text = "Klikk for å lese om " + NAVN[nokkel].to_lower()
	p.add_child(node)
	p.gui_input.connect(_ressurs_klikk.bind(nokkel))
	p.mouse_entered.connect(func(): p.add_theme_stylebox_override("panel", _boks(Color(1, 1, 1, 0.08), Color(0, 0, 0, 0), 6, 6.0)))
	p.mouse_exited.connect(func(): p.add_theme_stylebox_override("panel", _boks(Color(1, 1, 1, 0), Color(0, 0, 0, 0), 6, 6.0)))
	return p


func _ressurs_klikk(e: InputEvent, nokkel: String) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and skjerm == "verden":
		_vis_ressurs(nokkel)


func _liten_knapp(txt: String, handling: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", 17)
	b.custom_minimum_size.y = 38
	b.pressed.connect(_topp_handling.bind(handling))
	return b


## Knappene i topplinjen virker bare når ingen vinduer er åpne over gården.
func _topp_handling(handling: Callable) -> void:
	if skjerm == "verden":
		handling.call()


func _oppdater_topplinje() -> void:
	vinter_etikett.text = "Vinter %d av %d" % [min(vinter, ANTALL_VINTRE), ANTALL_VINTRE]
	solv_etikett.text = "Sølv: %d  (?)" % stats["solv"]
	for nokkel in STOTTE:
		var bar: ProgressBar = stat_barer[nokkel]
		var verdi: int = stats[nokkel]
		var farge := C_ACCENT if verdi < 25 else C_GULL
		bar.add_theme_stylebox_override("fill", _boks(farge, Color(0, 0, 0, 0), 4, 0.0))
		create_tween().tween_property(bar, "value", verdi, 0.4)
	trell_knapp.text = "Trellene (%d)" % treller.size()
	skip_knapp.disabled = not bygget.has("naustet")
	skip_knapp.tooltip_text = "Bygg naustet for å få et skip." if skip_knapp.disabled else ""
	skip_knapp.text = "Skipet: handel og tokt" if skip == "" else "Skipet (%s)" % _skiptype()["navn"].to_lower()
	ting_knapp.text = "Tinget (brukt i år)" if ting_brukt else "Kall inn tinget"
	inno_knapp.text = "Innovasjoner (%d av %d)" % [inno.size(), innodata["innovasjoner"].size()]


func _oppdater_hint(forst := "") -> void:
	var tekst := ""
	if aktive.is_empty():
		neste_knapp.disabled = false
		tekst = "Ingen flere saker. Bruk sølvet ditt: bygg (+), gi gaver, seil – eller trykk «Neste vinter»."
	else:
		var hvem := "To personer venter" if aktive.size() == 2 else "Én person venter"
		if aktive.size() > 2:
			hvem = "%d personer venter" % aktive.size()
		tekst = hvem + " på deg (!). Klikk på ressursene øverst for å lese om dem."
	# Si fra i tide når støtten er farlig lav, og hva som hjelper.
	var raad := {
		"bondene": "Bøndene er i ferd med å vende seg mot deg. Et gilde hjelper.",
		"aetten": "Ætten er i ferd med å vende deg ryggen. Gaver til frendene hjelper.",
		"gudene": "Gudene er vrede. Bygg offerlunden, og hold blot når du kan.",
		"aere": "Æren din er nesten borte. Vær gavmild, og vinn saker på tinget.",
	}
	for k in raad:
		if stats.has(k) and int(stats[k]) < 20:
			tekst = "Fare: " + raad[k]
			break
	hint.text = forst + tekst


# ---------------------------------------------------------------- byggeklosser

func _etikett(txt: String, storrelse := 21, farge := C_INK, font: Font = null) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", storrelse)
	l.add_theme_color_override("font_color", farge)
	if font:
		l.add_theme_font_override("font", font)
	return l


func _avsnitt(txt: String, storrelse := 21, farge := C_INK, font: Font = null) -> Label:
	var l := _etikett(txt, storrelse, farge, font)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _rik(bb: String, storrelse := 21) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.size_flags_horizontal = SIZE_EXPAND_FILL
	for navn in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		r.add_theme_font_size_override(navn, storrelse)
	r.text = bb
	return r


func _knapp(txt: String, handling: Callable, sentrert := false) -> Button:
	var b := Button.new()
	b.text = txt
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER if sentrert else HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size.y = 52
	b.pressed.connect(handling)
	return b


## Knapp som er grå fordi spilleren ikke har råd, med forklaring i teksten.
func _deaktiver(b: Button, grunn: String) -> void:
	b.disabled = true
	b.text = grunn


func _overskrift(liten: String, stor: String) -> void:
	if liten != "":
		innhold.add_child(_etikett(liten, 18, C_MUTED, font_fet))
	innhold.add_child(_etikett(stor, 34, C_ACCENT, font_fet))


func _tilbake_knapp(tekst := "Tilbake til gården") -> Button:
	var b := _knapp(tekst, _tilbake_til_garden, true)
	innhold.add_child(b)
	return b


## Tømmer vinduet over gården og viser det.
func _tom_innhold(navn: String) -> void:
	skjerm = navn
	overlegg.visible = true
	for c in innhold.get_children():
		innhold.remove_child(c)
		c.queue_free()
	rulle.scroll_vertical = 0
	rulle.custom_minimum_size.x = 820
	overlegg.modulate.a = 0.0
	create_tween().tween_property(overlegg, "modulate:a", 1.0, 0.2)
	_tilpass_hoyde.call_deferred()


func _lukk_vindu() -> void:
	overlegg.visible = false
	skjerm = "verden"


func _tilbake_til_garden() -> void:
	var tapt := _tapt()
	if tapt != "":
		_vis_slutt(tapt)
		return
	_lukk_vindu()
	_oppdater_hint()


func _faktakort(fakta: Dictionary, ny: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _boks(C_FAKTA, C_GULL, 8, 22.0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	v.add_child(_etikett("KUNNSKAPSKORT · NYTT!" if ny else "KUNNSKAPSKORT", 16, C_ACCENT, font_fet))
	v.add_child(_etikett(fakta["tittel"], 25, C_INK, font_fet))
	v.add_child(_avsnitt(fakta["tekst"], 20))
	v.add_child(_avsnitt("Kilde: " + fakta["kilde"], 17, C_MUTED, font_kursiv))
	if fakta.has("lenker"):
		v.add_child(_lenker(fakta["lenker"]))
	return p


## Viser kortet og legger det i samlingen.
func _vis_kort(id: String, fakta: Dictionary) -> void:
	var ny := not samling.has(id)
	_finn_kort(id)
	innhold.add_child(_faktakort(fakta, ny))


## Klikkbare lenker som åpnes i nettleseren, slik at kildene kan sjekkes.
func _lenker(lenker: Array) -> RichTextLabel:
	var linjer := ["[b]Les mer og sjekk kilden:[/b]"]
	for l in lenker:
		linjer.append("[url=%s][color=#%s]› %s[/color][/url]" % [l["url"], C_ACCENT.to_html(false), l["tekst"]])
	var r := _rik("\n".join(linjer), 17)
	r.meta_clicked.connect(func(url): OS.shell_open(str(url)))
	r.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	return r


func _til_runer(tekst: String) -> String:
	var t := tekst.to_lower().replace("th", "þ")
	var ut := ""
	for tegn in t:
		if RUNER.has(tegn):
			ut += RUNER[tegn]
		elif tegn == " " or tegn == "-":
			ut += "᛫"
	return ut


# ---------------------------------------------------------------- start og vintre

func _vis_start() -> void:
	topplinje.visible = false
	aktive = []
	verden.saker = aktive
	_tom_innhold("start")
	innhold.add_child(_etikett(_til_runer("høvdingen"), 30, C_MUTED, font_runer))
	innhold.add_child(_etikett("HØVDINGEN", 52, C_ACCENT, font_fet))
	innhold.add_child(_avsnitt("Vestlandet, år 980. Den gamle høvdingen er død, og nå er det du som skal lede gården og bygda.", 23, C_INK, font_kursiv))
	innhold.add_child(_rik(
		"I [b]%d vintre[/b] skal du ta de avgjørelsene en vikinghøvding måtte ta. Folk kommer til gården med saker om treller, ekteskap, hevn, gudene og ære. Du ser dem som [b]røde merker[/b] ved bygningene.\n\n" % ANTALL_VINTRE
		+ "Bygg ut gården, send skipet på handel eller tokt, og vinn støtte på [b]tinget[/b]. Hold [b]ætten[/b], [b]bøndene[/b] og [b]gudene[/b] fornøyde, og vinn [b]ære[/b]. Faller én av dem til null, er det slutt. Sølv i kista gir ingen makt: Det må brukes på gaver, gilder, skip og nye redskaper.\n\n"
		+ "Underveis får du [b]kunnskapskort[/b] om hvordan det faktisk var i vikingtiden. Klarer du å samle alle %d?" % _alle_kort().size()))

	var navnefelt := LineEdit.new()
	navnefelt.placeholder_text = "Skriv navnet ditt"
	navnefelt.max_length = 20
	navnefelt.custom_minimum_size.y = 52
	innhold.add_child(navnefelt)

	var start := _knapp("Bli høvding", func(): _start_spill(navnefelt.text), true)
	start.disabled = true
	navnefelt.text_changed.connect(func(t: String): start.disabled = t.strip_edges().is_empty())
	navnefelt.text_submitted.connect(_navn_sendt)
	innhold.add_child(start)
	innhold.add_child(_knapp("Se kunnskapskortene dine (%d av %d)" % [_antall_funnet(), _alle_kort().size()], _vis_samling, true))
	navnefelt.grab_focus.call_deferred()


func _antall_funnet() -> int:
	var n := 0
	for k in _alle_kort():
		if samling.has(k["id"]):
			n += 1
	return n


func _navn_sendt(navn: String) -> void:
	if not navn.strip_edges().is_empty():
		_start_spill(navn)


func _start_spill(navn: String) -> void:
	hovding_navn = navn.strip_edges().capitalize()
	stats = {"solv": 25, "aere": 50, "gudene": 50, "aetten": 50, "bondene": 50}
	flagg = {}
	bygget = {}
	kontakter = {}
	fiender = {}
	skip = ""
	inno = {}
	gjengjeld = {}
	gitt = {}
	vedtatt = {}
	brukte_kjeder = {}
	skip_borte_til = 0
	logg = {}
	treller = []
	for t in trelldata["start"]:
		treller.append(t.duplicate())
	verden.stats = stats
	verden.flagg = flagg
	verden.bygget = bygget
	ko = hendelser.duplicate()
	ko.shuffle()
	# Saker merket "forst" (farens gravferd) kommer alltid den første vinteren.
	for h in ko.duplicate():
		if h.get("forst", false):
			ko.erase(h)
			ko.push_front(h)
	vinter = 1
	topplinje.visible = true
	_start_vinter()


func _kan_bygges(sted: String) -> bool:
	return steder.get(sted, {}).has("pris")


## Er stedet på gården? Saker på steder som ikke er bygd, dukker ikke opp.
func _finnes(sted: String) -> bool:
	return not _kan_bygges(sted) or bygget.has(sted)


func _har_trell(id: String) -> bool:
	for t in treller:
		if t["id"] == id:
			return true
	return false


func _mulig_sak(h: Dictionary) -> bool:
	if not _finnes(h.get("sted", "langhuset")):
		return false
	if h.has("krever_trell") and not _har_trell(h["krever_trell"]):
		return false
	if h.get("krever_skip", false) and skip == "":
		return false
	return true


func _start_vinter() -> void:
	skip_seilt = false
	ting_brukt = false
	gitt = {}
	for t in treller:
		t["ny"] = false

	# Velg vinterens saker blant dem som passer med gården slik den er nå.
	aktive = []
	for h in ko.duplicate():
		if aktive.size() < SAKER_PER_VINTER and _mulig_sak(h):
			aktive.append(h)
			ko.erase(h)
	for sak in tingdata["faste"]:
		if int(sak["vinter"]) == vinter:
			aktive.append({"tingsak": sak, "sted": "tingstedet", "person": "Tinget: " + sak["tittel"], "tittel": sak["tittel"]})
	# Kjedesaker: følger av noe som har skjedd tidligere, f.eks. en ættefeide. Høyst én hver vinter.
	for h in kjeder:
		if brukte_kjeder.has(h["id"]) and not h.get("gjentas", false):
			continue
		if flagg.has(h["krever_flagg"]) and not flagg.has(h.get("uten_flagg", "")):
			aktive.append(h)
			brukte_kjeder[h["id"]] = true
			break
	# En trell kan ha rømt i løpet av året. Da må høvdingen bestemme seg.
	var rommling := {}
	if vinter > 1:
		for t in treller.duplicate():
			if randf() < float(t.get("flukt", trelldata["flukt"])):
				rommling = t
				treller.erase(t)
				aktive.append({"rommling": t, "sted": "skogen", "person": t["navn"] + " har rømt", "tittel": t["navn"] + " har rømt"})
				_logg("romt")
				break
	verden.saker = aktive
	neste_knapp.disabled = true

	# Inntekt: åkrene påvirkes av året (gudenes gunst), resten gir fast inntekt.
	var aaret := "Avlingen var middels god, og bøndene betalte skatten sin."
	var per_aaker := 5
	if stats["gudene"] >= 65:
		per_aaker = 8
		aaret = "Et rikt år! Kornet sto høyt, og fisket var godt. Bøndene sier gudene er med deg."
	elif stats["gudene"] < 30:
		per_aaker = 2 if bygget.has("buret") else 0
		aaret = "Uår. Kornet råtnet på åkeren. Folk hvisker at gudene er vrede."
		if bygget.has("buret"):
			aaret += " Heldigvis hadde du lagret korn i buret."
	else:
		per_aaker += int(_inno_sum("per_aaker"))
	var deler := []
	var aakre := 2 if bygget.has("nyaakeren") else 1
	deler.append(["Åkrene" if aakre > 1 else "Åkeren", per_aaker * aakre])
	for id in steder:
		if bygget.has(id) and steder[id].has("inntekt"):
			deler.append([steder[id]["navn"], int(steder[id]["inntekt"]) + int(_inno_sum("inntekt", id))])
	if not treller.is_empty():
		deler.append(["Trellenes arbeid (%d treller)" % treller.size(), _trellearbeid()])
	if flagg.has("marked"):
		deler.append(["Markedet i bygda", 3])
	if flagg.has("kors"):
		deler.append(["Kristne kjøpmenn ved brygga", KORS_HANDEL])

	if vinter == 1:
		deler = []
		aaret = "Du har overtatt gården og høysetet etter den gamle høvdingen. Gården er liten, men det finnes byggetomter (+) der du kan bygge den ut."
	var sum := 0
	for d in deler:
		sum += d[1]
	# Sølv som ble liggende ubrukt fra i fjor: En høvding skulle dele, ikke samle.
	var ubrukt := int(stats["solv"])
	var gjerrig := vinter > 1 and ubrukt > GJERRIG_GRENSE
	if gjerrig:
		_endre({"aere": -GJERRIG_STRAFF})
	stats["solv"] += sum
	# Gudene glemmer fort: Uten nye offer synker gunsten.
	var forfall := 0
	if vinter > 1:
		forfall = GUDER_FORFALL_MED_OFFERLUND if bygget.has("offerlunden") else GUDER_FORFALL
		if flagg.has("kors"):
			forfall += GUDER_FORFALL_KRISTEN
		_endre({"gudene": -forfall})
	# Vennskap må holdes ved like, og en ættefeide skaper uro i bygda.
	var lojal := {}
	if vinter > 1:
		lojal = {"aetten": -LOJAL_FORFALL, "bondene": -LOJAL_FORFALL - (FEIDE_URO if flagg.has("aettefeide") else 0)}
		_endre(lojal)
	_oppdater_topplinje()

	_tom_innhold("vinter")
	_overskrift("VINTER %d AV %d" % [vinter, ANTALL_VINTRE], "Et nytt år går mot slutten")
	innhold.add_child(_avsnitt(aaret))
	if not deler.is_empty():
		var linjer := []
		for d in deler:
			linjer.append("%s: [b]+%d sølv[/b]" % d)
		innhold.add_child(_rik("\n".join(linjer) + "\n[color=#%s][b]Til sammen: +%d sølv[/b][/color]" % [C_PLUSS.to_html(false), sum]))
	if forfall > 0:
		var hvorfor := "Gudene krever nye offer hvert år."
		if bygget.has("offerlunden"):
			hvorfor += " Offerlunden hjelper, for der blir det ofret jevnlig."
		else:
			hvorfor += " Med en offerlund ville gunsten sunket langsommere."
		if flagg.has("kors"):
			hvorfor += " Mange tror gudene er sinte fordi du har sluppet inn den kristne troen."
		innhold.add_child(_rik(hvorfor + "  " + _effekt_tekst({"gudene": -forfall}), 19))
	if not lojal.is_empty():
		var venner := "Vennskap må holdes ved like. Frender og bønder venter gaver og gilder av høvdingen sin."
		if flagg.has("aettefeide"):
			venner += " Ættefeiden gjør bøndene urolige."
		innhold.add_child(_rik(venner + "  " + _effekt_tekst(lojal), 19))
	if gjerrig:
		innhold.add_child(_rik("Du hadde %d sølv liggende ubrukt i kista. Folk sier at en høvding som samler i stedet for å dele, er gjerrig. Har du mer enn %d sølv til overs når vinteren kommer, taper du ære.  %s" % [ubrukt, GJERRIG_GRENSE, _effekt_tekst({"aere": -GJERRIG_STRAFF})], 19))
	if not rommling.is_empty():
		innhold.add_child(_etikett(rommling["navn"] + " er borte!", 26, C_ACCENT, font_fet))
		innhold.add_child(_avsnitt("En morgen var plassen til %s i trellehuset tom. Noen så spor mot skogen." % rommling["navn"], 21))
	var venter := "Nå venter det folk på gården som vil snakke med deg." if not aktive.is_empty() else "Ingen kommer med saker denne vinteren. Kanskje gården må bygges ut før nye folk kommer hit?"
	innhold.add_child(_avsnitt(venter, 21, C_MUTED, font_kursiv))
	innhold.add_child(_knapp("Gå ut på gården", _tilbake_til_garden, true))


func _neste_vinter() -> void:
	if not aktive.is_empty() or skjerm != "verden":
		return
	vinter += 1
	if vinter > ANTALL_VINTRE:
		_vis_slutt("")
	else:
		_start_vinter()


# ---------------------------------------------------------------- gården

func _sted_klikket(sted: String) -> void:
	if skjerm != "verden":
		return
	for h in aktive:
		if h.get("sted", "langhuset") == sted:
			if h.has("tingsak"):
				_vis_tingsak(h)
			elif h.has("rommling"):
				_vis_flukt(h)
			else:
				_vis_sak(h)
			return
	if not _finnes(sted):
		_vis_byggetomt(sted)
	elif sted == "trellehuset":
		_vis_treller()
	elif sted == "naustet":
		_vis_skip()
	elif sted == "tingstedet":
		_vis_tinget()
	elif sted == "langhuset":
		_vis_gaver()
	else:
		_vis_sted(sted)


func _vis_sted(sted: String) -> void:
	if not steder.has(sted):
		return
	_tom_innhold("sted")
	_overskrift("PÅ GÅRDEN", steder[sted]["navn"])
	innhold.add_child(_avsnitt(steder[sted]["tekst"], 21))
	if steder[sted].has("lenker"):
		innhold.add_child(_lenker(steder[sted]["lenker"]))
	_tilbake_knapp()


func _vis_byggetomt(sted: String) -> void:
	var s: Dictionary = steder[sted]
	var pris := _kost(s["pris"])
	_tom_innhold("bygg")
	_overskrift("BYGGETOMT", "Bygg: " + s["navn"])
	innhold.add_child(_avsnitt(s["tekst"], 21))
	innhold.add_child(_rik("[b]Dette får du:[/b] " + s.get("bygg_effekt", ""), 21))
	if s.has("lenker"):
		innhold.add_child(_lenker(s["lenker"]))
	var bygg := _knapp("Bygg – koster " + _kost_tekst(pris), _bygg.bind(sted), true)
	if not _har_rad(pris):
		_deaktiver(bygg, "Du har ikke råd – det koster " + _kost_tekst(pris))
	innhold.add_child(bygg)
	_tilbake_knapp("Ikke nå – tilbake til gården").set_meta("ikke_auto", true)


func _bygg(sted: String) -> void:
	var s: Dictionary = steder[sted]
	_betal(_kost(s["pris"]))
	bygget[sted] = true
	if sted == "naustet":
		skip = "byrding"
	_endre(s.get("effekter", {}))
	verden.puff(sted)
	_lukk_vindu()
	_oppdater_hint("Du har bygd %s! " % s["navn"].to_lower())


func _vis_ressurs(nokkel: String) -> void:
	var r: Dictionary = ressurser.get(nokkel, {})
	if r.is_empty():
		return
	_tom_innhold("ressurs")
	_overskrift("RESSURS · DU HAR NÅ %d" % int(stats[nokkel]), r["navn"])
	innhold.add_child(_etikett("I vikingtiden", 23, C_INK, font_fet))
	innhold.add_child(_avsnitt(r["historisk"], 21))
	innhold.add_child(_etikett("I spillet", 23, C_INK, font_fet))
	innhold.add_child(_avsnitt(r["spill"], 21))
	innhold.add_child(_lenker(r["lenker"]))
	_tilbake_knapp()


# ---------------------------------------------------------------- saker

func _vis_sak(h: Dictionary) -> void:
	_tom_innhold("sak")
	_overskrift("VINTER %d · %s" % [vinter, steder.get(h.get("sted", ""), {}).get("navn", "").to_upper()], h["tittel"])
	innhold.add_child(_etikett(h["person"], 19, C_MUTED, font_kursiv))
	innhold.add_child(_avsnitt(h["tekst"], 22))
	innhold.add_child(_etikett("Hva gjør du?", 20, C_INK, font_fet))

	for valg in h["valg"]:
		var kost := _kostnad(valg)
		var tekst: String = valg["tekst"]
		if not kost.is_empty():
			tekst += "   (koster " + _kost_tekst(kost) + ")"
		var b := _knapp(tekst, _velg.bind(h, valg))
		if not _har_rad(kost):
			_deaktiver(b, valg["tekst"] + "   (du har ikke råd – koster " + _kost_tekst(kost) + ")")
		innhold.add_child(b)
	_tilbake_knapp("Tenk på det – tilbake til gården").set_meta("ikke_auto", true)


func _kostnad(valg: Dictionary) -> Dictionary:
	if valg.has("kostnad"):
		return _kost(valg["kostnad"])
	var solv := int(valg.get("effekter", {}).get("solv", 0))
	return {"solv": -solv} if solv < 0 else {}


func _velg(h: Dictionary, valg: Dictionary) -> void:
	var utfall: Dictionary = valg
	var terning := ""
	if valg.has("sjanse"):
		if randf() < _sjanse(float(valg["sjanse"])):
			utfall = valg["suksess"]
			terning = "Lykken var med deg."
		else:
			utfall = valg["fiasko"]
			terning = "Lykken var ikke med deg."

	var effekter: Dictionary = utfall.get("effekter", {})
	_endre(effekter)
	if utfall.has("flagg"):
		flagg[utfall["flagg"]] = true
		if utfall["flagg"] == "skip_tapt":
			skip = ""
	for f in utfall.get("fjern_flagg", []):
		flagg.erase(f)
	if utfall.has("logg"):
		_logg(utfall["logg"])
	if valg.has("frigi_trell"):
		for t in treller.duplicate():
			if t["id"] == valg["frigi_trell"]:
				treller.erase(t)
	aktive.erase(h)
	_oppdater_topplinje()

	_tom_innhold("resultat")
	innhold.add_child(_etikett(h["tittel"], 30, C_ACCENT, font_fet))
	innhold.add_child(_avsnitt("Du valgte: " + valg["tekst"], 20, C_MUTED, font_kursiv))
	if terning != "":
		innhold.add_child(_etikett(terning, 20, C_INK, font_fet))
	innhold.add_child(_avsnitt(utfall["resultat"], 22))
	var eff := _effekt_tekst(effekter)
	if eff != "":
		innhold.add_child(_rik(eff, 20))
	_vis_kort(h["id"], h["fakta"])
	_tilbake_knapp()


# ---------------------------------------------------------------- treller

func _vis_treller() -> void:
	_tom_innhold("treller")
	_overskrift("TRELLEHUSET", "Trellene på gården")
	if treller.is_empty():
		innhold.add_child(_avsnitt("Du eier ingen treller nå.", 21))
	else:
		innhold.add_child(_avsnitt("Du eier %d mennesker. Arbeidet deres gir gården %d sølv hver vinter. Selger du noen, får du sølv med en gang, men mister arbeidet for resten av livet ditt som høvding." % [treller.size(), _trellearbeid()], 21))
	for t in treller:
		innhold.add_child(_trellkort(t))
	_vis_kort("treller", trelldata["fakta"])
	_vis_kort("trell_rettigheter", trelldata["fakta_rettigheter"])
	innhold.add_child(_knapp("Les om trellehuset", _vis_sted.bind("trellehuset"), true))
	_tilbake_knapp()


func _trellkort(t: Dictionary) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _boks(Color("e3d8bd"), Color("b8ab90"), 8, 20.0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var navn: String = t["navn"] + ("   · NY PÅ GÅRDEN" if t.get("ny", false) else "")
	v.add_child(_etikett(navn, 24, C_INK, font_fet))
	v.add_child(_etikett("%d år · %s" % [int(t["alder"]), t["opphav"]], 18, C_MUTED, font_kursiv))
	v.add_child(_avsnitt(t["historie"], 20))
	v.add_child(_rik("Arbeid: [b]+%d sølv[/b] hver vinter     Salgsverdi: [b]%d sølv[/b]" % [_arbeid(t), int(t["verdi"])], 17))
	var rad := HBoxContainer.new()
	rad.add_theme_constant_override("separation", 10)
	var selg := _knapp("Selg for %d sølv" % int(t["verdi"]), _selg_trell.bind(t), true)
	var fri := _knapp("Gi %s friheten" % t["navn"], _frigi_trell.bind(t), true)
	for b in [selg, fri]:
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 44
		rad.add_child(b)
	v.add_child(rad)
	return p


func _arbeid(t: Dictionary) -> int:
	return int(t.get("arbeid", trelldata["arbeid"]))


func _trellearbeid() -> int:
	var sum := 0
	for t in treller:
		sum += _arbeid(t)
	return sum


func _vis_flukt(h: Dictionary) -> void:
	var t: Dictionary = h["rommling"]
	_tom_innhold("flukt")
	_overskrift("VINTER %d · SKOGEN" % vinter, t["navn"] + " har rømt")
	innhold.add_child(_avsnitt(t["historie"], 20, C_MUTED, font_kursiv))
	innhold.add_child(_avsnitt("Sporene går inn i skogen og videre mot fjellet. Bøndene venter på hva du gjør: Lar du en trell slippe unna, kan flere få lyst til å prøve. Men det er langt å jakte, og ingen vet hva som venter.", 21))
	innhold.add_child(_etikett("Hva gjør du?", 20, C_INK, font_fet))
	var jakt_kost := {"bondene": 5}
	var jakt := _knapp("Send menn etter %s (koster %s – omtrent 60 %% sjanse)" % [t["navn"], _kost_tekst(jakt_kost)], _flukt_valg.bind(h, "jakt"))
	if not _har_rad(jakt_kost):
		_deaktiver(jakt, "Send menn etter %s (du har ikke råd – koster %s)" % [t["navn"], _kost_tekst(jakt_kost)])
	innhold.add_child(jakt)
	innhold.add_child(_knapp("La %s gå" % t["navn"], _flukt_valg.bind(h, "slipp")))
	innhold.add_child(_knapp("Kunngjør på tinget at %s er fri – ingen skal jakte" % t["navn"], _flukt_valg.bind(h, "fri")))


func _flukt_valg(h: Dictionary, valg: String) -> void:
	var t: Dictionary = h["rommling"]
	aktive.erase(h)
	var tekst := ""
	var effekter := {}
	match valg:
		"jakt":
			_betal({"bondene": 5})
			if randf() < 0.6:
				t["ny"] = false
				treller.append(t)
				_logg("fanget_igjen")
				tekst = "Etter tre dager fant mennene %s i en hule ved fjellet, sulten og forfrosset. %s ble ført tilbake til gården med hendene bundet. De andre trellene så det." % [t["navn"], t["navn"]]
			else:
				tekst = "Mennene lette i fem dager, men fant bare et brent bål ved fjellet. %s er borte. Noen sier %s kom seg til en handelsplass og om bord på et skip." % [t["navn"], t["navn"]]
				effekter = {"aere": -5}
		"slipp":
			tekst = "Du sender ingen etter %s, og sier ikke mer om saken. Gården mister arbeidskraften. Etter noen uker slutter folk å snakke om det." % t["navn"]
		"fri":
			_logg("frigitt")
			tekst = "Du kunngjør på tinget at %s er en fri løysing, og at ingen skal jakte. Noen kaller deg gavmild, andre mener du gir de andre trellene farlige ideer." % t["navn"]
			effekter = {"aere": 5, "bondene": -5}
	_endre(effekter)
	_tom_innhold("flukt_resultat")
	_overskrift("SKOGEN", t["navn"])
	innhold.add_child(_avsnitt(tekst, 21))
	var eff := _effekt_tekst(effekter)
	if eff != "":
		innhold.add_child(_rik(eff, 20))
	_vis_kort("trell_rettigheter", trelldata["fakta_rettigheter"])
	_tilbake_knapp()


func _selg_trell(t: Dictionary) -> void:
	treller.erase(t)
	_logg("solgt")
	_endre({"solv": int(t["verdi"])})
	_tom_innhold("trell_solgt")
	_overskrift("SOLGT", t["navn"])
	innhold.add_child(_avsnitt("Du selger %s til en handelsmann for %d sølv. Samme kveld blir %s ført om bord på en knarr som skal sørover, til markedene i Hedeby og videre. Du ser aldri %s igjen." % [t["navn"], int(t["verdi"]), t["navn"], t["navn"]], 21))
	innhold.add_child(_avsnitt("Bak hvert salg på trellemarkedene sto et menneske med et navn og en historie, som %s." % t["navn"], 20, C_MUTED, font_kursiv))
	innhold.add_child(_rik(_effekt_tekst({"solv": int(t["verdi"])})))
	innhold.add_child(_knapp("Tilbake til trellene", _vis_treller, true))
	_tilbake_knapp()


func _frigi_trell(t: Dictionary) -> void:
	treller.erase(t)
	_logg("frigitt")
	_endre({"aere": 5})
	_tom_innhold("trell_fri")
	_overskrift("FRIGITT", t["navn"])
	innhold.add_child(_avsnitt("Du holder et gilde og gir %s friheten foran vitner. Nå er %s en løysing, en frigitt. Men en løysing hadde fortsatt lavere status enn de frie bøndene, og gården mister arbeidskraften." % [t["navn"], t["navn"]], 21))
	innhold.add_child(_rik(_effekt_tekst({"aere": 5}) + "     [color=#%s]Du mister %d sølv i inntekt hver vinter.[/color]" % [C_MUTED.to_html(false), _arbeid(t)]))
	innhold.add_child(_knapp("Tilbake til trellene", _vis_treller, true))
	_tilbake_knapp()


## Henter en fange fra et tokt eller markedet. Hver person finnes bare én gang på gården.
func _ny_trell(opphav: String) -> Dictionary:
	var mulige := []
	for t in trelldata["fanger"].get(opphav, []):
		if not _har_trell(t["id"]):
			mulige.append(t)
	if mulige.is_empty():
		return {}
	var ny: Dictionary = mulige.pick_random().duplicate()
	ny["ny"] = true
	return ny


# ---------------------------------------------------------------- skipet: handel og tokt

func _mal(id: String) -> Dictionary:
	for m in handeldata["mal"]:
		if m["id"] == id:
			return m
	return {}


func _skip_hindring() -> String:
	if not bygget.has("naustet"):
		return "Du har ikke skip ennå. Bygg naustet først."
	if skip == "":
		return "Skipet ditt gikk tapt. Bygg et nytt før du kan seile igjen."
	if skip_borte_til >= vinter:
		return "Skipet er fortsatt på den lange reisen østover, og kommer hjem neste vinter."
	if skip_seilt:
		return "Skipet har allerede vært ute denne vinteren. Neste vinter kan det seile igjen."
	return ""


## Hvorfor skipet du har nå, ikke kan seile til dette målet. Tom tekst betyr at det går.
func _mal_hindring(m: Dictionary) -> String:
	var s := _skiptype()
	if s.is_empty():
		return ""
	if m.get("hav", false) and not s.get("hav", false):
		return "En %s tåler ikke åpent hav. Bygg et større skip hos skipsbyggeren." % s["navn"].to_lower()
	if m["type"] == "tokt" and not s.get("kan_tokt", false):
		return "En %s er et lasteskip og duger ikke til tokt. Bygg en snekke hos skipsbyggeren." % s["navn"].to_lower()
	return ""


func _mal_kost(m: Dictionary) -> Dictionary:
	var kost := _kost(m["kost"]).duplicate()
	if m["type"] == "tokt" and (flagg.has("felles_tokt") or gjengjeld.has("frendene")):
		kost.erase("bondene")
	return kost


## Det et tokt gir ved seier, med det ekstra byttet et stort langskip får med seg.
func _tokt_gevinst(m: Dictionary) -> Dictionary:
	var g: Dictionary = m.get("gevinst", {}).duplicate()
	var ekstra := int(_skiptype().get("bytte", 0))
	if ekstra > 0:
		g["solv"] = int(g.get("solv", 0)) + ekstra
	return g


func _skip_egenskaper(s: Dictionary) -> String:
	var deler := ["lasterom %d lass" % int(s["last"])]
	deler.append("tåler åpent hav" if s.get("hav", false) else "bare kystfart")
	if s.get("kan_tokt", false):
		var t := int(round(float(s.get("tokt_sjanse", 0.0)) * 100.0))
		deler.append("kan brukes til tokt" + (" (+%d %% sjanse for seier)" % t if t > 0 else ""))
	else:
		deler.append("kan ikke brukes til tokt")
	if int(s.get("bytte", 0)) > 0:
		deler.append("+%d sølv i bytte" % int(s["bytte"]))
	var h := int(round(float(s.get("sjanse", 0.0)) * 100.0))
	if h > 0:
		deler.append("tryggere reiser (+%d %%)" % h)
	return ", ".join(deler)


func _vis_skip() -> void:
	if not bygget.has("naustet"):
		return
	_tom_innhold("skip")
	_overskrift("NAUSTET", "Handel og tokt")
	innhold.add_child(_avsnitt("Velg et mål på kartet. På handelsferd fyller du skipet med varer fra gården og selger dem der prisen er best. Tokt gir bytte, ære og fanger, men koster liv og skaper fiender. Der du har plyndret, er folk forberedt neste gang du kommer.", 20))
	var s := _skiptype()
	if not s.is_empty():
		innhold.add_child(_rik("[b]Skipet ditt: %s[/b] – %s." % [s["navn"], _skip_egenskaper(s)], 19))
	var status := []
	if not kontakter.is_empty():
		var navn := []
		for id in kontakter:
			navn.append(_mal(id)["navn"])
		status.append("[b]Handelsvenner:[/b] %s – der får du 1 sølv mer for hvert lass." % ", ".join(navn))
	if _fiender_totalt() > 0:
		var forsvart := []
		for id in fiender:
			if int(fiender[id]) > 0:
				forsvart.append("%s (−%d %%)" % [_mal(id)["navn"], int(round(_forsvar_straff(id) * 100.0))])
		status.append("[color=#%s][b]Kyster som venter deg:[/b] %s – tokt dit blir farligere.[/color]" % [C_ACCENT.to_html(false), ", ".join(forsvart)])
	if flagg.has("felles_tokt"):
		status.append("[b]Tinget har vedtatt felles tokt:[/b] Neste tokt får mannskap fra nabobygdene.")
	elif gjengjeld.has("frendene"):
		status.append("[b]Frendene skylder deg en gjengjeld:[/b] De stiller som mannskap på neste tokt.")
	if not status.is_empty():
		innhold.add_child(_rik("\n".join(status), 19))
	var hindring := _skip_hindring()
	if hindring != "":
		innhold.add_child(_avsnitt(hindring, 20, C_ACCENT, font_fet))
	if skip == "":
		var kost := {"solv": 15, "bondene": 5}
		var b := _knapp("Bygg en ny byrding – koster " + _kost_tekst(kost), _nytt_skip.bind(kost), true)
		if not _har_rad(kost):
			_deaktiver(b, "Du har ikke råd til nytt skip – det koster " + _kost_tekst(kost))
		innhold.add_child(b)
	elif skip_borte_til < vinter:
		innhold.add_child(_knapp("Skipsbyggeren: bygg et større skip", _vis_skipsbygging, true))

	var kart := Kart.new()
	kart.mal = handeldata["mal"]
	kart.hjem = handeldata["hjem"]
	kart.kontakter = kontakter
	kart.font = font_tekst
	kart.font_fet = font_fet
	kart.valgt = valgt_mal
	kart.mal_valgt.connect(_velg_mal)
	innhold.add_child(kart)
	mal_detaljer = VBoxContainer.new()
	mal_detaljer.add_theme_constant_override("separation", 12)
	innhold.add_child(mal_detaljer)
	_vis_maldetaljer()
	_tilbake_knapp().set_meta("ikke_auto", true)


## Du kan bygge neste steg på veien du er på, eller begynne på den andre veien.
func _kan_bygge_skip(s: Dictionary) -> bool:
	if skip == "" or s["id"] == skip or not s.has("krever"):
		return false
	if s["krever"] == skip:
		return true
	return s["krever"] == "byrding" and _skiptype().get("krever", "") != s["id"]


func _vis_skipsbygging() -> void:
	_tom_innhold("skipsbygging")
	_overskrift("NAUSTET", "Skipsbyggeren")
	innhold.add_child(_avsnitt("Du kan bare ha ett skip. Et lasteskip har plass til mye varer, men er for tregt og tungt til tokt. Et langskip er raskt og har mange årer, men lite lasterom. Velg hvilken vei du vil gå.", 20))
	var naa := _skiptype()
	innhold.add_child(_rik("[b]Skipet ditt nå: %s[/b] – %s." % [naa["navn"], _skip_egenskaper(naa)], 19))
	for s in skipdata["typer"]:
		if s["id"] == skip or not s.has("pris"):
			continue
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", _boks(Color("e3d8bd"), Color("b8ab90"), 8, 20.0))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		p.add_child(v)
		v.add_child(_etikett(s["retning"].to_upper(), 16, C_ACCENT, font_fet))
		v.add_child(_etikett(s["navn"], 24, C_INK, font_fet))
		v.add_child(_avsnitt(s["tekst"], 19))
		v.add_child(_rik("[b]Dette får du:[/b] " + _skip_egenskaper(s) + ".", 18))
		var kost := _kost(s["pris"])
		var b := _knapp("Bygg %s – koster %s" % [s["navn"].to_lower(), _kost_tekst(kost)], _bygg_skip.bind(s), true)
		b.custom_minimum_size.y = 44
		if not _kan_bygge_skip(s):
			_deaktiver(b, "Du må ha en %s først" % _skiptype(s["krever"])["navn"].to_lower())
		elif not _har_rad(kost):
			_deaktiver(b, "Du har ikke råd – det koster " + _kost_tekst(kost))
		v.add_child(b)
		innhold.add_child(p)
	var tilbake := _knapp("Tilbake til kartet", _vis_skip, true)
	tilbake.set_meta("ikke_auto", true)
	innhold.add_child(tilbake)
	_tilbake_knapp()


func _bygg_skip(s: Dictionary) -> void:
	_betal(_kost(s["pris"]))
	skip = s["id"]
	_logg("skip_bygd")
	_oppdater_topplinje()
	_tom_innhold("skip_bygd")
	_overskrift("NYTT SKIP", s["navn"])
	innhold.add_child(_avsnitt("Hele vinteren har det lydt øksehogg fra naustet. Nå ligger skipet ferdig på vannet, nytjæret og med nytt seil.", 21))
	innhold.add_child(_rik("[b]Dette får du:[/b] " + _skip_egenskaper(s) + ".", 20))
	_vis_kort("seilet", skipdata["fakta"])
	innhold.add_child(_knapp("Tilbake til kartet", _vis_skip, true))
	_tilbake_knapp()


func _gudetekst() -> String:
	var prosent := int(round(_gudebonus() * 100.0))
	if prosent > 0:
		return "gudene er med deg: +%d %%" % prosent
	if prosent < 0:
		return "gudene er imot deg: %d %%" % prosent
	return "gudene er verken for eller imot deg"


func _nytt_skip(kost: Dictionary) -> void:
	_betal(kost)
	flagg.erase("skip_tapt")
	skip = "byrding"
	_vis_skip()


func _velg_mal(id: String) -> void:
	valgt_mal = id
	_vis_maldetaljer()


func _vis_maldetaljer() -> void:
	for c in mal_detaljer.get_children():
		mal_detaljer.remove_child(c)
		c.queue_free()
	var m := _mal(valgt_mal)
	if m.is_empty():
		mal_detaljer.add_child(_avsnitt("Klikk på et mål på kartet for å se mer.", 20, C_MUTED, font_kursiv))
		return
	var tokt: bool = m["type"] == "tokt"
	mal_detaljer.add_child(_etikett("TOKT" if tokt else "HANDELSFERD", 17, C_ACCENT if tokt else C_GULL, font_fet))
	mal_detaljer.add_child(_etikett(m["navn"], 28, C_INK, font_fet))
	mal_detaljer.add_child(_avsnitt(m["tekst"], 20))
	var kost := _mal_kost(m)
	var p := _reise_sjanse(m)
	var rod := C_ACCENT.to_html(false)
	var linjer := ["[b]Pris for å ruste ut skipet:[/b] " + (_kost_tekst(kost) if not kost.is_empty() else "ingenting")]
	if tokt:
		var delvis := minf(TOKT_DELVIS, 1.0 - p)
		var tap := maxf(1.0 - p - delvis, 0.0)
		linjer.append("[b]Seier:[/b] %d %%     [b]Halvveis:[/b] %d %%     [b]Nederlag:[/b] %d %%   [color=#%s](%s)[/color]" % [int(round(p * 100.0)), int(round(delvis * 100.0)), int(round(tap * 100.0)), C_MUTED.to_html(false), _gudetekst()])
		linjer.append("[b]Ved seier:[/b] " + _effekt_tekst(_tokt_gevinst(m)) + ", og du tar med deg et menneske hjem som trell.")
		linjer.append("[b]Halvveis:[/b] " + _effekt_tekst(m["delvis"]["effekter"]))
		linjer.append("[color=#%s][b]Ved nederlag:[/b] %s, og %d %% fare for å miste skipet.[/color]" % [rod, _effekt_tekst(m.get("fiasko_effekter", {})).replace("     ", ", "), int(round(_skip_tap_sjanse(m) * 100.0))])
		if int(fiender.get(m["id"], 0)) > 0:
			linjer.append("[color=#%s][b]Kysten er forsvart:[/b] Folk her husker deg fra før, og sjansen er %d %% lavere.[/color]" % [rod, int(round(_forsvar_straff(m["id"]) * 100.0))])
		linjer.append("[color=#%s][b]Fiender: +%d[/b] ved seier – neste tokt hit blir farligere.[/color]" % [rod, int(m.get("fiender", 0))])
		if flagg.has("felles_tokt"):
			linjer.append("[i]Nabobygdene stiller mannskap, så toktet koster ikke støtte fra bøndene.[/i]")
		elif gjengjeld.has("frendene"):
			linjer.append("[i]Frendene skylder deg en gjengjeld og stiller som mannskap, så toktet koster ikke støtte fra bøndene.[/i]")
	else:
		linjer.append("[b]Sjanse for å komme trygt fram:[/b] %d %%  [color=#%s](%s)[/color]" % [int(round(p * 100.0)), C_MUTED.to_html(false), _gudetekst()])
		if not m.get("gevinst", {}).is_empty():
			linjer.append("[b]I tillegg til sølvet:[/b] " + _effekt_tekst(m["gevinst"]))
		if kontakter.has(m["id"]):
			linjer.append("[b]Handelsvenner:[/b] Du er kjent her og får 1 sølv mer for hvert lass.")
		else:
			linjer.append("[b]Handelsvenner:[/b] Etter den første handelen her får du 1 sølv mer for hvert lass.")
		if m.get("trellmarked", false):
			linjer.append("[b]Trellemarked:[/b] Her selges også mennesker.")
		if m["id"] == "bulgar":
			linjer.append("[i]Reisen tar så lang tid at skipet er borte også neste vinter.[/i]")
	mal_detaljer.add_child(_rik("\n".join(linjer), 19))

	var hindring := _skip_hindring()
	if hindring == "":
		hindring = _mal_hindring(m)
	if hindring == "" and not _har_rad(kost):
		hindring = "Du har ikke råd – det koster %s å ruste ut skipet." % _kost_tekst(kost)
	if tokt:
		var b := _knapp("Seil til " + m["navn"], _seil.bind(m["id"]), true)
		if hindring != "":
			_deaktiver(b, hindring)
		mal_detaljer.add_child(b)
		return
	mal_detaljer.add_child(_etikett("Hva vil du laste skipet med?", 22, C_INK, font_fet))
	mal_detaljer.add_child(_avsnitt(m["pris_tekst"], 19, C_MUTED, font_kursiv))
	if hindring != "":
		mal_detaljer.add_child(_avsnitt(hindring, 19, C_ACCENT, font_fet))
	var last := _last()
	for v in skipdata["varer"]:
		var pris := _vare_pris(m, v["id"])
		var tekst := "%s:   %d lass × %d sølv = %d sølv" % [v["navn"], last, pris, last * pris]
		var b := _knapp(tekst, _seil.bind(m["id"], v["id"]))
		if v.has("krever") and not bygget.has(v["krever"]):
			_deaktiver(b, "%s   (du må bygge %s først)" % [v["navn"], steder[v["krever"]]["navn"].to_lower()])
		elif hindring != "":
			b.disabled = true
		mal_detaljer.add_child(b)
	mal_detaljer.add_child(_avsnitt("Lasterommet avgjør hvor mange lass du får med. Prisen per lass er forskjellig fra sted til sted.", 17, C_MUTED))


## Faren for å miste skipet når en reise går galt. Tjære halverer den.
func _skip_tap_sjanse(m: Dictionary) -> float:
	return float(m.get("skip_tap", 0.0)) * maxf(1.0 + _inno_sum("skip_tap"), 0.0)


func _seil(id: String, vare := "") -> void:
	var m := _mal(id)
	var kost := _mal_kost(m)
	var tokt: bool = m["type"] == "tokt"
	var p := _reise_sjanse(m)
	_betal(kost)
	var mannskap := ""
	if tokt and flagg.has("felles_tokt"):
		flagg.erase("felles_tokt")
		mannskap = "Nabobygdene stilte mannskap, slik tinget vedtok."
	elif tokt and gjengjeld.has("frendene"):
		gjengjeld.erase("frendene")
		mannskap = "Frendene dine stilte som mannskap. Nå har de gjengjeldt gaven din."
	skip_seilt = true
	if id == "bulgar":
		skip_borte_til = vinter + 1

	# Handel lykkes eller mislykkes. Tokt kan også ende halvveis.
	var r := randf()
	var utfall := "seier"
	if r >= p:
		utfall = "delvis" if tokt and r < p + TOKT_DELVIS else "tap"
	var effekter := {}
	var regnestykke := ""
	var fange := {}
	var skip_mistet := false
	var ny_venn := false
	var tekst := ""
	match utfall:
		"seier":
			tekst = m["suksess"]
			if tokt:
				effekter = _tokt_gevinst(m)
				if m.has("fanger"):
					fange = _ny_trell(m["fanger"])
					if not fange.is_empty():
						treller.append(fange)
						_logg("fanget")
				fiender[id] = int(fiender.get(id, 0)) + int(m.get("fiender", 0))
			else:
				effekter = m.get("gevinst", {}).duplicate()
				var pris := _vare_pris(m, vare)
				var sum := _last() * pris
				var vare_navn := ""
				for v in skipdata["varer"]:
					if v["id"] == vare:
						vare_navn = v["navn"].to_lower()
				regnestykke = "[b]Regnestykket:[/b] %d lass %s × %d sølv = [b]%d sølv[/b]\nPris per lass: %s" % [_last(), vare_navn, pris, sum, _pris_forklaring(m, vare)]
				effekter["solv"] = int(effekter.get("solv", 0)) + sum
				ny_venn = not kontakter.has(id)
				kontakter[id] = true
		"delvis":
			tekst = m["delvis"]["tekst"]
			effekter = m["delvis"]["effekter"]
			fiender[id] = int(fiender.get(id, 0)) + 1
		"tap":
			tekst = m["fiasko"]
			effekter = m.get("fiasko_effekter", {})
			if tokt:
				fiender[id] = int(fiender.get(id, 0)) + 1
			if randf() < _skip_tap_sjanse(m):
				skip_mistet = true
				flagg["skip_tapt"] = true
				skip = ""
	_endre(effekter)
	if tokt:
		_logg({"seier": "tokt_ok", "delvis": "tokt_delvis", "tap": "tokt_feil"}[utfall])
		if utfall != "tap":
			_logg("tokt_" + id)
	else:
		_logg("handel")
		if utfall == "seier":
			_logg("handel_" + id)
	_oppdater_topplinje()

	_tom_innhold("reise")
	_overskrift("HJEMKOMST", m["navn"])
	var dom := {"seier": "Toktet ble en seier." if tokt else "Reisen lyktes.", "delvis": "Toktet gikk bare halvveis.", "tap": "Toktet endte med nederlag." if tokt else "Reisen gikk galt."}
	innhold.add_child(_etikett(dom[utfall], 22, C_PLUSS if utfall == "seier" else C_ACCENT, font_fet))
	innhold.add_child(_avsnitt(tekst, 21))
	if mannskap != "":
		innhold.add_child(_avsnitt(mannskap, 19, C_MUTED, font_kursiv))
	if not kost.is_empty():
		innhold.add_child(_rik("[color=#%s]Det kostet %s å ruste ut skipet.[/color]" % [C_MUTED.to_html(false), _kost_tekst(kost)], 18))
	if regnestykke != "":
		innhold.add_child(_rik(regnestykke, 20))
		innhold.add_child(_avsnitt("Kjøpmannen legger hakksølv i den ene skåla og lodd i den andre, til vekta står stille.", 18, C_MUTED, font_kursiv))
	var eff := _effekt_tekst(effekter)
	if eff != "":
		innhold.add_child(_rik(eff, 20))
	if skip_mistet:
		innhold.add_child(_avsnitt("Skipet gikk tapt. De som overlevde, kom seg hjem med andre skip. Du må bygge et nytt skip før du kan seile igjen.", 21, C_ACCENT, font_fet))
	if ny_venn:
		innhold.add_child(_rik("[b]Nye handelsvenner:[/b] Neste gang du handler i %s, får du 1 sølv mer for hvert lass." % m["navn"], 19))
	if not fange.is_empty():
		innhold.add_child(_etikett("Fange tatt med hjem", 22, C_ACCENT, font_fet))
		innhold.add_child(_trellkort(fange))
	if tokt:
		innhold.add_child(_rik("[color=#%s][b]Fiender ved %s nå: %d[/b] – sjansen for seier neste gang er %d %% lavere.[/color]" % [C_ACCENT.to_html(false), m["navn"], int(fiender.get(id, 0)), int(round(_forsvar_straff(id) * 100.0))], 19))
	if utfall == "seier" and m.get("trellmarked", false):
		var paa_marked := _ny_trell("marked")
		if not paa_marked.is_empty():
			var mpris := int(paa_marked["verdi"]) + 4
			innhold.add_child(_etikett("På trellemarkedet", 22, C_INK, font_fet))
			innhold.add_child(_avsnitt("Mellom tønner og skinn står det mennesker til salgs. En av dem er %s." % paa_marked["navn"], 20))
			innhold.add_child(_trellkort_uten_knapper(paa_marked))
			var kjop := _knapp("Kjøp %s for %d sølv" % [paa_marked["navn"], mpris], _kjop_trell.bind(paa_marked, mpris), true)
			if int(stats["solv"]) < mpris:
				_deaktiver(kjop, "Du har ikke råd til å kjøpe (%d sølv)" % mpris)
			innhold.add_child(kjop)
	_vis_kort("handel_" + id, m["fakta"])
	if tokt:
		_vis_kort("plyndring", handeldata["fakta_plyndring"])
		_vis_kort("motangrep", handeldata["fakta_motangrep"])
	_tilbake_knapp()


func _trellkort_uten_knapper(t: Dictionary) -> PanelContainer:
	var p := _trellkort(t)
	var v: VBoxContainer = p.get_child(0)
	var rad := v.get_child(v.get_child_count() - 1)
	v.remove_child(rad)
	rad.queue_free()
	return p


func _kjop_trell(t: Dictionary, pris: int) -> void:
	_endre({"solv": -pris})
	treller.append(t)
	_logg("kjopt")
	_oppdater_topplinje()
	_tom_innhold("trell_kjopt")
	_overskrift("KJØPT", t["navn"])
	innhold.add_child(_avsnitt("Du betaler %d sølv, og %s blir ført om bord på skipet ditt. Nå arbeider %s på gården din." % [pris, t["navn"], t["navn"]], 21))
	innhold.add_child(_knapp("Se trellene dine", _vis_treller, true))
	_tilbake_knapp()


# ---------------------------------------------------------------- tinget

func _fakta_for_tingsak(sak: Dictionary) -> Array:
	if sak.has("fakta"):
		return ["ting_" + sak["id"], sak["fakta"]]
	# Viser til et annet kort, f.eks. en annen tingsak («leidang») eller en vanlig sak («primsigning»).
	var ref: String = sak.get("fakta_ref", "")
	for k in _alle_kort():
		if k["id"] == "ting_" + ref or k["id"] == ref:
			return [k["id"], k["fakta"]]
	return []


func _vis_tinget() -> void:
	_tom_innhold("ting")
	_overskrift("TINGSTEDET", "Kall inn tinget")
	innhold.add_child(_avsnitt("På tinget møtes de frie mennene i bygda. Her kan du legge fram forslag, men du kan ikke bestemme alene. Du må ha flertallet med deg.", 21))
	innhold.add_child(_rik("Din støtte på tinget er lik støtten fra bøndene: [b]%d[/b]. Du kan øke den ved å bruke [b]ætten[/b], [b]sølv[/b] og [b]æren[/b] din som politisk valuta." % int(stats["bondene"]), 21))
	if ting_brukt:
		innhold.add_child(_avsnitt("Du har allerede kalt inn tinget denne vinteren. Neste vinter kan du prøve igjen.", 20, C_ACCENT, font_fet))
	else:
		innhold.add_child(_etikett("Hvilken sak vil du legge fram?", 21, C_INK, font_fet))
		if vedtatt.size() >= tingdata["forslag"].size():
			innhold.add_child(_avsnitt("Tinget har vedtatt alle forslagene dine.", 20, C_MUTED, font_kursiv))
		for f in tingdata["forslag"]:
			# Det tinget har vedtatt, gjelder. Det kan ikke legges fram en gang til.
			if vedtatt.has(f["id"]):
				continue
			var valg: Dictionary = f["valg"][0]
			var b := _knapp("%s   (motstand: %d)" % [f["tittel"], int(valg["motstand"])], _start_ting.bind(f, valg, null))
			innhold.add_child(b)
	_vis_kort("ting_makt", tingdata["fakta"])
	innhold.add_child(_knapp("Les om tingstedet", _vis_sted.bind("tingstedet"), true))
	_tilbake_knapp().set_meta("ikke_auto", true)


func _vis_tingsak(h: Dictionary) -> void:
	var sak: Dictionary = h["tingsak"]
	_tom_innhold("tingsak")
	_overskrift("VINTER %d · TINGET ER KALT INN" % vinter, sak["tittel"])
	innhold.add_child(_etikett(sak["person"], 19, C_MUTED, font_kursiv))
	innhold.add_child(_avsnitt(sak["tekst"], 22))
	innhold.add_child(_rik("Tinget skal stemme. Din støtte er støtten fra bøndene: [b]%d[/b]. Hvilket syn vil du kjempe for?" % int(stats["bondene"]), 20))
	for valg in sak["valg"]:
		innhold.add_child(_knapp("%s   (motstand: %d)" % [valg["tekst"], int(valg["motstand"])], _start_ting.bind(sak, valg, h)))
	_tilbake_knapp("Tenk på det – tilbake til gården").set_meta("ikke_auto", true)


func _start_ting(sak: Dictionary, valg: Dictionary, h) -> void:
	ting_sak = sak
	ting_valg = valg
	ting_h = h
	ting_bonus = 0
	ting_brukte = {}
	_vis_avstemning()


func _ting_stotte() -> int:
	return int(stats["bondene"]) + ting_bonus + (OTTAR_STOTTE if gjengjeld.has("ottar") else 0)


## Storbonden Ottar kan tale mot deg – men ikke når han skylder deg en gjengjeld.
func _rival_sjanse() -> float:
	return 0.0 if gjengjeld.has("ottar") else TING_RIVAL_SJANSE


func _vis_avstemning() -> void:
	_tom_innhold("avstemning")
	_overskrift("TINGET ER SATT", ting_sak["tittel"])
	# Egne forslag har bare ett valg; da er saksteksten mer forklarende enn knappeteksten.
	var sak_tekst: String = ting_sak["tekst"] if ting_sak["valg"].size() == 1 else "Du kjemper for: " + ting_valg["tekst"]
	innhold.add_child(_avsnitt(sak_tekst, 21, C_INK, font_kursiv))
	var stotte := _ting_stotte()
	var motstand := int(ting_valg["motstand"])
	var vinner := stotte >= motstand
	innhold.add_child(_stemmebar(stotte, motstand))
	var sjanse := _ting_sjanse(stotte, motstand)
	var farge := C_PLUSS if vinner else C_ACCENT
	var dom := "Omtrent [color=#%s][b]%d %% sjanse[/b][/color] for at du vinner." % [farge.to_html(false), sjanse]
	var ottar := "Storbonden Ottar kan reise seg og tale mot deg (%d %% sjanse, +%d motstand). En gave til Ottar før tinget hindrer det." % [int(round(TING_RIVAL_SJANSE * 100.0)), TING_RIVAL_MOTSTAND]
	var regnet := "bøndene %d + det du har vunnet %d" % [int(stats["bondene"]), ting_bonus]
	if gjengjeld.has("ottar"):
		ottar = "Storbonden Ottar skylder deg en gjengjeld. Han taler for deg, og ingen reiser seg mot deg."
		regnet += " + Ottar %d" % OTTAR_STOTTE
	innhold.add_child(_rik("Din støtte: [b]%d[/b]  (%s)     Motstand: [b]%d[/b]\n%s Stemningen kan svinge litt begge veier. %s" % [stotte, regnet, motstand, dom, ottar], 19))
	innhold.add_child(_etikett("Skaff mer støtte før avstemningen:", 20, C_INK, font_fet))
	for p in tingdata["paavirkning"]:
		var kost := _kost(p["kost"])
		var b := _knapp("%s  (+%d støtte, koster %s)" % [p["tekst"], int(p["stotte"]), _kost_tekst(kost)], _paavirk.bind(p))
		if ting_brukte.has(p["id"]):
			_deaktiver(b, p["tekst"] + "  (gjort)")
		elif not _har_rad(kost):
			_deaktiver(b, p["tekst"] + "  (du har ikke råd – koster " + _kost_tekst(kost) + ")")
		innhold.add_child(b)
	innhold.add_child(_knapp("La tinget stemme", _ting_stem, true))


## Liten søyle som viser støtten din mot motstanden.
func _stemmebar(stotte: int, motstand: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 34)
	c.draw.connect(_tegn_stemmebar.bind(c, stotte, motstand))
	return c


func _tegn_stemmebar(c: Control, stotte: int, motstand: int) -> void:
	var maks := maxf(float(maxi(stotte, motstand)) * 1.15, 1.0)
	var w := c.size.x
	c.draw_rect(Rect2(0, 6, w, 22), Color("cfc4a8"))
	c.draw_rect(Rect2(0, 6, w * stotte / maks, 22), C_PLUSS if stotte >= motstand else C_ACCENT)
	var x := w * motstand / maks
	c.draw_line(Vector2(x, 0), Vector2(x, 34), C_INK, 3.0)


## Sjansen for å vinne når stemningen kan svinge ±TING_SVING og en rival kan dukke opp.
func _ting_sjanse(stotte: int, motstand: int) -> int:
	var uten_rival := clampf(float(TING_SVING + 1 + stotte - motstand) / (2 * TING_SVING + 1), 0.0, 1.0)
	var med_rival := clampf(float(TING_SVING + 1 + stotte - motstand - TING_RIVAL_MOTSTAND) / (2 * TING_SVING + 1), 0.0, 1.0)
	return int(round(100.0 * ((1.0 - _rival_sjanse()) * uten_rival + _rival_sjanse() * med_rival)))


func _paavirk(p: Dictionary) -> void:
	_betal(_kost(p["kost"]))
	ting_bonus += int(p["stotte"])
	ting_brukte[p["id"]] = true
	_vis_avstemning()


func _ting_stem() -> void:
	var sving := randi_range(-TING_SVING, TING_SVING)
	var rival := randf() < _rival_sjanse()
	var motstand := int(ting_valg["motstand"]) + (TING_RIVAL_MOTSTAND if rival else 0)
	var vant := _ting_stotte() + sving >= motstand
	# Ottar har nå gjengjeldt gaven sin.
	var ottar_talte := gjengjeld.has("ottar")
	gjengjeld.erase("ottar")
	_logg("ting_vunnet" if vant else "ting_tapt")
	if ting_h == null:
		ting_brukt = true
		if vant:
			vedtatt[ting_sak["id"]] = true
	else:
		aktive.erase(ting_h)
	var effekter: Dictionary = ting_valg.get("effekter", {}) if vant else {"aere": -5}
	_endre(effekter)
	if vant:
		if ting_valg.has("fiender_mal"):
			var fm: String = ting_valg["fiender_mal"]
			fiender[fm] = maxi(int(fiender.get(fm, 0)) + int(ting_valg.get("fiender", 0)), 0)
		if ting_valg.has("kontakt"):
			kontakter["hedeby"] = maxi(int(kontakter.get("hedeby", 0)), int(ting_valg["kontakt"]))
		if ting_valg.has("flagg"):
			flagg[ting_valg["flagg"]] = true
	_oppdater_topplinje()

	_tom_innhold("tingresultat")
	_overskrift("TINGET HAR STEMT", "Vedtatt!" if vant else "Tinget stemte deg ned")
	var forlop := []
	if ottar_talte:
		forlop.append("Storbonden Ottar reiste seg og talte for deg, slik han skyldte deg etter gaven (+%d støtte)." % OTTAR_STOTTE)
	if rival:
		forlop.append("Rett før avstemningen reiste storbonden Ottar seg og talte mot deg. Flere bønder nikket (+%d motstand)." % TING_RIVAL_MOTSTAND)
	if sving >= 5:
		forlop.append("Talen din gjorde inntrykk, og flere enn ventet stemte med deg (+%d støtte)." % sving)
	elif sving <= -5:
		forlop.append("Noen av dem som hadde lovet deg støtte, ombestemte seg da det gjaldt (%d støtte)." % sving)
	else:
		forlop.append("Stemningen på tinget var omtrent som ventet.")
	innhold.add_child(_avsnitt(" ".join(forlop), 20, C_MUTED, font_kursiv))
	if vant:
		innhold.add_child(_avsnitt(ting_valg["resultat"], 22))
	else:
		innhold.add_child(_avsnitt("Flertallet gikk imot deg. En høvding som taper på tinget, mister ansikt. Makten din hviler på at folk vil følge deg, og i dag ville de ikke det.", 22))
	var eff := _effekt_tekst(effekter)
	if eff != "":
		innhold.add_child(_rik(eff, 20))
	if vant and ting_valg.has("fiender_mal"):
		var fm2: String = ting_valg["fiender_mal"]
		innhold.add_child(_rik("[b]Fiender ved %s: %+d[/b]  (nå %d)" % [_mal(fm2)["navn"], int(ting_valg.get("fiender", 0)), int(fiender.get(fm2, 0))], 19))
	var kort := _fakta_for_tingsak(ting_sak)
	if not kort.is_empty():
		_vis_kort(kort[0], kort[1])
	_tilbake_knapp()


# ---------------------------------------------------------------- gaver og gilder

func _vis_gaver() -> void:
	_tom_innhold("gaver")
	_overskrift("LANGHUSET", "Gaver og gilder")
	innhold.add_child(_avsnitt(gavedata["tekst"], 21))
	for g in gavedata["mottakere"]:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", _boks(Color("e3d8bd"), Color("b8ab90"), 8, 20.0))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		p.add_child(v)
		v.add_child(_etikett(g["navn"], 24, C_INK, font_fet))
		v.add_child(_avsnitt(g["tekst"], 19))
		var eff := _effekt_tekst(g.get("effekter", {}))
		if eff != "":
			v.add_child(_rik("[b]Med en gang:[/b] " + eff, 18))
		if g.has("gjengjeld"):
			var skylder := "  [color=#%s][b](skylder deg dette nå)[/b][/color]" % C_PLUSS.to_html(false) if gjengjeld.has(g["id"]) else ""
			v.add_child(_rik("[b]Gjengjeld:[/b] " + g["gjengjeld"] + skylder, 18))
		var kost := _kost(g["kost"])
		var b := _knapp("%s – koster %s" % [g["knapp"], _kost_tekst(kost)], _gi_gave.bind(g), true)
		b.custom_minimum_size.y = 44
		if gitt.has(g["id"]):
			_deaktiver(b, "Du har allerede gjort dette i vinter")
		elif gjengjeld.has(g["id"]) and g.get("effekter", {}).is_empty():
			_deaktiver(b, "Gaven er ikke gjengjeldt ennå")
		elif not _har_rad(kost):
			_deaktiver(b, "Du har ikke råd – det koster " + _kost_tekst(kost))
		v.add_child(b)
		innhold.add_child(p)
	innhold.add_child(_knapp("Les om langhuset", _vis_sted.bind("langhuset"), true))
	_tilbake_knapp().set_meta("ikke_auto", true)


func _gi_gave(g: Dictionary) -> void:
	_betal(_kost(g["kost"]))
	_endre(g.get("effekter", {}))
	gitt[g["id"]] = true
	if g.has("gjengjeld"):
		gjengjeld[g["id"]] = true
	_logg("gaver")
	_tom_innhold("gave_gitt")
	_overskrift("LANGHUSET", g["navn"])
	innhold.add_child(_avsnitt(g["resultat"], 21))
	var eff := _effekt_tekst(g.get("effekter", {}))
	if eff != "":
		innhold.add_child(_rik(eff, 20))
	if g.has("gjengjeld"):
		innhold.add_child(_rik("[b]Gjengjeld:[/b] " + g["gjengjeld"], 20))
	_vis_kort("gaver", gavedata["fakta"])
	innhold.add_child(_knapp("Tilbake til gaver og gilder", _vis_gaver, true))
	_tilbake_knapp()


# ---------------------------------------------------------------- innovasjoner

func _innovasjon(id: String) -> Dictionary:
	for i in innodata["innovasjoner"]:
		if i["id"] == id:
			return i
	return {}


## Hvorfor innovasjonen ikke kan tas i bruk ennå. Tom tekst betyr at den kan det.
func _inno_hindring(i: Dictionary) -> String:
	if i.has("krever") and not inno.has(i["krever"]):
		return "Krever først: " + _innovasjon(i["krever"])["navn"].to_lower()
	if i.has("krever_sted") and not bygget.has(i["krever_sted"]):
		return "Du må bygge %s først" % steder[i["krever_sted"]]["navn"].to_lower()
	return ""


## «har» (tatt i bruk), «kan» (kan kjøpes nå), «dyr» (mangler sølv) eller «laast» (krever noe først).
func _inno_tilstand(i: Dictionary) -> String:
	if inno.has(i["id"]):
		return "har"
	if _inno_hindring(i) != "":
		return "laast"
	if not _har_rad(_kost(i["pris"])):
		return "dyr"
	return "kan"


## Innovasjonene på én vei, billigst først, slik at treet leses fra venstre mot høyre.
func _inno_paa_vei(vei: String) -> Array:
	var ut := []
	for i in innodata["innovasjoner"]:
		if i["vei"] == vei:
			ut.append(i)
	ut.sort_custom(func(a, b): return int(a["pris"]) < int(b["pris"]))
	return ut


func _ikon(id: String, storrelse: float, farge: Color) -> InnoIkon:
	var ik := InnoIkon.new()
	ik.id = id
	ik.farge = farge
	ik.custom_minimum_size = Vector2(storrelse, storrelse)
	ik.mouse_filter = MOUSE_FILTER_IGNORE
	return ik


func _ikonfarge(tilstand: String) -> Color:
	match tilstand:
		"har": return Color("f0c869")
		"kan": return Color("efe3c6")
		"dyr": return Color("b3a68d")
	return Color("6f655a")


func _ingen_mus(node: Node) -> void:
	for c in node.get_children():
		if c is Control:
			c.mouse_filter = MOUSE_FILTER_IGNORE
		_ingen_mus(c)


func _vis_innovasjoner() -> void:
	_tom_innhold("innovasjoner")
	rulle.custom_minimum_size.x = 1080
	inno_knapper = {}
	var alle: Array = innodata["innovasjoner"]
	if inno_valgt == "" or _innovasjon(inno_valgt).is_empty():
		# Velg det første du kan ta i bruk nå, ellers det første du ikke har.
		for tilstand in ["kan", "dyr", "laast", "har"]:
			for i in alle:
				if inno_valgt == "" and _inno_tilstand(i) == tilstand:
					inno_valgt = i["id"]
	_overskrift("NYTT PÅ GÅRDEN", "Innovasjoner")
	innhold.add_child(_rik(innodata["tekst"] + "  Du har tatt i bruk [b]%d av %d[/b], og du har [b]%d sølv[/b]." % [inno.size(), alle.size(), int(stats["solv"])], 19))

	var tre := PanelContainer.new()
	tre.add_theme_stylebox_override("panel", _boks(C_TREE_BG, Color("5a4630"), 8, 18.0))
	var rader := VBoxContainer.new()
	rader.add_theme_constant_override("separation", 12)
	tre.add_child(rader)
	for vei in innodata["veier"]:
		rader.add_child(_inno_rad(vei))
	innhold.add_child(tre)

	inno_detalj = VBoxContainer.new()
	innhold.add_child(inno_detalj)
	_vis_inno_detalj()
	_tilbake_knapp().set_meta("ikke_auto", true)


## Én rad i treet: veien til venstre, så innovasjonene som knutepunkter langs et spor.
func _inno_rad(vei: Dictionary) -> HBoxContainer:
	var rad := HBoxContainer.new()
	rad.add_theme_constant_override("separation", 0)

	var hode := HBoxContainer.new()
	hode.custom_minimum_size = Vector2(216, 0)
	hode.add_theme_constant_override("separation", 10)
	hode.tooltip_text = vei["navn"] + ": " + vei["tekst"]
	hode.mouse_filter = MOUSE_FILTER_STOP
	var hik := _ikon(vei["id"], 44, C_GULL)
	hik.size_flags_vertical = SIZE_SHRINK_CENTER
	hode.add_child(hik)
	var hv := VBoxContainer.new()
	hv.size_flags_horizontal = SIZE_EXPAND_FILL
	hv.alignment = BoxContainer.ALIGNMENT_CENTER
	hv.add_theme_constant_override("separation", 0)
	hv.add_child(_etikett(vei["navn"].to_upper(), 18, C_GULL, font_fet))
	var ht := _avsnitt(vei["tekst"], 14, Color("a8997f"), font_kursiv)
	hv.add_child(ht)
	hode.add_child(hv)
	_ingen_mus(hode)
	rad.add_child(hode)

	var forrige := ""
	for i in _inno_paa_vei(vei["id"]):
		var tilstand := _inno_tilstand(i)
		var linje := InnoLinje.new()
		linje.custom_minimum_size = Vector2(22 if forrige == "" else 30, 0)
		linje.farge = C_GULL if forrige == "har" else Color("4f4338")
		linje.mouse_filter = MOUSE_FILTER_IGNORE
		rad.add_child(linje)
		rad.add_child(_inno_node(i, tilstand))
		forrige = tilstand
	return rad


func _inno_node(i: Dictionary, tilstand: String) -> InnoKnapp:
	var b := InnoKnapp.new()
	b.custom_minimum_size = Vector2(240, 72)
	b.tooltip_text = i["navn"]
	b.lag_tips = _inno_tips.bind(i)
	b.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	b.set_meta("ikke_auto", true)
	b.pressed.connect(_velg_inno.bind(i["id"]))
	_inno_node_stil(b, tilstand, i["id"] == inno_valgt)
	inno_knapper[i["id"]] = b

	var marg := MarginContainer.new()
	marg.set_anchors_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		marg.add_theme_constant_override("margin_" + side, 8)
	b.add_child(marg)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	marg.add_child(h)

	# Ikonet sitter i en liten ramme, som i et teknologitre.
	var ramme := PanelContainer.new()
	ramme.add_theme_stylebox_override("panel", _boks(Color("17130f"), _ikonfarge(tilstand).darkened(0.35), 4, 4.0))
	ramme.size_flags_vertical = SIZE_SHRINK_CENTER
	ramme.add_child(_ikon(i["id"], 46, _ikonfarge(tilstand)))
	h.add_child(ramme)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	var navn := _avsnitt(i["navn"], 16, C_LYS if tilstand != "laast" else Color("9d9282"), font_fet)
	v.add_child(navn)
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 5)
	var merke: String = {"har": "hake", "kan": "solv", "dyr": "solv", "laast": "laas"}[tilstand]
	var sfarge: Color = {"har": Color("f0c869"), "kan": Color("e6cf8f"), "dyr": C_TREE_ROD, "laast": Color("8f8475")}[tilstand]
	status.add_child(_ikon(merke, 16, sfarge))
	var stekst := "I bruk" if tilstand == "har" else _kost_tekst(_kost(i["pris"]))
	if tilstand == "laast" and i.has("krever_sted"):
		stekst = "Krever " + steder[i["krever_sted"]]["navn"].to_lower()
	status.add_child(_etikett(stekst, 14, sfarge))
	v.add_child(status)
	h.add_child(v)
	_ingen_mus(b)
	return b


func _inno_node_stil(b: Button, tilstand: String, valgt: bool) -> void:
	var bg: Color = {"har": Color("4a3b1f"), "kan": Color("3a3029"), "dyr": Color("312923"), "laast": Color("26211c")}[tilstand]
	var kant: Color = {"har": C_GULL, "kan": Color("b9a47c"), "dyr": Color("6f6250"), "laast": Color("443a31")}[tilstand]
	var normal := _boks(bg, kant, 6, 0.0)
	var hover := _boks(bg.lightened(0.08), kant.lightened(0.3), 6, 0.0)
	for s in [normal, hover]:
		if valgt:
			s.set_border_width_all(3)
			s.border_color = Color("f6e2a6")
			s.shadow_color = Color(0.96, 0.78, 0.35, 0.35)
			s.shadow_size = 6
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


## Den rike infoboksen som vises når musa holdes over en innovasjon.
func _inno_tips(i: Dictionary) -> Control:
	var tilstand := _inno_tilstand(i)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	var topp := HBoxContainer.new()
	topp.add_theme_constant_override("separation", 12)
	var ramme := PanelContainer.new()
	ramme.add_theme_stylebox_override("panel", _boks(Color("17130f"), C_GULL.darkened(0.3), 4, 4.0))
	ramme.add_child(_ikon(i["id"], 52, _ikonfarge(tilstand) if tilstand != "laast" else Color("b3a68d")))
	topp.add_child(ramme)
	var tv := VBoxContainer.new()
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.add_child(_etikett(i["navn"], 22, Color("f0c869"), font_fet))
	var vei_navn := ""
	for vei in innodata["veier"]:
		if vei["id"] == i["vei"]:
			vei_navn = vei["navn"]
	tv.add_child(_etikett(vei_navn, 15, Color("a8997f"), font_kursiv))
	topp.add_child(tv)
	v.add_child(topp)
	v.add_child(_tips_strek())
	v.add_child(_tips_tekst(i["tekst"], 16, C_LYS, font_tekst))
	v.add_child(_tips_strek())
	v.add_child(_etikett("Virkning", 15, C_GULL, font_fet))
	v.add_child(_tips_tekst(i["virkning_tekst"], 17, C_TREE_GRONN, font_fet))
	v.add_child(_tips_strek())
	var kost := _kost(i["pris"])
	var linjer := []
	match tilstand:
		"har":
			linjer.append(["Tatt i bruk på gården din.", Color("f0c869")])
		"laast":
			linjer.append(["Pris: " + _kost_tekst(kost), Color("d8c9a6")])
			linjer.append([_inno_hindring(i) + ".", C_TREE_ROD])
		"dyr":
			linjer.append(["Pris: " + _kost_tekst(kost), Color("d8c9a6")])
			linjer.append(["Du mangler %d sølv." % (int(kost.get("solv", 0)) - int(stats["solv"])), C_TREE_ROD])
		"kan":
			linjer.append(["Pris: " + _kost_tekst(kost), Color("d8c9a6")])
			linjer.append(["Klikk for å velge, og ta den i bruk nedenfor.", Color("a8997f")])
	for l in linjer:
		v.add_child(_tips_tekst(l[0], 16, l[1], font_tekst))
	return v


func _tips_tekst(txt: String, storrelse: int, farge: Color, font: Font) -> Label:
	var l := _avsnitt(txt, storrelse, farge, font)
	l.custom_minimum_size.x = 400
	return l


func _tips_strek() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.77, 0.57, 0.23, 0.4)
	r.custom_minimum_size = Vector2(0, 1)
	return r


func _velg_inno(id: String) -> void:
	inno_valgt = id
	for nid in inno_knapper:
		_inno_node_stil(inno_knapper[nid], _inno_tilstand(_innovasjon(nid)), nid == id)
	_vis_inno_detalj()


## Feltet under treet: alt om den valgte innovasjonen, og knappen for å ta den i bruk.
func _vis_inno_detalj() -> void:
	for c in inno_detalj.get_children():
		inno_detalj.remove_child(c)
		c.queue_free()
	var i := _innovasjon(inno_valgt)
	if i.is_empty():
		return
	var tilstand := _inno_tilstand(i)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _boks(C_FAKTA if tilstand == "har" else Color("e3d8bd"), C_GULL if tilstand == "har" else Color("b8ab90"), 8, 18.0))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	p.add_child(h)
	var ramme := PanelContainer.new()
	ramme.add_theme_stylebox_override("panel", _boks(C_TREE_BG, C_GULL, 6, 6.0))
	ramme.size_flags_vertical = SIZE_SHRINK_BEGIN
	ramme.add_child(_ikon(i["id"], 72, _ikonfarge(tilstand) if tilstand != "laast" else Color("b3a68d")))
	h.add_child(ramme)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	v.add_child(_etikett(i["navn"] + ("   · I BRUK" if tilstand == "har" else ""), 23, C_INK, font_fet))
	v.add_child(_avsnitt(i["tekst"], 18))
	v.add_child(_rik("[b]Virkning:[/b] " + i["virkning_tekst"], 18))
	h.add_child(v)
	if tilstand != "har":
		var kost := _kost(i["pris"])
		var b := _knapp("Ta i bruk – koster " + _kost_tekst(kost), _kjop_inno.bind(i), true)
		b.custom_minimum_size = Vector2(230, 56)
		b.size_flags_vertical = SIZE_SHRINK_CENTER
		if tilstand == "laast":
			_deaktiver(b, _inno_hindring(i))
		elif tilstand == "dyr":
			_deaktiver(b, "Du har ikke råd – det koster " + _kost_tekst(kost))
		h.add_child(b)
	inno_detalj.add_child(p)


func _kjop_inno(i: Dictionary) -> void:
	_betal(_kost(i["pris"]))
	inno[i["id"]] = true
	_logg("inno")
	_oppdater_topplinje()
	inno_valgt = ""
	_vis_innovasjoner()


# ---------------------------------------------------------------- slutten

func _tilnavn(sum: int) -> String:
	if sum >= 300:
		return "den store"
	if sum >= 240:
		return "den vise"
	if sum >= 180:
		return "den gode"
	return "den seige"


func _vis_slutt(tapt: String) -> void:
	_tom_innhold("slutt")
	neste_knapp.disabled = true
	hint.text = ""
	var sum := 0
	for nokkel in STOTTE:
		sum += int(stats[nokkel])
	var innskrift := ""
	if tapt == "":
		var tilnavn := _tilnavn(sum)
		innhold.add_child(_etikett("Du klarte %d vintre!" % ANTALL_VINTRE, 36, C_ACCENT, font_fet))
		innhold.add_child(_avsnitt("Du styrte bygda gjennom gode og harde år. Folk vil huske deg som %s %s." % [hovding_navn, tilnavn], 22))
		innskrift = "Bøndene reiste denne steinen etter %s %s, som var høvding i %d vintre." % [hovding_navn, tilnavn, ANTALL_VINTRE]
	else:
		var vintre_styrt := vinter - 1
		innhold.add_child(_etikett("Tiden din som høvding er over", 34, C_ACCENT, font_fet))
		innhold.add_child(_avsnitt(TAP_TEKST[tapt], 22))
		innskrift = "%s var høvding i %d vintre." % [hovding_navn, vintre_styrt] if vintre_styrt != 1 else "%s var høvding i én vinter." % hovding_navn

	innhold.add_child(_sagakort(tapt))
	innhold.add_child(_etikett("Tenk over", 23, C_INK, font_fet))
	var sporsmal := []
	for q in sagadata["refleksjon"]:
		sporsmal.append("•  " + q)
	innhold.add_child(_avsnitt("\n".join(sporsmal), 20))
	_vis_kort("sagaer", sagadata["fakta"])
	innhold.add_child(_runestein(innskrift))
	innhold.add_child(_rik("Sølv: [b]%d[/b]     Ære: [b]%d[/b]     Gudenes gunst: [b]%d[/b]     Ætten: [b]%d[/b]     Bøndene: [b]%d[/b]\nTreller: [b]%d[/b]     Handelsforbindelser: [b]%d[/b]     Fiender: [b]%d[/b]" % [stats["solv"], stats["aere"], stats["gudene"], stats["aetten"], stats["bondene"], treller.size(), kontakter.size(), _fiender_totalt()], 19))
	innhold.add_child(_avsnitt("Du har samlet %d av %d kunnskapskort. Spill igjen for å møte nye saker!" % [_antall_funnet(), _alle_kort().size()], 21, C_INK, font_fet))
	innhold.add_child(_knapp("Spill igjen", _vis_start, true))
	var kort_knapp := _knapp("Se kunnskapskortene", _vis_samling, true)
	kort_knapp.set_meta("ikke_auto", true)
	innhold.add_child(kort_knapp)


## «Sagaen om deg»: skrevet som om en kristen islending satte den sammen rundt 1280,
## ut fra det spilleren faktisk gjorde – og farget av hvem som vant og fortalte den videre.
func _sagakort(tapt: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _boks(Color("f3e9cf"), Color("a8916a"), 4, 34.0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	var tittel := "Sagaen om " + hovding_navn
	if tapt == "":
		tittel += " " + _tilnavn(_stottesum())
	var t := _etikett(tittel, 32, C_ACCENT, font_fet)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var under := _avsnitt("Skrevet ned på Island rundt år 1280 – nesten 300 år etter at du levde.", 17, C_MUTED, font_kursiv)
	under.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(under)
	for avsnitt in _lag_saga(tapt):
		v.add_child(_avsnitt(avsnitt, 20))
	return p


func _stottesum() -> int:
	var sum := 0
	for nokkel in STOTTE:
		sum += int(stats[nokkel])
	return sum


func _lag_saga(tapt: String) -> Array:
	var n := hovding_navn
	var s := []
	s.append("Det var en høvding som het %s. %s rådde for en gård og en bygd på Vestlandet i de dager da Håkon jarl styrte Norge, og landet ennå var hedensk." % [n, n])

	# Troen, sett med kristne øyne
	if flagg.has("kors"):
		s.append("%s lot prester fra England tegne korsets tegn over seg. Mange mener at Guds nåde allerede da begynte å virke i høvdingens hjerte, lenge før kongene førte kristendommen til landet." % n)
	elif flagg.has("stort_blot") or int(stats["gudene"]) >= 70:
		s.append("%s var en stor blotmann og holdt fast ved de hedenske gudene, slik folk gjorde i den mørke tiden før lyset fra Kristus nådde Norge. Det sies at blodet fra offerhestene rant over steinen i offerlunden." % n)
	elif flagg.has("droppet_blot"):
		s.append("Det fortelles at %s en vinter nektet å blote til de falske gudene. Bøndene ble harme, men vi som kjenner den sanne Gud, regner det til høvdingens ære." % n)
	else:
		s.append("%s blotet til de gamle gudene, slik alle gjorde i den tiden, for ingen hadde ennå hørt om Kristus." % n)

	# Tokt
	var land := []
	if int(logg.get("tokt_england", 0)) > 0:
		land.append("England")
	if int(logg.get("tokt_irland", 0)) > 0:
		land.append("Irland")
	if not land.is_empty():
		s.append("%s herjet i vesterled og ranet Guds hus i %s. Hellige menn ble drept eller ført bort som treller. Det var en tung synd, og om det vil vi ikke si mer." % [n, " og ".join(land)])
	if int(logg.get("tokt_frankerriket", 0)) > 0:
		s.append("Skipene til %s seilte også opp elva Seinen i Frankland og kom hjem med mye gods. Skaldene kvad om det, men frankerne ba til Gud om å bli fridd fra nordmennenes raseri." % n)
	if int(logg.get("tokt_feil", 0)) > 0:
		s.append("Ikke alle ferdene gikk vel. Mange gode menn fra bygda ligger i fremmed jord, og kvinnene gråt i langhusene den høsten.")
	var tokt_i_alt := int(logg.get("tokt_ok", 0)) + int(logg.get("tokt_delvis", 0)) + int(logg.get("tokt_feil", 0))
	if tokt_i_alt == 0:
		s.append("%s fór aldri i viking, men satt fredelig på gården sin." % n)
	elif land.is_empty() and int(logg.get("tokt_frankerriket", 0)) == 0 and int(logg.get("tokt_ok", 0)) > 0:
		s.append("%s sendte de unge mennene i bygda i vesterled, og skipet kom hjem tungt av sølv. Hvor de hadde herjet, er det ingen som vet lenger." % n)

	# Handel
	if int(logg.get("handel_bulgar", 0)) > 0:
		s.append("Det sies at skipet til %s seilte den lange østerveien gjennom Gardarike, og kom hjem med sølv fra Serkland. På myntene sto tegn som ingen her kunne lese." % n)
	elif int(logg.get("handel", 0)) > 0 or not kontakter.is_empty():
		s.append("%s var en klok kjøpmann og hadde venner i mange handelsbyer. Derfor ble bygda rik." % n)

	# Trellene
	if int(logg.get("frigitt", 0)) > 0:
		s.append("%s ga treller friheten. Det var en god gjerning, for alle mennesker er like for Gud – og det var mer enn mange hedninger gjorde." % n)
	var handlet := []
	if int(logg.get("kjopt", 0)) > 0:
		handlet.append("kjøpte")
	if int(logg.get("solgt", 0)) > 0:
		handlet.append("solgte")
	if not handlet.is_empty():
		s.append("Men %s %s også mennesker som fe på markedet, slik hedningene gjorde i den tiden." % [n, " og ".join(handlet)])
	if int(logg.get("fanget_igjen", 0)) > 0:
		s.append("En trell som rømte fra gården, ble jaget opp mot fjellet og ført tilbake i bånd.")
	if not treller.is_empty() and int(logg.get("frigitt", 0)) == 0:
		s.append("Trellene på gården er ikke nevnt med navn i noen gammel fortelling. Ingen husket dem.")

	# Det folk husket
	if flagg.has("vant_holmgang"):
		s.append("%s felte berserken Ljot på holmgang, og det ble regnet for en stor bedrift." % n)
	if flagg.has("gjestfri"):
		s.append("%s var gjestmild. En kald vinterkveld tok høvdingen imot tre fremmede, og en av dem var en gammel enøyd mann som var borte om morgenen. Hedningene trodde det var Odin selv." % n)
	if flagg.has("reddet_barn"):
		s.append("Det fortelles også at %s ga korn til en fattig kvinne, slik at barnet hennes fikk leve. Det regnes for en kristelig gjerning, selv om høvdingen ikke var døpt." % n)
	if flagg.has("aettefeide"):
		s.append("Etter et drap i et gilde ble det ufred mellom ættene i bygda, og den feiden varte lenge.")
	elif flagg.has("forlik"):
		s.append("Etter et drap i et gilde ble det ufred mellom ættene i bygda. Men %s fikk til forlik, og bøtene ble veid opp i sølv foran vitner." % n)
	if int(logg.get("gaver", 0)) >= 4:
		s.append("%s var gavmild med sølvet og holdt store gilder. Derfor hadde høvdingen mange venner, og få våget å tale imot på tinget." % n)
	if flagg.has("kvad"):
		s.append("Skalden Torleiv diktet et kvad om %s. Noen vers av det er ennå kjent, og på dem bygger mye av denne fortellingen." % n)

	# Tinget
	var vunnet := int(logg.get("ting_vunnet", 0))
	var tapte := int(logg.get("ting_tapt", 0))
	if vunnet > tapte:
		s.append("%s var vellidt på tinget og klok i råd, og bøndene fulgte ofte høvdingen." % n)
	elif tapte > vunnet:
		s.append("Bøndene var ofte uenige med %s på tinget, og høvdingen tapte mange saker der." % n)

	# Slutten – og hvem som fortalte historien videre
	match tapt:
		"":
			s.append("%s styrte bygda i åtte vintre og ble kalt %s %s. Ætten etter høvdingen ble stor og mektig, og det er fra dem vi har denne fortellingen. Derfor blir det mest sagt godt om høvdingen her." % [n, n, _tilnavn(_stottesum())])
		"bondene":
			s.append("Til slutt vendte bøndene seg mot %s, og tinget valgte en annen til høvding. Denne fortellingen har vi fra ætten som tok makten etterpå, og de hadde liten grunn til å tale vel om den som kom før dem." % n)
		"aetten":
			s.append("Til slutt vendte frendene seg bort, og %s sto alene. Ingen ætt tok vare på minnet, og derfor er mye av denne sagaen glemt." % n)
		"aere":
			s.append("%s mistet all ære og døde fattig og glemt. Fortellingen har vi fra rivalene, og de husket best det som gikk galt." % n)
		"gudene":
			s.append("Etter flere uår mente bøndene at gudene hadde vendt seg bort fra %s, og høvdingen måtte flykte fra bygda. Hedningene trodde uår var straff fra gudene. Vi vet at alt skjer etter Guds vilje." % n)
	s.append("Og her slutter sagaen om %s." % n)
	return s


func _runestein(innskrift: String) -> PanelContainer:
	var p := PanelContainer.new()
	var s := _boks(C_STEIN, Color("6b6a63"), 60, 30.0)
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	p.add_theme_stylebox_override("panel", s)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var runer := _avsnitt(_til_runer(hovding_navn), 46, Color("3a2a22"), font_runer)
	runer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(runer)
	var tekst := _avsnitt(innskrift, 20, Color("1f1a17"), font_kursiv)
	tekst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tekst)
	var forklaring := _avsnitt("Navnet ditt skrevet med den yngre futharken, runene som ble brukt i vikingtiden.", 16, Color("2f2a25"))
	forklaring.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(forklaring)
	return p


func _vis_samling() -> void:
	topplinje.visible = false
	_tom_innhold("samling")
	var alle := _alle_kort()
	_overskrift("", "Kunnskapskortene dine")
	innhold.add_child(_avsnitt("Du har funnet %d av %d kort. Kortene dukker opp når du løser saker, seiler, bruker tinget og ser til trellene." % [_antall_funnet(), alle.size()], 21))
	innhold.add_child(_knapp("Tilbake", _vis_start, true))
	for k in alle:
		if samling.has(k["id"]):
			innhold.add_child(_faktakort(k["fakta"], false))
		else:
			var p := PanelContainer.new()
			p.add_theme_stylebox_override("panel", _boks(Color("cfc4a8"), Color(0, 0, 0, 0), 8, 18.0))
			p.add_child(_etikett("᛫ ᛫ ᛫   Ikke funnet ennå", 19, C_MUTED, font_kursiv))
			innhold.add_child(p)
	innhold.add_child(_knapp("Tilbake", _vis_start, true))


# ---------------------------------------------------------------- test

## Kjør med: godot --path . -- --autotest [--skjermbilde]
## Spiller noen runder med tilfeldige valg, prøver alle delene av spillet og avslutter.
func _autotest() -> void:
	var bilder := "--skjermbilde" in OS.get_cmdline_user_args()
	if "--kart" in OS.get_cmdline_user_args():
		_start_spill("Ragnvald")
		bygget["naustet"] = true
		skip = "knarr"
		kontakter["kaupang"] = true
		_lukk_vindu()
		_vis_skip()
		_velg_mal("bulgar")
		await get_tree().create_timer(1.5).timeout
		get_viewport().get_texture().get_image().save_png("user://skjerm_kart.png")
		rulle.scroll_vertical = 2000
		await get_tree().create_timer(0.5).timeout
		get_viewport().get_texture().get_image().save_png("user://skjerm_kart2.png")
		get_tree().quit()
		return
	if "--nytt" in OS.get_cmdline_user_args():
		# Skjermbilder av skip, last, innovasjoner og gaver.
		_start_spill("Ragnvald")
		for id in ["naustet", "smia", "fjoset", "offerlunden"]:
			bygget[id] = true
		skip = "knarr"
		stats["solv"] = 62
		kontakter["hedeby"] = true
		inno["vekt"] = true
		gjengjeld["ottar"] = true
		flagg["aettefeide"] = true
		vinter = 3
		_start_vinter()
		await _bilde("ny_vinter")
		_tilbake_til_garden()
		aktive.clear()
		_oppdater_hint()
		await _bilde("ny_gaard")
		_vis_skip()
		_velg_mal("dublin")
		await _bilde("ny_skip", 760)
		_velg_mal("england")
		await _bilde("ny_tokt", 760)
		_vis_skipsbygging()
		await _bilde("ny_skipsbygger", 250)
		_vis_innovasjoner()
		await _bilde("ny_innovasjoner", 150)
		# Hold musa over et knutepunkt for å se infoboksen.
		var node: Control = inno_knapper["jernvinne"]
		get_viewport().warp_mouse(node.get_global_rect().get_center())
		await get_tree().create_timer(1.2).timeout
		get_viewport().get_texture().get_image().save_png("user://skjerm_ny_inno_tips.png")
		_vis_gaver()
		await _bilde("ny_gaver")
		_seil("hedeby", "jern")
		await _bilde("ny_handel")
		get_tree().quit()
		return
	if "--saga" in OS.get_cmdline_user_args():
		_start_spill("Ragnvald")
		flagg["stort_blot"] = true
		flagg["gjestfri"] = true
		flagg["kvad"] = true
		logg = {"tokt_irland": 1, "tokt_ok": 1, "solgt": 1, "handel_bulgar": 1, "handel": 1, "ting_vunnet": 2}
		var rommling: Dictionary = treller[1]
		treller.erase(rommling)
		var h := {"rommling": rommling, "sted": "skogen", "person": "", "tittel": ""}
		aktive.append(h)
		_vis_flukt(h)
		await get_tree().create_timer(1.0).timeout
		get_viewport().get_texture().get_image().save_png("user://skjerm_flukt.png")
		vinter = ANTALL_VINTRE + 1
		_vis_slutt("")
		await get_tree().create_timer(1.0).timeout
		for i in 3:
			rulle.scroll_vertical = 330 + i * 560
			await get_tree().create_timer(0.4).timeout
			get_viewport().get_texture().get_image().save_png("user://skjerm_saga%d.png" % i)
		get_tree().quit()
		return
	var tatt := {}
	var runder := 0
	for steg in 3000:
		await get_tree().create_timer(0.7 if bilder else 0.01).timeout
		if bilder and not tatt.has(skjerm):
			tatt[skjerm] = true
			var fil := "user://skjerm_%s.png" % skjerm
			get_viewport().get_texture().get_image().save_png(fil)
			print("Skjermbilde: ", ProjectSettings.globalize_path(fil))
		match skjerm:
			"start":
				if runder >= (1 if bilder else 3):
					break
				runder += 1
				_start_spill("Ragnvald")
				continue
			"verden":
				_autotest_paa_garden(tatt)
				continue
			"skip":
				if valgt_mal == "" or randf() < 0.3:
					_velg_mal(handeldata["mal"].pick_random()["id"])
			"slutt":
				print("Runde %d ferdig: %s  treller: %d  kontakter: %s  fiender: %d  bygd: %s" % [runder, stats, treller.size(), kontakter.keys(), _fiender_totalt(), bygget.keys()])
		var knapper := []
		for c in _alle_knapper(innhold):
			if not c.disabled and not c.has_meta("ikke_auto"):
				knapper.append(c)
		if knapper.is_empty():
			# Bare «tilbake»-knapper igjen (f.eks. når spilleren ikke har råd til noe): gå tilbake.
			if _alle_knapper(innhold).is_empty():
				push_error("Ingen knapper på skjermen: " + skjerm)
				break
			_tilbake_til_garden()
			continue
		knapper.pick_random().pressed.emit()
	var mangler := []
	for k in _alle_kort():
		if not samling.has(k["id"]):
			mangler.append(k["id"])
	print("Autotest ferdig. Kort samlet: %d/%d. Ikke funnet: %s" % [_antall_funnet(), _alle_kort().size(), mangler])
	get_tree().quit()


func _bilde(navn: String, rull := 0) -> void:
	await get_tree().create_timer(0.5).timeout
	rulle.scroll_vertical = rull
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("user://%s.png" % navn)


# ---------------------------------------------------------------- balansemåling

## Kjør med: godot --headless --path . -- --balanse=300
## Lar noen enkle «spillere» spille mange ganger og skriver ut hvordan det gikk.
## Brukes til å justere tallene i spillet, ikke av elevene.
## «elev» velger én vei per spill og tar et tilfeldig valg i halvparten av sakene.
## Det ligner mer på en elev enn botene som alltid regner ut det beste valget.
const BOTER := ["tilfeldig", "elev", "hjemme", "handel", "tokt"]
var bot_feilrate := 0.0


func _balanse(antall: int) -> void:
	test_modus = true
	print("Balansemåling: %d spill per spillertype" % antall)
	for bot in BOTER:
		var vunnet := 0
		var tap := {}
		var tilnavn := {}
		var solv_slutt := 0.0
		var stotte_slutt := 0.0
		var solv_sum := []
		var solv_n := []
		solv_sum.resize(ANTALL_VINTRE)
		solv_n.resize(ANTALL_VINTRE)
		solv_sum.fill(0.0)
		solv_n.fill(0)
		var forste := {true: [0, 0], false: [0, 0]}
		var ekstra := {}
		for i in antall:
			bot_feilrate = 0.5 if bot == "elev" else 0.0
			var r := _bot_spill(["hjemme", "handel", "tokt"].pick_random() if bot == "elev" else bot)
			if r["tapt"] == "":
				vunnet += 1
				for k in r["ekstra"]:
					ekstra[k] = float(ekstra.get(k, 0.0)) + float(r["ekstra"][k])
				solv_slutt += r["slutt_solv"]
				stotte_slutt += r["sum"]
				var t := _tilnavn(r["sum"])
				tilnavn[t] = int(tilnavn.get(t, 0)) + 1
			else:
				tap[r["tapt"]] = int(tap.get(r["tapt"], 0)) + 1
			for v in r["solv"].size():
				solv_sum[v] += r["solv"][v]
				solv_n[v] += 1
			if r.has("forste_tokt"):
				forste[r["forste_tokt"]][0] += 1
				forste[r["forste_tokt"]][1] += 1 if r["tapt"] == "" else 0
			await get_tree().process_frame
		var snitt := []
		for v in ANTALL_VINTRE:
			snitt.append(int(round(solv_sum[v] / maxi(solv_n[v], 1))))
		print("--- %s: klarte %d %%   tapte på: %s" % [bot, int(round(100.0 * vunnet / antall)), tap])
		print("    sølv ved starten av hver vinter (snitt): %s" % [snitt])
		if vunnet > 0:
			print("    de som klarte det: sølv til slutt %d, sum støtte %d, tilnavn %s" % [int(solv_slutt / vunnet), int(stotte_slutt / vunnet), tilnavn])
			var linje := "    snitt til slutt:"
			for k in ekstra:
				linje += "  %s %.1f" % [k, ekstra[k] / vunnet]
			print(linje)
		for utfall in [true, false]:
			if forste[utfall][0] > 0:
				print("    første tokt %s: %d spill, %d %% klarte alle vintrene" % ["lyktes" if utfall else "gikk galt", forste[utfall][0], int(round(100.0 * forste[utfall][1] / forste[utfall][0]))])
	get_tree().quit()


func _bot_spill(bot: String) -> Dictionary:
	_start_spill("Bot")
	var solv := []
	var sist := 0
	var ut := {}
	for steg in 600:
		if skjerm == "slutt":
			break
		if skjerm != "verden":
			_tilbake_til_garden()
			continue
		if sist != vinter:
			sist = vinter
			solv.append(int(stats["solv"]))
		if not aktive.is_empty():
			_bot_sak(bot, aktive[0])
		else:
			var for_ok := int(logg.get("tokt_ok", 0))
			var for_feil := int(logg.get("tokt_feil", 0))
			_bot_vinter(bot)
			if not ut.has("forste_tokt"):
				if int(logg.get("tokt_ok", 0)) > for_ok:
					ut["forste_tokt"] = true
				elif int(logg.get("tokt_feil", 0)) > for_feil:
					ut["forste_tokt"] = false
			_neste_vinter()
	ut["tapt"] = _tapt()
	ut["solv"] = solv
	ut["slutt_solv"] = int(stats["solv"])
	ut["sum"] = _stottesum()
	ut["ekstra"] = {
		"ære": stats["aere"], "gudene": stats["gudene"], "ætten": stats["aetten"], "bøndene": stats["bondene"],
		"innovasjoner": inno.size(), "treller": treller.size(), "gaver": int(logg.get("gaver", 0)),
		"skip bygd": int(logg.get("skip_bygd", 0)), "tokt": int(logg.get("tokt_ok", 0)) + int(logg.get("tokt_delvis", 0)) + int(logg.get("tokt_feil", 0)), "handel": int(logg.get("handel", 0)),
	}
	return ut


## Hvor mye et sett med effekter er verdt for en spiller som tenker seg om.
## Støtte som er lav, teller mer enn støtte som er høy.
func _bot_verdi(effekter: Dictionary) -> float:
	var sum := 0.0
	for k in effekter:
		if not stats.has(k):
			continue
		var v := float(effekter[k])
		if k == "solv":
			sum += v * 0.7
		else:
			sum += v * clampf(1.0 + (50.0 - float(stats[k])) / 40.0, 0.4, 2.5)
	return sum


func _bot_valgverdi(valg: Dictionary) -> float:
	if valg.has("sjanse"):
		var p := _sjanse(float(valg["sjanse"]))
		return p * _bot_verdi(valg["suksess"].get("effekter", {})) + (1.0 - p) * _bot_verdi(valg["fiasko"].get("effekter", {}))
	if valg.has("motstand"):
		var p2 := _ting_sjanse(int(stats["bondene"]), int(valg["motstand"])) / 100.0
		return p2 * _bot_verdi(valg.get("effekter", {})) - (1.0 - p2) * 5.0
	return _bot_verdi(valg.get("effekter", {}))


func _bot_beste(liste: Array, smart: bool) -> Dictionary:
	if not smart or randf() < bot_feilrate:
		return liste.pick_random()
	var beste: Dictionary = liste[0]
	for v in liste:
		if _bot_valgverdi(v) > _bot_valgverdi(beste):
			beste = v
	return beste


func _bot_sak(bot: String, h: Dictionary) -> void:
	var smart := bot != "tilfeldig"
	if h.has("tingsak"):
		_start_ting(h["tingsak"], _bot_beste(h["tingsak"]["valg"], smart), h)
		_bot_ting(smart)
	elif h.has("rommling"):
		var v: String = "jakt" if smart else ["jakt", "slipp", "fri"].pick_random()
		if v == "jakt" and not _har_rad({"bondene": 5}):
			v = "slipp"
		_flukt_valg(h, v)
	else:
		var mulige: Array = h["valg"].filter(func(v): return _har_rad(_kostnad(v)))
		if mulige.is_empty():
			aktive.erase(h)
			return
		_velg(h, _bot_beste(mulige, smart))


func _bot_ting(smart: bool) -> void:
	if smart:
		for p in tingdata["paavirkning"]:
			if _ting_sjanse(_ting_stotte(), int(ting_valg["motstand"])) >= 75:
				break
			var kost := _kost(p["kost"])
			var trygt := true
			for k in kost:
				if k != "solv" and int(stats[k]) - int(kost[k]) < 35:
					trygt = false
			if trygt and _har_rad(kost):
				_paavirk(p)
	_ting_stem()


func _bot_vinter(bot: String) -> void:
	var smart := bot != "tilfeldig"
	var onsker := []
	match bot:
		"hjemme":
			onsker = ["nyaakeren", "offerlunden", "fjoset", "buret", "smia"]
		"handel", "tokt":
			onsker = ["naustet", "nyaakeren", "offerlunden", "fjoset", "buret", "smia"]
		_:
			for id in steder:
				if _kan_bygges(id) and randf() < 0.35:
					onsker.append(id)
			onsker.shuffle()
	for id in onsker:
		if not bygget.has(id) and _har_rad(_kost(steder[id]["pris"])):
			_bygg(id)
	if bygget.has("naustet"):
		_bot_skip(bot)
	_bot_gaver(bot)
	_bot_innovasjoner(bot)
	var mulige: Array = tingdata["forslag"].filter(func(f): return not vedtatt.has(f["id"]))
	if _tapt() == "" and not ting_brukt and not mulige.is_empty() and (smart or randf() < 0.3):
		var forslag: Dictionary = mulige.pick_random()
		if smart:
			for f in mulige:
				if int(f["valg"][0]["motstand"]) < int(forslag["valg"][0]["motstand"]):
					forslag = f
		_start_ting(forslag, forslag["valg"][0], null)
		_bot_ting(smart)
	_tilbake_til_garden()


## Den beste varen å laste skipet med til dette handelsstedet.
func _bot_vare(m: Dictionary) -> String:
	var beste := ""
	for v in skipdata["varer"]:
		if v.has("krever") and not bygget.has(v["krever"]):
			continue
		if beste == "" or _vare_pris(m, v["id"]) > _vare_pris(m, beste):
			beste = v["id"]
	return beste


func _bot_skip(bot: String) -> void:
	if skip == "":
		if _har_rad({"solv": 15, "bondene": 5}):
			_nytt_skip({"solv": 15, "bondene": 5})
		return
	if skip_borte_til >= vinter:
		return
	var vei := []
	match bot:
		"tokt":
			vei = ["snekke", "skeid"]
		"handel":
			vei = ["knarr", "storknarr"]
		"tilfeldig":
			if randf() < 0.3:
				vei = [skipdata["typer"].pick_random()["id"]]
	for id in vei:
		var s := _skiptype(id)
		if _kan_bygge_skip(s) and _har_rad(_kost(s["pris"])):
			_bygg_skip(s)
			break
	if _skip_hindring() != "":
		return
	# Finn målet som lønner seg best av dem skipet kan nå.
	var maal := ""
	var beste := -999.0
	for m in handeldata["mal"]:
		if _mal_hindring(m) != "" or not _har_rad(_mal_kost(m)) or m["id"] == "bulgar":
			continue
		var verdi := 0.0
		if m["type"] == "tokt":
			if bot == "hjemme" or int(stats["bondene"]) < 30 or int(stats["aetten"]) < 30:
				continue
			var p := _reise_sjanse(m)
			verdi = p * (_bot_verdi(_tokt_gevinst(m)) + 8.0) + minf(TOKT_DELVIS, 1.0 - p) * _bot_verdi(m["delvis"]["effekter"]) + maxf(1.0 - p - TOKT_DELVIS, 0.0) * (_bot_verdi(m["fiasko_effekter"]) - 15.0) - 10.0
			if bot == "tokt":
				verdi += 12.0
		else:
			verdi = _reise_sjanse(m) * _last() * _vare_pris(m, _bot_vare(m)) * 0.7 - float(_mal_kost(m).get("solv", 0)) * 0.7
		if bot == "tilfeldig":
			verdi = randf()
		if verdi > beste:
			beste = verdi
			maal = m["id"]
	if maal != "" and (bot != "tilfeldig" or randf() < 0.5) and (beste > 0.0 or bot == "tilfeldig"):
		_seil(maal, _bot_vare(_mal(maal)) if _mal(maal)["type"] == "handel" else "")


func _bot_gaver(bot: String) -> void:
	for g in gavedata["mottakere"]:
		if gitt.has(g["id"]) or not _har_rad(_kost(g["kost"])) or randf() < bot_feilrate:
			continue
		var vil := false
		if bot == "tilfeldig":
			vil = randf() < 0.25
		elif g["id"] == "ottar":
			vil = not gjengjeld.has("ottar") and not ting_brukt and int(stats["solv"]) >= 30
		elif g["id"] == "frendene":
			vil = int(stats["aetten"]) < 50 or int(stats["solv"]) >= 30
		else:
			vil = int(stats["bondene"]) < 50 or int(stats["solv"]) >= 30
		if vil:
			_gi_gave(g)


func _bot_innovasjoner(bot: String) -> void:
	var kjopt := 0
	for i in innodata["innovasjoner"]:
		if inno.has(i["id"]) or _inno_hindring(i) != "" or kjopt >= 2 or randf() < bot_feilrate:
			continue
		var pris := int(i["pris"])
		if bot == "tilfeldig":
			if randf() < 0.25 and int(stats["solv"]) >= pris:
				_kjop_inno(i)
				kjopt += 1
			continue
		# En spiller som tenker seg om, kjøper det som passer med veien sin, og sparer litt sølv.
		var passer := true
		var v: Dictionary = i["virkning"]
		if v.has("sjanse_tokt") or v.has("skip_tap"):
			passer = bot == "tokt"
		elif v.has("pris_vare") or v.has("pris_alle"):
			passer = bot == "handel"
		elif v.has("sjanse_reise"):
			passer = bot != "hjemme"
		if passer and int(stats["solv"]) >= pris + 12:
			_kjop_inno(i)
			kjopt += 1


func _alle_knapper(node: Node) -> Array:
	var ut := []
	for c in node.get_children():
		if c is Button:
			ut.append(c)
		else:
			ut.append_array(_alle_knapper(c))
	return ut


func _autotest_paa_garden(tatt: Dictionary) -> void:
	var tomter := []
	for id in steder:
		if _kan_bygges(id) and not bygget.has(id) and _har_rad(_kost(steder[id]["pris"])):
			tomter.append(id)
	var r := randf()
	if not tatt.has("ressurs_testet"):
		tatt["ressurs_testet"] = true
		_vis_ressurs(RESSURSER.pick_random())
	elif not tomter.is_empty() and r < 0.15:
		_sted_klikket(tomter.pick_random())
	elif bygget.has("naustet") and _skip_hindring() == "" and r < 0.3:
		_vis_skip()
	elif not ting_brukt and r < 0.4:
		_vis_tinget()
	elif not treller.is_empty() and r < 0.47:
		_vis_treller()
	elif r < 0.54:
		_vis_gaver()
	elif r < 0.61:
		_vis_innovasjoner()
	elif not aktive.is_empty():
		var h: Dictionary = aktive[0]
		_sted_klikket(h.get("sted", "langhuset"))
	else:
		_neste_vinter()


# ---------------------------------------------------------------- tegnede ikoner

## Knutepunkt i innovasjonstreet. Viser en egen, rik infoboks når musa holdes over.
class InnoKnapp extends Button:
	var lag_tips: Callable

	func _make_custom_tooltip(_for_text: String) -> Object:
		return lag_tips.call()


## Sporet mellom knutepunktene i en rad.
class InnoLinje extends Control:
	var farge := Color.WHITE

	func _draw() -> void:
		var y := size.y / 2.0
		draw_line(Vector2(0, y), Vector2(size.x, y), farge, 3.0)


## Enkle strektegninger av redskapene, tegnet i et rutenett på 64 x 64.
class InnoIkon extends Control:
	var id := ""
	var farge := Color.WHITE
	var _s := 1.0
	var _o := Vector2.ZERO

	func _p(x: float, y: float) -> Vector2:
		return _o + Vector2(x, y) * _s

	func _strek(punkter: Array, lukket := false, bredde := 3.0) -> void:
		var pts := PackedVector2Array()
		for q in punkter:
			pts.append(_p(q[0], q[1]))
		if lukket:
			pts.append(pts[0])
		draw_polyline(pts, farge, bredde * _s, true)

	func _flate(punkter: Array, f := Color(0, 0, 0, 0)) -> void:
		var pts := PackedVector2Array()
		for q in punkter:
			pts.append(_p(q[0], q[1]))
		draw_colored_polygon(pts, farge if f.a == 0.0 else f)

	func _ring(x: float, y: float, r: float, fylt := false, bredde := 3.0) -> void:
		if fylt:
			draw_circle(_p(x, y), r * _s, farge)
		else:
			draw_arc(_p(x, y), r * _s, 0, TAU, 32, farge, bredde * _s, true)

	func _bue(x: float, y: float, r: float, fra: float, til: float) -> void:
		draw_arc(_p(x, y), r * _s, fra, til, 16, farge, 3.0 * _s, true)

	func _draw() -> void:
		_s = minf(size.x, size.y) / 64.0
		_o = (size - Vector2(64, 64) * _s) / 2.0
		var svak := Color(farge, 0.35)
		match id:
			# Veiene
			"jorda":
				for x in [18.0, 32.0, 46.0]:
					_strek([[32, 58], [x, 14]])
					_flate([[x, 4], [x + 4, 12], [x, 20], [x - 4, 12]])
				_strek([[22, 40], [42, 40]], false, 4.0)
			"utmarka":
				_flate([[2, 56], [22, 18], [32, 32], [42, 12], [62, 56]], svak)
				_strek([[2, 56], [22, 18], [32, 32], [42, 12], [62, 56]])
				_flate([[42, 12], [48, 24], [42, 21], [37, 24]])
			"skipet":
				_strek([[4, 26], [10, 42], [54, 42], [60, 26]])
				_strek([[32, 42], [32, 6]])
				_flate([[16, 10], [48, 10], [50, 32], [14, 32]], svak)
				_strek([[16, 10], [48, 10], [50, 32], [14, 32]], true)
				for x in [18.0, 32.0, 46.0]:
					_ring(x, 48, 5, true)
			"handverket":
				_strek([[22, 58], [40, 22]], false, 5.0)
				_flate([[26, 8], [56, 22], [50, 34], [20, 20]])
				_strek([[8, 58], [56, 58]])
			# Innovasjonene
			"ard":
				_strek([[6, 18], [42, 44]], false, 4.0)
				_strek([[38, 42], [50, 14]], false, 3.5)
				_strek([[46, 22], [58, 18]])
				_flate([[36, 44], [58, 52], [40, 54]])
				_strek([[4, 58], [60, 58]], false, 2.0)
			"seter":
				_strek([[2, 52], [20, 20], [30, 34], [42, 12], [62, 52]])
				_flate([[22, 44], [32, 34], [42, 44]])
				_flate([[24, 44], [40, 44], [40, 56], [24, 56]])
				_strek([[4, 58], [60, 58]], false, 2.0)
			"fangst":
				for side in [-1.0, 1.0]:
					var x := func(v: float) -> float: return 32.0 + side * v
					_strek([[x.call(4), 44], [x.call(10), 28], [x.call(18), 16], [x.call(24), 4]])
					_strek([[x.call(10), 28], [x.call(22), 26]])
					_strek([[x.call(16), 18], [x.call(26), 14]])
				_flate([[24, 42], [40, 42], [36, 60], [28, 60]])
			"jernvinne":
				_strek([[18, 58], [23, 26], [41, 26], [46, 58]], true)
				_flate([[27, 46], [37, 46], [37, 58], [27, 58]])
				_flate([[32, 4], [39, 15], [36, 22], [28, 22], [25, 15]])
			"kvern":
				_ring(32, 36, 24)
				_ring(32, 36, 7, true)
				_strek([[32, 36], [50, 20]])
				_ring(50, 20, 4, true)
				_bue(32, 36, 16, PI * 0.9, PI * 1.6)
			"tjaere":
				_strek([[18, 26], [14, 41], [18, 58], [46, 58], [50, 41], [46, 26]], true)
				_strek([[16, 34], [48, 34]], false, 2.0)
				_strek([[16, 50], [48, 50]], false, 2.0)
				_flate([[32, 2], [38, 12], [26, 12]])
				_ring(32, 14, 6, true)
			"seil":
				_strek([[32, 4], [32, 46]])
				_flate([[12, 8], [52, 8], [56, 38], [8, 38]], svak)
				_strek([[12, 8], [52, 8], [56, 38], [8, 38]], true)
				for x in [22.0, 32.0, 42.0]:
					_strek([[x, 8], [x, 38]], false, 2.0)
				_strek([[4, 44], [12, 56], [52, 56], [60, 44]], true)
			"vev":
				_strek([[14, 4], [8, 60]])
				_strek([[50, 4], [56, 60]])
				_strek([[8, 8], [56, 8]], false, 4.0)
				for x in [20.0, 26.0, 32.0, 38.0, 44.0]:
					_strek([[x, 8], [x, 48]], false, 1.5)
					_ring(x, 52, 3, true)
				_strek([[16, 30], [48, 30]], false, 3.0)
			"vekt":
				_strek([[32, 10], [32, 56]])
				_strek([[20, 58], [44, 58]], false, 4.0)
				_strek([[6, 16], [58, 16]])
				_ring(32, 10, 3, true)
				for x in [12.0, 52.0]:
					_strek([[x, 16], [x - 7, 36]], false, 1.5)
					_strek([[x, 16], [x + 7, 36]], false, 1.5)
					_flate([[x - 10, 36], [x + 10, 36], [x + 6, 42], [x - 6, 42]])
			"vaapen":
				_flate([[32, 2], [38, 12], [38, 40], [26, 40], [26, 12]], svak)
				_strek([[32, 2], [38, 12], [38, 40], [26, 40], [26, 12]], true)
				_strek([[32, 10], [32, 38]], false, 1.5)
				_flate([[14, 40], [50, 40], [50, 46], [14, 46]])
				_flate([[29, 46], [35, 46], [35, 56], [29, 56]])
				_ring(32, 59, 4, true)
			# Små merker
			"solv":
				_ring(32, 32, 24, true)
				draw_arc(_p(32, 32), 15 * _s, 0, TAU, 24, Color(0, 0, 0, 0.35), 5 * _s, true)
			"hake":
				_strek([[8, 34], [24, 52], [56, 12]], false, 9.0)
			"laas":
				_bue(32, 28, 13, PI, TAU)
				_strek([[19, 28], [19, 32]], false, 6.0)
				_strek([[45, 28], [45, 32]], false, 6.0)
				_flate([[12, 30], [52, 30], [52, 60], [12, 60]])
			_:
				_ring(32, 32, 22)
