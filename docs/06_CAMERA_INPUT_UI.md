# 06 — Kamera, sterowanie, UX PC/Android

## Kamera
2D 2:1 fixed-angle / bez rotacji. Płynne śledzenie postaci podczas eksploracji, ograniczenia do granic mapy, zoom w określonym zakresie; bez nieskończonego oddalania. Przy walce czytelny kadr strefy i ograniczony zoom. Y-sort na stopach/warstwach, lokalne hide/fade dachów i frontowych ścian w małych budynkach. W większych wnętrzach osobna scena.

## Input
**PC**: WASD (sterowanie ruchem w logicznych osiach świata / zgodne z czytelną mapą ekranową), mysz do interakcji i click-to-move, rolka zoom, łatwe skróty zdolności 1–4, Esc anulowanie. Dokumentuj mapowanie fizycznych klawiszy w projekcie.

**Android**: landscape, tap-to-move, pan, pinch zoom, duże i oddalone od krawędzi przyciski HUD, osobne układy paneli i dialogów, podgląd przed potwierdzeniem celu ataku. Wirtualny joystick tylko po testach. Nie zakładaj hover ani prawego kliknięcia.

**Wspólny gameplay**: te same zasięgi, kolizje, AP/MP, wyniki i ograniczenia pola widzenia. Nie pozwól, by inna liczba widocznych kafli na monitorze dawała w online przewagę — kontroluj widok aktywnego starcia niezależnie od proporcji ekranu.

## Czytelność
- W pierwszych testach standardowy telefon w landscape, UI docelowo około 48 dp minimalnego obszaru dotyku, wyraźne etykiety; dostosuj do density i user scale.
- Zoom, podgląd siatki, zaznaczony cel, czytelne linie zasięgu i zablokowane pola.
- Mniejszy HUD, panele kontekstowe, bez gęstych tooltipów i mikrotekstu.
- Teksty dialogów zwykłą czytelną czcionką, nie ozdobną mini pixel-font.
- Zachowaj rozdzielenie skali UI i tekstury pikselowej świata. Unikaj przypadkowego filtrującego bilineara w sprite'ach.

## Testy przed zamknięciem skali
1. Wejścia do budynków/NPC identyfikowalne na telefonie.
2. Pojedyncze pole 10×10 możliwe do wybrania bez ciągłych pomyłek; feedback i anulowanie działają.
3. Po przejściu do wnętrza brak zasłaniania postaci i czytelna kamera.
4. Zmiana proporcji PC/Android nie zmienia zasad walki.

## Reguły UI
Na PC menu boczne i dolna belka umiejętności; na Androidzie panele na żądanie i przyciski na dole z bezpiecznymi odstępami. Kolor + kształt/ikonografia do rozróżniania jednostek/stref (nie samo czerwone/zielone). Elementy obracane/ukrywane lokalnie u każdego gracza, nie przez wspólny stan świata.
