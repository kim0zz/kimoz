# Kimoz

Prototyp Auto Battler Zoo w Godot 4.7.2: lokalny i prywatny online mecz, draft, łączenie jednostek oraz roster 8 lvl1, 12 lvl2 i 12 lvl3. Nadrzędna specyfikacja: `GAME_DESIGN_V0_2.md` oraz późniejsze wyraźne decyzje użytkownika.

Zacznij od [aktualnego stanu i mapy kontekstu](docs/CURRENT_STATE.md): odróżnia grę B, historyczne A, eksperyment T i przyszły design. Równorzędne priorytety to wybór rezultatów fuzji na lvl2/lvl3 oraz czytelność GUI i feedbacku. Wybór wariantu nie jest jeszcze zaimplementowany. [Workflow zadania i odbiór jakości](docs/TASK_WORKFLOW.md), [dobór kontroli](docs/VERIFICATION_MAP.md), [mapa kodu](docs/COMBAT_IMPLEMENTATION.md).

Dokumenty liczb i wyników, m.in. `FULL_ROSTER_SKILLS.md`, `FULL_ROSTER_RESULTS.md`, `MATCH_LVL2_IMPLEMENTATION.md` oraz `LVL3_RESULTS.md`, opisują kolejne historyczne etapy. Przy interpretacji sprawdź datę, wariant i hashe; nie traktuj ich jako aktualnego wyniku wszystkich kontroli.

## Uruchamianie

Otwórz `project.godot` w Godot i naciśnij **F6** dla otwartej sceny albo **F5** dla całego projektu.
W menu wybierz **mecz lokalny** dla dwóch graczy przy jednym komputerze albo **online**. Początkowo wybieracie po dwa zwierzęta ze wspólnej puli ośmiu w kolejności ABBA. Potem przygotujcie składy i rozpocznijcie walkę. Pokoje z kodem wymagają konfiguracji EOS opisanej w [EOS_SETUP.md](docs/EOS_SETUP.md); połączenie po IP jest nadal dostępne.

W kolejnych rundach akcja oznacza wybór zwierzęcia ze wspólnej puli albo połączenie kompatybilnych rodziców: lvl1 + lvl1 → lvl2, lvl2 + lvl2 → lvl3. Zaznacz dwóch rodziców w swoim składzie i naciśnij **Połącz wybrane**. Standardowo masz dwie akcje. Jednorazowo otrzymujesz dodatkową akcję przy spadku do dwóch żyć i osobno do jednego; pozostanie na tym samym poziomie życia nie odnawia bonusu. Pula nie uzupełnia się w trakcie rundy. Brak legalnej akcji powoduje pas.

Maksymalnie wystawiasz sześć jednostek i trzymasz trzy na ławce. W przygotowaniu zmieniasz aktywność, zamieniasz jednostkę z rezerwą i ustawiasz kolejność. Odrzucanie jest bezpłatne. Przegrana zabiera jedno z pięciu żyć; remis nie zabiera życia. Zwierzęta wracają do kolejnej walki z pełnym HP i świeżymi cooldownami.

Przycisk **Combat Lab** otwiera osobne laboratorium. Wybierz preset lub ustaw po 1–6 jednostek (również hybrydy) w obu drużynach i naciśnij **Start / pauza**. Puste sloty są pomijane; duplikaty są dozwolone. Poniższe skróty dotyczą laboratorium:

Do oceny skilli wybierz jeden z presetów **Cały roster** i prędkość **1×**. **B** używa bieżących danych pełnego meczu; **A** odtwarza historyczne liczby lvl1/lvl2 i wybrane wcześniejsze zachowania. Przełączenie w pauzie resetuje walkę, zachowując składy. Pełny mecz zawsze używa B. Osobny **Teamfight Lab (T)** jest eksperymentem ról i sytuacyjnego AI; nie zmienia automatycznie zasad B.

- **Spacja** — start / pauza, **R** — reset obecnego składu.
- **Krok** — jeden tick symulacji (1/60 sekundy), również podczas pauzy.
- **0.5× / 1× / 2× / 4×** — prędkość prezentacji; reguły i krok symulacji pozostają takie same.
- Zmiana składu lub presetu resetuje walkę. Pozycje startowe wynikają z roli i kolejności slotów.
- Najedź na jednostkę, aby zobaczyć jej robocze statystyki. Po zakończeniu prezentowany jest wynik; ostatni raport zapisuje się w katalogu danych użytkownika Godot.

Roster ma kreskówkowe pełne sylwetki; część postaci osobne pozy, a Hipopotam rig z ruchomych części. To nie jest zakończona animacja wszystkich postaci/skilli. Jakość i czytelność wymagają odbioru w normalnej skali walki, nie tylko technicznego PASS.

Z terminala w katalogu projektu:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/godot.ps1 check
powershell -NoProfile -ExecutionPolicy Bypass -File tools/godot.ps1 run
```

`check` importuje zasoby i uruchamia projekt bez okna na 60 klatek. Nie testuje całej rozgrywki ani wyglądu.
Ścieżka do lokalnego silnika jest w ignorowanym przez Git pliku `tools/godot.local.txt`.
Po przeniesieniu silnika zaktualizuj tę ścieżkę lub ustaw zmienną `GODOT_BIN`.

## Wspólna praca

Katalog projektu: `C:\Users\gorsk\OneDrive\Dokumenty\kimoz`.
Pracując z asystentem, używaj tego katalogu jako projektu i zachowaj `AGENTS.md` oraz `docs/kierunek.md`.
Godot i asystent pracują na tych samych plikach; zapisuj zmiany w edytorze przed zleceniem ich modyfikacji.

- `scenes/` — sceny, w tym główna scena startowa.
- `scripts/` — kod GDScript.
- `assets/` — grafika i dźwięki.
- `resources/` — dane i zasoby Godot.
- `scripts/combat/` — wspólny deterministyczny silnik walki dla widoku i symulacji.
- `scripts/presentation/` — widok i sterowanie laboratorium.
- `tests/` i `scripts/testing/` — testy reguł i serie symulacji; dobór: `docs/VERIFICATION_MAP.md`, komendy i historia wyników: `docs/TESTING.md`.
- `resources/README.md` — parametry początkowe, jednostki miary i definicje danych.
- `docs/kierunek.md` — ustalenia o grze i stylu.

Repozytorium: https://github.com/kim0zz/kimoz. Zastany stan zapisano i wypchnięto jako pierwszy commit `4bb6b80` (2026-10-01); jest punktem odniesienia przed zmianą kontekstu agentów. Buildy, cache, raporty generowane i lokalna konfiguracja EOS pozostają poza Git.

## Godot MCP

Zainstalowano Godot MCP Toolkit 1.0.2 w `addons/godot_mcp_toolkit/` oraz serwer npm tej samej wersji w `tools/mcp-server/`.
Konfiguracja Codex zawiera serwer `godot-kimoz`, przypisany do tego projektu przez `GODOT_MCP_PROJECT_PATH`.
Po instalacji zapisz pracę i ponownie otwórz projekt w Godot oraz uruchom ponownie Codex.
Dodatek w Godot powinien pokazać panel MCP i komunikat o nasłuchiwaniu na localhost.
MCP pozwala sprawdzać stan edytora bez sterowania kursorem. Testy i symulacje uruchamiają bezpośrednio silnik Godot, a wygląd można sprawdzać w zwykłym oknie gry.

Źródło dodatku: https://github.com/NPGameDev/godot-mcp-toolkit (tag v1.0.2).
Zależności serwera są przypięte w `tools/mcp-server/package-lock.json`.
Nie trzeba kupować usługi ani podawać klucza API do tego połączenia.
