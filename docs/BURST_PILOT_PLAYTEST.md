# Mocniejsze skille — próba v0.2

> Archiwum pierwszej próby trzech hybryd. Obecnie zmieniono cały roster (§47 GAME_DESIGN); A oznacza stan sprzed rozszerzenia, zawierający już trzy poprawione hybrydy. Aktualny playtest: presety „Cały roster”, wariant B, prędkość 1×. Liczby w FULL_ROSTER_SKILLS.md, wyniki w FULL_ROSTER_RESULTS.md.

## Jak porównać

W Combat Lab wybierz jeden z trzech ostatnich presetów: „Próba • ciężki skok”, „Próba • potężny banan” albo „Próba • trzy stożki”. Zacznij przy prędkości 1×.

- B: nowe liczby i osobne początkowe cooldowny. To także wariant używany w pełnym meczu.
- A: poprzednie liczby i początkowy cooldown 2 s.
- Oba warianty mają te same nowe efekty. Przełącznik działa podczas pauzy i resetuje walkę, zachowując skład.

Oceń, czy rozpoznajesz przygotowanie i moment trafienia, czy seria ma trzy czytelne uderzenia oraz czy oczekiwanie na mocny skill jest przyjemne. Gotowy pasek oznacza gotowość cooldownu; dojście do celu, przygotowanie i lot pocisku mogą opóźnić trafienie.

## Zakres

Tylko Orzeł–Hipopotam, Małpa–Hipopotam i Niedźwiedź–Gepard. Wyróżnione obrażenia, efekty trafienia, ślad utraconego HP, krótka reakcja sylwetki oraz robocze dźwięki. Reakcja sylwetki nie przesuwa jednostki w symulacji. Finalny artwork i rozszerzenie na pozostałe zwierzęta czekają na ocenę tej próby.

Liczby oraz wyniki symulacji: [BURST_PILOT_NUMBERS.md](BURST_PILOT_NUMBERS.md).

## Co sprawdzono technicznie

- Import i uruchomienie projektu: `tools/godot.ps1 check` — PASS.
- Początkowe i kolejne cooldowny, pasywne kolce oraz izolacja wariantów: `tests/burst_pilot_tests.gd` — PASS.
- Paski gotowości, w tym 5-sekundowe pierwsze ładowanie: `tests/skill_readiness_tests.gd` — 10 kontroli PASS.
- A/B zachowuje składy, reset usuwa efekty, pełny mecz wraca do B. Wyniki z prezentacją przy 1× i 4× są identyczne z samą symulacją: `tests/burst_presentation_tests.gd` — PASS.
- Zrzuty rzeczywistych trafień wszystkich trzech skilli wykonano w rendererze Compatibility; sprawdzono także widok wariantu A. Nie był to ręczny test klikania ani ocena grywalności.
- Sprawdzono generowanie trzech niepustych próbek dźwiękowych. Nie wykonano odsłuchu; brzmienie pozostaje do oceny w playteście.

Wąskie gardło dalszego rozwoju to teraz ocena odczucia walki, a nie kolejna duża seria identycznych symulacji.
