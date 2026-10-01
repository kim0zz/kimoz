# Combat Prototype v0.1 — weryfikacja

## Aktualizacja: pełny roster skilli

Aktualne wyniki i zakres kontroli: `FULL_ROSTER_VERIFICATION.md`, liczby: `FULL_ROSTER_SKILLS.md`, porównanie zespołów: `FULL_ROSTER_RESULTS.md`. Historyczne wyniki poniżej dotyczą wcześniejszych parametrów.

Porównanie A/B: `godot --headless --path . --script res://scripts/testing/roster_impact_runner.gd`; osobny przekrój 6v6: ta sama komenda z `-- --six-only`. Bieżący preset do oceny wyglądu: **Cały roster**, wariant B, prędkość 1×.

Testy mechanik korzystają teraz z obrażeń i terminów otwarcia z definicji, zamiast wymuszać historyczne 2 s i 2 obrażenia kolców. Oddzielny `burst_pilot_tests.gd` weryfikuje odtworzenie zapisanych liczb A oraz izolację klonów wszystkich jednostek. Nie ma potrzeby ponawiać całej macierzy po samej zmianie prezentacji.

Harness używa dokładnie `CombatSimulation`, którą wyświetla scena gry. Nie tworzy uproszczonego modelu obrażeń. Wszystkie komendy uruchamiaj z katalogu projektu. Lokalizacja silnika pochodzi z `GODOT_BIN` lub `tools/godot.local.txt`.

## Lokalny mecz i lvl2

Celowane testy reguł i połączenia widoku z modelem:

```powershell
$engine = (Get-Content tools/godot.local.txt -Raw).Trim()
& $engine --headless --path . --script res://tests/hybrid_mechanics_tests.gd
& $engine --headless --path . --script res://scripts/match/match_model_test.gd
& $engine --headless --path . --script res://scripts/match/match_ui_smoke.gd
```

Kalibracja lvl2 używa `scripts/testing/lvl2_balance_runner.gd`. Pełną serię uruchamiaj przy zmianach balansu, nie przy każdej korekcie UI:

```powershell
& $engine --headless --path . --script res://scripts/testing/lvl2_balance_runner.gd -- --label reproduce_lvl2
```

Runner zapisuje raport JSON oraz CSV walk i jednostek w `reports/lvl2/`. Przy interpretacji oddzielamy pojedynki, walki przeciw parom/trójkom, hybrydy między sobą i kontrolowane wyłączenie mechanik. Bieżące wyniki i korekty: `LVL2_BALANCE_REPORT.md`. Starsze serie poniżej dotyczą historycznych wersji lvl1.

## Komendy

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_combat.ps1 test
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_combat.ps1 quick -Label baseline
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_combat.ps1 full -Label final
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_combat.ps1 full -Label reproduce -Scenario six_00_01 -TraceOne
powershell -NoProfile -ExecutionPolicy Bypass -File tools/godot.ps1 check
```

Opcjonalne `-Output` wskazuje katalog raportów. Domyślnie `reports/combat/`. Etykiety zapisują osobne pliki; ponowne użycie tej samej etykiety nadpisuje jej raporty. `-Scenario` przyjmuje dokładne ID z JSON/CSV; dla `six_*` potrzebne `full`. `-TraceOne` eksportuje ślad pierwszej wybranej walki do JSONL.

## Testy reguł

`tests/combat_tests.gd` kończy proces niezerowym kodem przy nieudanej asercji. Wrapper wykrywa także błędy parsera/runtime. Obecny zestaw: 326 asercji. Obejmuje:

- osiem poprawnych definicji, odrzucenie pustych/nieznanych/zbyt dużych składów;
- niezależność runtime i Resource oraz reset;
- neutralne 100 HP / 10 obrażeń co sekundę: brak trafienia przed 1 s, koniec około 10 s, TTK 9 s od pierwszego trafienia;
- równoczesne trafienia, remis, pierwszeństwo kolców, anulowanie śmiertelnego ciosu, nierekurencyjność, trzy trafienia kontra jedno;
- applied damage, proporcjonalny overkill i focus fire;
- swept collision, łańcuch trzech stykających się jednostek, blokowanie sojuszników, granice;
- opóźniony o 2 s/jednorazowy dive, pominięcie frontu, legalne lądowanie także po śmierci celu w locie;
- dash po przeżyciu trafienia, brak cofania damage/niewrażliwości, warunek pobliskiego melee, cooldown;
- wind-up Hipopotama, cooldown od rozpoczęcia, anulowanie serii przez śmierć;
- rzeczywistą redukcję damage przez Skunksa, odświeżanie bez stackowania i wygaśnięcie;
- pociski po śmierci strzelca oraz wygaśnięcie po śmierci celu;
- focus, retarget, wycofanie ranged, powtarzalność całego śladu i odbicie drużyn;
- wszystkie osiem lvl1 do zakończenia, zachowanie sumy obrażeń i poprawność liczb;
- 121 próbek geometrii sprawdza dokładne odbicie i siatkę 1/512 px dla przesunięcia, podejścia, interpolacji i granic;
- regresje lustrzanego 6v6: jednoczesne dive, self-match i wybór niemal równych celów; wynik, czas oraz HP;
- kontrolowane 6v6: wszystkie kroki w granicach, brak nakładania wrogów poza lotem, cooldowny, brak melee basiców w aktywnej akcji.

To zestaw regresyjny, nie formalny dowód wszystkich możliwych konfiguracji. Headless nie zastępuje sprawdzenia czytelności i interakcji sceny gry.

## Serie

`quick`: 332 przypadki:

- 64 uporządkowane 1v1 (z lustrami) × 5 wariantów odległości/offsetu = 320;
- 6 fixture'ów interakcji 2v2/3v3, każdy po obu stronach = 12.

`full`: 1180 przypadków:

- powyższe 332;
- wszystkie 28 składów po sześć różnych zwierząt × 28 przeciwników = 784;
- 64 kontrolne 1v1 bez umiejętności w geometrii wariantu `duel_0`.

Wszystkie mają seed 1. Zmiany seedu nie są sztucznymi niezależnymi próbami: jest to deterministyczne pokrycie zadanych scenariuszy, nie estymacja win rate populacji graczy. Rodziny 1v1, 6v6, interakcje oraz ablation są raportowane osobno. Domyślna geometria zespołów wynika z roli i slotu, tak jak w widoku gry. Warianty pozycji 1v1 są wyłącznie fixture'ami testowymi.

Watchdog po 120 sekundach symulacji oznacza `inconclusive`. Nie daje zwycięstwa/remisu i nie zmienia zasad końca walki w grze. Taki przypadek jest automatycznie odtwarzany ze śladem do diagnozy.

## Raporty i interpretacja

JSON zawiera silnik, datę UTC, dt, hash SHA-256 skryptów/danych z początku serii, opis próby, agregaty i pełne podsumowanie każdej walki z pozycjami, składem i seedem. CSV zawiera walki oraz oddzielnie metryki każdej jednostki. JSONL zawiera zdarzenia wybranej walki.

Win rate = zwycięstwa / zakończone walki (remisy w mianowniku, inconclusive poza nim). Score rate dodatkowo daje 0,5 punktu za remis. Udział drużynowy jednostki w 6v6 jest korelacją składu, nie efektem przyczynowym tej jednostki. >70% lub <30% to alert analizy, nie polecenie automatycznej korekty.

TTK dotyczy wyłącznie zabitych i liczy czas od pierwszego otrzymanego trafienia do śmierci. Ocalały ma -1 i nie wchodzi do średniej TTK. Czas walki, czas pierwszego trafienia i czas życia są osobne. Dla 6v6 raport zawiera udział 20–30 s, medianę i p90. Małe próbki oraz self-matchupy wymagają interpretacji.

Damage dealt/taken to faktycznie utracone HP. Overkill i anulowanie przez kolce zapisane osobno. Skill uses, okazje, śmierć przed okazją, status uptime / czas życia, zmiany celu / czas życia, pasmo ranged, udział obrażeń od focus fire i powstałe końcówki 1v1 zachowują jawne mianowniki. Udział focus nie dowodzi sam w sobie korzyści przyczynowej. Kontrola umiejętności wyłączonych jest narzędziem analizy, nie trybem gameplayowym.

## Odbiór

Testy i serie potwierdzają reguły oraz mierzą obecny balans. Osobno trzeba sprawdzić scenę 6v6 przy normalnej prędkości, odczytywanie ról i efektów oraz wpływ zmian składu. Przyjemność oglądania i czytelność potwierdza użytkownik/designer. Wynik testów nie jest takim potwierdzeniem.




Aktualizacja v0.1.1: regresje początkowej blokady aktywnych skilli/dashu (119/120 tick), zwykłego celu Orła przed dive, kolców i basiców od startu oraz kolizji sojuszników w ruchu/dashu/lądowaniu. Fixture testujące samą mechanikę umiejętności jawnie mogą ustawić startup_skill_delay=0; gra i runner używają domyślnych 2 s.

Dodano kontrolę Małpy bez skilli przeciw wszystkim ośmiu lvl1: sama ściana nie może powodować bezkończącego krążenia zamiast strzelania. Lokalne obchodzenie dotyczy blokady przez sojusznika.
# Celowana regresja v0.1.2

`godot --headless --path . --script res://tests/ranged_contact_tests.gd`: 39 sprawdzeń, pięć geometrii Orzeł–Małpa wraz z odbiciem stron, zwarcie bez ucieczki, wzajemne trafienia, próg zwolnienia, śmierć zagrożenia, wyjątek lotu i Małpa z ochroną. Uruchamiać przy zmianach tego zachowania bez obowiązkowego powtarzania całej macierzy balansu.
# Celowana regresja v0.1.3

`godot --headless --path . --script res://tests/skunk_ranged_tests.gd`: 24 sprawdzenia, w tym 8 presetów i ich lustra (dokładny wynik i czas), pocisk Skunksa bez wywoływania kolców, działanie chmury, zwarcie oraz wybór Skunksa przez dive. Pełna seria balansowa nie jest wymagana do tej próby roli.

## Celowana regresja v0.1.4

`godot --headless --path . --script res://tests/eagle_repeat_tests.gd`: 25 sprawdzeń, starty dive w 2/8/14 s, powtarzalne obrażenia w zwarciu, basic między skokami, brak pościgu za dalekim celem podczas cooldownu, wybór najdalszego melee przed bliższym ranged oraz 8 presetów i ich lustra. Wynik: PASS. Pełnej macierzy balansu nie uruchamiano.

## Przebudowa skilli

Bieżąca celowana weryfikacja: `godot --headless --path . --script res://tests/skill_redesign_tests.gd`. Sprawdza geometrię stożka i unik przez wyjście, stun i czas wygaśnięcia, DOT tylko wewnątrz chmury, jej wygaśnięcie, zerwanie aggro całej grupy, skok za plecy/legalne lądowanie i wyjątek1v1. Dodatkowo 8 presetów z lustrami sprawdza zakończenie i symetrię. Nie uruchamia pełnej macierzy balansu. Starsze raporty liczbowe nie opisują tego zestawu skilli.

Weryfikacja aktualnej przebudowy: 33 celowane sprawdzenia PASS (w tym 8 presetów i ich lustra), import/start Godot PASS, test prezentacji przy 0,5x/1x/4x PASS. Oceniono podglądy zwykłego renderera przy3,4s i4,1s (stożek, chmury, stun). Domyślna walka22,75s. Pełnej macierzy1180 nie uruchamiano. Balans pozostaje do playtestu.

## Czytelność UI i cooldownów
Celowana kontrola: `godot --headless --path . --script res://tests/skill_readiness_tests.gd` — początkowe 2 s, pełny odnawialny cooldown, utrzymanie gotowości, pasywki i niezależne skille hybrydy. Zmiany prezentacji nie wymagają ponawiania macierzy balansu.

Wynik: 9 sprawdzeń cooldownów PASS; kontrola UI i zwykłego renderera PASS (tura, partner z ławki, podgląd fuzji po powrocie z walki, paski po 1 i 4 sekundach). Końcowy import i start projektu PASS. Bez ponawiania symulacji balansowych.

## Wynik walki i audyt udziału skilli

`godot --headless --path . --script res://scripts/testing/skill_impact_runner.gd`: 80 bazowych walk drużynowych i 80 dopasowanych prób bez aktywnych skilli (kolce pozostają). Wynik: 160 zakończonych walk, zgodne sumy damage, 40 grup lustrzanych w obu wariantach, bez nieznanych kategorii i watchdogów. Raport: `reports/skill_impact/skill_impact.json`; interpretacja: `SKILL_IMPACT_REVIEW.md`. Hash końcowy źródeł: `1e9265c05cf28f8ef5421808e7201bb9ff80dbeec37087c2d133aa9720aa53c3`, start = koniec. To audyt aktualnych liczb, nie ich kalibracja.

Prezentacja zwycięstwa: zrzuty zwykłego renderera 1280×720 dla wygranej A/B, remisu i końca meczu ocenione bez przycięcia. Dodatkowo sprawdzono wynik B przez `finish_battle` i stan 4:5. `match_ui_smoke.gd` PASS; końcowy import/start Godota PASS. Nie uruchamiano pełnej macierzy 1996 walk.


## Prywatne online v0.1 (2026-09-25)

Celowane testy:

- `godot --headless --path . --script res://tests/online_session_test.gd` — dwie niezależne instancje MultiplayerAPI, handshake, niezgodna wersja z komunikatem u gościa, przenoszenie typów komend/stanu/zdarzeń.
- `godot --headless --path . --script res://tests/online_commands_test.gd` — własność jednostek, kolejność tury, nieaktualne/replikowane komendy, błędny format, niezależny snapshot modelu.
- Dwa procesy: `godot --path . --script res://tests/online_match_test.gd -- host` oraz identyczna komenda z `guest`. Port testowy 24678. Pełny przebieg ze skróconym wyłącznie w teście stanem 2 żyć: draft, zarządzanie składem, gotowość, walka, fuzje, wynik per jednostka, koniec meczu, rewanż i rozłączenie. Test zapisuje `user://online_test_host.json` i `online_test_guest.json`; pola `rounds` muszą być identyczne. Bez `--headless` zapisuje także zrzuty walki i wyniku.
- `godot --path . --script res://tests/selection_ui_test.gd` — jednoznaczny wybór, zachowanie przewinięcia strony i listy jednostek; zrzuty wyboru i lobby.
- `godot --path . --script res://tests/damage_summary_ui_test.gd` — nadal widoczne wszystkie 12 wierszy statystyk na wyniku rundy/meczu.

Wynik lokalnego testu dwóch procesów z rendererem: 2 rundy, 185 odebranych klatek walki, dokładnie identyczne kompletne podsumowania obu stron, rewanż i rozłączenie PASS. Wszystkie wymienione regresje PASS. Import/start projektu PASS. To test automatyczny, nie ręczny playtest dwóch osób przez internet.

Dodatkowa jednorazowa próba pojemności: wszystkie 12 lvl3 podzielone 6v6, wariant B, jedna walka do ticka 2041. 681 pakietów co 3 ticki przeszło walidację; największy 38 896 B przy limicie 131 072 B; maksymalnie 13 zdarzeń przy limicie 512. Próba kodeka obejmowała lokalne Resources skilli następczych, statusy, pociski, chmury i brak kroków symulacji u gościa. Nie powtarzano macierzy balansu.

Przy zmianie zasad, danych albo formatu sieciowego aktualizować `PROTOCOL_FINGERPRINT` w `scripts/network/online_session.gd`. Obie strony powinny otrzymać tę samą paczkę. Stan i klatki walki używają jednego uporządkowanego kanału, aby nie gubić zdarzeń przy zmianie fazy. Publiczny internet, opóźnienia i utrata pakietów wymagają dalszego testu na dwóch komputerach.
