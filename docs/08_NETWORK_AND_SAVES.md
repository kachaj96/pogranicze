# 08 — Multiplayer i zapisy

## Tryby
- Solo: proces gry pełni rolę autorytatywnego hosta, kontroluje postać gracza i jednego towarzysza.
- Co-op: maksymalnie 2 aktywnych graczy, każdy steruje 1 postacią. Stan świata, walka i decyzje należą do kampanii hosta. Postać gościa zachowuje indywidualne dane zgodnie z jasno określoną polityką progresu.
- Nie ma serwerów MMO, wspólnych hubów, PvP ani publicznego matchmakingu w MVP.

## Architektura online
- Host autorytatywny. Klient wysyła `Command` ze swoim peer ID, jednostką, polem/celem, numerem sekwencyjnym, żądaną fazą. Host weryfikuje uprawnienia, AP/MP, LoS, kolejność, zajętość pól i stan gry.
- Wynik to numerowane `BattleEvent`s i snapshot (potrzebny do późnego dołączenia/synchronizacji), klient animuje rezultat, nie dopisuje obrażeń na własną rękę.
- Idempotencja: powtórzone request ID nie wykonuje tej samej akcji drugi raz.
- W offline ten sam resolver obsługuje lokalne komendy. Nie twórz dwóch silników walki.
- Wspólna faza drużyny: akcje obu graczy w kolejności zatwierdzonej przez hosta; podczas konfliktu o to samo pole pierwsza legalna komenda rozstrzygana, druga dostaje powód odmowy.

## Właściciel decyzji o świecie
W pierwszym wydaniu host podejmuje ostateczną decyzję o pieczęci. Gość może uczestniczyć w rozmowie/interfejsie, ale w przypadku rozbieżności rozstrzyga host. Wyraźnie pokazuj tę zasadę w UI.

## Połączenie
- Na etap początkowy: LAN + bezpośrednie IP dla kontrolowanego testu przez internet.
- ENet w Godot wykorzystuje UDP; za NAT dołączanie przez publiczny internet może wymagać przekierowania portu lub pośrednika. Nie obiecuj „join code bez konfiguracji” dopóki nie ma uruchomionej usługi pośredniczącej / odpowiedniej implementacji.
- Do późniejszego wydania zaprojektuj interfejs `JoinService`, aby można było dołożyć relay/lobby bez przepisywania CombatResolver.
- Android: export preset z uprawnieniem INTERNET. Różne wersje platform muszą mieć zgodny protokół i numer formatu stanu.

## Rozłączenia
MVP: utrata połączenia pokazuje powód i zapobiega wykonywaniu kolejnych niezautoryzowanych działań; host może przejść do bezpiecznego stanu/pauzy. Automatyczne odzyskiwanie sesji to późniejsza funkcja, osobna bramka testów. Nie zapisuj uszkodzonych snapshotów.

## Zapis
Wersjonowany format: schema version, campaign ID, host world flags, quest states, region ID, player characters / companion, inventory, timestamp, RNG state jeśli walka w toku. Preferuj bezpieczne snapshoty między starciami w MVP; zapisy w środku każdej tury dopiero po stabilizacji. Atomowy zapis tymczasowy + rename / backup i obsługa błędu odczytu. Nie ufaj danym pochodzącym od klienta ani z nieznanych wersji save.

## Minimalne testy sieci
Dwa lokalne procesy: join, przydział postaci, ruch/atak, brak podwójnego obrażenia, odrzucenie niedozwolonej akcji, jednakowy stan po turze. Windows↔Android gdy rzeczywiste narzędzia i telefon są dostępne; jeśli nie, `NOT RUN` z instrukcją wykonania na urządzeniu.
