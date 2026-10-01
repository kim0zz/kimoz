> Uwaga: opisy i wyniki Skunksa, Jeża–Skunksa oraz Skunksa–Królika poniżej dotyczą stanu sprzed przebudowy na ruchomy ślad smrodu. Aktualny design: §49 GAME_DESIGN_V0_2.md; bieżące liczby: Resources.

# Pełny roster skilli v0.2

## Warianty A/B

`CombatVariants.definitions("A")` i `definitions("B")` zwracają osobne, głęboko sklonowane definicje wszystkich 8 jednostek lvl1 i 12 hybryd lvl2.

- **A** odtwarza stan liczbowy zasobów z chwili przed rozszerzeniem próby. Liczby wszystkich jednostek i umiejętności są zapisane w `resources/balance/full_roster_baseline.json`; dotyczy to również trzech pilotów, których wersja B była już wtedy aktywna.
- **B** czyta bieżące zasoby i zachowuje znane liczby pilotów Orzeł–Hipopotam, Małpa–Hipopotam i Niedźwiedź–Gepard.
- Pasywne kolce mają początkowy cooldown 0 s. Każda aktywna umiejętność ma własny początkowy cooldown; późniejsze użycia nadal korzystają z normalnego cooldownu zasobu.

Wariant A zachowuje wartości liczbowe, nie kopiuje zewnętrznych zasobów do drugiego zestawu plików. Klony obu wariantów nie mutują wspólnych Resources.

## Wartości lvl1

| Zwierzę | Basic: obrażenia / interwał | Skill w B | Pierwsza gotowość / kolejne użycie |
| --- | ---: | --- | ---: |
| Niedźwiedź | 6,5 / 1 s | Zamaszysta łapa: 45 obrażeń w stożku | 4 / 5 s |
| Gepard | 3,5 / 0,333 s | Seria: 3 × 15 obrażeń | 3,5 / 5 s |
| Orzeł | 7 / 1 s | Nurkowanie: 55 obrażeń | 4 / 6 s |
| Jeż | 5,5 / 1 s | Kolce: 3 obrażenia zwrotne za trafienie melee, pasywnie | 0 / pasywne |
| Hipopotam | 6 / 1,5 s | Ciężki cios: 45 obrażeń, ogłuszenie 1 s | 4,5 / 6 s |
| Małpa | 6,5 / 1 s | Banan: 38 obrażeń | 3,5 / 4 s |
| Królik | 5,5 / 0,5 s | Skok z odciągnięciem aggro, bez obrażeń | 2,5 / 5 s |
| Skunks | 4 / 1 s | Chmura: 6 obrażeń co 0,5 s przez 3 s, maks. 36 | 3,5 / 6 s |

Podstawowe trafienia spadają w większości, a większy udział przechodzi do istniejących ataków specjalnych. Wyjątkiem jest Królik: jego skill zapewnia pozycję i kontrolę aggro, nie zadaje obrażeń, więc zachowuje podstawowy atak. Jeż ma mniejszą redukcję basics i umiarkowanie mocniejsze kolce, aby jego kontaktowa kontra pozostała odczuwalna.

## Wartości hybryd lvl2

W tabeli podano basic, główne obrażenia skilla oraz osobną gotowość otwarcia i normalny cooldown. Przy umiejętności wieloczęściowej każda porcja jest wypisana osobno. Czasy kontroli w sekcji 42 pozostają bez zmian.

| Hybryda | Basic: obrażenia / interwał | Skill i otwarcie / cooldown |
| --- | ---: | --- |
| Niedźwiedź–Gepard | 6 / 0,5 s | Stożek: 3 × 24; 3,5 / 7 s |
| Niedźwiedź–Jeż | 5,5 / 0,5 s | Stożek 40; kolce 4 pasywnie; 4 / 6 s |
| Niedźwiedź–Małpa | 6,5 / 0,5 s | Stożek 34 + pocisk 14; 4 / 7 s |
| Gepard–Orzeł | 8 / 0,5 s | Trzy skoki: 3 × 15 obrażeń; 3,5 / 7 s |
| Gepard–Królik | 7 / 0,5 s | Skok i 3 × 14; 2,5 / 5,5 s |
| Małpa–Skunks | 6,2 / 0,5 s | Pocisk 9 + chmura 5 co 0,5 s przez 3 s; spowolnienie bez zmian; 3,5 / 4,5 s |
| Małpa–Hipopotam | 6 / 0,5 s | Banan 65 + ogłuszenie 1,25 s; 4,5 / 10 s |
| Orzeł–Jeż | 5,5 / 0,5 s | Nurkowanie 40; kolce 3 pasywnie; 4 / 6 s |
| Orzeł–Hipopotam | 6 / 0,5 s | Nurkowanie 80 + ogłuszenie 2 s; 5 / 12 s |
| Hipopotam–Królik | 6,5 / 0,5 s | Skok, następnie 45 + ogłuszenie 1,2 s; 4,5 / 7,5 s |
| Jeż–Skunks | 5,5 / 0,5 s | Chmura 6 co 0,5 s przez 3 s; kolce 3 pasywnie; 3,5 / 6 s |
| Skunks–Królik | 6 / 0,5 s | Chmura 6 co 0,5 s przez 3 s; boczny skok bez obrażeń; 3,5 / 6 s dla chmury, 2,5 / 5,5 s dla skoku |

Moc rozdzielono zgodnie z rolą: seria Geparda zachowuje rytm kilku trafień; Orzeł–Hipopotam odkłada największe uderzenie na późniejszy moment; chmury wygrywają, jeśli cel pozostanie w obszarze; kolce nadal karzą przeciwnika za wielokrotne trafianie Jeża; Królik i hybrydy z jego skokiem korzystają z mobilności bez dopisywania obrażeń do czysto użytkowego skilla. Nie zwiększono czasów ogłuszenia ani zachwiania. Nie zakładano jednakowego udziału skilli ani celu 50/50 w pojedynkach.

## Sprawdzenie liczb

- `tests/burst_pilot_tests.gd`: 102 asercje, w tym pełna zgodność A z snapshotem, izolacja klonów, 24 indywidualne wartości gotowości skilli i gotowość pasywnych kolców od ticka 0.
- B przeciw pojedynczym lvl1: 576 scenariuszy, wszystkie 96 parowań hybryda–lvl1 wygrane przez hybrydę; 288 par lustrzanych zgodnych pod względem wyniku i czasu, bez utknięć ani nakładania startowych pozycji.
- Po korekcie chmury Małpy–Skunksa ponownie sprawdzono jej 48 pojedynków lvl2–lvl1: wszystkie ukończone, bez utknięć. Wyniki mieszczą się w opisanych parach lustrzanych.
- Raporty: `reports/lvl2/full_roster_candidate/singles.json` oraz `reports/lvl2/monkey_skunk_cloud_check/`.

To deterministyczne scenariusze kontrolne, a nie estymacja populacyjnego win rate. Para i drużyna mogą osłaniać jednostkę o słabej samodzielności; wymagania o kontrach rozstrzyga szersza seria A/B oraz walk zespołowych.

