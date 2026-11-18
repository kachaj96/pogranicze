class_name UiText
extends RefCounted
## Polish UI strings for rule codes. Code identifiers stay English.

const REASONS := {
	"duplicate": "Ta komenda została już wykonana.",
	"battle_over": "Walka zakończona.",
	"unknown_unit": "Nieznana jednostka.",
	"unit_dead": "Ta postać nie żyje.",
	"not_owner": "To nie Twoja postać.",
	"wrong_phase": "Teraz nie jest faza tej drużyny.",
	"already_ready": "Zakończono już fazę - czekasz na drugiego gracza.",
	"invalid_target": "Niedozwolony cel.",
	"unreachable": "Nie da się tam dojść.",
	"not_enough_mp": "Za mało PR (punktów ruchu).",
	"not_enough_ap": "Za mało PA (punktów akcji).",
	"out_of_range": "Poza zasięgiem.",
	"no_line_of_sight": "Brak linii wzroku.",
	"not_in_line": "Cel musi być w linii prostej lub ukośnej.",
	"unknown_ability": "Postać nie zna tej umiejętności.",
	"unknown_command": "Nieznana komenda.",
	"missing_id": "Błąd komendy (brak id).",
	"missing_peer": "Błąd komendy (brak gracza).",
}


static func reason(code: String) -> String:
	return REASONS.get(code, code)
