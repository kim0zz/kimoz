> Uwaga: opisy i wyniki Skunksa, Jeża–Skunksa oraz Skunksa–Królika poniżej dotyczą stanu sprzed przebudowy na ruchomy ślad smrodu. Aktualny design: §49 GAME_DESIGN_V0_2.md; bieżące liczby: Resources.

# Porównanie pełnego rosteru A/B

## Zakres i interpretacja

Porównanie uruchamia pełne definicje `CombatVariants.definitions("A")` i `definitions("B")`. Wariant A odtwarza zapisany snapshot `resources/balance/full_roster_baseline.json`, a B korzysta z aktualnych definicji jednostek. Raport zawiera 40 ustalonych składów 3v3, każdy w dwóch lustrzanych ustawieniach i w obu wariantach, łącznie 160 walk.

Zestaw obejmuje 24 zrównoważone konteksty rotujące wszystkie 20 jednostek oraz 16 dopasowanych prób ról: osłonięty i odsłonięty carry, diver przeciw backline i ekranowi, kolce przeciw szybkim atakom w skupieniu i rozproszeniu oraz stożek przeciw skupionym i rozproszonym celom. Próby kontrolne zmieniają jawnie pojedynczego członka składu. Nie ma pojedynków 1v1 ani interpretacji wyników jako turniejowej win rate.

Wyniki jednostek opisują wystąpienia w tych konkretnych składach: obrażenia basic/skill/DOT/thorns, liczbę użyć skilli, czas pierwszego skilla, śmierć przed pierwszym skillem, obrażenia zadane i otrzymane, przeżycie oraz TTK tylko dla jednostek, które zginęły. Zestawienie podaje także czas walki. `aggro_break`, przekazanie celu po przerwaniu aggro i uptime ogłuszenia są proxy użyteczności; same w sobie nie dowodzą przyczynowości.

## Walidacja

Runner sprawdza komplet 20 ID, 40 grup, 160 walk, watchdog 120 s, zgodność sum obrażeń z kategoriami i zdarzeniami, równość obrażeń zadanych i otrzymanych oraz zgodność wyników i czasu dla lustrzanych przebiegów. Błąd walidacji kończy proces kodem różnym od zera. Hash źródeł obejmuje skrypty, zasoby `.tres` i snapshot JSON; zmiana podczas przebiegu unieważnia raport.

## Wynik przebiegu

Liczby A/B zostały zamrożone przed pomiarem. Główna próba objęła 40 składów 3v3, dwa ustawienia lustrzane i oba warianty: 160 walk. Dodatkowy przekrój 6v6 użył czterech składów w tej samej parowanej konfiguracji: 16 walk. Wszystkie grupy ukończyły się przed watchdogiem. Walidacja sum obrażeń przeszła; nie było różnic czasu ani wyniku w 80 lustrach 3v3 i 8 lustrach 6v6.

### Składy 3v3

- **Osłona ranged carry:** średni czas spadł z 25,73 s do 25,15 s. Małpa–Hipopotam przeżyła 8/8 wystąpień w A i 6/8 w B; obrażenia skilli wyniosły 1082→855 łącznie, a średnie zadane obrażenia 203,8→183,4 na wystąpienie. Próba zawiera również kontrolną zamianę osłaniającego hybryda, więc wynik nie izoluje samego ustawienia ochrony.
- **Diver:** w próbie backline/ekranu średni czas wzrósł z 16,98 s do 19,64 s. Orzeł–Hipopotam zadał 320→480 obrażeń skilli w czterech wystąpieniach i użył skilla 4→6 razy. Zginął we wszystkich czterech; żaden nie zginął przed pierwszym użyciem.
- **Kolce przeciw szybkości:** czas prób spadł z 19,46 s do 15,28 s. Niedźwiedź–Jeż przeżył wszystkie cztery wystąpienia; obrażenia od kolców wzrosły 116→141, a obrażenia skilli 216→332.
- **Stożek:** czas prób spadł z 18,93 s do 15,91 s. Niedźwiedź–Gepard przeżył wszystkie cztery wystąpienia, ale jego użycia skilla wyniosły 12→8, a obrażenia skilli 516→432. Ten przekrój łączy skupiony/rozproszony układ z kontrolną zamianą składu.
- **Małpa–Skunks w rotujących kontekstach:** suma obrażeń DOT wzrosła 560,4→949,2 w dwunastu wystąpieniach. Średnie całkowite obrażenia pozostały zbliżone (265,6→268,8), a przeżycie spadło z 10/12 do 8/12. Użycia aktywnego skilla wzrosły z 56 do 68. To współwystępujący sygnał z całym zestawem zmienionych liczb, nie izolowany efekt samej chmury.

### Przekrój 6v6

W czterech zestawieniach mediana czasu walki wyniosła 29,33 s w A i 26,69 s w B. Udział obrażeń kategorii `skill` wzrósł z 30,3% do 49,5%; po doliczeniu DOT udział aktywnych obrażeń skilli wyniósł 37,8%→57,9%. Są to sumy obrażeń obu drużyn w tych czterech stałych składach, a nie turniejowa skuteczność.

### Granice wniosku

Wyniki opisują wyłącznie zaprojektowane składy, pozycje i lustrzane przebiegi. Czas walki oraz wyniki całych drużyn nie przypisują wpływu jednej jednostce. `aggro_break`, wymuszony retarget i uptime ogłuszenia pozostają wskaźnikami użyteczności bez wnioskowania o przyczynowości.

Szczegóły i zapis wejść znajdują się w `reports/full_roster/full_roster_ab.json`, `full_roster_ab_matches.csv`, `full_roster_ab_units.csv` oraz w osobnym przekroju 6v6 `reports/full_roster/full_roster_ab_six.json`, `full_roster_ab_six_matches.csv`, `full_roster_ab_six_units.csv`.

Uruchomienie 6v6 bez ponownego liczenia głównej próby:

```powershell
godot --headless --path . --script res://scripts/testing/roster_impact_runner.gd -- --six-only
```
