# POGRANICZE — status

Data: 2026-11-18
Gałąź: `ccr-f7bfb621-4so2ob` (push OK)
Etap: M0 zamknięty, M1 (combat proof) zrealizowany na placeholderach. Następny: M2.

## Co działa teraz (dowód)
- Projekt Godot 4.7.2 importuje się i startuje (headless + render pod Xvfb/llvmpipe).
- Menu → walka 10×10 „Polana w Starym Lesie”: 2 postacie gracza (Wędrowiec IRON, Wiera WHISPER/ASH), 3 wrogów (Wilk, Strażnik, Szeptucha).
- 6 PA / 3 PR, ruch 4-sąsiedni (BFS, omija szczeliny przy równej długości), ataki 8-kierunkowe, LoS (ściany i jednostki blokują), pchnięcia z kolizją i blokadą narożników, szczelina CRACK, osłona (ward), fazy drużyna → AI, gotowość per właściciel (pod co-op), idempotentne komendy, snapshot `to_dict/from_dict`.
- Podgląd akcji liczony przez ten sam resolver na kopii stanu. PC: hover + klik. Dotyk: tap → podgląd → tap = potwierdź, Anuluj.
- Proste AI (dowolna drużyna), pełna bitwa kończy się (5 rund).

## Placeholdery
Cała grafika rysowana kodem (romby, bloki, figury). Brak audio. Brak eksploracji, sieci, zapisu.

## Reguły ustalone w implementacji (odwracalne)
- CRACK: 3 obr. przy każdym wejściu na pole (ruch lub pchnięcie); stanie jest bezpieczne.
- Kolizja przy pchnięciu: 2 obr. × niewykorzystane pola; tylko pchnięta jednostka.
- Zasięg: per umiejętność `manhattan` lub `chebyshev` (melee chebyshev = 8 kierunków).
- Obszarowe nie ranią sojuszników (`friendly_fire` w danych, domyślnie false).
- Osłona wygasa na początku następnej fazy własnej drużyny.
- Facing 0..7 = N, NE, E, SE, S, SW, W, NW względem ekranu; siatka (+1,0) = SE.
- Peer AI = 0; komenda `peer` ma ustawiać host, nigdy payload klienta.

## Testy
| Komponent | Check | Wynik | Uwagi |
|---|---|---|---|
| Import projektu | `--headless --import` | PASS | Godot 4.7.2 |
| Logika walki | `tests/run_tests.gd` (17 testów) | PASS | ruch bez przekątnych, PA/PR ≥ 0, LoS, push/crack/kolizja, ward, duplikat komendy, właściciel/faza, determinizm, podgląd = wynik, pełna bitwa |
| Scena walki | `tests/smoke_combat_scene.gd` | PASS | klik myszy → ruch; pełna bitwa przez kontroler i animacje; widoki zgodne ze stanem |
| Render PC 1280×720 | zrzut przez `tools/capture.gd` | PASS (wizualnie) | HUD, zasięg, obszar, komunikat LoS |
| Android build/urządzenie | - | NOT RUN | brak export templates, SDK i telefonu w chmurze |
| Windows build | - | NOT RUN | eksport dopiero na bramce |
| Sieć | - | NOT RUN | M3 jeszcze nie zaczęty |

## Ryzyka zauważone
- Czytelność Androida: przy 20:9 pole ma ok. 24×47 dp (telefon 2400×1080, ~420 dpi), poniżej zalecanych 48 dp. Łagodzi to dwustopniowe potwierdzanie i pinch zoom, ale rozmiar kafla/zoom walki trzeba zweryfikować na telefonie (A01).
- Zoom niecałkowity jest OK dla placeholderów; dla pixel artu trzeba przejść na kroki całkowite.

## SpriteCook
- Plugin nie da się włączyć z aplikacji mobilnej Claude. Wariant przyjęty: serwer MCP jako custom connector claude.ai (`https://mcp.spritecook.ai/mcp/claude`, OAuth) + oficjalne skille skopiowane do `.claude/skills/` (MIT, źródło w `.claude/skills/SPRITECOOK_SOURCE.md`).
- Serwer osiągalny z kontenera (401 = wymaga logowania). Kredyty i modele jeszcze niesprawdzone, zero generacji.
- Istotne z dokumentacji: tileset `perspective="isometric"`, `piece_set="isometric-2x4-64"` pasuje do kafla 64×32; pixel art domyślnie `gemini-nano-banana-2.1`, ok. 12 kredytów za 1K (do potwierdzenia `list_generation_models`); postać izometryczna przez `generate_character(perspective="isometric")`.
- Plan M5: `get_credit_balance` → `list_generation_models` / `list_tileset_options` → 1 tileset podłoża + 1 postać wzorcowa → stop na ocenę. Manifest: `assets/raw/spritecook/spritecook-assets.json` (tylko asset_id, sha12, label).

## Grafika proceduralna (test stylu, review: pending)
- Pipeline bez kosztów: Blender 4.5.4 LTS (Cycles CPU) renderuje przebiegi danych (światło, AO, indeks materiału, cień), `tools/art/pixelize.py` mapuje je na rampy palety z Art Bible + selektywny kontur. Teren: `tools/art/gen_terrain.py` (PIL).
- Kamera: ortho, elewacja 30°, azymut 45° = dokładne 2:1, 1 jednostka = 1 pole = 64×32 px. Światło z lewej góry.
- Gotowe (w `assets/raw/procedural`, manifest `manifest.json`): Wędrowiec 8 kierunków × idle 4 + walk 8 klatek (klatka 192×144, anchor 80,128), chata 3×2, drzewo, kamień pieczęci, blok kamienny, 5 kafli podłoża.
- Odtworzenie: `BLENDER=... tools/art/build_all.sh` (ok. 1 min). Blender nie jest w repo; w nowej sesji pobrać 4.5.4 LTS z download.blender.org.
- Podgląd: menu → „Podgląd grafiki”, scena `scenes/art/art_showcase.tscn` (zoom 2×).
- Słabe strony: brak kafli przejściowych trawa/ścieżka, dach bez faktury gontu, postać prostsza niż ręczny pixel art, brak animacji ataku.

## Blokery wymagające człowieka
1. Dodać custom connector SpriteCook na claude.ai (przeglądarka) i zalogować się OAuth, potem nowa sesja.
2. Test na telefonie Android (później, przy bramce M2/M5).

## Następne kroki
1. M2: scena eksploracji (osada), ruch 8-kierunkowy znormalizowany, kolizje, NPC/dialog, wejście do domu z fade dachu, wejście w walkę.
2. M3: NetworkSession (ENet, host autorytatywny) na istniejącym kontrakcie komend.
3. Po włączeniu SpriteCook: sprawdzenie kredytów i pierwszy asset referencyjny.
