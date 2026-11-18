# 13 — Eksporty, repo i codzienna praca

## Stabilność środowiska
Przed implementacją sprawdź dostępność `godot` / `godot4`, wersję, GDScript import, platformę wykonywania Claude. Nie instaluj bez potrzeby ciężkiego toolchainu, jeśli celem M1 jest tylko weryfikacja kodu. W razie braku Godot wypisz dokładną instrukcję użytkownikowi i oznacz test `NOT RUN`.

## GitHub
- Repo `pogranicze` istnieje. Nie twórz nowego repo ani nie wypychaj zmian do innego origin.
- `git status`, `git remote -v`, aktualna gałąź, `project.godot`, pliki `CLAUDE.md` i dokumentację sprawdź przed modyfikacją.
- Jeśli repo ma cudzy kod / poprawki, zachowaj je i dołącz spec ostrożnie, bez zamiany całej historii.
- Commit nazwany wg etapu, np. `feat(combat): playable tactical prototype` lub `docs: add Pogranicze development kit`.
- Użytkownik chce postępu w tym repo. Jeżeli uprawnienia pozwalają, małe logiczne commity/push; jeśli narzędzie nie pozwala na push, podaj konkretne instrukcje i nie twierdź, że repo zaktualizowano.
- `.gitignore`: `.godot/`, `.import/` zależnie od wersji i konwencji, build outputs, cache, local `.env`, lokalne sekrety, certyfikaty/signing, debug logs. Nie ignoruj `project.godot`, skryptów i import metadata potrzebnych projektowi.

## Windows
Przygotuj profil debug export wtedy, gdy projekt ma już grywalny fragment. Nie rób builda po każdej zmianie. Zapisuj wersję Godot i wymagane template'y.

## Android
Oficjalna dokumentacja: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- Eksport Android wymaga konfiguracji narzędzi wskazanych przez dokumentację dla wybranej wersji Godot (często JDK 17, SDK i export templates). Dokładne wersje pakietów sprawdź na bieżąco.
- W preset włącz Android `INTERNET` dla co-op; zaplanuj landscape, adaptację UI i konfigurację package ID.
- Instalowanie na prawdziwym telefonie, ekran dotykowy, podpisy debug/release i test kompatybilności tylko gdy jest rzeczywisty dostęp.
- Sekretów podpisywania nie commituj. Debug APK na etapie slice; AAB/release później.

## Sceny i postęp
Każdy etap zostawia działające minimum i `docs/PROGRESS.md` z: data, etap, co działa, co jeszcze nie, testy, dokładne zobowiązania użytkownika i następny minimalny krok. Nie tworzyć codziennie długich raportów ani osobnych prezentacji. Jeden status repo wystarczy.

## Typowe blokery użytkownika
- Wtyczka SpriteCook wymaga logowania OAuth: użytkownik sam potwierdza w przeglądarce; nie wpisuje klucza do Claude.
- Claude Code nie ma dostępu do lokalnego Git/Godot: użytkownik ustawia połączenie lub instaluje narzędzia zgodnie z konkretami Claude.
- Fizyczny Android niepodpięty: Claude pisze kod/export config i daje pojedynczy test manualny do wykonania, kiedy sprzęt dostępny.
- Publikacja release: osobne certyfikaty i konta, nie tworzone automatycznie.
