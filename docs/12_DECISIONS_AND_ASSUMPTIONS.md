# 12 — Decision Register (stan 18.11.2026)

## Zatwierdzone przez użytkownika / wiążące
| ID | Decyzja |
|---|---|
| D01 | POGRANICZE — dark fantasy RPG z eksploracją otwartych regionów, miasteczkami, wnętrzami, lochami i zamkami docelowo. |
| D02 | Taktyczna walka turowa inspirowana Dofusem (oryginalne systemy i oprawa). |
| D03 | Solo + dwóch graczy online; projektuj skalowanie tak, by solo nie było gorszą grą. |
| D04 | Blizny Świata: decyzje gracza trwale zmieniają wybrane stany regionów i walki. |
| D05 | Windows PC i Android, jeden świat i mechanika, osobne sterowanie i HUD. |
| D06 | Izometryczny rzut 2:1 w 2D, detaliczny mroczny pixel art, kierunek v0.4 zaakceptowany jako roboczy. |
| D07 | W exploracji 8 kierunków swobodnego ruchu; w walce 4 sąsiadujące pola logiczne, 8 kierunków celowania; docelowo 8 kierunków animacji. |
| D08 | Godot 4.x, SpriteCook jako generator assetów, Claude Code w istniejącym repo `pogranicze`. |
| D09 | Testy tylko niezbędne dla zmiany; pełna regresja tylko przy bramce lub zmianie wysokiego ryzyka. |
| D10 | Wcześniejsze realistyczne obrazy NIE stanowią finalnego pixel-artowego standardu. |

## Propozycje autorów specyfikacji — odwracalne
| ID | Element | Wartość startowa | Kiedy potwierdzić |
|---|---|---|---|
| A01 | Rozmiar kafla | 64×32 px | Próbny import i Android |
| A02 | Drużyna | 2 aktywne jednostki w solo/co-op | Pierwszy prototyp |
| A03 | Punkty walki | 6 AP / 3 MP | Pierwsze 3–5 bitew |
| A04 | Fazy | Drużyna → AI; komendy w kolejności hosta | Wspólny CombatResolver |
| A05 | 3 szkoły | Żelazo / Popiół / Szept | Iteracja postaci |
| A06 | Wnętrza | Dach fade małe; osobna scena duże | M2 |
| A07 | Host authority | WorldState kampanii hosta; gość ma własną postać | M3/M4 |
| A08 | Polityka decyzji | Host decyduje o zmianie świata | M4 |
| A09 | Renderer | Compatibility | Test Android |
| A10 | Platformy | Android landscape | UI smoke test |
| A11 | Pierwszy quest | Pieczęć: SEALED / BROKEN | M4 |
| A12 | 4 umiejętności postaci | Atak, push, obszar, ward | M1/M4 |

## Nieustalone / nie blokują rozpoczęcia
- Nazwa finalna gry (POGRANICZE roboczo pozostaje).
- Kompletna opowieść, frakcje i rozmiar całego świata.
- Produkcyjna paleta pixel art, rozdzielczość bazowa, dokładne rozmiary wszystkich sprite'ów i finał HUD.
- Ostateczny balans, XP, loot tables, statusy, endgame.
- Docelowy system NAT traversal/relay/lobby bez konfiguracji portów.
- Android release signing, publikacja, minimalne system specs.

## Zasada decyzyjna
Claude może sam wybrać odwracalne detale implementacji (dokładny kształt testowej siatki, nazwa sygnału, układ katalogów) i wpisać je do PROGRESS. Nie może bez zgody zmieniać rdzenia (platforma, rzut 2:1, 8/4, model single/co-op) ani wydawać znaczących środków/kredytów SpriteCook.
