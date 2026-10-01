# Aktualny stan i kontekst Kimoz

Aktualizacja: 2026-10-01. Ta mapa prowadzi do źródeł potrzebnych do zadania. Rozdziela stan kodu od designu i wyników historycznych. Reguły pracy: [AGENTS.md](../AGENTS.md); nadrzędne decyzje: [brief](../GAME_DESIGN_V0_2.md) oraz późniejsze wyraźne decyzje użytkownika.

## Najważniejsze priorytety użytkownika

Dwa równorzędne priorytety, potwierdzone 2026-10-01 w briefie §63:

- Wybór rezultatu hybrydy przy łączeniu do **lvl2 i lvl3**. Gracz ma rozumieć dostępne opcje i konsekwencje wyboru.
- Czytelne GUI i feedback: zrozumienie własnej drużyny, dostępnych wyborów oraz przebiegu walki. Obecny odbiór jest niejasny i pogarsza przyjemność gry.

Przykład problemu jakości: zlecone animacje działały, ale były znacznie słabsze wizualnie niż oczekiwał użytkownik. Przy zmianach wizualnych/gameplayowych obowiązuje nagranie lub porównanie, a potem ocena i playtest użytkownika. Szczegóły odbioru: [workflow zadania](TASK_WORKFLOW.md).

## Działająca implementacja

Stan odczytany z kodu baseline `4bb6b80`. To opis implementacji, nie deklaracja aktualnego PASS wszystkich testów.

- Godot 4.7.2, GDScript, 2D, Compatibility; scena startowa `scenes/main.tscn`.
- Lokalny mecz 1v1, Combat Lab oraz prywatne online po IP lub przez pokoje EOS. Konfiguracja i realny test połączenia opisane w [EOS_SETUP.md](EOS_SETUP.md).
- Katalog: 8 lvl1, 12 lvl2, 12 lvl3. Każda legalna para rodziców daje obecnie jeden ustalony wynik; **wybór wariantu przy fuzji nie jest jeszcze wdrożony**. Źródło: `scripts/data/catalog.gd`, metoda `fusion()`.
- Wspólna pula ośmiu bazowych zwierząt; start ABBA daje po dwa. Dalej standardowo dwie akcje: dobór lub fuzja. Jednorazowo dodatkowa akcja po spadku do dwóch żyć i osobno do jednego; remis nie odnawia bonusu.
- Pięć żyć, sześć miejsc aktywnych, trzy na ławce. Lvl1 + lvl1 → lvl2, lvl2 + lvl2 → lvl3 według zaimplementowanych przepisów. Reguły: `scripts/match/match_model.gd`.
- Pełny mecz korzysta z B. Bazowy Królik ma skok z tarczą (`shield_jump`), Małpa jest ranged; zwykłe ranged nie utrzymują automatycznie preferowanego dystansu.
- Cały roster ma kreskówkowe sylwetki; cztery postacie mają osobne pozy. Hipopotam ma osobny rig z części. Istnienie assetów i animacji nie potwierdza jakości oczekiwanej przez użytkownika.

## Warianty i przyszły design

- **A**: historyczne liczby lvl1/lvl2 i wybrane historyczne zachowania w Combat Lab. Lvl3 nie jest odtwarzany jako osobny historyczny zestaw liczb. Źródło: `scripts/data/combat_variants.gd`.
- **B**: dane i zachowania używane w pełnym meczu; nie utożsamiać ich z przyszłym rosterem.
- **T**: oddzielny Teamfight Lab, eksperyment ról i sytuacyjnego AI; `teamfight_simulation.gd` i `teamfight_definitions.gd`. Zachowania T nie obowiązują automatycznie w B.
- **Zatwierdzony kierunek**: nowe role i dominacja, dwa kierunki hybryd lvl2, nowa macierz par; opis w [warsztacie hybryd](HYBRID_DOMINANCE_WORKSHOP.md) i briefie §62. Nowe Resources nie zostały wdrożone.
- **Otwarte**: nieomówione warianty hybryd, przepisy i sposób dziedziczenia dominacji na lvl3 oraz dokładny zestaw opcji wyboru lvl3. Priorytet wyboru lvl3 nie rozstrzyga tych zasad.
- **Odłożone**: więzi drużynowe; [GENE_BONDS_PLAN.md](GENE_BONDS_PLAN.md) jest starszą propozycją, nie bieżącym zakresem wdrożenia. Nie wprowadzaj golda, sklepu ani oceny „siły teamu” bez określenia reguł. Użytkownik mówi o zakupie/wyborze jednostek; obecna gra używa akcji dobierania, nie waluty.

## Dobór kontekstu do zadania

- **Draft, fuzja, lvl2/lvl3**: brief §53, §55, §62–63; dla przyszłego designu `HYBRID_DOMINANCE_WORKSHOP.md`. Sprawdź `catalog.gd`, `match_model.gd`, Resources rodziców i wyników. Mapa kodu: [COMBAT_IMPLEMENTATION.md](COMBAT_IMPLEMENTATION.md).
- **GUI, informacje o drużynie i wyborach**: brief §44–45, §48, §50–52, §57, §59, §61, §63; późniejsze sekcje zastępują starsze w odpowiednim zakresie. Kod: `match_controller.gd`, `development_view.gd`, `unit_info.gd`.
- **Combat i balans B/A**: brief §42–43, §47, §49, §53, §60–61; kod `combat_simulation.gd`, `combat_movement.gd`, `combat_variants.gd` i zmieniane Resources. Raport czytaj z datą/hashami; nie stosuj historycznych liczb jako aktualnej kalibracji.
- **Eksperyment T**: [TEAMFIGHT_LAB_V0_1.md](TEAMFIGHT_LAB_V0_1.md), `teamfight_simulation.gd`, `teamfight_definitions.gd`; zachowaj izolację od B.
- **Animacja i feedback walki**: brief §58, §61, §63; [wdrożona oprawa](art_direction/v0_1/IMPLEMENTED.md), [animacja Hipopotama](art_direction/v0_1/HIPPO_ANIMATION.md); kod widoków i efektów. Odbiór: `TASK_WORKFLOW.md`.
- **Online i eksport**: [EOS_SETUP.md](EOS_SETUP.md), [ONLINE.md](ONLINE.md) jako starsza instrukcja IP z późniejszą aktualizacją EOS; `scripts/network/`, `export_presets.cfg`, skrypt pakowania. Przy zmianie zasad/danych/formatu sprawdź fingerprint protokołu. Nie utożsamiaj lokalnego testu ENet z testem EOS przez internet.

W każdym zadaniu przeczytaj kod dotkniętego obszaru; mapa nie zastępuje odczytu implementacji. Przy niejasnym zakresie lub sprzeczności prześledź odpowiednie późniejsze decyzje w briefie i `kierunek.md`. Przy szerokiej przebudowie przeczytaj cały brief.

## Baseline i granice weryfikacji

`4bb6b80` to pierwszy commit zastanego systemu. Oddzielny audyt i manifest powstały przed porządkowaniem dokumentacji. Niniejsza mapa jest zmianą kontekstu do późniejszego porównania; nie jest wynikiem benchmarku modeli.

Nie ma jeszcze potwierdzonego wspólnego zielonego zestawu regresji na tym baseline. [VERIFICATION_MAP.md](VERIFICATION_MAP.md) wskazuje rodziny kontroli i znane historyczne oczekiwania. Zanim ocenimy model za regresję, trzeba odróżnić wcześniejszą awarię od nowej. Koszt, tokeny, pierwszy odbiór i czas użytkownika mierzymy przy rzeczywistych zadaniach; brak danych zapisujemy jako nieznany.
