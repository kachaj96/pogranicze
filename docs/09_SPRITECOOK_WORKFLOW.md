# 09 — SpriteCook: autoryzacja, jakość, integracja

## Zweryfikowany kierunek integracji (18.11.2026)
Oficjalny plugin Claude Code: https://github.com/SpriteCook/claude-plugin
Instrukcja: https://www.spritecook.ai/claude
Oficjalny MCP zawarty w pluginie: `https://mcp.spritecook.ai/mcp/claude`, OAuth przy pierwszym użyciu. Nie wymaga ręcznego przekazywania klucza API w czacie (klucz jest dla alternatywnej integracji API). Dostępne skille do generowania sprite'ów, tilesetów, animacji i Godot.

## Instalacja — preferowana
1. W Claude Code sprawdź, czy plugin SpriteCook i jego narzędzia MCP są już dostępne.
2. Jeśli nie, użyj systemu wtyczek Claude Code, dodaj oficjalny marketplace z repo `SpriteCook/claude-plugin`, zainstaluj SpriteCook. W sesji z obsługą slash commands mogą działać `/plugin marketplace add SpriteCook/claude-plugin` i `/plugin install spritecook` (dokładną nazwę zarejestrowanego marketplace zweryfikuj poleceniem `/plugin`). Alternatywnie wykonaj kroki z oficjalnego repo.
3. Spróbuj wywołać bezpłatne / niskokosztowe listowanie narzędzi, statusu konta lub modelów. Jeśli trzeba: poproś użytkownika o osobiste zalogowanie się przez przeglądarkę. **Nie proś o klucz w rozmowie.**
4. Jeśli sesja jest w chmurze i plugin nie daje się zainstalować, podaj konkretny blocker. Nie twórz fikcyjnych PNG; prace nad kodem i placeholderami mogą iść dalej.
5. Nie dodawaj jednocześnie kilku konektorów SpriteCook; duplikowanie pluginu z ręcznym MCP tworzy problemy z uprawnieniami.

## Generowanie bez marnowania kredytów
Zanim uruchomisz generowanie: sprawdź kredyty, dostępne modele/ustawienia, koszt jednego wyniku. Jeśli znaczący lub nieznany koszt — uzgodnij z użytkownikiem limit prób. Pierwsza partia max 1–3 próbne assety, po czym **stop na ocenę** geometrii i stylu.

## Style lock
- Zatwierdzone motywy: izometria/dimetria 2:1, 64×32 tile candidate, detailed pixel art, styl Wounded Medieval Fantasy, naturalna ziemia/drewno/kamień/mch, oszczędne pieczęcie, dzienne światło z górnej lewej.
- **Nie** twórz realistycznych panoram, splash painting czy izometrycznego pseudo-3D jako assetów mapy.
- Najpierw hero asset / reprezentatywny kadr z dokładnym anchor, geometrią i rozmiarem piksela. Zapisz `reference_asset_id` / preset i używaj jako referencji przy generowaniu następnych elementów. Funkcja ta jest opisana w oficjalnych skillach SpriteCook.
- Sprawdź, czy model obsługuje żądaną geometrię. Jeśli nie, zastosuj ręczną korektę lub minimalny geometryczny szablon i integrację pod prawdziwą siatkę, zamiast akceptować niedokładny pseudo-izometryczny tileset.

## Pipeline plików
```
assets/raw/spritecook/<asset-id-or-date>/  # surowe eksporty, metadata
assets/final/terrain/
assets/final/characters/
assets/final/architecture/
assets/final/props/
assets/final/effects/
```
Nie trzymaj w repo kosztownych duplikatów eksportów lub screenshotów bez uzasadnienia; jeśli zespół później tego potrzebuje, ustal Git LFS i licencje.

Manifest assetów powinien zawierać: source, asset ID, timestamp, model/preset/reference, dimensions, perspective, anchor, animation frames, license/terms, review status. Nie commituj tokenów lub wygasających podpisanych URL-i jako trwałych źródeł.

## Minimalna walidacja mechaniczna
- PNG ma prawidłową przezroczystość tam, gdzie jest wymagana.
- Pixel grid spójny; brak frędzli alfa i rozmyć na krawędziach.
- Kafel idealnie trafia w oczekiwaną siatkę 2:1; krawędzie terenu łączą się bez seam.
- Postacie mają stały anchor przy stopach, widok 8 kierunków, zgodne proporcje.
- Element po zaimportowaniu do Godota mieści się w zasięgu kamery na Androidzie i nie zaburza czytelności planszy.
- SpriteCook-export/Godot prefab po sprawdzeniu istniejących funkcji pluginu; nie obiecuj automatycznej obsługi dowolnego formatu bez walidacji.

## Art approval gate
Zanim stworzysz pełen zestaw animacji i budynków, pokaż 2 sceny w Godot: fragment Zimnego Brodu i walkę w Starym Lesie. Użytkownik zatwierdza jakość albo Claude wyjaśnia, gdzie wymagane są korekty. To jedyna wymagana bramka jakości grafiki na wczesnym etapie, nie zatwierdzanie każdego kamyka.

## Alternatywa
Starsze `npx spritecook-mcp setup` jest udokumentowaną metodą dla różnych agentów, ale dla Claude Code preferowany jest oficjalny plugin z OAuth. Jeśli nie ma OAuth, powróć do aktualnej oficjalnej instrukcji i użyj bezpiecznej konfiguracji prywatnej, nigdy sekretu w repo.
