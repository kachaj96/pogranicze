# CLAUDE.md — POGRANICZE

## Właściciel projektu i język
Pracujesz w istniejącym repozytorium `pogranicze`. Użytkownik zatwierdził kierunek gry; nie wracaj do pytań o gatunek, platformę, perspektywę lub model walki. Rozmawiaj z nim po polsku, prosto i technicznie, bez marketingu i wypełniaczy. Nazwy klas, plików, funkcji, scen i komentarzy w kodzie po angielsku.

## Hierarchia prawdy
1. Jawna nowa decyzja użytkownika.
2. Ten plik i `docs/12_DECISIONS_AND_ASSUMPTIONS.md`.
3. Specyfikacje w `docs/`.
4. Istniejący kod i ograniczenia środowiska (zgłaszaj kolizje, nie zakładaj, że są poprawne).
5. Własne rozsądne decyzje w sprawach niezamkniętych, dokumentowane w logu.

## Kontrakt gry
- PC Windows + Android, cross-play 2 osób, gra solo pełnowartościowa.
- Godot 4.x stabilny, GDScript, czyste 2D, Compatibility jako start.
- Styl: detailed dark fantasy pixel art, Wounded Medieval Fantasy. Rzut izometryczny 2:1, bez rotacji kamery. Kafel orientacyjny 64×32 px, do walidacji.
- Eksploracja: 8 kierunków swobodnego ruchu po płaszczyźnie świata (w tym przekątne), prędkość znormalizowana. Walka: ruch 4-sąsiedni po kwadratowej logicznej siatce przedstawionej jako romby 2:1; ataki mogą celować w 8 kierunkach. Docelowe animacje postaci 8-kierunkowe.
- Walka turowa: domyślnie 6 AP i 3 MP; wspólna faza drużyny i faza przeciwników. Rozstrzyganie akcji sekwencyjne i autorytatywne; nie udawaj synchronicznej symulacji przy dwóch klientach.
- Solo = postać + jeden kontrolowany w walce towarzysz. Co-op = dwóch graczy, każdy swoją postacią. Nie buduj MMO.
- Świat: ręcznie projektowane regiony, wnętrza, questy odkrywane przez eksplorację, trwałe zmiany Blizn Świata.
- Pierwszy fragment: Zimny Bród → Stary Las → Stara Kaplica → wybór losu pieczęci → zmiana lasu i kolejnej walki.

## Operacje na repo
- Na początku: sprawdź branch, status Git, strukturę repo, projekt Godota i zależności. Nie zakładaj pustego repo.
- Nie kasuj ani nie nadpisuj cudzych plików bez potrzeby. Nie używaj `git reset --hard`, `push --force`, czyszczenia gałęzi, niebezpiecznego refaktoringu.
- Zachowaj pracę, realizuj małe logiczne commity; push tylko jeśli połączenie i uprawnienia pozwalają, bez obchodzenia zabezpieczeń.
- Jeśli użytkownik dostarczył ZIP: rozpakuj względnie do root, wykryj konflikty; zmerguj dokumentację, nie duplikuj katalogów i nie usuwaj innej pracy.
- Trzymaj repo aktualne: `docs/14_PROGRESS_TEMPLATE.md` jako wzór, rzeczywisty stan w `docs/PROGRESS.md`.

## Zakres i priorytety
1. Audyt repo + minimalny szkielet i działająca scena.
2. Grający się turowy prototyp z placeholderami.
3. Eksploracja i przejścia do wnętrz.
4. Fundamenty online i weryfikacja dwóch klientów (gdy środowisko pozwala).
5. WorldState, zapis, jedna rozgałęziona decyzja.
6. Pipeline SpriteCook, ograniczony Art Validation Pack, integracja zatwierdzonych assetów.
7. Vertical slice i eksporty. Nie próbuj implementować wszystkich etapów w jednym niekontrolowanym commicie.

## SpriteCook
- Preferuj oficjalny plugin `https://github.com/SpriteCook/claude-plugin`, MCP + skills, autoryzacja OAuth. Zweryfikuj dostępność w bieżącym Claude Code. Gdy niedostępny, podaj użytkownikowi dokładne kroki lub bezpieczny plan awaryjny.
- Bez kosztownej masowej generacji bez weryfikacji modelu, kredytów, zgodności i zatwierdzonego głównego assetu. Najpierw 1–3 próbne assety; wykorzystaj identyfikator assetu referencyjnego dla spójności.
- `assets/raw` to wejście, `assets/final` to zatwierdzone zasoby. Nie przenoś automatycznie błędnych sprite'ów do final.
- Nigdy nie zapisuj kluczy API, sekretów, tokenów, podpisów release ani prywatnych URL-i z tokenem w Git/komentarzach/promptach.

## Testowanie — ekonomia czasu
- Po małej zmianie: tylko test dotkniętego modułu / importu / sceny, szybka walidacja składni.
- Po zmianie wspólnego modelu danych, zapisu, walki, sieci, kamery, pipeline'u eksportu: trafne testy integracyjne.
- Pełna regresja wyłącznie na bramkach etapów lub przy realnym ryzyku zmiany przekrojowej, nie po każdej edycji.
- Eksport APK i Windows tylko przy konfiguracji narzędzi, zmianie krytycznej dla platformy albo na bramce wydania. Nie buduj APK po każdym commicie.
- Testy sieciowe na dwóch klientach dopiero po zmienianiu sieci/synchronizacji, nie na każdej zmianie grafiki.
- Wynik: PASS / FAIL / NOT RUN z przyczyną. Nigdy nie deklaruj testu wykonanego, jeśli narzędzia niedostępne.
- Nie dodawaj nadmiarowych frameworków testowych, gigantycznej CI ani testów snapshotowych grafiki bez wykazanej potrzeby.

## Kryteria jakości
- Logika walki, świata i zapisu rozdzielona od renderowania i wejścia.
- Dane przeciwników, zdolności, statystyk i regionów, nie zaszyte w UI.
- Pozycjonowanie, trafianie, odmowa niedozwolonych akcji i brak duplikacji komend sieciowych.
- Raster kafli 2:1 i punkty zakotwiczenia obiektów; zero mieszania rzutu izometrycznego z 3/4 perspektywą kamerową.
- Na telefonie czytelne pola i przewidywalny dotyk; interfejs responsive, nie tylko skalowany HUD PC.
- Małe, grywalne, uczciwie opisane efekty zamiast wielkiej ilości niedokończonych systemów.

## Kiedy pytać użytkownika
Tylko w przypadku realnej blokady: SpriteCook OAuth/koszt, dostęp repo, instalacja na jego komputerze, podpisy, konieczna decyzja wpływająca na fundamentalny kierunek. W przeciwnym razie wybierz rozsądną opcję odwracalną, opisz ją i kontynuuj.

## Raport końca etapu
Co działa; które pliki zmieniono; co zostało sprawdzone (konkretnie); czego nie dało się sprawdzić; ewentualny commit; 1–3 następne kroki i jednoznaczne czynności wymagające użytkownika. Bez fałszywych potwierdzeń.
