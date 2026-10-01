# Mapa implementacji Kimoz

Aktualizacja mapy: 2026-10-01, na podstawie kodu baseline `4bb6b80`. Rozdzielenie implementacji, wariantów i przyszłego designu: [CURRENT_STATE.md](CURRENT_STATE.md). Poniższy opis nie oznacza nowego przebiegu wszystkich testów.

## Uruchomienie i odpowiedzialności

`scenes/main.tscn` jest wejściem menu, z którego uruchamiany jest mecz `scenes/match/match.tscn` lub Combat Lab. `scripts/match/match_model.gd` przechowuje fazę meczu, życia, oferty, akcje i trwałe składy. `scripts/presentation/match_controller.gd` obsługuje draft, łączenie, przygotowanie, wynik i integrację online. Każdą walkę przekazuje do osadzonej sceny `scenes/combat/combat_prototype.tscn`.

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

`ZooUnitDefinition`, `ZooSkillDefinition`, `ZooStatusDefinition`, `ZooMatchDefinition` w `scripts/data/` definiują zasoby w `resources/`. `ZooCatalog` zawiera osiem lvl1, dwanaście lvl2 i dwanaście lvl3. Pary rodziców wyznaczają legalne fuzje; obecne `fusion()` zwraca jeden ustalony wynik, bez wyboru wariantu. Nowa macierz i dominacja opisane w warsztacie pozostają przyszłym designem.

Lista skilli obsługuje aktywne oraz pasywne mechaniki. Runtime ma jedną aktywną akcję; serie, kolejne skoki i ciosy po dashu to fazy tej akcji, a lvl3 korzysta również z następczych skilli. Stun przerywa akcję, krótkie zachwianie tylko opóźnia. Slow wpływa na zwykły ruch wewnątrz chmury. Nie wdrożono ogólnego edytora dowolnych efektów. Liczby/kontrakty danych sprawdzaj w aktualnych Resources; `resources/README.md` zawiera także wcześniejsze parametry.

Wartości techniczne, kadencje i geometria są opisane w `resources/README.md`. Zmiana parametru nie wymaga zmiany kodu konkretnego zwierzęcia.

## Prezentacja i telemetry

`unit_view.gd` korzysta z kreskówkowych assetów/atlasów i osobnego rigu Hipopotama; odczytuje stan, akcje, HP i tarcze. `effects_view.gd` interpretuje zdarzenia walki. `development_view.gd` przedstawia drzewko rozwoju, a `unit_info.gd` informacje o jednostkach. Żaden efekt wizualny nie jest warunkiem trafienia. Żywe ciała są rozdzielane przez ruch; rysunek lub animacja może wychodzić poza promień kolizji. Odbiór jakości opisuje `TASK_WORKFLOW.md`.

Ostatnia walka interaktywna zapisuje `user://last_combat.json`. Runner eksportuje JSON, CSV walk, CSV jednostek oraz opcjonalny ślad JSONL. Dokładne definicje mianowników, powtórzenie scenariusza i testy: `TESTING.md`.

## Warianty i sieć

`combat_variants.gd` klonuje dane A/B; pełny mecz używa B. `teamfight_simulation.gd` rozszerza rdzeń, korzystając z oddzielnych definicji eksperymentu T; nie utożsamiaj ról T z danymi normalnego meczu.

`scripts/network/online_session.gd` obsługuje autorytet gospodarza, wersję i walidację danych dla ENet/EOS. `combat_wire.gd` przenosi stan/zdarzenia walki: gość wyświetla wynik symulacji gospodarza, zamiast wykonywać niezależny lockstep. `eos_rooms.gd`, `packet_chunks.gd` i `eos_lifecycle.gd` obsługują pokoje, fragmentację i zamknięcie usługi. Szczegóły oraz ograniczenia: `EOS_SETUP.md`.

## Ograniczenia weryfikacji

Deterministyczność jest testowana na tym samym silniku/platformie. Nie obiecuje zgodności bitowej między platformami ani nie stanowi implementacji sieciowego lockstep. Dane testowe nie zastępują playtestu z użytkownikiem. Dobór aktualnych kontroli i oczekiwania historyczne: `VERIFICATION_MAP.md`. Zmiany gameplayowe poza zaakceptowanym zakresem wymagają osobnego zlecenia.
