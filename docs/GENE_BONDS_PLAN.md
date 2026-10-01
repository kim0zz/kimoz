# Więzi genów — plan pierwszego prototypu

Data: 2026-09-27. Status: kierunek zaakceptowany; poniżej rekomendowany projekt do wdrożenia i testów. Osiem efektów i ich liczby są propozycją, nie zatwierdzonym balansem. Ten etap nie wdraża mechaniki.

## Cel
Prosta reguła „dwie osobne jednostki ze wspólnym genem wzmacniają się” ma dawać cel podczas draftu, pierwszy przełom na lvl2 i późniejsze zwieńczenie na lvl3. Lvl3 może korzystać z czterech więzi jednocześnie. Nie gwarantujemy automatycznego zwycięstwa skompletowanego buildu.

## 1. Rekomendowane reguły v1
- Geny wynikają z bazowych przodków jednostki, nie z jej aktualnej roli ani liczby skilli.
- Liczą się wszystkie wystawione jednostki lvl1/lvl2/lvl3. Lvl1 ma jeden gen. Ławka nie aktywuje ani nie otrzymuje więzi.
- Dla każdego genu wymagane są co najmniej dwie osobne jednostki posiadające ten gen. Mogą być identycznymi kopiami. Jedna jednostka wnosi najwyżej jeden punkt do danego genu.
- Kiedy więź jest aktywna, otrzymują ją wszystkie wystawione jednostki z tym genem. Dwa Jeże aktywują Jeża; Jeż i Niedźwiedź–Jeż również. Dwie kopie Niedźwiedzia–Jeża aktywują oba geny.
- Każdy gen ma jeden próg i jeden efekt. Więcej partnerów nie zwiększa poziomu bonusu.
- Jednostka dostaje dany efekt raz. Lvl2 może mieć dwa, lvl3 cztery różne efekty. Lvl3 nie aktywuje więzi sam sobie.
- Jedna para hybryd może aktywować kilka wspólnych genów. Także dwie różne formy lvl3 mogą wzajemnie uruchomić wszystkie cztery wspólne geny; to przypadek do celowego testu, nie ukryty wyjątek.
- Skład i aktywne więzi zamrażamy przy starcie walki. Śmierć partnera nie usuwa bonusu; efekt wygasa po walce. W przygotowaniu zmiany składu przeliczają podgląd natychmiast.
- Fuzja usuwa rodziców przed obliczeniem nowego zestawu więzi. Może uruchomić nowe i wyłączyć wcześniejsze. Bez zachowywania bonusów z poprzedniej rundy.
- Poziom jednostki sam nie mnoży siły bonusu. Brak losowych aktywacji w v1.

## 2. Tempo i koszt — ważniejsze niż same liczby buffów
Obecne zasady: po dwie jednostki na starcie, potem dwie akcje na rundę; dobór i fuzja kosztują po jednej akcji; pięć żyć. Poniższe granice zakładają dostępność ofert, brak wyrzucania i brak bonusów comeback. Blokowanie draftu przez rywala może je opóźnić.

Po rozszerzeniu na lvl1: dwa identyczne zwierzęta nie są dostępne w startowym drafcie, bo pula zawiera tylko jedną kopię każdego. Drugą kopię można dobrać przed drugą walką i już uruchomić pierwszą więź. Lvl2 + bazowy partner wymaga po starcie dwóch doborów i jednej fuzji, więc najwcześniej jest dostępny przed trzecią walką bez comebacku.

Pierwszy duet lvl2: cztery bazowe jednostki i dwie fuzje. Po startowych dwóch zwierzętach pozostają dwa dobory i dwie fuzje, czyli cztery akcje. Pierwsza więź jest osiągalna przed trzecią walką.

Sam lvl3: cztery jednostki bazowe i trzy fuzje. Pozostaje pięć akcji po starcie, czyli najwcześniej przed czwartą walką.

Lvl3 z czterema aktywnymi genami i czterema pomocnikami lvl1: osiem bazowych jednostek i trzy fuzje, czyli dziewięć akcji po starcie. Najwcześniej przed szóstą walką, przy pięciu miejscach aktywnych. Słabe bazowe wsparcie zajmuje miejsca, ale po śmierci nadal utrzymuje więź zamrożoną na starcie — koniecznie sprawdzić, czy taka tania obstawa nie dominuje.

Lvl3 z czterema aktywnymi genami i dwoma pomocnikami lvl2: wystarczą lvl3 oraz dwie odpowiednie hybrydy lvl2, np. Błyskobanan + Niedźwiedź–Gepard + Małpa–Skunks. Potrzeba ośmiu jednostek bazowych i pięciu fuzji, czyli jedenastu akcji po starcie. Najwcześniej przed siódmą walką. Skład wymaga ponownego zebrania rodziców, więc nie dostaje tych więzi za darmo przy fuzji.

Przykład z czterema osobnymi pomocnikami kosztuje dwanaście jednostek bazowych i siedem fuzji: siedemnaście akcji po starcie, najwcześniej przed dziesiątą walką. Mecz bez remisów kończy się najpóźniej na dziewiątej walce. Bonusy comeback zmieniają dostępny budżet; w pomiarach zapisujemy ich faktyczne użycie.

Wniosek: pierwszy playtest musi sprawdzić zarówno frajdę z wczesnego duetu, jak i osiągalność docelowego lvl3. Na razie zachowujemy ekonomię i życia. Jeśli większość graczy nie dociera do interesujących układów, osobno testujemy tempo fuzji lub długość meczu; nie zmieniamy obu naraz.

## 3. Osiem efektów — kandydaci, nie zamknięta specyfikacja
Każdy efekt musi działać z jednostką bazową i istniejącymi hybrydami swojego genu. Nie zakładamy, że Małpa jest już healerem lub wszystkie Króliki dają tarcze: to nie opisuje obecnego pełnego rosteru.

- Niedźwiedź / Krzepa: dodatkowe maksymalne i początkowe HP. Prosty, stale użyteczny punkt odniesienia dla siły innych więzi.
- Gepard / Rozpęd: po rozpoczęciu pierwszej pełnej aktywnej umiejętności jednorazowo skraca czas do jej następnego użycia. Musi obejmować całą sekwencję, nie każdą fazę, i nie przyspieszać samej animacji. Wymaga sprawdzenia form opartych na reakcji/śladzie.
- Małpa / Ciężkie banany: wzmacnia bezpośrednie obrażenia pocisków. Bez mnożenia DOT chmury tworzonej przez pocisk i bez wzmacniania stożka tylko dlatego, że później emituje banany. Audyt wszystkich form Małpy musi potwierdzić zastosowanie.
- Orzeł / Bezpieczne lądowanie: krótka tarcza po pierwszym skutecznym ofensywnym lądowaniu. Tylko raz na walkę, nie po każdym przeskoku serii.
- Jeż / Ostre kolce: zwiększa istniejące obrażenia zwrotne. Nie dodaje drugiego odbicia ani odbicia od DOT/pocisków.
- Hipopotam / Ciężki kaliber: wzmacnia pierwszy skuteczny pakiet bezpośredniego trafienia skillem. Dla AoE cały pakiet, dla serii pierwsze trafienie; brak wydłużania stuna. Doprecyzować identyfikację pakietu przed implementacją.
- Skunks / Gęsty smród: wydłuża trwanie pozostawionych chmur. Nie wydłuża fazy przenikania ani ruchu, nie zmienia reguł nakładania DOT.
- Królik / Druga szansa: raz na walkę, po przeżyciu obrażeń sprowadzających HP poniżej progu, otrzymuje krótką tarczę. Nie wskrzesza ani nie anuluje śmiertelnego trafienia. Działa również z dawnymi hybrydami ofensywnymi.

Przed kodowaniem bonusów ustalić wartości, progi, czasy i kolejność zdarzeń dla wszystkich ośmiu. Preferować procent bazowej wartości efektu/HP tam, gdzie ma to sens. Nie stosować mnożenia bonus przez bonus: premie do tego samego źródła obrażeń sumować względem jego bazowej wartości.

Tarcze Orła, Królika i istniejącego skilla Królika wymagają jednej jawnej reguły współistnienia i przypisania pochłoniętych obrażeń. Rekomendacja: osobne źródła i czasy, odświeżanie tego samego źródła zamiast jego kumulacji; kolejność pochłaniania według najbliższego wygaśnięcia. Wartości dobrać tak, aby zestaw dwóch tarcz pozostawiał okno odpowiedzi.

## 4. Najważniejsze ryzyka i próby
- Najłatwiejsze odtwarzanie rodziców lvl3 może zdominować inne ścieżki. Porównać lvl3 + jego odtworzonych rodziców z mieszanymi pomocnikami i kilkoma duetami lvl2.
- Cztery bonusy nie muszą być czterema mnożnikami DPS. Efekty mają różne funkcje i okna działania, bez wydłużania ogłuszeń.
- Dwie różne formy lvl3 mogą mieć te same cztery geny. Sprawdzić wszystkie pary, nie zakładać unikalności zestawu genów.
- Kopie same aktywują więzi i mogą być bardzo wydajne. Dwa identyczne lvl3 mają automatycznie cztery więzi, ale kosztują osiem bazowych jednostek i sześć fuzji. Porównać je z lvl3 wspartym jednostkami lvl1 oraz rozbudowaną drużyną lvl2. Celowo porównać skład z kopiami i zróżnicowany skład o takim samym koszcie akcji.
- Kontry mają wynikać z walki. Nie dodajemy przymusowej jednostki wyłączającej więzi. Bazowy Jeż z buffem nadal powinien mieć sensowną relację siły do hybrydy; sprawdzić efekt duplikatów szczególnie we wczesnych rundach.
- Ukończony build ma być odczuwalnie mocny, ale drogie składy porównujemy przy tym samym budżecie, nie tylko tej samej liczbie ciał.
- Rozdzielić dwie oceny: skuteczność gotowego składu i ryzyko dojścia do niego w realnym drafcie. Same walki gotowych drużyn nie potwierdzą regrywalności.

## 5. Interfejs
Przy drużynie kompaktowy pasek tylko posiadanych genów: portret zwierzaka, 1/2 lub aktywne 2/2. Szczegóły pokazują wszystkie formy aktywujące więź; licznik progu pozostaje 2/2 także przy większym składzie.

Na karcie jednostki jeden/dwa/cztery małe portrety przodków ze stanem więzi. Szczegóły jednym zdaniem wyjaśniają efekt i aktualne liczby. Nie tworzymy ośmiu nowych pasków nad jednostkami w walce.

Podgląd fuzji przed zatwierdzeniem: więzi włączone, utracone i zachowane dla całej drużyny oraz wynikowej jednostki. Podgląd ma uwzględniać faktyczne miejsca aktywne/ławkę zgodnie z obecną logiką fuzji. Nie liczy rodziców dwa razy.

Przy starcie walki krótka prezentacja aktywnych więzi. Jednorazowe efekty mają sygnał na jednostce. Podsumowanie i panel szczegółów pokazują aktywne geny; telemetria rozdziela dodatkowe obrażenia i pochłonięcie tarcz. Wszystko ma mieścić się w obecnym ekranie 1280×720 i działać z padem.

## 6. Wdrożenie w obecnym projekcie
1. Dane i czysty resolver: wykorzystać istniejące ZooCatalog.base_traits(), które już rekurencyjnie odczytuje przodków. Jeden resolver liczy osobne aktywne jednostki, geny, beneficjentów i podgląd zmian. Ten sam kod dla UI i symulacji.
2. Definicje więzi jako Resources; parametry efektów oddzielnie od kodu. Stan walki i zużyte aktywacje przechowywać per jednostka, nigdy we współdzielonych Resources.
3. CombatSimulation.setup(): obliczyć obie drużyny po walidacji składów, zastosować bonusy i wyemitować ich początkowy stan. Resety muszą przywracać bazowe wartości. Punkty zdarzeń w _start_skill, lądowaniu, obrażeniach i chmurach obsługują efekty bez rekurencji.
4. development_view.gd i podgląd przepisów: prezentacja genów i symulacja wyniku fuzji bez mutacji meczu. Bez zmiany kosztów akcji.
5. Online: host nadal rozstrzyga. combat_wire.gd pomija Resource definition, więc efektywne staty muszą być jawnie przenoszone w stanie albo deterministycznie odtwarzane do prezentacji; nie wystarczy lokalnie zmienić Resource hosta. Zsynchronizować aktywacje i zdarzenia, zmienić RULES_VERSION oraz PROTOCOL_FINGERPRINT.
6. Laboratorium: jawny przełącznik więzi dla porównania tych samych składów. Historyczne A i odrębny Teamfight T nie dostają systemu przypadkiem przez wspólną klasę bazową. Test pełnego meczu używa docelowego wariantu.

## 7. Kolejność i odbiór
Etap A: resolver, walidacja całej macierzy oraz podgląd fuzji; jeszcze bez zmiany wyniku walki.
Etap B: komplet ośmiu uzgodnionych efektów w laboratorium, testy zdarzeń i porównania ON/OFF. Częściowy zestaw służy tylko technicznym próbom; nie wyciągamy z niego wniosków o całym balansie.
Etap C: pełny mecz, prezentacja, online, celowane porównania gotowych buildów przy równych kosztach.
Etap D: playtest z kolegami. Dopiero jego wynik rozstrzyga dalsze zmiany tempa i liczb.

Testy reguł: pojedynczy lvl3 nie aktywuje niczego; identyczne kopie aktywują próg; lvl1 i hybryda współdzielą gen; lvl1 liczy się, ławka nie; jedna para może uruchomić kilka genów; niezależność drużyn; fuzja usuwa rodziców; zmiana ławki, śmierć partnera, reset i rewanż; stabilność wyników po obu stronach areny.
Testy efektów: sekwencje, AoE, brak celu, przerwany lub chybiony skill, śmiertelny cios, jednoczesne trafienia, tarcze różnych źródeł, DOT i kolce bez łańcuchów, brak mutacji Resources. Roundtrip stanu online i rzeczywista próba host/gość.
Weryfikacja: tools/godot.ps1 check, testy celowane, następnie jedna szersza seria dobranych składów. Oglądanie przy 1× i sprawdzenie UI w rendererze są osobnymi wymaganiami.

W playteście zapisujemy rundę pierwszej więzi, pierwszego lvl3 i 2/3/4 więzi na lvl3; zużyte akcje i bonusy comeback; stan żyć; planowane i faktyczne fuzje; wybory genów/form oraz wynik. Pytamy, czy gracz rozumiał cel przed jego zdobyciem i potrafił wskazać efekt więzi w walce. Nie uznajemy wysokiego win rate lvl3 z czterema bonusami za dowód balansu — to może być skutek tego, kto w ogóle dożył do tego etapu.

## Poza zakresem tej iteracji
Tryb wieloosobowy, przebudowa wszystkich ról/skilli, losowe wydarzenia, nagrody za wygraną, nowe formy, zmiana macierzy fuzji i kolejne progi więzi. Można do nich wrócić po sprawdzeniu podstawowego systemu.


## Korekta użytkownika: więzi również na lvl1
Dwa zwykłe zwierzęta również dają sobie bonus. Stosujemy jeden spójny próg dwóch ciał ze wspólnym genem, zamiast wymogu różnych hybryd. Kopie i lvl1 liczą się oraz otrzymują bonus. Macierz łączenia pozostaje bez zmian: jednakowe zwierzęta nadal nie są przepisem na fuzję, a nie każde dwa różne są kompatybilne. Fuzja dwóch różnych bazowych zwierząt zachowuje ich wkład po jednym punkcie do dwóch genów; łączenie lvl2 bez wspólnych genów analogicznie zachowuje wkład do czterech. Przy zachowaniu aktywności wynikowej formy sama taka legalna fuzja nie zmniejsza liczników genów. Zmiana aktywności/ławki może je zmienić. Wcześniejsze rozważania o utracie progu przez samo zmniejszenie liczby ciał są przy tych zasadach nieaktualne; podgląd nadal ma obliczać rzeczywisty stan przed i po.

