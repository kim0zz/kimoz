# Weryfikacja rozszerzenia skilli na cały roster

## Relacje poziomów i kontry

Pokrycie bieżących liczb to 1948 różnych scenariuszy regresji. Nie są to losowe próbki ani turniejowy win rate.

- **576 lvl2 kontra pojedynczy lvl1:** wszystkie 96 parowań wygrywa hybryda, w trzech geometriach i po obu stronach.
- **864 lvl2 kontra para lvl1:** 468 wygranych hybrydy, 396 wygranych pary. Każda hybryda ma zarówno wygrane, jak i porażki przeciw parom.
- **72 lvl2 kontra trzy wybrane składy trójek:** 4 wygrane hybrydy, 68 wygranych trójki. Wygrywały Niedźwiedź–Jeż i Jeż–Skunks, po obu stronach.
- **420 lvl2 kontra lvl2** i **16 mieszanych walk** domykają serię. Wynik pojedynku nie jest celem do wyrównania do 50/50. Historyczny próg diagnostyczny 35–65% z runnera nie jest kryterium akceptacji.
- Wszystkie walki zakończone, bez watchdogów i początkowego nakładania ciał. Wszystkie 974 pary lustrzane mają zgodny wynik i czas.

Źródła: `reports/lvl2/full_roster_candidate/singles.json` oraz `reports/full_roster/full_roster_regression.json`.

## Jedna korekta i ponowne użycie niezmienionych wyników

Po pierwszych pojedynkach zmieniono wyłącznie tick chmury Małpy–Skunksa z 3 na 5. Redukcja basica bez poprawy chmury nie realizowała zamierzonego przeniesienia mocy do skilla. Jej 48 pojedynków sprawdzono ponownie — wszystkie wygrane. Pozostałych 528 nie powtarzano.

Porównanie hashy potwierdza, że między pierwszym raportem a końcową szeroką serią różnił się wyłącznie `resources/hybrid_skills/monkey_skunk_banana.tres`. Raporty powtórzonych 48 przypadków w `reports/lvl2/monkey_skunk_cloud_check/` odpowiadają końcowym źródłom. 1948 oznacza unikalne przypadki z aktualnym wynikiem, nie liczbę uruchomień silnika.

## Testy techniczne i prezentacja

Zaktualizowano stare oczekiwania testów o wspólnych 2 s otwarcia i dawnych obrażeniach: teraz kontrolują terminy i damage wynikające z definicji, zachowując sprawdzenia mechanik.

- `tests/combat_tests.gd`: 326 istniejących kontroli rdzenia — PASS.
- `eagle_repeat_tests.gd`, `skunk_ranged_tests.gd`, `skill_redesign_tests.gd`: odpowiednio 25, 24 i 33 kontrole — PASS.
- `tests/burst_pilot_tests.gd`: 102 kontrole zgodności zapisanej bazy A, niezależności Resources, indywidualnego pierwszego cooldownu wszystkich skilli oraz kolejnych użyć — PASS.
- `tests/hybrid_mechanics_tests.gd`: 27 kontroli serii, ogłuszenia, reakcji, chmur i legalnego ruchu — PASS.
- `tests/skill_readiness_tests.gd`: 10 kontroli pasków gotowości — PASS.
- `tests/burst_presentation_tests.gd`: wszystkie 20 jednostek w składach testowych, A/B, reset, wymuszenie B w pełnym meczu oraz identyczny wynik prezentacji przy 1× i 4× względem rdzenia — PASS.
- `tools/godot.ps1 check`: import i uruchomienie — PASS.
- Renderer Compatibility: sześć zrzutów dwóch nowych presetów 6v6 po 5,5, 9 i 14 sekundach. Oceniono czytelność trafień, statusów, chmur, pasków oraz nowych kontrolek. Nie był to ręczny test klikania ani odsłuch; finalny odbiór tempa i brzmienia wymaga playtestu.

Porównanie zespołowe A/B, udział skilli i metryki ról opisuje `FULL_ROSTER_RESULTS.md`. Dane aktualnych jednostek: `FULL_ROSTER_SKILLS.md`.
