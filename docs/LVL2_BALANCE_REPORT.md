# Raport równowagi hybryd lvl2

## Metoda

Testy używają produkcyjnej symulacji walki i katalogu jednostek. Jednostki zaczynają z pełnym HP i świeżymi cooldownami, z normalną blokadą aktywnych skilli przez 2 s. Każdy pojedynek jest deterministyczny (ziarno 1); raport zapisuje surowe wyniki i metryki jednostek w JSON oraz CSV. Sumy kontrolne kodu walki, katalogu i zasobów są porównywane przed i po teście.

Pełny zestaw obejmuje 1 996 przypadków:

- 576 walk każdej z 12 hybryd przeciw 8 jednostkom lvl1, w trzech układach 1v1 i po obu stronach areny;
- 864 walk hybryd przeciw każdej nieuporządkowanej parze lvl1 z powtórzeniami, wraz z lustrzanym układem;
- 420 walk lvl2 przeciw lvl2: wszystkie pary, trzy układy dla różnych jednostek i oba kierunki;
- 72 walki z trzema wybranymi jednostkami lvl1 przeciw każdej hybrydzie, wraz z odbiciem lustrzanym;
- 16 walk w mieszanych drużynach hybryd i lvl1;
- 48 parowanych prób z pojedynczą mechaniką włączoną lub wyłączoną: kolce przeciw szybkim atakom, dive Orła przeciw dystansowym, ogłuszenie Hipopotama przeciw dużym porcjom obrażeń oraz obszarowy atak Niedźwiedzia–Geparda przeciw grupie.

## Wyniki końcowe

Wszystkie 1 996 przypadków zakończyły się bez przekroczenia limitu kontrolnego 120 s i bez początkowego nakładania ciał. Wszystkie 96 różnych par hybryda–lvl1 zakończyło się zwycięstwem hybrydy w każdym z sześciu wariantów: 576/576 zwycięstw łącznie, po 48 na hybrydę. Odbicie lustrzane zachowało dokładnie czas walki i odwróciło zwycięzcę we wszystkich 998 porównaniach.

W starciach z parą lvl1 hybrydy wygrały 766 z 864 walk, a drużyny lvl1 wygrały 98. W starciach z trójkami hybrydy wygrały 10 z 72, a lvl1 wygrały 62. To potwierdza kontrprzykłady dla obu stron w objętej testem puli; nie oznacza, że każda para lub trójka jest kontrą.

W bezpośrednich starciach lvl2 trzy wyniki indywidualne wypadły poza pasmem przeglądu 35–65% (66 starć bez samych ze sobą): Niedźwiedź–Małpa 21,2%, Hipopotam–Królik 72,7%, Skunks–Królik 18,2%. Pozostałe dziewięć hybryd mieści się w tym paśmie. To sygnały do sprawdzenia w dalszej grze, a nie wymóg równego wyniku każdej pary.

Niedźwiedź–Małpa wygrał m.in. przeciw trójce Gepard + Królik + Jeż, kończąc z 53/228 HP. Jest to przykład użyteczności tej hybrydy przeciw grupie mimo słabego wyniku 1v1; hybryda ta sama nie ma kolców. Raport JSON podaje składy i identyfikatory wszystkich zwycięskich przypadków.

## Wyniki poszczególnych hybryd

Pierwszy procent dotyczy 66 pojedynków z innymi hybrydami, bez walk z własnym typem. Drugi wynik to zwycięstwa przeciw parom lvl1 (72 przypadki na hybrydę); przy braku remisów jest też jej przeżywalnością w tej rodzinie testów.

- Niedźwiedź–Gepard: 39,4%; przeciw parom 64/72 (88,9%).
- Niedźwiedź–Małpa: 21,2%; 64/72 (88,9%).
- Niedźwiedź–Jeż: 63,6%; 60/72 (83,3%).
- Gepard–Orzeł: 60,6%; 68/72 (94,4%).
- Gepard–Królik: 42,4%; 72/72 (100%). W tej geometrii żadna para lvl1 go nie pokonała; nie przenosimy tego wniosku na wszystkie możliwe ustawienia.
- Małpa–Skunks: 54,5%; 64/72 (88,9%).
- Małpa–Hipopotam: 60,6%; 68/72 (94,4%).
- Orzeł–Jeż: 63,6%; 62/72 (86,1%).
- Orzeł–Hipopotam: 63,6%; 64/72 (88,9%).
- Hipopotam–Królik: 72,7%; 62/72 (86,1%).
- Jeż–Skunks: 39,4%; 62/72 (86,1%).
- Skunks–Królik: 18,2%; 56/72 (77,8%).

Przykłady kontr: Małpa + Skunks wygrywają z Niedźwiedziem–Jeżem, Niedźwiedź + Gepard oraz Gepard + Hipopotam wygrywają z Gepardem–Orłem, dwa Niedźwiedzie wygrywają z Niedźwiedziem–Małpą. W drugą stronę Orzeł–Hipopotam pokonuje trójkę Małpa + Skunks + Orzeł (27 HP na końcu), a Niedźwiedź–Jeż trójkę Gepard + Królik + Jeż (93 HP). Wyniki pokazują zależność od składu; same nie izolują przyczyny zwycięstwa.

## Czas, obrażenia i użycia skilli

- Lvl2–lvl1: mediana walki 8,02 s, średni TTK zabitych 6,45 s.
- Lvl2 przeciw parze: mediana 14,51 s, średni TTK 7,33 s.
- Lvl2 przeciw trójce: mediana 12,95 s, średni TTK 7,19 s.
- Lvl2–lvl2: mediana 13,54 s, średni TTK 12,55 s.
- Mieszane drużyny: mediana 14,47 s, średni TTK 7,33 s.

TTK liczymy od pierwszego otrzymanego trafienia do śmierci; ocalałe jednostki nie wchodzą do tej średniej. Obrażenia oznaczają rzeczywiście utracone HP, bez overkillu.

Przykłady średnich na walkę przeciw parom lvl1: Niedźwiedź–Gepard zadaje 209,7 i otrzymuje 157,7 obrażeń, używając serii stożków 2,50 razy; Niedźwiedź–Małpa 210,2 / 154,2 obrażeń i 2,39 użycia skilla; Orzeł–Hipopotam 212,1 / 133,2 oraz 1,47 skoku; Skunks–Królik 209,0 / 179,3, 4,42 chmury i 2,97 uniku. Jeż–Skunks tworzy średnio 2,89 chmury i ma 11,61 aktywacji pasywnych kolców — tych aktywacji nie należy porównywać z liczbą aktywnych castów. Pełne pomiary wszystkich jednostek, także slow i zachwiania, są w CSV/JSON.

## Wykonane korekty

Pierwsza seria dawała hybrydom 850/864 wygranych przeciw parom oraz 48/72 przeciw trójkom. Po korektach wyniki wynoszą odpowiednio 766/864 i 10/72. Nie zmieniano statystyk lvl1 ani zasad draftu.

HP od pierwszego baseline'u do końcowych wartości:

- Niedźwiedź–Gepard 305 → 225; Niedźwiedź–Małpa 310 → 228; Niedźwiedź–Jeż 350 → 240.
- Gepard–Orzeł 270 → 200; Gepard–Królik 265 → 220.
- Małpa–Skunks 280 → 220; Małpa–Hipopotam 310 → 210.
- Orzeł–Jeż 350 → 230; Orzeł–Hipopotam 335 → 210; Hipopotam–Królik 340 → 215.
- Jeż–Skunks 330 → 220; Skunks–Królik 285 → 220.

Zmniejszono również bazowe obrażenia hybryd, początkowo o około 8%, z dodatkowymi korektami dominujących form. Końcowe wartości zapisane są w Resources. Istotne korekty skilli:

- Niedźwiedź–Gepard: 3 × 8,5 → 3 × 14 obrażeń, CD 7 s.
- Niedźwiedź–Małpa: stożek 16 → 25, bonusowy banan 8,5 → 12, CD 7 s.
- Małpa–Hipopotam: pocisk 38 → 34, CD 8 → 9 s.
- Hipopotam–Królik: cios po skoku 42 → 36, CD 6,5 → 7,5 s.
- Orzeł–Hipopotam: ostatecznie zachowuje początkowe 40 obrażeń i stun 2 s, CD wydłużony z 8 do 12 s. Pośrednie obniżenie obrażeń zostało zastąpione dłuższym cooldownem.

Naprawiono też zerowe pole obrażeń dwóch chmur w pierwszych definicjach danych oraz zależny od kolejności aktualizacji kierunek potrójnego dive. Te poprawki poprawiają zgodność implementacji z designem; nie są nerfem lub buffem przyjętej mechaniki.

## Sprawdzenie osi mechanik

Testy z wyłączaniem mechanik wykazały mierzalne zmiany czasu walki i obrażeń, ale żadne z 24 porównań (48 walk) nie zmieniło zwycięzcy. Są to wskazówki o wpływie mechaniki w ustalonym układzie, nie dowód, że sama mechanika powoduje wynik całej walki.

W sześciu porównaniach na oś: kolce skróciły walkę z szybkim napastnikiem średnio o 1,74 s; pełny dive skrócił starcie z dystansowym o 3,87 s; samo ogłuszenie o 1,82 s. Stożki przeciw grupie zwiększyły zadane obrażenia o 74,83, ale nie odwróciły porażki. Wyłączenie dive obejmuje ruch i jego obrażenia, więc ten test nie mierzy czystego wpływu mobilności. Bazowa kadencja hybryd pozostaje wspólna (0,5 s); zróżnicowanie osi częstotliwości trafień wynika na tym etapie przede wszystkim z ich skilli.

## Odczyt asercji i ograniczenia

`every_hybrid_beats_each_lvl1_in_coverage` sprawdza warunek „bez ukrytego zwycięzcy” dla skończonej puli jednostek, geometrii i odbić lustrzanych. Asercje walk 2v1 i 3v1 wymagają zwycięstw obu stron i zapisują konkretne składy. Pasmo bezpośrednich starć ocenia każdą hybrydę oddzielnie, bez samych ze sobą.

To deterministyczny zestaw testowy, a nie losowa próba ani prognoza wyników graczy. Nie obejmuje wszystkich możliwych składów, ustawień, decyzji graczy ani pełnych bitew 6v6. Wyniki wskazują, że hybrydy przechodzą test przeciw pojedynczym lvl1, lecz nie dowodzą idealnej równowagi.

## Pliki i uruchomienie

- Raport pełny: [`reports/lvl2/lvl2_final_calibrated.json`](../reports/lvl2/lvl2_final_calibrated.json)
- Surowe walki: [`reports/lvl2/lvl2_final_calibrated_matches.csv`](../reports/lvl2/lvl2_final_calibrated_matches.csv)
- Metryki jednostek: [`reports/lvl2/lvl2_final_calibrated_units.csv`](../reports/lvl2/lvl2_final_calibrated_units.csv)
- Runner: [`scripts/testing/lvl2_balance_runner.gd`](../scripts/testing/lvl2_balance_runner.gd)

```powershell
$engine = (Get-Content tools/godot.local.txt -Raw).Trim()
& $engine --headless --path . --script res://scripts/testing/lvl2_balance_runner.gd -- --label lvl2_reproduce
& $engine --headless --path . --script res://tests/lvl2_balance_assertions.gd -- --report res://reports/lvl2/lvl2_reproduce.json
```

Raport końcowy ma sumę SHA-256 źródeł `2481772fd7b4516cd64b2db19abc9f56314027227e520e2ea790919af2e778d9`; suma nie zmieniła się podczas testu. Asercje raportu przeszły: 26 sprawdzeń, 0 błędów.
