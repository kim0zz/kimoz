# Dobór kontroli dla zmian w Kimoz

Mapa wskazuje zakres według zmienianego zachowania. Nie jest deklaracją PASS wszystkich wymienionych plików. Instrukcja runnerów i historyczne wyniki: [TESTING.md](TESTING.md). Odbiór jakości: [TASK_WORKFLOW.md](TASK_WORKFLOW.md).

## Wspólna kontrola i wynik procesu

Po zmianach obowiązuje `powershell -NoProfile -ExecutionPolicy Bypass -File tools/godot.ps1 check`: import i start na 60 klatek headless. To nie uruchamia zestawu regresji ani nie ocenia UI.

Celowany test uruchamiaj z katalogu repo, silnikiem z `GODOT_BIN` albo `tools/godot.local.txt`:

```powershell
$engine = $env:GODOT_BIN
if (-not $engine) { $engine = (Get-Content tools/godot.local.txt -Raw).Trim() }
& $engine --headless --path . --script res://scripts/match/match_model_test.gd
```

Zastąp ścieżkę właściwym plikiem. Dla testu wizualnego pomiń `--headless`. Sprawdź kod zakończenia oraz log (`SCRIPT ERROR:`, `ERROR:`, `FAIL:`, błąd asercji). Niektóre pliki używają bezpośrednich `assert`, więc sam exit code bez logu/komunikatu końcowego może być niewystarczający. Brak błędu parsera nie dowodzi, że scenariusz doszedł do końca.

## Rodziny kontroli

- **Draft, akcje, ławka, fuzja**: `scripts/match/match_model_test.gd`, `tests/comeback_tests.gd`, `tests/lvl3_tests.gd`; następnie `scripts/match/match_ui_smoke.gd`. Po zmianie reguł uwzględnij odpowiednie komendy online.
- **GUI i drzewko rozwoju**: dobierz `tests/development_ui_test.gd`, `tests/selection_ui_test.gd`, `tests/damage_summary_ui_test.gd` oraz match UI smoke. Uruchom właściwe testy w rendererze i obejrzyj zrzuty. Dla nowego wyboru hybrydy obecne testy nie wystarczą: potrzebne będą przypadki wyboru/anulowania, kosztu akcji i rezultatu lvl2/lvl3 zgodne z zamkniętym designem.
- **Aktualny combat B**: celowane rodziny `tests/lvl3_tests.gd`, `tests/hybrid_mechanics_tests.gd`, `tests/no_ranged_kiting_test.gd`, `tests/rabbit_support_test.gd`, `tests/skunk_trail_tests.gd`, `tests/skunk_phase_tests.gd`. Wybierz te związane ze zmianą, sprawdź ich oczekiwania względem bieżących danych. Przy zmianie resolvera/ruchu sprawdź również szersze kontrakty `combat_tests.gd`, z zastrzeżeniami poniżej.
- **Izolacja wariantów i prezentacja**: `tests/burst_pilot_tests.gd`, `tests/burst_presentation_tests.gd` oraz lvl3 tests. Kontrolują wybrane kontrakty A/B i nested Resources; oczekiwania należy odnieść do aktualnego wariantu.
- **Teamfight T**: `tests/teamfight_tests.gd`, `tests/teamfight_scenarios.gd`, `tests/teamfight_ui_test.gd`; sprawdź powrót do B. Celowane scenariusze T nie są pełną kalibracją rosteru B.
- **Animacja/feedback**: `tests/hippo_animation_test.gd` dla Hipopotama; odpowiednio `tests/cartoon_visual_test.gd`, `tests/burst_presentation_tests.gd`, `tests/rabbit_support_visual_test.gd` lub `tests/no_kiting_visual_test.gd`. Test synchronizacji/atlasu nie ocenia jakości artystycznej. Dołącz dowód przy 1× i odbiór użytkownika.
- **Online lokalne**: `tests/online_commands_test.gd`, `tests/online_session_test.gd`, `tests/eos_rooms_test.gd`, dwa procesy `tests/online_match_test.gd` (host i guest) oraz potrzebne testy feedbacku/UI. Dla fragmentacji użyj wariantu `--chunks` opisanego w `EOS_SETUP.md`; porównaj kompletne `rounds` obu raportów.
- **EOS i dystrybucja**: procedura w `EOS_SETUP.md`; live smoke naprawdę loguje urządzenie i tworzy pokój. Nie uruchamiaj go w zadaniu niezwiązanym z usługą. Test przez dwie sieci i rozpakowana paczka z wymaganymi DLL są osobnymi kontrolami. Standardowy `tools/export_windows.ps1` na baseline pakuje tylko EXE i instrukcję — nie zakładaj, że tworzy kompletną paczkę EOS.

## Oczekiwania historyczne wymagające przeglądu

`docs/TEAMFIGHT_LAB_V0_1.md` odnotowuje trzy nieaktualne oczekiwania `tests/skill_redesign_tests.gd` dotyczące dawnej stacjonarnej chmury Skunksa. To zapis historycznej awarii, nie dzisiejszy pomiar wyniku.

`tests/combat_tests.gd`, `tests/ranged_contact_tests.gd`, `tests/skunk_ranged_tests.gd`, `tests/eagle_repeat_tests.gd` i `tests/skill_readiness_tests.gd` powstawały przy starszych zachowaniach/liczbach; w dokumentacji są ich wcześniejsze wyniki. Nie oznaczamy całych plików jako zbędnych: mogą zawierać nadal ważne kontrakty. Sprawdź konkretną nieudaną asercję względem wariantu i późniejszych decyzji, zwłaszcza ruchomego Skunksa, braku kitingu, shield jump Królika oraz indywidualnych pierwszych cooldownów.

Jeśli zastany test nie przechodzi, zapisz plik, asercję i stan bazowy. Nie zmieniaj designu tylko po to, by spełnić stare oczekiwanie; nie usuwaj również asercji bez wyjaśnienia jej zastąpienia. Naprawa testów wymaga zachowania właściwego kontraktu i jawnego zakresu zadania.

## Kiedy uruchamiać serie balansu

Zmiana samej dokumentacji, layoutu lub animacji nie wymaga pełnej macierzy. Przy zmianach liczb, czasu/warunków skilla, ruchu lub targetowania dobierz sparowane scenariusze przed/po. Szeroką serię uruchamiaj dla większego etapu balansu, nie automatycznie przy każdej poprawce.

`tools/run_combat.ps1 test` odpala wyłącznie `tests/combat_tests.gd`; `quick/full` to deterministyczne serie lvl1, nie zestaw wszystkich testów. Dla lvl2 i porównań rosteru istnieją osobne runnery w `scripts/testing/`. Wyniki podawaj z wariantem, datą/hashami, seedem i mianownikami. Raport historyczny oraz 50% globalnej symetrycznej macierzy nie dowodzą aktualnego balansu ani wartości supportu.

## Baseline do porównań modeli

Na `4bb6b80` nie wykonano wspólnego kontrolnego przebiegu wszystkich rodzin. Ta dokumentacja nie ustanawia zielonego baseline testów. Przed benchmarkiem wykonaj wybrany wspólny zestaw na zamrożonym stanie i zanotuj PASS/FAIL/niewykonane wraz z oczekiwaniami historycznymi. Potem porównuj nowe regresje względem tego wyniku, używając identycznych kryteriów dla modeli.
