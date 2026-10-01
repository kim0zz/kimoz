# Combat Prototype v0.1 — raport implementacji

## Zakres i uruchomienie

W projekcie `kimoz` działa Combat Lab: jedna arena 2D, ręczne składy po 1–6 jednostek, osiem lvl1, presety, start/pauza/reset, pojedynczy krok i prędkości 0,5×–4×. Uruchom projekt w Godot przez F5, ustaw składy i kliknij Start.

Zaimplementowano ruch z blokowaniem przeciwników, targetowanie ról, walkę melee, dystans i pociski Małpy, jednorazowy dive Orła, reaktywny dash Królika, kolce Jeża rozliczane pierwsze, osłabienie Skunksa, ciężki cios Hipopotama, serię Geparda i mocny cios Niedźwiedzia. Działają focus fire bez limitu atakujących, HP, obrażenia, cooldowny, wind-up/recovery, status, śmierć oraz eliminacja drużyny i jednoczesny remis.

Wspólny rdzeń z krokiem 1/60 s obsługuje widok i headless. Parametry są w Resources, stan walki jest oddzielny. Robocza grafika jest rysowana w kodzie: osiem sylwetek, obrysy, HP, kolory drużyn i efekty zdarzeń. Nie dodano systemów spoza zleconego zakresu.

## Weryfikacja

- Import i start projektu w Godot 4.7.2: PASS.
- Testy reguł: 274 asercje, 0 błędów.
- Kontroler prezentacji przy 0,5×, 1× i 4×: zgodne pełne podsumowania z headless, podczas i po walce; działają pauza, reset i zatrzymanie wyniku.
- Osiem dodatkowych lustrzanych 6v6 jednego gatunku: osiem remisów, bez przenikania przeciwników w sprawdzanych krokach.
- Końcowy audyt: 1174 porównania lustrzanych zestawień, wszystkie z prawidłowo odwróconym wynikiem i dokładnie identycznym czasem. Błąd precyzji znaleziony w seriach diagnostycznych został usunięty.
- Uruchomiono zwykłe okno gry z rendererem Compatibility i obejrzano zrzut 6v6. Sygnały/kontroler sprawdzono automatycznie; nie jest to playtest użytkownika ani ręczny test myszą wszystkich kontrolek.

## Końcowa seria symulacji

1180 przypadków: 320 pojedynków (64 pary × 5 geometrii), 12 interakcji 2v2/3v3, 784 zestawienia 6v6 bez duplikatów oraz 64 kontrolne pojedynki bez skilli. Seed 1; powtórzenia deterministyczne nie są niezależną próbą populacji graczy. Remis pozostaje w mianowniku win rate; watchdog 120 s oznacza nierozstrzygnięty test, nigdy regułę zakończenia gry.

- **1v1**: 320 walk; A/B/remis: 140/140/40; nierozstrzygnięte: 0. Czas: średnia 12.11 s, mediana 11.15 s, p90 17.97 s.

- **1v1_no_skills**: 64 walk; A/B/remis: 26/26/12; nierozstrzygnięte: 0. Czas: średnia 15.58 s, mediana 14.98 s, p90 21.8 s.

- **6v6**: 784 walk; A/B/remis: 378/378/28; nierozstrzygnięte: 0. Czas: średnia 29.52 s, mediana 30.18 s, p90 38.32 s.

- **interactions**: 12 walk; A/B/remis: 6/6/0; nierozstrzygnięte: 0. Czas: średnia 18.51 s, mediana 18.51 s, p90 21.9 s.

W 6v6 38.52% walk mieści się w 20–30 s; końcówka 1v1 występuje w 18.37% walk. Jej mediana trwa 4.88 s.

Osobny podzbiór równych jednostek: 40 self-matchupów (osiem gatunków × pięć geometrii), wszystkie remisowe. Mediana 13.73 s, średnia 14.56 s, p90 25.93 s; tylko 7/40 w oknie 10–12 s. Mediana całej macierzy 1v1 nie potwierdza więc celu dla równych pojedynków. Neutralny fixture 100 HP / 10 DPS kończy się w 10 s od startu kontaktu, z TTK 9 s od pierwszego trafienia.

### Metryki jednostek w 6v6

Win rate oznacza wynik drużyn zawierających jednostkę — nie dowodzi jej samodzielnego wpływu. Damage dealt/taken to średnia faktycznych obrażeń na występ. TTK to mediana czasu od pierwszego otrzymanego trafienia do śmierci, wyłącznie wśród zabitych. Użycia skilli są sumą aktywacji/triggerów w próbie; dla kolców to trafienia odwetowe, nie casty.

- **Niedźwiedź** (1176 występów): win rate 50%; przeżycie 27.55%; damage dealt/taken 105.32/130.8; TTK 6.42 s; skille: bear_slam: 3848.

- **Gepard** (1176 występów): win rate 46.26%; przeżycie 14.97%; damage dealt/taken 106.99/73.4; TTK 2.22 s; skille: cheetah_flurry: 3048.

- **Małpa** (1176 występów): win rate 55.78%; przeżycie 55.78%; damage dealt/taken 215.14/58.83; TTK 25.21 s; skille: monkey_banana: 8836.

- **Orzeł** (1176 występów): win rate 36.05%; przeżycie 0.68%; damage dealt/taken 35.76/84.86; TTK 5.63 s; skille: eagle_dive: 1176.

- **Jeż** (1176 występów): win rate 49.66%; przeżycie 25.34%; damage dealt/taken 71.28/100.28; TTK 4 s; skille: hedgehog_thorns: 11750.

- **Hipopotam** (1176 występów): win rate 50.51%; przeżycie 20.92%; damage dealt/taken 74.8/144.72; TTK 6.22 s; skille: hippo_heavy: 3308.

- **Skunks** (1176 występów): win rate 48.13%; przeżycie 27.21%; damage dealt/taken 42.75/87.53; TTK 5.37 s; skille: skunk_cloud: 3954.

- **Królik** (1176 występów): win rate 49.32%; przeżycie 27.55%; damage dealt/taken 92.24/63.86; TTK 4.97 s; skille: rabbit_dash: 1686.

### Outliery i interpretacja

Alerty macierzy 1v1 (>70% / <30% zwycięstw): Orzeł 25%, Hipopotam 82.5%, Małpa 80%, Królik 12.5%, Skunks 0%. Role wsparcia i mobilne nie muszą osiągać 50% w pojedynkach. W 6v6 wynik jednostki jest skorelowany z pozostałą piątką; bez kontrolowanej przyczyny nie stroimy statów na podstawie samego udziału zwycięstw.

Jednostki z okazją do użycia skilla, ale bez żadnej aktywacji w 6v6: 0. Małpa spędza 47.62% obserwowanego czasu z żywym celem w preferowanym paśmie. Obserwacja jest zapisana także podczas castu; nie oznacza to, że poza pasmem nie atakuje.

Orzeł jest najważniejszym kandydatem do przeglądu: drużyny z nim wygrywają 36.05%, a on sam przeżywa zaledwie 8/1176 występów (0.68%). Małpa ma najwyższy udział zwycięstw drużynowych (55.78%) i średnie obrażenia (215.14). To sygnał do oceny wartości dive i dostępu do tyłów. Hipopotam jest mocny solo, ale w 6v6 jego udział zwycięstw wynosi 50.51%; Skunks i Królik osiągają odpowiednio 48.13% i 49.32%. Dane nie uzasadniają ich automatycznego osłabienia/wzmocnienia wyłącznie na podstawie duelów.

Trzy kontrolowane podmiany przy tym samym przeciwniku i zachowaniu miejsca wymienianej jednostki w składzie:

1. Orzeł → Małpa: `six_01_03` → `six_02_03`, wynik B w 23.45 s → wynik A w 28.05 s (wymieniamy jednostkę drużyny A). Orzeł zadaje 35 obrażeń i ginie; Małpa zadaje 137.13 i zostaje z 65 HP.
2. Gepard → Niedźwiedź: `six_01_00` → `six_07_00`, wynik A w 33.05 s → wynik B w 39.37 s. Więcej obrażeń zastępującej jednostki (115 → 168.5) nie zapewnia zwycięstwa składu.
3. Skunks → Hipopotam: `six_04_00` → `six_05_00`, wynik A w 32.87 s → wynik B w 37.98 s. Skunks ma 31.63 damage i cztery chmury, Hipopotam 91.5 damage i cztery ciężkie ciosy.

Podmiany wykazują mierzalną zmianę przebiegu. Wyjaśnienie wpływu ochrony tyłów, utility i kolejności celów wymaga oglądania śladów; sam wynik nie izoluje mechanizmu przyczynowego.

## Korekty

**Nie zmieniono liczb balansu po symulacjach.** Zachowano wszystkie bazowe HP i nominalne basic DPS. Kadencje, geometria, prędkości i początkowe wartości skilli są jawnie opisane w `resources/README.md`; to implementacyjne parametry startowe zaakceptowanego planu, nie wynik strojenia.

W trakcie weryfikacji poprawiono błędy techniczne: kolizje łańcucha jednostek, kontrolę zasięgu przy trafieniu, legalność lądowania po śmierci celu w locie, wspólne rozliczanie jednoczesnych lądowań, telemetry focus/opportunity i subpikselowe tolerancje wyboru celu/zasięgu oraz liczenie pozycji względem środka areny na dokładnej siatce 1/512 piksela. Są to poprawki zgodności zasad, nie nowe mechaniki. Wczesne serie diagnostyczne dotyczą wcześniejszego kodu i nie służą do porównania efektu nerfu.

## Ograniczenia i decyzje do dalszego etapu

- Prototyp przeszedł weryfikację techniczną w opisanym zestawie. Cele tempa nie są jeszcze w pełni spełnione: mediana 6v6 przekracza górny próg 30 s o 0.175 s; równe pojedynki mają medianę 13.73 s zamiast 10–12 s. Potrzebna jest dalsza, kontrolowana kalibracja po ocenie ról; nie obniżono kryteriów odbioru.
- Do decyzji projektowej: oczekiwana przeżywalność Orła po dive i wartość jego presji na tyły. Bardzo niska przeżywalność oraz słabsze wyniki wymagają świadomej oceny tej roli przed zmianą HP, obrażeń lub cooldownów.

- Przy skupieniu jednostek przechodzących przez sojuszników sylwetki, HP i podpisy mogą się zasłaniać. Wymaga dopracowania czytelności prezentacji; nie zmieniono reguły przenikania sojuszników.
- Odbiór gameplayu pozostaje otwarty: użytkownik/designer musi ocenić role, zauważalność skilli, wpływ składów i przyjemność oglądania przy 1×. Automatyczne wyniki nie potwierdzają, że gra jest już dobrze zbalansowana lub przyjemna.
- Lvl2/lvl3, hybrydyzacja, draft, sieć, ekonomia, meta progression i finalne grafiki/UI nie są zaimplementowane, zgodnie ze zleceniem.

## Pliki i odtwarzanie

Dokumentacja projektu: `docs/COMBAT_IMPLEMENTATION.md`, `docs/TESTING.md`, `resources/README.md`. Dane końcowej serii: `combat_reports/final.json`, `final_matches.csv`, `final_units.csv` i ślad JSONL. Logi testów: `combat_tests.log`, `presentation_tests.log`, `godot_check.log`; zrzut: `combat_prototype.png`. Ostatnia interaktywna walka zapisuje `user://last_combat.json`.

Odtworzenie w katalogu projektu:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_combat.ps1 test
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_combat.ps1 full -Label final
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_combat.ps1 full -Label reproduce -Scenario six_12_14 -TraceOne
```

Silnik: 4.7.2-stable (official); utworzenie raportu UTC: 2026-09-24T22:04:04. SHA-256 zestawu skryptów i danych na początku serii: `ada98eef8be4fef45cb95ffa2aa39beddc5ed7d0c258e2163b24a09f25e40631`. Indywidualne hashe są w JSON. Hashe rdzenia walki i Resources zgadzają się z końcowym projektem. Po rozpoczęciu serii poprawiono wyłącznie obsługę przycisku Krok przy pustym składzie w controllerze i jego test prezentacji; końcowy test prezentacji również przeszedł.
