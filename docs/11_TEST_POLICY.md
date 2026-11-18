# 11 — Polityka testów: szybka produkcja, brak pozornego QA

## Zasada nadrzędna
Testuj **tylko to, na co realnie wpływa zmiana**, chyba że zmiana dotyczy kontraktu wspólnego lub osiągnięto bramkę integracyjną. Brak testu tam, gdzie jest zbędny; brak pomijania testu tam, gdzie może zepsuć save, synchronizację, walkę lub uruchomienie gry.

## Po każdej zmianie
- Rozważ, czy kod się importuje/parsuje. Jeśli dotknięto skryptów Godot — szybki `--headless --path ... --editor --quit` / odpowiednik kompatybilny z zainstalowaną wersją. **Nie uruchamiaj pełnej gry** dla zmian README/tekstów/kolorów.
- Następnie jedna lokalna weryfikacja właściwego modułu/sceny, np. walidacja A* po zmianie movement, albo test kolizji po zmianie mapy.
- Nie pisz wielkiej suite tylko po to, aby wykonać test; krótkie testy czystej logiki są preferowane.

## Matryca wpływu
| Zmiana | Minimalna weryfikacja | Pełna regresja? |
|---|---|---|
| Dokumentacja / copy | Odczyt / lint jeżeli istnieje | Nie |
| Sprite lub tileset | Import PNG + podgląd jednej sceny | Nie |
| CombatResolver / AP / path | Testy legalności ruchu, obrażeń i fazy; 1 walka | Tylko gdy kontrakt zmieniony |
| Eksploracja / kamera | Odpowiednia mapa, przejście lub UI | Nie |
| UI PC | Zmodyfikowany panel na PC | Nie |
| UI Android | Zmodyfikowany panel/touch flow na Androidzie, gdy dostępny | Nie |
| WorldState/save | Round-trip save/load + wariant pieczęci | Część scen zależnych |
| Multiplayer/protokół | Host + client, 2–3 akcje, zgodność stanu | Tak przy bramce sieciowej |
| Godot version/export settings | Import + szybka kontrola eksportu | Smoke odpowiedniej platformy |
| Release/beta milestone | Ścieżka eksploracja→walka→wybór→save→load | Tak, raz na bramce |

## Definicja testu minimalnego
Najtańszy test, który realnie może wykryć regresję danego wymagania. `PASS` tylko po uruchomieniu. `NOT RUN` jeżeli brak Godota, pakietu Android SDK, podpiętego telefonu, drugiego klienta lub konfiguracji połączenia. Wskaż brakujące narzędzie i komendę/instrukcję do samodzielnego wykonania.

## Regresja nie jest domyślna
Nie uruchamiaj wszystkich scen po każdej zmianie, nie rób screenshotów każdego UI, nie przebudowuj Windows+Android przy każdej edycji skryptu, nie odpytuj całego repo wielokrotną analizą, nie mnoż podobnych testów.

## Kryteria minimalne, których nie wolno pominąć
- Combat: niedozwolona akcja nie zmienia stanu; nie istnieje ruch diagonalny po siatce; AP/MP nie schodzą poniżej zera; nie ma powtórnego wykonania komendy sieciowej.
- Save: zmiana pieczęci jest identyczna po odczycie, format wersjonowany.
- Online: peer nie może wydawać poleceń postaci innego gracza; stan hosta rozstrzyga konflikty.
- Android UI: dotknięcie pola da się anulować, gracz widzi zasięg i koszt.
- Assets: poprawna siatka i alpha przed wrzuceniem do `assets/final`.

## Raport testów
`Component | Change | Check | Result (PASS/FAIL/NOT RUN) | Notes`. Krótko, bez zmyślania benchmarków FPS i „wszystko OK” bez konkretnych dowodów.
