# 05 — Art Bible / POGRANICZE v0.4 zatwierdzone jako kierunek

## Styl
**Wounded Medieval Fantasy**, szczegółowy mroczny pixel art, rzut izometryczny/dimetryczny 2:1. Świat żywy i zamieszkały, nie zawsze ciemny: zieleń lasu, ciepłe światło domów, szary kamień ruin, subtelne skażenie. Atmosfera poprzez materiały, historię miejsc i oświetlenie; nie przez samą czernię.

## Cechy wspólne assetów
- Te same proporcje i geometryczna projekcja, spójny poziom szczegółu i rozmiar piksela.
- Paleta kierunkowa: `#171C20` cień, `#34454A` zimny kamień, `#556A55` natura, `#775A45` drewno, `#C7B79D` jasne powierzchnie, `#D29B59` ogień, `#816782` skażenie. To akcenty, nie zakaz pozostałych kolorów.
- Paleta produkcyjna orientacyjnie 40–56 próbek, dopasowana do modelu/działania generatora i walidacji sceny. Kontroluj nasycenie i kontrast.
- Umowny kierunek światła dziennego z góry/lewej sceny; cienie zgodne w obrębie sąsiednich elementów.
- Naturalne detale, czytelne sylwetki i zamierzone skupiska pikseli. Żadnych losowych plam, pseudo-pikselowego wygładzania, mieszania pixel art + HD na jednym poziomie mapy.
- Ruchome cienie/pochodnie mogą zmieniać kierunek lokalnie, ale nie mogą walczyć z na stałe narysowanym światłem.

## Geometria i skala — do technicznej walidacji
- Kafel `64×32 px` jako hipoteza wstępna. Logiczną siatkę modeluj niezależnie od grafiki.
- Sylwetka postaci wstępnie ok. 40–48 px szer. i 72–88 px wys. (liczy się widoczność na Androidzie i odniesienie do kafla), anchor na stopach.
- Drzewo może wystawać poza zajmowane pola; rzeczywiste kolizje są zdefiniowane osobno.
- Wnętrza i fasady modularne: ściany, narożniki, drzwi, dachy, okna, schody, filary, meble.
- W czasie walki subtelna siatka, a range/telegraph zawsze czytelne. Silne VFX krótkie, bez zasłaniania postaci.

## Motywy
- Pęknięcia: skała, metal, korzenie, gleba, rzeczywistość.
- Naprawy: obręcze, wsporniki, łaty, prowizoryczne konstrukcje.
- Pieczęcie: lokalne symbole i obrzędy, nie wszechobecne świecące runy.
Używać oszczędnie, aby motyw w ważnej scenie był czytelny.

## Biomy
1. Zimny Bród: ciemne drewno i kamień, naprawiane budynki, drogi błotne/bruki, światła z okien.
2. Stary Las: wilgoć, paprocie, stare drogi, omszałe kamienie, gęstsza zieleń; stan BROKEN zmienia wybrane obiekty, nie 100% mapy.
3. Kaplica: kamień, stare drewno, uszkodzone ławy, znaki i świeczniki, czytelne przejścia.
4. Twierdza/Mokradła: opis wizji, ale produkcja po slice.

## Postacie
Wędrowiec bez przesadnie heroicznych proporcji; ubranie tunika/spodnie/płaszcz/pas; stylizowana fizjonomia i realistyczne materiały. Żelazo: solidniejsza sylwetka i metal; Popiół: warstwowe zabrudzone tkaniny; Szept: znaki, talizmany, lekkie ubranie. Wyposażenie nie musi być zablokowane do szkoły.

## Referencje
`references/visual_studies` to **schematy techniczne**, niefinalna estetyka. Realistyczne obrazy wygenerowane wcześniej to climate refs, nie target produkcyjny. Nie kopiować assetów, kompozycji ani znaków rozpoznawczych cudzych gier.

## Art Validation Pack — NIE generować masowo
1. Jeden **hero asset**: kompletna miniaturowa scenka z trawą, kamieniem, fragmentem ściany i wędrowcem albo 1–3 reprezentatywne obiekty, z weryfikacją izometrii 2:1.
2. Jeden próbny kafel podłoża, jedna ściana/element budynku, jeden sprite postaci w 2 kierunkach do sprawdzenia proporcji; dalej dopiero rozwijanie 8 kierunków.
3. Jeden mockup mini-mapki eksploracyjnej i jednej walki w silniku, na PC oraz Androidzie.
4. Zatwierdź spójność, czystość alfa, pixel grid, anchory, skalę, tileable edges i brak pomyłek kierunku światła. Dopiero potem generuj pełen zestaw.
5. Zachowaj `reference_asset_id` / preset z tego samego generatora, by używać przy kolejnych assetach.

## Prawa/pochodzenie
Zapisuj źródło i identyfikator assetu, datę, wersję modelu/presetu, liczbę klatek, rozmiary, licencję/warunki. Nie wolno mylić assetu wygenerowanego z finalnym zatwierdzonym.
