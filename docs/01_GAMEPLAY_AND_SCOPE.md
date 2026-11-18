# 01 — Gameplay i granice zakresu

## Pętla
Osada (rozmowy, wyposażenie) → wyprawa (eksploracja, ryzyko, odkrycia) → spotkanie / walka / loch → wynik i decyzja → rozwój oraz widoczna zmiana świata → powrót lub dalsza wyprawa.

## Eksploracja
- Swoboda tras w ramach połączonych regionów; regiony ładowane jako sceny/chunki, nie jedna nieskończona mapa.
- Wnętrza małych domów: dach lokalnie znika / frontowe ściany stają się niewidoczne; większe budowle mają osobne sceny.
- Niezbędne obiekty: drzwi, NPC, skrzynie/notatki, punkt przejścia, wejście do lochu, zdarzenie aktywujące bitwę.
- Dialogi informują o świecie. Jedna linia questu bez stałej prowadzącej strzałki wystarczy w slice; dostępny dziennik ma zapobiegać zagubieniu.
- Wrogi poziom zagrożenia wynika z konkretnego miejsca i sygnalizacji, nie jednolitego automatycznego level scalingu. Solo ma równoważną dwuosobową drużynę (gracz + towarzysz), więc nie trzeba mnożyć HP wrogów w co-op.

## Taktyka
Bitwy w sąsiedztwie miejsca spotkania. Strefy bojowe osadzone wizualnie na mapie eksploracji, ale logicznie kontrolowane (np. 10x10/12x12) z czytelną siatką i przeszkodami. Domyślne AP/MP i fazy opisane w `03_COMBAT_AND_MOVEMENT.md`.

## Prototyp i vertical slice
**Prototyp:** minimalne mechaniki na placeholderach, bez rozległych fabuł. **Vertical slice:** jedna kompletna przygoda z wybraną grafiką, dźwiękiem i prawdziwym UX. Nie mieszaj tych celów.

## Zakres etapowy
Pierwszy zakres: jedna osada, jeden fragment lasu, jedna kaplica/krypta, dwa stany lasu, 2 grane postacie, 3 typy wrogów + boss (boss może dojść na późnej bramce), trzy szkoły koncepcyjne (mechanicznie ograniczona podpróba), 4 używalne umiejętności na postać w slice, ekwipunek minimalny, jeden quest rozgałęziony, jedno save slot MVP, PC+Android, LAN + podstawowa obsługa połączenia internetowego zgodnie z rzeczywistymi ograniczeniami środowiska.

## Antyscope
Na MVP nie implementuj: RPG z setkami itemów, generowania regionów AI w czasie gry, PvP, chatu globalnego, aukcji, achievementów, systemów głodu, budowania osad, dynamicznej ekonomii, housing, systemu reputacji we wszystkich frakcjach, proceduralnego nieskończonego podziemia, ogromnego drzewka umiejętności.

## Próg jakości
Po pierwszych kilku starciach gracz powinien rozumieć i przewidywać wyniki akcji. Jeśli walka nie daje satysfakcji na placeholderach, nie dodawaj animacji i kolejnych lokacji — popraw reguły i tempo.
