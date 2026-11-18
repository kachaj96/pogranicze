# 07 — Architektura Godot

## Fundament
Godot 4.x stabilne wydanie, GDScript, render 2D Compatibility w pierwszym przebiegu. Ostateczna wersja silnika powinna być przypięta w README projektu po sprawdzeniu aktualnego środowiska. Nie aktualizuj projektu na niezweryfikowaną wersję tylko dlatego, że jest najnowsza.

## Przykładowe katalogi runtime
```
project.godot
scenes/
  main/
  world/
  interiors/
  combat/
scripts/
  core/
  world/
  combat/
  character/
  network/
  save/
  ui/
data/
  regions/
  abilities/
  enemies/
assets/
  raw/
  final/
  ui/
tests/
docs/
```
Nie twórz pustej struktury katalogów tylko dla wyglądu; nazwy możesz zmienić zgodnie z istniejącym repo, zachowując rozdział odpowiedzialności.

## Składniki
- `GameState` / `SessionState`: aktualny tryb, region, stan rozgrywki.
- `RegionDefinition` (Resource/JSON): podstawowa mapa, wejścia, warianty, obiekty, punkty zdarzeń.
- `WorldState`: trwałe flagi questów/pieczęci, progres, wersja zapisu.
- `RegionRuntime`: buduje mapę z RegionDefinition + WorldState; lokalne ukrywanie dachów NIE jest globalną flagą world state.
- `CombatState`: czysty model planszy z komórkami, blokadami, jednostkami, fazą, punktami akcji/ruchu i efektami.
- `CombatResolver`: przyjmuje komendę (aktor, typ, cel, identyfikator, faza/seq) → waliduje → zapisuje deterministyczny wynik wydarzeń.
- `CombatPresenter`: odtwarza wydarzenia w sprite'ach/animacjach i HUD; nie oblicza obrażeń.
- `ExplorationController`: input PC/Android, ruch i kolizje, interakcje z obiektami.
- `NetworkSession`: peer, host, client, walidacja własności postaci, odpowiedzi i snapshoty.
- `SaveService`: serializacja wersjonowanych rekordów, odczyt/zapis atomowy, brak zapisu payloadów nieznanych typów.

## Sieć i logika
Offline: jeden proces autorytatywny dla obu członków drużyny. Online: host rozpatruje akcje i wysyła zautoryzowany wynik/zmiany stanu. Nie synchronizuj co klatkę wszystkich sprite'ów podczas tur. Ruch eksploracyjny może wymagać interpolacji i kontroli hosta na późniejszym etapie; zachowaj oddzielenie od komend taktycznych.

## Isometria i TileMapLayer
Stosuj `TileMapLayer` dla podłoża i wybranych elementów, osobne sceny dla drzwi, wysokich obiektów, efektów i postaci. TileSet skonfigurowany pod 2:1, odpowiedni Y-sort. Wysokie assety mogą zajmować większy sprite niż pole kolizji. Nie polegaj na wizualnych pikselach do obliczania ścieżek.

## Dane zamiast hardcodowania
Przeciwnicy, zdolności, pozycje spawnów, bazowe statystyki, teksty dialogów, flagi questów i warianty regionów w czytelnych zasobach. Zapis nie powinien serializować bezpośrednio całego drzewa scen.

## Import assetów
Dla zaakceptowanych PNG alpha, nearest filter, bez przypadkowego mipmap/blur, stabilne anchors, metadata rozmiarów i pochodzenia. Atlasy tylko jeśli dają realną korzyść, nie jako przedwczesna optymalizacja.

## Kryteria architektoniczne
Po zmianie sprite'a nie trzeba modyfikować CombatResolver; po zmianie zasad ruchu testy nie zależą od gotowej mapy; zapis odtworzy stan pieczęci i położenie drużyny; identyczna komenda walki przy identycznym stanie daje identyczny wynik (z kontrolowanym seedem RNG, gdy się pojawi).
