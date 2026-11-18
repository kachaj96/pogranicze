# START — POGRANICZE / Claude Code

Pracujemy nad grą **POGRANICZE** w istniejącym repozytorium GitHub **`pogranicze`**, do którego masz podłączony dostęp. Otrzymujesz archiwum `POGRANICZE_Development_Kit_v1.0.zip` (albo jego rozpakowane pliki). Jest to wiążąca dokumentacja projektu. **Nie twórz nowego repo, nie zakładaj projektu od zera bez sprawdzenia zawartości i nie usuwaj istniejącego kodu.**

## 1. Najpierw rozpakuj i zorientuj się w repo

Jeżeli ZIP jest załącznikiem dostępnym w Twoim środowisku, znajdź go i rozpakuj **zawartość** do katalogu głównego repo `pogranicze`, bez dodatkowego zagnieżdżenia. Jeżeli masz dostęp tylko do rozmowy, a nie do pliku ZIP, powiedz mi dokładnie, jak mam go dostarczyć — nie udawaj, że go odczytałeś. Jeżeli dokumenty już znajdują się w repo, użyj ich bez dublowania. Przed kopiowaniem przejrzyj `git status`, aktualną gałąź, strukturę, `project.godot`, istniejący `CLAUDE.md`, ewentualne konflikty i niezacommitowane zmiany. Przy konflikcie merytorycznie połącz pliki i pokaż mi, co się zmieniło; nie nadpisuj cudzej pracy.

Przeczytaj `START_HERE.md`, `CLAUDE.md` i dokumenty w `docs/`. Uznaj decyzje użytkownika z `docs/12_DECISIONS_AND_ASSUMPTIONS.md` za zatwierdzone. Nie zadawaj ponownie pytań o gatunek, platformy, kamerę, style ruchu ani solo/co-op. Detale odwracalne wybieraj samodzielnie i dokumentuj.

## 2. Cel i zasady gry

Zrób działającą grę Godot 4.x w GDScript, rozwijaną etapami dla **Windows PC + Android**. Widok 2D izometryczny/dimetryczny 2:1, szczegółowy dark fantasy pixel art (Wounded Medieval Fantasy). Świat: osada Zimny Bród, Stary Las, Stara Kaplica; ręcznie projektowana eksploracja i wybrane trwałe zmiany stanu regionu (Blizny Świata). Walka turowa w stylu taktycznym Dofusa, ale z własnymi mechanikami i grafiką.

W eksploracji: **8 kierunków swobodnego ruchu**, poprawna normalizacja przekątnych. W walce: **4-sąsiedni ruch po logicznej siatce kwadratowej**, 8 kierunków celowania/oddziaływania; docelowo 8 kierunków animacji sprite'ów. Startowe parametry walki 6 PA/3 PR, 2 aktywne postacie. Solo: gracz + sterowany w walce towarzysz. Co-op: dwóch graczy online, host rozstrzyga działania i zapisuje stan kampanii. Nie twórz MMO, PvP ani ogromnego świata. **Najpierw walka na placeholderach, dopiero potem większa produkcja assetów.**

## 3. SpriteCook — obowiązkowo sprawdź i przygotuj

Użyj oficjalnej wtyczki SpriteCook dla Claude Code: `https://github.com/SpriteCook/claude-plugin` (MCP + skille). Sprawdź najpierw, czy już działa. Jeżeli nie, sprawdź aktualną instrukcję producenta `https://www.spritecook.ai/claude` i skonfiguruj ją w swoim środowisku, zamiast zgadywać format `.mcp.json`. Preferuj plugin i logowanie **OAuth w przeglądarce**, bez ręcznego klucza API. Jeśli potrzebujesz mojego działania, napisz jasno: „Otwórz ..., kliknij ..., zaloguj się ...”; nie proś mnie o wklejanie sekretów. W chmurze z ograniczonym terminalem pokaż wykonalny wariant i kontynuuj pozostały kod, nie blokując całej produkcji.

Zanim zużyjesz kredyty SpriteCook, sprawdź dostępność modeli, kredytów i ewentualny koszt oraz potwierdź rozsądny limit, jeśli nieznany. Nie generuj od razu 50 assetów. Gdy przyjdzie etap grafiki, zrób najpierw 1–3 reprezentatywne testowe assety i jeden **hero asset**, zweryfikuj rzeczywiste 2:1, pixel grid, anchory, przezroczystość, spójność na telefonie i zapisz identyfikator wzorcowego assetu do dalszych generacji. Rozdziel `assets/raw` i `assets/final`. Wcześniejsze schematy w `references/visual_studies` są tylko kompozycyjnymi szkicami, NIE gotowym stylem finalnym.

## 4. Testy — tylko konieczne

**Priorytet: płynna praca i grywalne przyrosty, a nie rytualne testowanie wszystkiego.** Po zmianie rób najszybszy test danego modułu / importu / sceny. Nie uruchamiaj całej regresji po poprawkach tekstów, grafiki i drobnym UI. Testy integracyjne rób po zmianach wspólnych kontraktów walki, WorldState, sieci, zapisów lub kamery. Pełna regresja oraz buildy PC/Android wyłącznie na bramkach etapów, przed wydaniem lub przy rzeczywistym ryzyku krytycznej regresji. Nie eksportuj APK po każdym commicie, nie odpalaj dwóch klientów po zmianie sprite'a. Test sieci host + klient uruchamiaj przy pracach sieciowych lub bramce M3/M6. Jeśli nie masz Godota, Android SDK lub urządzenia, zgłoś `NOT RUN`, powód oraz kroki do wykonania, zamiast twierdzić, że coś przetestowałeś. Nie pomijaj testów bezpieczeństwa komend hosta, AP/PR i save tylko dla szybkości.

## 5. Sposób pracy

Działaj samodzielnie, ale w małych logicznych kamieniach milowych z `docs/10_MILESTONES.md`: audyt/scaffold → turowy prototyp walki → eksploracja → fundament co-op → world state/save → walidacja SpriteCook → vertical slice. Zachowaj działające minimum na końcu etapu, dokumentuj krótki stan w `docs/PROGRESS.md`, a po możliwie działających zmianach rób małe commity. Push do istniejącego repo, jeżeli masz uprawnienia; nigdy nie stosuj force-push, nie usuwaj cudzych branchy i nie deklaruj push bez potwierdzenia.

**Rozpocznij rzeczywistą pracę teraz, nie poprzestawaj na planie.** Najpierw wykonaj M0 i przejdź do pierwszego wykonywalnego fragmentu M1: uruchamialna scena Godot i minimalny, sprawdzony model siatki/walki. Nie próbuj tworzyć całej gry jednym skokiem, nie rozpoczynaj rozległej grafiki przed walidacją 2:1. Jeśli coś wymaga ode mnie działania lub autoryzacji, poinformuj mnie krótko, konkretnie i kontynuuj inne odblokowane zadania.

## 6. Raport na końcu

Podaj krótko: (1) co faktycznie działa, (2) pliki i commit/branch, (3) co dokładnie przetestowałeś, a czego nie, (4) status SpriteCook i **moje konkretne czynności** (jeżeli są), (5) najbliższy minimalny krok. Bez ogólników i wielostronicowego raportu.
