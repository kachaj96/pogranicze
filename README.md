# POGRANICZE

Dark fantasy RPG, izometryczny pixel art 2:1, turowa walka taktyczna. PC Windows + Android.
Dokumentacja projektu: `START_HERE.md`, `CLAUDE.md`, `docs/`. Aktualny stan: `docs/PROGRESS.md`.

## Silnik

**Godot 4.7.2-stable** (standard, nie .NET), GDScript, renderer Compatibility.
Nie podbijaj wersji bez sprawdzenia importu i testów.

## Uruchomienie

Otwórz folder w Godot 4.7.2 i uruchom (F5). Menu → „Walka próbna”.

Sterowanie PC: klik = wybór/potwierdzenie (podgląd pod kursorem), 1-4 umiejętności, M ruch,
Tab następna postać, Spacja/Enter koniec tury, Esc anuluj, kółko zoom, przeciągnięcie LPM = przesuwanie kamery.
Android: tap = podgląd, drugi tap w to samo pole = potwierdzenie, „Anuluj” cofa; pinch zoom, przeciąganie = kamera.

## Testy

```
godot --headless --path . --import                              # raz, po zmianie skryptów/klas
godot --headless --path . -s res://tests/run_tests.gd           # logika walki
godot --headless --path . -s res://tests/smoke_combat_scene.gd  # scena walki (klik + pełna bitwa)
```

Zrzut ekranu sceny (wymaga ekranu, np. `xvfb-run`):
```
godot --path . --rendering-driver opengl3 -s res://tools/capture.gd -- res://scenes/combat/combat.tscn out.png 40
```

## Struktura

- `scripts/combat/` - czysty model walki (`CombatState`, `CombatRules`, `CombatResolver`, `CombatAI`), bez renderowania.
- `scripts/combat/view/` - prezentacja planszy i jednostek (placeholdery rysowane kodem).
- `scripts/combat/combat_controller.gd` - wejście, komendy do resolvera, odtwarzanie zdarzeń.
- `scripts/ui/` - HUD, menu, teksty UI.
- `data/` - zdolności, jednostki, starcia (JSON). Eksport: `data/*.json` w include filter.
- `assets/raw` wejście z generatora, `assets/final` tylko zatwierdzone assety.
- `references/` - szkice kompozycyjne, wyłączone z importu Godota (`.gdignore`).
