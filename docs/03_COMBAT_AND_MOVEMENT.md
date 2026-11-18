# 03 — Walka i ruch: formalne reguły

## Geometria
Kwadratowa **logiczna** siatka walki o współrzędnych całkowitych `(col,row)`. Projekcja ekranu 2:1 z prototypowymi wymiarami kafla `64×32`: `screen_x = origin_x + (col - row)*32`, `screen_y = origin_y + (col + row)*16` (bez wysokości sprite'a). Render i logika muszą być rozdzielone. Dopuszczalne korekty rozmiaru i origin po walidacji urządzeń.

## Eksploracja
Płynne sterowanie w 8 kierunkach we współrzędnych świata, opcjonalne click-to-move/tap-to-move. Wektory diagonalne znormalizowane do tej samej prędkości. Obowiązuje kolizja z terenem i postaciami; nie wolno przecinać narożników dwóch blokujących przeszkód. Widok postaci: docelowo osiem facingów (N, NE, E, SE, S, SW, W, NW), w zgodzie z projekcją i obrotem sprite'a. W trybie dotykowym wyznaczanie ścieżki ma unikać diagonalnego corner cutting.

## Walka
- Zwykle jedna instancja starcia `10×10`–`12×12` pól; konkretne układy mogą się różnić.
- Dostępny ruch po 4 sąsiadach `(±1,0),(0,±1)`, każda sąsiadująca komórka o koszcie podstawowym 1 MP; brak kroków diagonalnych. Można mierzyć zasięg manhattanowski; konkretne zaklęcie może mieć osobny kształt (linia, krzyż, romb, okrąg, osiem kierunków).
- Startowe wartości postaci (robocze): 6 PA i 3 PR; inne stany modyfikują wartości. Akcja kosztuje PA; ruch kosztuje PR.
- Kolejność: wspólna faza drużyny → faza AI. Dwie postacie w fazie drużyny mogą wykonywać akcje naprzemiennie. Host rozpatruje komendy **jedną po drugiej**, waliduje i wysyła wynik — brak rzeczywistej równoległości akcji.
- Zasady podstawowe: occupied cell, wall, line-of-sight, attack range, AP/MP, blocked tiles, turn ownership, hit/impact effects, death/state transitions. Bez zaszywania reguł w sprite'ach lub UI.
- Zasięg, przesunięcie i obszar działania wyświetl przed potwierdzeniem. Podgląd skutku ma odpowiadać wynikom logiki.

## Pola specjalne
`CRACK`: obrażenia/efekt za wejście lub zakończenie tury (dokładna reguła jedna i udokumentowana); `SEAL`: aktywacja interakcją lub zdolnością; `ANOMALY`: przemieszczenie/ograniczenie ruchu. Nie ma losowych niewidocznych efektów. Teren działa na wrogów i sojuszników według spójnych reguł.

## Prototyp czterech umiejętności na archetyp
- Basic attack: obrażenia na 1–2 pola, koszt np. 3 PA.
- Push: przemieszczenie przeciwnika o 1 pole (kolizje!), koszt np. 3 PA.
- Zone spell: wybrane pole + przyległe pola, 4 PA, widoczny obszar.
- Ward/control: nałożenie stanu lub uruchomienie pieczęci, 3 PA.
Liczby są robocze. Ważniejsza od balansu na starcie jest czytelność interakcji i powtarzalność wyniku.

## Przykładowy test logiki
Drużyna A/B, przeciwnik E, blokujący słup na polu (3,3). A ma 3 PR, nie może przejść przez słup ani przeciwnika; wejście po przekątnej jest niedozwolone. A odpycha E na `CRACK`, host stosuje efekt; B wybiera umiejętność Szeptu w tym samym etapie; następnie faza AI. Próba akcji o zbyt wysokim koszcie lub za ścianą ma zostać odrzucona bez zmiany stanu.

## Interfejs
Rozróżnij aktywnego bohatera, kontrolowaną drużynę, sojusznika, wroga, przeszkody i pole niebezpieczne. Na Androidzie dwustopniowe zatwierdzanie ataku/ruchu po tapnięciu (wybór → podgląd → potwierdzenie) z opcją anulowania. Nie dopuszczaj „ślepych” naciśnięć.

## Przyszłe decyzje
Inicjatywa w obrębie fazy, krytyki, opór, obrażenia środowiskowe i finalny balans — po prototypie. Nie dodawaj skomplikowanych statystyk, zanim nie zadziała walka z podstawowymi regułami.
