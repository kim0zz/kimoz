# Combat Prototype v0.1 — mapa implementacji

## Uruchomienie i odpowiedzialności

`scenes/main.tscn` instancjonuje `scenes/match/match.tscn`. `scripts/match/match_model.gd` przechowuje fazę meczu, życia, oferty, akcje i trwałe składy. `scripts/presentation/match_controller.gd` obsługuje lokalny draft, łączenie, przygotowanie i wynik. Każdą walkę przekazuje do osadzonej sceny `scenes/combat/combat_prototype.tscn`; Combat Lab nadal jest dostępny osobno.

Kontroler walki tworzy widoki i jedną instancję `CombatSimulation`. Nie oblicza obrażeń ani celów. W `_physics_process` akumulator przelicza czas prezentacji na kroki 1/60 s; zmiana szybkości nie zmienia DT.

`scripts/combat/combat_simulation.gd` jest autorytatywnym rdzeniem, bez zależności od sceny, grafiki czy fizyki Godot. Stan jednostek to osobne słowniki runtime. Wspólne Resources nigdy nie przechowują bieżącego HP ani cooldownów. `combat_movement.gd` rozwiązuje kontakt kół przeciwników; od v0.1.1 sojusznicy również blokują ruch, a lokalne obchodzenie pomaga uniknąć kolejki.

Dla ośmiu lvl1 systemy targetowania, akcji, pocisków, statusu i rozliczania trafień pozostają metodami jednego rdzenia. Nie tworzono osobnych frameworków ani klasy dla każdego gatunku. Wybór zachowania opiera się na `role` i `skill.behavior`, a liczby na Resources. Oddzielenie metod do modułów w przyszłości nie powinno zmienić kontraktu symulacji.

## Kontrakt

- `setup(team_a, team_b, seed, options)` resetuje stan, przyjmuje po 1–6 ID oraz opcjonalne fixture'y pozycji/definicji i `disable_skills` / `trace`.
- `step()` wykonuje dokładnie jeden krok; po końcu nic nie zmienia.
- `summary()` zwraca wynik i statystyki jednostek.
- `events` zawiera zdarzenia ostatniego kroku dla prezentacji; `trace` opcjonalnie zapisuje całą historię zdarzeń.
- `resolve_hits()` i `apply_status()` są też punktami wejścia testów reguł.

Koniec gry wynika wyłącznie z pełnego wybicia drużyny. Watchdog jest własnością runnera, nie silnika walki. Obrażenia są deterministyczne; seed rozstrzyga tylko remisy w wyborze celów.

Pozycje są liczone względem środka areny i przechowywane na siatce 1/512 piksela. Jest to niewidoczna normalizacja precyzji liczb, która zapobiega rozchodzeniu się lustrzanych trajektorii przy dodawaniu przesunięcia do dużych współrzędnych świata. Obowiązuje również dla dash, dive i pocisków. Kontakt ma margines 2/512 piksela zapobiegający penetracji przy zaokrągleniu; nie zmienia nominalnych promieni jednostek ani statystyk balansu.

## Dane i rozszerzalność

`ZooUnitDefinition`, `ZooSkillDefinition`, `ZooStatusDefinition`, `ZooMatchDefinition` w `scripts/data/` definiują zasoby w `resources/`. Katalog zawiera osiem lvl1 i dwanaście lvl2, a pary rodziców wyznaczają legalne fuzje. Lista skilli obsługuje aktywne oraz pasywne mechaniki. Runtime ma jedną aktywną akcję; serie, kolejne skoki i ciosy po dashu to fazy tej akcji. Stun ją przerywa, krótkie zachwianie tylko opóźnia. Slow wpływa na zwykły ruch wewnątrz chmury. Nie wdrożono lvl3 ani ogólnego edytora dowolnych efektów.

Wartości techniczne, kadencje i geometria są opisane w `resources/README.md`. Zmiana parametru nie wymaga zmiany kodu konkretnego zwierzęcia.

## Prezentacja i telemetry

`unit_view.gd` rysuje osiem roboczych sylwetek i hybrydy łączące cechy rodziców, oznaczenie II oraz HP/status/animację. `effects_view.gd` interpretuje zdarzenia walki. Żaden efekt wizualny nie jest warunkiem trafienia. Od v0.1.1 wszystkie żywe ciała są rozdzielone; animowany obrys lub podpis nadal może wychodzić poza promień ciała.

Ostatnia walka interaktywna zapisuje `user://last_combat.json`. Runner eksportuje JSON, CSV walk, CSV jednostek oraz opcjonalny ślad JSONL. Dokładne definicje mianowników, powtórzenie scenariusza i testy: `TESTING.md`.

## Ograniczenia techniczne v0.1

Deterministyczność jest testowana na tym samym silniku/platformie. Nie obiecuje zgodności bitowej między platformami ani nie stanowi implementacji sieciowego lockstep. Dane testowe nie zastępują playtestu z użytkownikiem. Zmiany gameplayowe poza zaakceptowanym zakresem wymagają osobnego zlecenia.
