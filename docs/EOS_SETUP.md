# Pokoje Kimoz przez Epic Online Services

Status: kod i paczka Windows przechodzą sprawdzenia lokalne. Utworzenie pokoju w EOS i mecz przez dwie sieci wymagają uzupełnienia konfiguracji oraz testu z drugim komputerem. Nie przedstawiać lokalnych testów ENet jako potwierdzenia działania relay Epic.

## Jednorazowe ustawienia autora gry

1. Zaloguj się na https://dev.epicgames.com/portal/ i otwórz produkt Kimoz. Wymagane umowy akceptuje właściciel konta.
2. W Product Settings zapisz Product ID. Wybierz sandbox i deployment tego produktu; zapisz ich Sandbox ID i Deployment ID. Obie kopie gry muszą używać tego samego deploymentu.
3. W Product Settings → Clients utwórz klienta `Kimoz Windows`. Przypisz politykę typu `Peer2Peer`, przeznaczoną dla niezaufanej aplikacji gracza. Potrzebne są Connect, Lobbies oraz P2P. Nie używaj polityki Trusted Server ani administracyjnych danych dostępowych.
4. Skopiuj Client ID oraz Client Secret tego klienta gry. Nie wysyłaj wartości do czatu ani logów.
5. Uzupełnij `config/eos.cfg`, korzystając z `config/eos.example.cfg`. Ten plik jest pomijany w Git. Nie umieszczaj w nim hasła do Epic, danych administratora ani kluczy serwerowych.
6. Ponownie uruchom grę i wybierz Graj online → Utwórz pokój. Po zmianie konfiguracji restart jest konieczny, ponieważ platforma EOS jest inicjalizowana raz na proces.

Konfiguracja klienta gry jest dołączana do eksportu. Client Secret w aplikacji gracza nie jest sekretem administracyjnym i da się go wydobyć z paczki; uprawnienia ogranicza polityka klienta. Nie dodawaj do niej operacji serwera ani administracji.

Logowanie używa EOS Connect Device ID. Nie otwiera Epic Account Portal, nie wymaga Epic Games Launchera i nie używa overlayu. Device ID jest zachowywane między uruchomieniami. Dwie kopie na tym samym koncie Windows mogą mieć tę samą tożsamość EOS; do prawdziwego testu użyj drugiego komputera lub osobnego użytkownika systemu.

## Granie

Gospodarz wybiera **Utwórz pokój** i kopiuje kod w formacie `ABCD-EFGH-JKLM`. Znajomy wpisuje kod i wybiera **Dołącz kodem**. Obaj muszą mieć tę samą paczkę. Pokój mieści dwie osoby, a gospodarz prowadzi grę jako A. EOS próbuje połączenia bezpośredniego i pozwala na relay. Nie trzeba konfigurować przekierowania portów; blokady ruchu przez lokalną zaporę lub sieć nadal mogą przeszkadzać.

Wyjście gospodarza kończy mecz. Nie ma odzyskiwania przerwanej partii ani przejmowania roli gospodarza. Kod jest losowym identyfikatorem pokoju, nie hasłem ani systemem uwierzytelniania znajomych. Dołączanie odbywa się przez wyszukanie konkretnego identyfikatora lobby; gra nie udostępnia przeglądarki publicznych pokoi.

## Implementacja

- EOSG 2.3.1, commit `56238973e2cd7ac9ac99ca14f88934465f0a8997`, wydanie Windows x64 z https://github.com/3ddelano/epic-online-services-godot/releases/tag/2.3.1. Kod dodatku nie był modyfikowany. Licencja dodatku jest w jego katalogu; SDK Epic podlega oddzielnym warunkom Epic.
- `scripts/network/eos_rooms.gd`: konfiguracja, Connect Device ID, lobby 2-osobowe, kontrola członkostwa przed przyjęciem P2P, anulowanie i usuwanie/opusczenie pokoju. Overlay, presence, RTC audio i migracja gospodarza wyłączone.
- `online_session.gd`: dotychczasowy autorytet, uzgadnianie wersji i walidacja danych; obsługuje ENet oraz EOSGMultiplayerPeer. Wyłącznie członek lobby może otrzymać akceptację P2P gospodarza.
- `packet_chunks.gd`: kompresja DEFLATE, fragmenty 700 bajtów, ograniczone rozmiary wejścia/wyjścia, zachowanie kolejności na niezawodnym kanale. Fragmenty składają się w te same pakiety Variant bez deserializacji obiektów.
- Autoloady EOSG skonfigurowano bezpośrednio w project.godot. GDExtension deklaruje DLL-e eksportowane z grą. Nie włączaj osobno edytorowego dodatku, żeby nie dublować tej konfiguracji.
- Bez zmian zasad draftu, walki i balansu. Zachowano połączenie po IP w rozwijanej sekcji.

## Testy i eksport

- `tools/godot.ps1 check`: import i start projektu.
- `tests/online_session_test.gd` oraz ten sam test z argumentem użytkownika `--chunks`: handshake, typy danych, niezgodna wersja.
- `tests/eos_rooms_test.gd`: kod pokoju, limity/nieprawidłowe fragmenty, 90 KB danych, duże wiadomości i kolejność state/combat przez lokalny transport.
- `tests/online_match_test.gd -- host --chunks` oraz `-- guest --chunks`: pełny test dwóch procesów na 127.0.0.1, draft, walka, fuzja, rewanż i rozłączenie. To nie jest test EOS.
- `tests/eos_rooms_ui_test.gd` w zwykłym rendererze: przyciski, błędny kod, brak konfiguracji, powrót lokalny i zrzut do reports/eos-rooms-ui.png.
- Eksport próbny: `builds/eos-preview/kimoz.exe`, obok wymagane DLL-e. Wysyłaj cały folder w ZIP, nie sam plik EXE. Przed rozesłaniem trzeba uzupełnić konfigurację i ponowić eksport.

Po konfiguracji: uruchomić `tests/eos_live_smoke.gd`, który naprawdę loguje urządzenie, tworzy pokój i go zamyka. Następnie na dwóch komputerach przetestować dołączenie, całą partię, zamknięty/pełny pokój, anulowanie, ponowne utworzenie oraz przerwanie internetu. W razie błędu 403 zweryfikować politykę klienta i dostępność deploymentu; nie zmieniać automatycznie uprawnień na administracyjne.

Źródła: https://dev.epicgames.com/docs/epic-online-services/multiplayer/nat-p2p-interface oraz dokumentacja i kod przypiętego wydania EOSG.

## Aktualizacja weryfikacji — 2026-09-27
Konfiguracja została uzupełniona. Test eos_live_smoke.gd potwierdził prawdziwe logowanie Device ID, tworzenie pokoju, wyszukiwanie po kodzie, usunięcie oraz poprawne zakończenie procesu bez błędów. KimozEOSLifecycle zwalnia platformę i zamyka SDK po zwolnieniu scen. Adapter usuwa cykle referencji lobby/członków dodatku EOSG. Weryfikacja dołączenia i relay na dwóch komputerach pozostaje otwarta.
