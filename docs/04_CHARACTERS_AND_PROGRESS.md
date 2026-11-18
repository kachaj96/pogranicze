# 04 — Postacie, szkoły, towarzysz

## Model postaci
Postać ma identyfikator, parametry walki, zestaw 4 aktywnych umiejętności w pierwszym slice, sloty ekwipunku w ograniczonym zakresie, rozwój i wygląd. Szkoły to **kierunki rozwoju**, a nie twarde klasy wyposażenia.

## Trzy szkoły (projektowe)
- `IRON` / Żelazo: pancerz, osłona, ataki fizyczne, odpychanie i kontrola przejść.
- `ASH` / Popiół: obrażenia obszarowe, ogień, efekty pól i rozprzestrzenianie zagrożeń.
- `WHISPER` / Szept: pieczęcie, klątwy, osłabienia, ochrona i manipulacja pozycją.

Pierwszy test nie wymaga pełnych 3 drzewek — wystarczy kilka umiejętności dowodzących różnych stylów. Docelowo jedna szkoła główna i opcjonalnie dodatkowa, lecz pełny system hybrydowy jest po MVP. Nie twórz 12 klas ani dużych tablic wynikowych statystyk.

## Ekwipunek
Pierwsze warianty mają modyfikować decyzje bojowe (np. siła/odległość odepchnięcia) albo oferować prostą wartość obrony. W slice niewielki zbiór przedmiotów i czytelne UI; żaden generator tysięcy losowych przedmiotów.

## Solo i 2-player
- Solo: 1 postać gracza + 1 towarzysz, który automatycznie podąża podczas eksploracji, a podczas walki jest sterowany przez gracza. Nie wymagamy kompletnej AI towarzysza dla trybu solo.
- Online: 2 postacie graczy; brak towarzysza jako trzeciej jednostki, chyba że graficzny kompan bez wpływu na balans.
- Podstawowe starcia projektowane pod **dwie** postacie po stronie graczy, bez automatycznego mnożnika HP przeciwników za co-op.
- Rejoin w trakcie walki, niezależny zapis wyposażenia gościa i konflikty progresji wymagają testów osobnych.

## Animacje
8 kierunków docelowych dla idle i ruchu. Wstępne zestawy: idle 4 klatki/kierunek, walk 6–8/kierunek. Atak i rzucanie zaklęć docelowo 8 kierunków, prototyp może używać neutralnych animacji i obrotu kierunku dopóki pakiet artu nie przejdzie walidacji. Nie odwracaj asymetrycznej broni/tarczy bez walidacji. Stopy mają stały anchor; sprite może wystawać poza pole logiczne.

## Przeciwnicy MVP
- Rozszczepiony Wilk: szybki kontakt, flankowanie.
- Pusty Strażnik: wolny, blokowanie przejścia, cios liniowy z telegraph.
- Szeptucha Korzeni: przeszkody, spowolnienie, kontrola terenu.
- Boss: Strażnik Pękniętej Pieczęci, odkształca planszę, ataki z zapowiedzią.

Dopiero po udanym prototypie animacji i walki rozwijaj różnorodność przeciwników.
