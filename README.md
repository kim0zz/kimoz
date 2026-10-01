# Kimoz

Prototyp Auto Battler Zoo w Godot 4.7.2: lokalny mecz, draft, łączenie jednostek i walka ośmiu lvl1 oraz dwunastu hybryd lvl2. Nadrzędna specyfikacja: `GAME_DESIGN_V0_2.md`.

Bieżący etap: mocniejsze skille całego rosteru — `docs/FULL_ROSTER_SKILLS.md`; porównanie drużyn: `docs/FULL_ROSTER_RESULTS.md`. Opis pętli meczu: `docs/MATCH_LVL2_IMPLEMENTATION.md`. Poprzednie raporty balansu i próby trzech hybryd są historyczne. Mapa kodu: `docs/COMBAT_IMPLEMENTATION.md`.

## Uruchamianie

Otwórz `project.godot` w Godot i naciśnij **F6** dla otwartej sceny albo **F5** dla całego projektu.
Scena startowa otwiera **lokalny mecz dla dwóch graczy przy jednym komputerze**. Początkowo wybieracie po dwa zwierzęta ze wspólnej czwórki w kolejności ABBA. Potem przygotujcie składy i rozpocznijcie walkę.

W kolejnych rundach akcja oznacza wybór zwierzęcia ze wspólnej puli albo połączenie dwóch kompatybilnych lvl1 w lvl2. Zaznacz dwóch rodziców w swoim składzie i naciśnij **Połącz wybrane**. Zwykle masz jedną akcję; przy dwóch życiach dwie, przy jednym trzy. Pula nie uzupełnia się w trakcie rundy. Brak legalnej akcji powoduje pas.

Maksymalnie wystawiasz sześć jednostek i trzymasz trzy na ławce. W przygotowaniu zmieniasz aktywność, zamieniasz jednostkę z rezerwą i ustawiasz kolejność. Odrzucanie jest bezpłatne. Przegrana zabiera jedno z pięciu żyć; remis nie zabiera życia. Zwierzęta wracają do kolejnej walki z pełnym HP i świeżymi cooldownami.

Przycisk **Combat Lab** otwiera osobne laboratorium. Wybierz preset lub ustaw po 1–6 jednostek (również hybrydy) w obu drużynach i naciśnij **Start / pauza**. Puste sloty są pomijane; duplikaty są dozwolone. Poniższe skróty dotyczą laboratorium:

Do oceny nowych skilli wybierz jeden z presetów **Cały roster** i prędkość **1×**. Wariant **B** to nowe liczby wszystkich jednostek; **A** zachowuje stan sprzed rozszerzenia (z trzema poprawionymi hybrydami). Przełączenie w pauzie resetuje walkę, zachowując składy. Efekty wizualne są wspólne, a pełny mecz zawsze używa B.

- **Spacja** — start / pauza, **R** — reset obecnego składu.
- **Krok** — jeden tick symulacji (1/60 sekundy), również podczas pauzy.
- **0.5× / 1× / 2× / 4×** — prędkość prezentacji; reguły i krok symulacji pozostają takie same.
- Zmiana składu lub presetu resetuje walkę. Pozycje startowe wynikają z roli i kolejności slotów.
- Najedź na jednostkę, aby zobaczyć jej robocze statystyki. Po zakończeniu prezentowany jest wynik; ostatni raport zapisuje się w katalogu danych użytkownika Godot.

Wygląd jest roboczy: proste rysowane sylwetki, obrysy, paski HP i sygnały skilli. Nie są potrzebne Blender ani kupione assety.

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
- `tests/` i `scripts/testing/` — testy reguł i serie symulacji; instrukcja: `docs/TESTING.md`.
- `resources/README.md` — parametry początkowe, jednostki miary i definicje danych.
- `docs/kierunek.md` — ustalenia o grze i stylu.

Git jest zainicjalizowany lokalnie; samo istnienie repozytorium nie zapisuje historii. Stan początkowy nie ma jeszcze commitów.

## Godot MCP

Zainstalowano Godot MCP Toolkit 1.0.2 w `addons/godot_mcp_toolkit/` oraz serwer npm tej samej wersji w `tools/mcp-server/`.
Konfiguracja Codex zawiera serwer `godot-kimoz`, przypisany do tego projektu przez `GODOT_MCP_PROJECT_PATH`.
Po instalacji zapisz pracę i ponownie otwórz projekt w Godot oraz uruchom ponownie Codex.
Dodatek w Godot powinien pokazać panel MCP i komunikat o nasłuchiwaniu na localhost.
MCP pozwala sprawdzać stan edytora bez sterowania kursorem. Testy i symulacje uruchamiają bezpośrednio silnik Godot, a wygląd można sprawdzać w zwykłym oknie gry.

Źródło dodatku: https://github.com/NPGameDev/godot-mcp-toolkit (tag v1.0.2).
Zależności serwera są przypięte w `tools/mcp-server/package-lock.json`.
Nie trzeba kupować usługi ani podawać klucza API do tego połączenia.
