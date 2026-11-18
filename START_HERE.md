# POGRANICZE — START HERE

Wersja pakietu: 1.0 / 2026-11-18. Język roboczy: polski. Nazwy techniczne: angielski. Repozytorium docelowe: `pogranicze` (JUŻ ISTNIEJE).

## Co to jest

Dokumentacja startowa gry PC (Windows) + Android, Godot 4.x, GDScript, izometryczne 2D dark fantasy pixel art. Nie jest to ukończona gra, repo ani paczka gotowych assetów. To specyfikacja do wdrożenia przez Claude Code w istniejącym repo.

**Najważniejsze:** najpierw działająca mechanika na placeholderach, następnie rygorystyczny test pierwszego stylu w SpriteCook, później właściwe assety. Nie generować hurtowo grafiki, zanim nie zostanie zweryfikowana.

## Instrukcja dla właściciela projektu

1. Otwórz Claude Code z dostępem do istniejącego repozytorium GitHub `pogranicze`.
2. Załącz ZIP, jeśli używana wersja Claude Code obsługuje przesyłanie plików. Jeśli nie, dodaj ZIP do dostępnego katalogu roboczego projektu lub rozpakuj **zawartość** do głównego katalogu repozytorium (bez pośredniego folderu). Nie nadpisuj istniejących plików bez sprawdzenia zmian.
3. Wklej `PROMPT_START_CLAUDE_CODE.md` (dostarczony też jako osobny TXT).
4. Claude ma zidentyfikować repo, sprawdzić istniejące pliki i sam rozpocząć wdrażanie pierwszego etapu. Odpowiadasz tylko na konkretne blokery: autoryzacja SpriteCook, repo, środowisko exportu, ewentualne koszty generowania.
5. Jeśli Claude działa wyłącznie w chmurze i nie ma lokalnego Godota lub Android SDK, powinien tworzyć kod i przeprowadzać dostępne testy, a wymagające sprzętu kroki oznaczyć jako nieweryfikowane. Nie wolno mu deklarować, że sprawdził APK na urządzeniu bez faktycznego testu.

## Kolejność dokumentów

- `CLAUDE.md` — wiążące reguły pracy w repo.
- `docs/00_PRODUCT_BRIEF.md` — tożsamość produktu i ograniczenia.
- `docs/01_GAMEPLAY_AND_SCOPE.md` — pętla, doświadczenie gracza, zakres.
- `docs/02_WORLD_AND_QUEST.md` — lokacje, quest, Blizny Świata.
- `docs/03_COMBAT_AND_MOVEMENT.md` — walki turowe, 8 vs 4 kierunki.
- `docs/04_CHARACTERS_AND_PROGRESS.md` — szkoły, solo, towarzysz.
- `docs/05_ART_DIRECTION.md` — wiążące zasady grafiki.
- `docs/06_CAMERA_INPUT_UI.md` — kamera, PC, Android, czytelność.
- `docs/07_TECH_ARCHITECTURE.md` — projekt Godot, dane, warstwy.
- `docs/08_NETWORK_AND_SAVES.md` — online, zapisy, zabezpieczenia.
- `docs/09_SPRITECOOK_WORKFLOW.md` — połączenie i pipeline.
- `docs/10_MILESTONES.md` — kolejność wykonania, bramki.
- `docs/11_TEST_POLICY.md` — minimalne, celowane testy.
- `docs/12_DECISIONS_AND_ASSUMPTIONS.md` — co zatwierdzone, co jeszcze robocze.
- `docs/13_EXPORT_AND_OPERATIONS.md` — buildy i prowadzenie prac.
- `docs/14_PROGRESS_TEMPLATE.md` — zapis statusu dla kolejnej sesji.

## Referencje wizualne

`references/visual_studies` zawiera wcześniejsze **schematy izometryczne**, a nie finalny art i nie pliki do bezpośredniej integracji w grze. Używaj do rozplanowania kompozycji i siatki. Nie naśladuj ich uproszczonej estetyki jako docelowej. Wcześniejsze realistyczne matte painting nie wyznaczają perspektywy ani techniki renderowania gry.

## Priorytet

Najpierw mała, grywalna wersja, której rdzeń jest przyjemny w eksploracji i taktyce. Zwiększanie rozmiaru świata nie jest sukcesem samym w sobie.
