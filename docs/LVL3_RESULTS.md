# Wyniki pierwszej próby lvl3 — 2026-09-25

## Zakres i metoda

Uruchomiono 56 deterministycznych walk w wersji `combat-v0.7-lvl3`:

- 12 pojedynków jednej lvl3 przeciwko obu jej rodzicom lvl2 walczącym razem,
- 12 pojedynków lvl3 przeciwko wybranej parze `eagle_hippo` + `monkey_hippo`,
- 4 walki drużyn o tym samym budżecie sześciu zwierząt bazowych: `[lvl3, lvl1, lvl1]` przeciwko `[lvl2, lvl2, lvl1, lvl1]`,
- każda walka powtórzona po zamianie stron.

Symulacje używały automatycznych pozycji, tego samego seeda w parze lustrzanej i limitu 120 s czasu walki. Każdy wiersz wyniku zachowuje czas, zwycięzcę, obrażenia według rodzaju i skilla, użycia skilli, przeżycie, czas śmierci oraz czas ogłuszenia, zachwiania i spowolnienia. Raport zawiera też 120 hashy skryptów i Resources, aby wskazać badany stan danych.

## Wyniki

- Wszystkie 56 walk zakończyło się przed limitem; nie było utknięć.
- Wszystkie 28 par lustrzanych miały odwrócony wynik i identyczny czas.
- Lvl3 wygrały 5 z 12 pojedynków przeciwko swoim dwóm rodzicom razem; rodzice wygrali 7. Nie było remisów.
- Lvl3 wygrały 2 z 12 pojedynków z wybraną parą `eagle_hippo` + `monkey_hippo`; para lvl2 wygrała 10. Nie było remisów.
- W czterech drużynach o równym budżecie bazowych zwierząt strona lvl3 wygrała 1 walkę; drużyna dwóch lvl2 wygrała 3. Każdy wynik potwierdziła próba lustrzana.

Mediana czasu walk wyniosła 20,63 s przeciwko parze rodziców, 18,74 s przeciwko wybranej parze lvl2 oraz 26,63 s w drużynach o równym budżecie. Zakresy odpowiednio: 14,42–47,13 s, 17,02–28,02 s i 15,68–31,92 s.

W tym pokryciu wyróżniły się `lvl3_02` i `lvl3_03`: wygrały wszystkie cztery walki 1v2 i zadały średnio 435 oraz 430 obrażeń na występ. `lvl3_04` przegrała wszystkie sześć uwzględnionych walk, a `lvl3_05`, `lvl3_07`, `lvl3_09` i `lvl3_12` przegrały wszystkie cztery walki 1v2. W drużynowej próbie `lvl3_08` wygrała jako jedyna z czterech badanych form lvl3.

## Ograniczenia

To wąskie, deterministyczne pokrycie wybranych składów i domyślnych pozycji. Wynik przeciwko `eagle_hippo` + `monkey_hippo` dotyczy tylko tej pary, a nie całego rosteru lvl2. Nie dowodzi przewagi ani słabości dla innych ustawień, osłony lub kolejności draftu. Wyniki nie są celem 50/50 i same nie uzasadniają zmiany liczb. W szczególności obrażenia i kontrolę trzeba ocenić w kolejnych składach drużynowych oraz w playteście.

Testy kontraktów lvl3: **114 asercji, 0 błędów**. Pełne wiersze walk i metryki jednostek: [lvl3_simulations_2026-09-25.json](../reports/lvl3/lvl3_simulations_2026-09-25.json).
