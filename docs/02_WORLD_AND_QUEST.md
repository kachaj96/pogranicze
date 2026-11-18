# 02 — Świat i pierwsza przygoda

## Lore — baza, nie zamknięta fabuła
Pogranicze jest pasem ziemi na skraju osiadłej cywilizacji. Stare pieczęcie ograniczają anomalie zwane Bliznami Świata. Ich awarie wpływają na roślinność, szlaki, ludność i niektóre właściwości walki. Mieszkańcy nie są bezradnymi statystami: żyją, naprawiają, handlują, odchodzą lub adaptują się. Nie wprowadzaj głównego wątku „wybraniec ratuje wszechświat” bez osobnego uzgodnienia.

## Region początkowy
**Zimny Bród:** mała osada przy trakcie, karczma, kuźnia, kilka domów, brama/palisada, plotki o zaginionych kupcach. Zabudowa ciemne drewno, kamień, poprawki i naprawy, ciepłe światło w oknach. Nazwa nie wymusza zimy i śniegu na wszystkich mapach.

**Stary Las:** wilgotne drzewa, korzenie, omszałe kamienie, stara droga, polana, ślady sanktuarium. Dwa stany:
- `SEALED`: mniej anomalii, bezpieczniejszy trakt, kupiec może wrócić.
- `BROKEN`: skażone pola, niebezpieczne stworzenia, nowe przejście/zasób, część szlaku zamknięta.

**Stara Kaplica:** mała ruina ze świecami, zniszczonymi ławkami, niszami, zejściem do krypty i pieczęcią. Otoczenie opowiada historię, ale nie wymaga wielu cutscenek.

**Ruiny Twierdzy, Trakt Zamkowy, Mokradła:** odłożone poza MVP, możliwe zaczątki połączeń na mapie świata, ale nie jako gotowe lokacje.

## Przygoda — wersja robocza
1. Wejście do Zimnego Brodu, poznanie 2–3 NPC i podejrzenie zagrożenia.
2. Trop w Starym Lesie poprzez dialog, ślad lub dokument — co najmniej dwie drogi poznania celu.
3. Jedno starcie uczące ruchu i przeszkód; odblokowanie drogi do kaplicy.
4. Kaplica: eksploracja, układ przestrzenny, interakcja z ołtarzem, starcie związane z pieczęcią.
5. Decyzja:
   - **Odnowienie:** bezpieczniejszy trakt + powracający NPC/kupiec, inne spotkanie po powrocie.
   - **Przejęcie mocy / zniszczenie:** wyraźnie trudniejszy fragment lasu + nowe przejście / specjalna nagroda i mechanika anomalii.
6. Weryfikacja konsekwencji w osadzie, lesie i przynajmniej jednym późniejszym starciu.

Nie twórz fałszywego wyboru, gdzie obie opcje prowadzą do identycznej sceny. Każda ma wiarygodną korzyść i koszt.

## WorldState — minimalne pola
`seal_state` enum (`UNRESOLVED`, `SEALED`, `BROKEN`), `chapel_boss_defeated`, `merchant_returned`, `hidden_path_open`, `forest_variant`, `quest_stage`; wersjonowane dla save. Bazowy układ map bez kopiowania całych wariantów. Stan hosta jest źródłem prawdy dla sesji online.

## Zasada visual storytelling
Rekwizyty i świat sugerują wydarzenia; NPC dostarczają wybranych szczegółów, dziennik przechowuje to, co faktycznie odkryto. Brak stałych wielkich znaczników wszędzie; unikaj też „szukaj jednego piksela” bez czytelnego sygnału.
