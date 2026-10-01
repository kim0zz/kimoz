# Siła skilli i czytelność walki — przegląd 2026-09-25

> Historyczny pomiar sprzed pilotażu v0.2. Późniejsza implementacja i porównanie A/B trzech hybryd: `BURST_PILOT_NUMBERS.md`, sekcja 46 briefu. Poniższe procenty opisują wcześniejsze liczby, nie nowy wariant B.

## Zakres

Audyt aktualnych Resources i produkcyjnej symulacji. Nie zmieniamy obrażeń, cooldownów, ruchu ani zasad walki. Osobna zmiana prezentacji wzmacnia komunikat zwycięstwa rundy i meczu.

Pytanie użytkownika dotyczy dwóch różnych rzeczy: udziału skilli w wyniku walki oraz odczuwalnej siły pojedynczego użycia. Duży udział DOT nie gwarantuje mocnego momentu trafienia. Mały udział obrażeń nie przesądza o małej wartości ogłuszenia albo zerwania aggro.

## Wniosek z pomiarów

Oba problemy występują jednocześnie. Hybrydy mają wyraźnie większy udział basiców niż lvl1 w badanych składach; dodatkowo prezentacja większości mocnych trafień niewiele różni się od basiców. Nie wynika z tego, że skille są nieistotne: wyłączenie aktywnych umiejętności zmienia wynik 24 z 80 parowanych porównań.

### Metoda i ograniczenia

160 walk: 80 ze skillami i 80 odpowiadających im prób bez aktywnych skilli (pasywne kolce pozostają). Bazowe 80 to 16 walk lvl1 2v2, 16 lvl1 6v6, 24 mieszane 3v3 (1 hybryda + 2 lvl1 na stronę) i 24 mieszane 6v6 (3 hybrydy + 3 lvl1 na stronę). Składy rotują po katalogu; scenariusze obejmują odbicia lustrzane. Nie są niezależną losową próbą zachowań graczy, występują powtórzenia składów. Każda hybryda ma 16 występów w bazowych walkach, lvl1 mają 56 lub 68. To diagnostyka, nie pełna kalibracja ani estymacja populacyjnego win rate.

Udziały to iloraz sum rzeczywiście zadanych obrażeń, po odjęciu overkillu, nie średnia procentów jednostek. „Aktywne” obejmuje bezpośrednie skille + DOT; kolce raportowane osobno. Udział jest opisem źródła utraconego HP, a nie wzrostem siły jednostki względem wersji bez skilla. Wszystkie 160 walk zakończyło się przed watchdogiem 120 s; sumy kategorii, zdarzeń i obrażeń otrzymanych/zadanych są zgodne. Wyniki i czas odbić lustrzanych przeszły kontrolę runnera. Każda jednostka posiadająca aktywny skill rozpoczęła przynajmniej jeden w swoim występie — nie oznacza to, że każde rozpoczęcie skutecznie trafiło.

### Podział obrażeń

- **Lvl1 w walkach 2v2:** basic 56,0%; bezpośrednie skille 35,1%; DOT 5,2%; kolce 3,6%. Aktywne razem **40,3%**. Mianownik: 6142 obrażenia, 64 występy.
- **Lvl1 w walkach 6v6:** basic 53,8%; bezpośrednie skille 39,2%; DOT 4,7%; kolce 2,4%. Aktywne razem **43,9%**. Mianownik: 18 600 obrażeń, 192 występy.
- **Same hybrydy w mieszanych 3v3:** basic 65,7%; bezpośrednie skille 23,6%; DOT 2,8%; kolce 7,9%. Aktywne razem **26,4%**. Mianownik: 11 001,6 obrażeń, 48 występów.
- **Same hybrydy w mieszanych 6v6:** basic **70,8%**; bezpośrednie skille 19,5%; DOT 4,2%; kolce 5,4%. Aktywne razem **23,7%**. Mianownik: 32 463,6 obrażeń, 144 występy.
- Lvl1 w tych samych mieszanych 6v6: aktywne **40,6%**, basic 54,3%, kolce 5,1%. Różnica między poziomami nie wynika więc wyłącznie z porównania różnych rozmiarów walk.

Zaokrąglenia mogą powodować sumę 99,9% lub 100,1%.

### Konkretne jednostki

We wszystkich bazowych składach łącznie, udział aktywnych skilli w obrażeniach danej jednostki:

- Hipopotam lvl1: **68,5%**; Niedźwiedź lvl1: **59,6%**. Jeśli ich ciosy nie wyglądają na ważne, sam niski udział damage tego nie wyjaśnia.
- Niedźwiedź–Małpa: **40,4%**; Niedźwiedź–Gepard: **37,0%**.
- Gepard–Orzeł: **29,9%**; Orzeł–Hipopotam: **23,6%**; Małpa–Hipopotam: **22,7%**; Hipopotam–Królik: **22,9%**; Gepard–Królik: **16,4%**.
- Małpa–Skunks: **34,8%**, z czego około 18,1 punktu procentowego stanowi DOT.
- Skunks–Królik: **11,4%** z chmury; unik nie zadaje obrażeń. Nie jest to pełna wycena jego przeżywalności.
- Jeż lvl1: **31,4%** z pasywnych kolców. Królik lvl1: **0%** damage ze skilla zgodnie z designem; jego wartość to ruch i zerwanie aggro, nie burst.

Orzeł–Hipopotam rozpoczął 20 skoków w 16 występach (średnio 1,25); Małpa–Hipopotam 40 specjalnych rzutów (2,5/występ). Niedźwiedź–Gepard rozpoczął 24 serie (1,5/występ). Skunks–Królik użył chmury 64 razy i uniku 44 razy, czyli odpowiednio 4,0 i 2,75/występ. Niski damage chmury nie wynika wyłącznie z braku użyć.

### Wielkość trafienia i wpływ poza damage

Mediana dodatniego, pojedynczego zdarzenia obrażeń: basic **9**, bezpośredni skill **19**, DOT **4**, kolce **3**. Skill to więc około 2,1 basica w medianie zdarzeń. W odniesieniu do maksymalnego HP trafionego celu mediany wynoszą odpowiednio **4,7%, 11,9%, 2,25% i 1,36%**. To pojedyncze trafienia/pulsy: potrójna seria ma trzy zdarzenia, a AoE osobne na każdego przeciwnika. Nie należy odczytywać tych wartości jako całych castów.

Wyłączenie aktywnych skilli po obu stronach zmieniło zwycięzcę/wynik w **24/80** porównaniach. Ze skillami walka była średnio o **3,82 s** krótsza. Różnica nie jest jednolita: lvl1 6v6 23,89 s ze skillami vs 37,57 s bez, ale mieszane 3v3 20,66 s vs 19,85 s. Wyłączenie usuwa także ruch, kontrolę i czas wykonywania akcji — nie izoluje czystego damage ani pojedynczej jednostki.

W mieszanym 6v6 odnotowano łącznie **90,8 jednostko-sekund ogłuszenia**, **9,4 zachwiania** i **119,8 spowolnienia** w 24 walkach. To czas po stronie ofiar, sumowany między jednostkami; okresy mogą zachodzić na siebie. Nie jest to czas zatrzymania całej walki ani przypisanie skuteczności do konkretnego autora skilla.

### Jak interpretować to projektowo

Najmocniejszy sygnał to duży udział basiców hybryd, szczególnie tych zapowiedzianych jako burst. Rekomenduję zmianę rozkładu mocy dla wybranych hybryd wraz z poprawą feedbacku; nie globalny buff wszystkich skilli. Dla Hipopotama lvl1 najpierw sprawdziłbym prezentację — jego skill już stanowi większość damage. Dla chmur, kolców i uników należy zachować odmienną tożsamość, zamiast wymuszać na wszystkich duży pojedynczy cios.

Pliki pomiarów: `reports/skill_impact/skill_impact.json`, `skill_impact_matches.csv`, `skill_impact_units.csv`, `per_unit_summary.csv`. Odtwarzanie: `godot --headless --path . --script res://scripts/testing/skill_impact_runner.gd`. Raport JSON zawiera wersję silnika i hashe plików sprzed/po przebiegu; pomiar nie zmienia zasobów produkcyjnych.

## Co już wynika z implementacji

- `effects_view.gd` wyświetla większość obrażeń skilli i basiców jednakowo: czerwona liczba, font 12, wspólny czas życia 0,72 s. Osobne efekty mają m.in. kolce, stożek i dokładnie skill `cheetah_flurry`; hybrydowe serie nie korzystają automatycznie z tego efektu pazurów.
- `unit_view.gd` pokazuje tę samą reakcję błysku na otrzymane obrażenia. HP zmienia się bez osobnego zaznaczenia utraconej porcji. Są już zapowiedzi stożków, ruch skoków i oznaczenia ogłuszenia, ale nie tworzą pełnego zestawu reakcji na mocne trafienie.
- W aktualnych skryptach/scenach nie ma dźwięków uderzeń ani zatrzymania animacji przy uderzeniu (hit-stop).
- Wszystkie hybrydy mają bazowy interwał ataku 0,5 s. Orzeł–Hipopotam: basic 9,2, czyli nominalnie 18,4 DPS, skok 40 co 12 s oraz stun 2 s. Małpa–Hipopotam: basic 9,7 co 0,5 s, specjalny banan 27 co 10 s oraz stun 1,25 s. To dane zasobów, a nie zmierzone DPS: ruch, zamach, stun, śmierć i reset zegara basiców zmieniają rzeczywistą wydajność.
- Banan Małpy–Hipopotama zadaje nominalnie tylko 2,78 zwykłego trafienia tej jednostki. Przygotowanie 0,8 s i recovery 0,6 s zajmują łącznie 1,4 s, podczas których ofensywny skill zastępuje basic. Przy ciągłym atakowaniu 19,4 DPS × 1,4 s daje porównywalne 27,16 obrażeń. To przybliżenie kosztu czasu, nie pomiar korzyści netto: ataki są dyskretne, pocisk leci, ogłuszenie ma wartość i zegar basiców jest resetowany. Wyjaśnia jednak, dlaczego samo „27 damage + stun” może dawać głównie kontrolę zamiast odczucia potężnego burstu.
- Starszy `LVL2_BALANCE_REPORT.md` opisuje inny stan niektórych zasobów (np. Małpa–Hipopotam 34 / 9 s). Nie używamy jego liczb jako bieżących wyników audytu.
- Historyczny baseline §22 mówił o około 20–30% dodatkowej efektywnej wartości względem samych basiców. Nie oznacza to 20–30% udziału damage i nie stanowi docelowego wymagania dla widowiskowych hybryd.

## Materiały twórców gier

### TFT: udział skillów zależy od roli

[Riot, Roles Revamped and Item Changes (2025)](https://teamfighttactics.leagueoflegends.com/en-us/news/game-updates/roles-revamped-and-item-changes/) rozróżnia m.in. strzelców, których główne obrażenia pochodzą z ataków, oraz casterów, których główne obrażenia pochodzą z umiejętności. To przydatny precedens dla podziału tożsamości jednostek, nie benchmark procentowy dla naszej gry.

### Hierarchia efektów odpowiada znaczeniu zdarzenia

[Riot, Clarity in League (2021)](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/) wiąże wyrazistość efektu z obrażeniami, kontrolą tłumu i wpływem na rozgrywkę; jednocześnie zaleca ograniczanie szumu. Wniosek dla nas: mocny skill powinien wyróżniać się względem basiców, ale nie każdy tick chmury powinien wyglądać jak eksplozja.

### Satysfakcja może wzrosnąć bez podnoszenia obrażeń

[Jonasson i Purho, Juice It or Lose It, GDC Europe 2012](https://www.gdcvault.com/play/1016789/Juice-It-or-Lose) demonstrują poprawianie odczucia gry przez dodatkowe reakcje i efekty. Publiczny opis sesji wspiera kierunek pracy nad feedbackiem; nie dostarcza norm damage ani dowodu, że konkretne czasy efektów sprawdzą się u nas.

W przejrzanych materiałach nie ma uniwersalnej normy typu „skill musi zadawać 60% obrażeń”. Takie progi byłyby naszą hipotezą projektową, wymagającą playtestu.

## Rekomendowany następny eksperyment — jeszcze nie wdrożony

1. Wybrać trzy reprezentatywne akcje: ciężkie lądowanie Orła–Hipopotama, banan Małpy–Hipopotama i seria Niedźwiedzia–Geparda.
2. Wariant A: te same liczby, mocniejsza zapowiedź i reakcja trafienia, wyraźna porcja utraconego HP, odróżnione liczby skilla, dopasowany dźwięk i krótka reakcja sylwetki. Efekty wyzwalane faktycznym trafieniem, nie samym rozpoczęciem skilla. Serie powinny pokazywać rytm trzech trafień; chmury pokrycie i impulsy.
3. Wariant B: ten sam poprawiony feedback, ale część mocy przesunięta z basiców do skilla. Nie zwiększać po prostu wszystkich obrażeń i nie skracać automatycznie CD — celem jest mocniejszy moment, nie częstszy spam. Przy takich zmianach ponownie sprawdzić wymagania lvl2–lvl1, kontry, czas walki i zgony przed pierwszym skillem.
4. Porównać A i B na tych samych składach i prędkości 1×. Ocena użytkownika: czy da się rozpoznać autora i ofiarę skilla, czy widać skutek, czy moment jest satysfakcjonujący i czy walka pozostaje czytelna. Symulacja nie mierzy tego za gracza.

Odrzut wizualny sylwetki można testować bez zmiany kolizji. Faktyczne przesunięcie jednostki zmienia zasięgi, front i targetowanie — to nowa mechanika wymagająca osobnej decyzji. Globalny hit-stop lub potrząsanie ekranem przy każdym trafieniu w 6v6 grozi utratą czytelności; ewentualny efekt powinien być oszczędny i mieć limit częstotliwości.
