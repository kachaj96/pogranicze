# 10 — Plan implementacji i bramki

Zasada: małe pionowe przekroje działającego produktu, nie monolityczny sprint na całą grę. Przy każdym etapie dopisz aktualny `docs/PROGRESS.md` z działającymi funkcjami i nierozwiązanymi blockerami.

## M0 — Repo audit / bootstrap
**Deliverable:** potwierdzony branch, zmergowana dokumentacja, wybrana wersja Godot, `.gitignore`, minimalny projekt ze sceną startową, uruchamiający się lokalnie jeśli narzędzia są dostępne; status SpriteCook, lista czynności po stronie użytkownika.
**Gate:** brak usuwania istniejących elementów bez porównania; projekt otwiera się i startuje albo `NOT RUN` z przyczyną. Nie wymaga jeszcze assetów AI.

## M1 — Combat proof (pierwsza grywalna rzecz)
**Deliverable:** strefa 10×10, dwie postacie po stronie gracza, 2–3 wrogów, selekcja pola, 6 AP/3 MP, pathfinding 4 sąsiedzi, ściany, LoS, legalne/nielegalne akcje, 4 zdolności, fazy, proste AI; debug HUD. Placeholdery.
**Gate:** jedna kompletna bitwa bez zawieszeń; AP/MP i occupancy prawidłowe, push i terrain effect działają. **Minimalne testy logiki** przy zmianach resolvera.

## M2 — Eksploracja / wnętrza
**Deliverable:** mała osada + wejście do domu + ścieżka do fragmentu lasu; swobodny 8-kierunkowy ruch, dialog z NPC, interakcje, kamera, dach/ściany fade, przejście do M1 bez sztucznego rozdziału mechaniki.
**Gate:** przemieszczanie i interakcje na PC, podstawowa ścieżka dotykowa w podglądzie/urządzeniu; poprawne colls/anchors. **Test scen** i ruchu, nie cała regresja.

## M3 — Network proof
**Deliverable:** host i klient, dwie postacie, współdzielony model CombatResolver, rozstrzygnięcie komend na hoście, replikacja wyników, podstawowe odrzucanie nielegalnych requestów, komunikat rozłączenia. Cross-platform tam, gdzie dostępne.
**Gate:** dwa klienty identyczny stan po końcu tury, komendy nie powodują podwójnych obrażeń. Nie obiecuj bezportowego internetu. Testuj po zmianach sieci i na bramce, nie po zmianie NPC.

## M4 — World State + save + jeden quest
**Deliverable:** Zimny Bród → Stary Las → Kaplica; seal_state; 2 warianty wybranych obiektów, spotkań i pola walki; zapis i odczyt; hostowy stan świata.
**Gate:** obie ścieżki dają różne, obserwowalne skutki, poprawne save/load, brak dublowania stanów po rejoin.

## M5 — Art Validation / SpriteCook
**Deliverable:** oficjalna integracja pluginu, hero asset + mała próbna partia, osobne raw/final, manifest i gotowy wzorzec do późniejszych generacji; mockup w Godot, test PC/Android czytelności.
**Gate:** spójny rzut 2:1, alpha, rozmiary, brak seamów i czytelny HUD; dopiero potem poszerzaj zestaw. Jeśli SpriteCook zablokowany, placeholdery zostają, a bramka jest otwarta.

## M6 — Vertical slice
**Deliverable:** reprezentatywny wycinek z dopracowanym audio/obrazem, wioską, lasem, kaplicą, boss encounter, wyborem, zapisem, solo i 2p w testowym przepływie; Windows build, Android debug APK gdy środowisko pozwala.
**Gate:** ukończalna krótka przygoda, kontrolowana liczba błędów, zgodna logika na obu platformach, jednorazowy pełny smoke/regression przed wydaniem demonstracji.

## Priorytet ryzyka
Jeśli coś blokuje projekt, rozwiązuj w tej kolejności: walka działa → przejścia i kamery działają → sieć ma rzeczywistą synchronizację → WorldState przetrwa zapis → art jest spójny i czytelny → dopiero dokładanie zawartości.

## Nieodwracalne decyzje
Perspektywa, skala, standard animacji, kontrakt komend walki, model kampanii online. Przy ich zmianie krótki design review, aktualizacja dokumentacji i trafny test integracyjny. Nie oznacza to wielotygodniowych ceremonii.
