# Warsztat: role, genotypy i dominacja

Status: aktywny warsztat projektowy, 2026-09-27. Ten dokument rejestruje decyzje i otwarte pytania. Nie jest potwierdzeniem implementacji.

## Aktualny priorytet i roadmapa — 2026-09-28
Ta sekcja zastępuje wcześniejsze propozycje oddzielnego shippingu ról i dominacji.

Zatwierdzony zakres pierwszego większego delivery: nowe role ośmiu zwierząt oraz wybór dominującego rodzica podczas fuzji, ze spójnymi nowymi zachowaniami lvl2 i lvl3. Użytkownik chce projektować od razu dwa kierunki hybryd, zamiast najpierw adaptować jeden wynik i później ponownie przebudowywać go na dwa.

Poza delivery: więzi/genotypy drużynowe, osobne buffy/debuffy między rundami i większy multiplayer. Geny jako pochodzenie i dominacja przy fuzji nie oznaczają uruchomienia bonusów za wspólny składnik. Wcześniejsze reguły więzi są zachowane jako odłożony materiał.

Kolejność prac:
1. Warsztat dominacji: rola rodzica głównego, wkład pomocniczego, dwa kontrastujące warianty jednej pary; następnie wszystkie pary lvl2. Przy obecnych 12 parach dwa kierunki dają 24 warianty lvl2.
2. Osobne rozstrzygnięcie lvl3: czy zachowuje wcześniejsze kierunki rodziców i jak wybiera główną funkcję. Nie zakładać automatycznie 24 wariantów lvl3: pełne dziedziczenie wcześniejszych decyzji może dać więcej kombinacji. Zamknąć regułę przed rozpisaniem rosteru i kodowaniem.
3. Implementacja i weryfikacja etapami wewnętrznymi: bazowe role, reprezentatywna para z dominacją, pozostałe lvl2 i lvl3, podgląd obu wyników fuzji, oznaczenia, online i pełny mecz. Laboratorium jest narzędziem diagnostycznym, a nie zamiennikiem pierwszej pełnej paczki dla kolegów. Wczesny feedback do prób jest możliwy bez przedstawiania ich jako ukończonego delivery.
4. Dostarczyć spójną grywalną paczkę; ocenić czytelność ról, sens obu kierunków, tempo walki, koszt fuzji, realne różnice składów i chęć rewanżu. Poprawki na podstawie playtestu.
5. Do więzi wrócić tylko jeśli po tym nadal brakuje głębi; nie są obowiązkowym kolejnym wydaniem.

Zachować obecną grę jako punkt odniesienia. Nie zmieniać jednocześnie draftu/żyć/kosztów bez wykazanego powodu. Nazwy i oznaczenia wariantów powinny wyjaśniać rolę; zakres dodatkowej grafiki do warsztatu. Brak implementacji w dotychczasowych aktualizacjach dokumentacji.

Najbliższa propozycja do decyzji, nie zatwierdzone prawo: dominujący rodzic określa główną rolę i sposób walki, pomocniczy nadaje jej charakterystyczną modyfikację. Nie kopiować mechanicznie dwóch pełnych zestawów umiejętności. Przykład do warsztatu: Hipopotam–Małpa jako tank z leczeniem bliskich sojuszników albo healer z obszarowym przerwaniem napastników. Dokładne skille nadal otwarte.

## Ustalenia użytkownika (historia; kolejność zastąpiona roadmapą powyżej)
1. Najpierw określamy role bazowych zwierząt, inspirując się Teamfight Lab.
2. Role mają być wyraźnie odczuwalne: tank bardzo wytrzymały, niski damage, ewentualnie kontrola; DPS mocny i delikatny; healer i inne wsparcie mają własne zadania.
3. Następnie projektujemy genotypy: co daje każdy, warunki aktywacji i czy liczą się zwykłe zwierzęta, czy tylko hybrydy. Ostatnie pytanie zostało ponownie otwarte przez użytkownika; wcześniejszy wariant z lvl1 nie jest już zamkniętą decyzją.
4. Osobny pogłębiony warsztat określi dominującego i pomocniczego rodzica, wynikowe zachowania oraz potencjalne nazwy i wygląd. Liczba zachowanych/aktywnych genów pozostaje otwarta. Wcześniejsza rekomendacja zachowania obu nie stanowi decyzji użytkownika.
5. Oddzielne buffy/debuffy między rundami i wydarzenia pozostają poza zakresem. Efekty genotypów oraz umiejętności jednostek oczywiście są częścią projektowania.
6. Celem pozostają proste wejście, satysfakcjonująca walka, głębia składów, widoczny moment uruchomienia kombinacji i więcej niż jeden sensowny plan drużyny.

## Sposób pracy
Prowadzimy małe rundy pytań dotyczące jednego tematu. Asystent przedstawia rekomendację, alternatywy i konsekwencje. Po odpowiedzi zapisuje ustalenia i przechodzi do kolejnego zagadnienia. Nie zastępuje odpowiedzi użytkownika własnymi założeniami. Propozycje, zatwierdzone decyzje, implementacja i wyniki testów są oznaczane oddzielnie.

## Wcześniejsza kolejność warsztatów (zastąpiona aktualną roadmapą)
A. Obsada bazowych ról, w tym brakujący czysty ranged DPS.
B. Kontrakty ról: co jednostka robi, komu pomaga, jej słabość, targetowanie, pozycjonowanie, jedna/dwie umiejętności, czytelność. Najpierw tank–healer–protektor, następnie napastnicy i kontrola.
C. Konkretne skille i parametry startowe, scenariusze odbioru w laboratorium. Sprawdzić drużyny bez healera/tanka, nie wymuszać kompletowania wszystkich ról. Nie przenosić automatycznie całego AI wariantu T ani wszystkich jego liczb.
D. Genotypy: kto aktywuje, kto korzysta, próg, kopie, ławka, trwałość w walce, koszt składu, osiem efektów lub dostosowanie liczby do zaakceptowanego rosteru. Dotychczasowe GENE_BONDS_PLAN.md jest materiałem roboczym i wymaga aktualizacji po decyzjach.
E. Dominacja: jedna para jako pełny przykład, rola rodzica głównego/pomocniczego, geny, tożsamość lvl3, liczba wariantów, nazwy, sylwetki i animacje. Następnie pełna macierz. Nie wdrażamy automatycznie wszystkich permutacji.
F. Spójna specyfikacja i etapy implementacji: reguły, dane, symulacja, UI, online, testy i playtest. Wdrażanie zamkniętych etapów bez domyślania nierozstrzygniętych mechanik.

## Obsada po pierwszej odpowiedzi użytkownika
Zatwierdzone kierunki jednostek:
- Królik: pełnoprawny delikatny DPS dystansowy. Atakuje z daleka, skacze i cofa się, utrzymując dystans. Traci dotychczasową rolę i skill nadawania tarcz. Ostateczny wybór użytkownika: rzuca marchewkami i wykonuje obronny odskok, kiedy wróg jest zbyt blisko. Odskok ma cooldown, nie daje niewrażliwości; przy ścianie szuka legalnego miejsca w bok. Zastępuje rozważany atak własnym ciałem. Konkretne zasięgi, rytm ataków, cooldown i długość skoku pozostają do ustalenia. To zamierzona specyfika nowego Królika, nie automatyczne przywrócenie kite'owania wszystkim ranged.
- Małpa: główny skill to leczenie, a dodatkowo ma słaby podstawowy atak zgodnie z późniejszą decyzją użytkownika o basicach dla każdej roli. Zastępuje to wcześniejsze „wyłącznie leczenie” rozumiane jako całkowity brak damage. Bez automatycznego przeniesienia ogłuszającego krzyku z T. Forma i zasięg basica do specyfikacji. Zatwierdzone: regularne leczenie pojedynczego sojusznika, wyłącznie innych, bez samoleczenia. Dokładne targetowanie, zasięg, liczby i zachowanie bez innych sojuszników do ustalenia.
- Jeż: protektor nadający sojusznikom kolczastą tarczę. Tarcza zapewnia dodatkową osłonę i odbija obrażenia. Zatwierdzone: odbicie trafień bezpośrednich — ciosów, skoków i pocisków, bez ograniczenia do melee. Chmury, inne obrażenia okresowe i inne odbicia nie uruchamiają kolców. Kolce tarczy działają podczas trwania osłony. Zatwierdzone: cel to jeden zagrożony sojusznik pod presją przeciwników; odbicie wynosi ustalany później procent obrażeń faktycznie pochłoniętych przez tę tarczę. Trafienie rozbijające osłonę odbija tylko część pochłoniętą, nie obrażenia przechodzące na HP. Jeż dodatkowo ma własne lekkie pasywne odbicie, niezależne od nadanej tarczy; jego wartość i zakres typów trafień pozostają otwarte. Zatwierdzone: tarczę daje wyłącznie innym sojusznikom, nigdy sobie. Własne lekkie kolce pozostają także gdy jest sam. Czas trwania, cooldown i dokładny procent nadal do ustalenia. Ma drobny basic; gdy przeciwnik podejdzie, walczy bez automatycznego odwrotu. Dokładny zasięg basica do specyfikacji. Zdanie o rezygnacji z tarcz interpretujemy w kontekście usunięcia osłony Królika; użytkownik równocześnie wyraźnie zlecił tarczę bazowemu Jeżowi.

Luka ranged DPS rozwiązana Królikiem; nie dodajemy dziewiątego zwierzęcia na podstawie wcześniejszej propozycji asystenta.
Hipopotam — zatwierdzony tank z dużą wytrzymałością, niskimi obrażeniami i krótkim ogłuszeniem obszarowym zamiast prowokacji. Nie przenosimy prowokacji z Teamfight Lab do nowego zestawu. Zatwierdzony warunek: rozpoczyna tupnięcie przy pierwszej możliwości po cooldownie, gdy co najmniej jeden wróg jest w zasięgu; nie czeka na grupę ani przygotowanie skilla przeciwnika. Od razu oznacza brak taktycznego przetrzymywania, nie usunięcie animacji przygotowania. Promień, czas przygotowania, pierwszy cooldown, odnowienie i czas stuna do określenia. Brak decyzji o dodatkowym skillu lub tarczy.
Niedźwiedź — zatwierdzony ofensywny frontliner: mocny szeroki zamach łapą z obrażeniami obszarowymi, bez stuna. Mniej wytrzymały od Hipopotama, z wyraźnie większym damage; twardszy i wolniejszy od Geparda. Parametry do dobrania.
Gepard — zatwierdzony delikatny DPS melee: szybkie podstawowe ataki i powtarzalna seria pazurów w pojedynczy cel. Atakuje najbliższego przeciwnika, bez przeskakiwania frontu. Nie dodajemy osobnej egzekucji z Teamfight Lab. Użytkownik chce zostawić bardziej złożone kombinacje hybrydom.
Orzeł — zatwierdzony asasyn z powtarzalnym skokiem i mocnym pojedynczym trafieniem w najdalszego żywego przeciwnika, wybieranego przy rozpoczęciu skoku. Pomiędzy skokami zwykła walka przy celu. Bez preferowania najmniejszego HP ani automatycznego wyboru healera. Liczby oraz szczegóły zachowania po utracie celu do specyfikacji.
Skunks — kontrola obszaru: zachowuje ruchomy ślad smrodu i obieganie przeciwnika. Późniejsza zasada basiców dla wszystkich dodaje mu również drobny podstawowy atak; jego forma i możliwość wykonywania podczas emisji wymagają specyfikacji. Chmury zadają niewielkie obrażenia w czasie i lekko spowalniają ruch znajdujących się w nich przeciwników. Bez dodatkowego stuna; slow nie dotyczy ataków ani cooldownów. Przenikanie podczas emisji nie oznacza niewrażliwości ani odporności na stun. Dokładny DPS, siła slow, rytm ticków, czas chmur i cooldown pozostają do kalibracji. Zachowujemy dotychczasową regułę braku mnożenia własnego DOT przez nakładające się chmury i niesumowania slow.

Kierunki wszystkich ośmiu ról określone. Zatwierdzona wspólna reguła: każda jednostka ma podstawowy atak niezależnie od roli, także healer, protektor i Skunks. To nie oznacza jednakowego DPS wszystkich ról; tank/wsparcie zadają niewielkie obrażenia, ofensywne role zachowują swój profil. Małpa i Jeż walczą, gdy ktoś podejdzie: brak sytuacyjnego odwrotu za sojuszników i brak dodawania im skilli ucieczki na lvl1; takie kombinacje rozważamy na hybrydach. Zachowujemy wcześniej zaakceptowany konkretny odskok Królika — odpowiedź o zachowaniu wsparcia nie traktowana jako jego odwołanie. Samotna Małpa może zadawać obrażenia basiciem, więc nie wprowadzamy automatycznej porażki healera. Nadal należy sprawdzić impasy leczenia kilku jednostek.

Najbliższy warsztat: zakres pierwszej grywalnej wersji ról; genotypy drużynowe odłożone. Przed implementacją ról domykamy parametry, targetowanie leczenia, współistnienie tarcz i dokładne formy basiców. Nie wymagamy od użytkownika zatwierdzania każdej drobnej liczby; startowe wartości będą propozycją do testów.

## Kryteria dla każdej roli
- Jednozdaniowa obietnica zrozumiała przed zakupem.
- Główny sposób działania i konkretna słabość.
- Wkład widoczny w walce i raportowany odpowiednią miarą, nie tylko damage.
- Co robi bez idealnego partnera i jako ostatnia żywa jednostka.
- Przykład współpracy oraz możliwej odpowiedzi rywala.
- Wyraźne odróżnienie od sąsiedniej roli, zwłaszcza tank/protektor/bruiser.

## Materiały i ograniczenia
Źródła: GAME_DESIGN_V0_2.md, docs/TEAMFIGHT_LAB_V0_1.md, docs/GENE_BONDS_PLAN.md i bieżąca rozmowa. T jest eksperymentem, nie aktualnym pełnym meczem. Jego raport po poprawkach pozycjonowania opisuje walki około 43–69 s, więc nie zakładamy automatycznie zachowania dotychczasowego tempa 20–30 s. Docelowe tempo omówimy przy projektowaniu skilli.










## Warsztat genotypów: poziom więzi zależny od poziomów jednostek
Status: reguła najmocniejszej pary i wspólnego poziomu dla nosicieli zatwierdzona; efekty i balans otwarte, bez implementacji.
Użytkownik proponuje trzy poziomy: udział zwykłego zwierzęcia daje więź I; jednostki lvl2 lub wyższe więź II; dwa lvl3 ze wspólnym składnikiem więź III („giga więź”). To ponownie otwiera wcześniejszą propozycję jednego progu. Dla większej liczby nosicieli obowiązuje zatwierdzona poniżej reguła najmocniejszej pary.

Zatwierdzone przez użytkownika: dla każdego genu wybieramy dwie najwyżej rozwinięte wystawione jednostki, które go posiadają. Niższy poziom z tej pary wyznacza poziom więzi. Mniej niż dwie jednostki oznacza brak więzi. Przykłady: 1+1 / 2+1 / 3+1 → I; 2+2 / 3+2 → II; 3+3 → III. Dodanie trzeciego nosiciela lvl1 do dwóch lvl2 nie obniża więzi II. Liczymy osobne jednostki, bez sumowania bonusów za każdą parę.

Zatwierdzone: jeden poziom więzi danego genu obowiązuje wszystkie wystawione jednostki posiadające ten gen, także lvl1 korzystające z II/III uruchomionego przez mocniejszą parę. Nie ograniczamy otrzymywanego poziomu więzi własnym poziomem jednostki. Ryzyko zbyt silnych tanich beneficjentów wymaga testów.

Poziomy powinny wzmacniać jeden rozpoznawalny efekt genu. Nie zakładamy potrajania wszystkich wartości ani trzech osobnych efektów naraz. Konkretny charakter III, dopuszczenie identycznych kopii jako pary, relacja z dominacją i liczbą zachowanych genów do zamknięcia w warsztacie. Samo osiągnięcie dwóch lvl3 nie dowodzi, że III będzie wystarczająco rzadkie — po zamknięciu reguł przeliczyć koszt i realny timing.

## Ryzyko dominacji kopii i siła lvl3
Użytkownik obawia się, że spamowanie jednostek z więziami będzie skuteczniejsze niż inwestycja w lvl3; proponuje zwiększenie skoku siły lvl2 → lvl3 jako przeciwwagi. Zapisujemy kierunek do kalibracji, bez zatwierdzania mnożnika statystyk ani automatycznej wygranej lvl3 nad każdą parą lvl2.

Rekomendacja: lvl3 powinien stanowić odczuwalny awans już bez kompletu aktywnych więzi. Siła może wynikać z mocnego, czytelnego skilla i oszczędności miejsca, nie tylko HP/DPS. Mocny lvl3 nie jest samodzielnym rozwiązaniem spamu: dwie identyczne formy lvl3 mogłyby uruchamiać kilka więzi III naraz, zależnie od ustaleń o kopiach i dominacji.

Więcej nosicieli tego samego genu nie podnosi poziomu ponad wynik dwóch najlepszych ani nie daje osobnego stosu za każdą parę. Jednak zwiększa liczbę beneficjentów, więc korzyść szerokiego składu nadal istnieje. W projektowaniu efektów unikać nieograniczonych wzajemnych wyzwalaczy, mnożenia aur i nieskończonego podtrzymywania leczenia/tarcz.

Porównania do testów: szeroki skład lvl1; para lvl2 + tanie kopie z więzią II; różnorodne lvl2; jeden lvl3 z pozostałym budżetem wsparcia; pary lvl3 (identyczne i różne, jeśli dopuszczone). Liczyć bazowych rodziców, dobory, akcje fuzji, rundę dostępności i limit sześciu miejsc. Osobno porównać decyzję przed/po pojedynczej fuzji, a osobno końcowe składy o podobnym koszcie. Sprawdzić przeciwników i ustawienia, nie wyłącznie globalny win rate.

Otwarte pytanie warsztatowe: identyczne kopie hybrydy mogą aktywować pełne II/III czy wyższe więzi wymagają różnych form? Nie dodajemy ograniczenia bez decyzji użytkownika. Trzy poziomy więzi, ich siła i udział dominacji muszą być oceniane razem z dostępnością lvl3 w rzeczywistym meczu.



## Bieżący warsztat par
Szczegóły w docs/HYBRID_DOMINANCE_WORKSHOP.md. Niedźwiedź + Gepard: dwa kierunki zaakceptowane. Przy wyborze dominacji pokazujemy profil hybrydy. Nazwy robocze, parametry do kalibracji.

## Aktualizacja macierzy
2026-09-28: Zatwierdzono nową macierz 12 par lvl2, po 3 partnerów na zwierzę: Niedźwiedź–Gepard, Niedźwiedź–Małpa, Niedźwiedź–Jeż, Gepard–Królik, Gepard–Hipopotam, Małpa–Skunks, Małpa–Hipopotam, Orzeł–Jeż, Orzeł–Królik, Orzeł–Skunks, Hipopotam–Królik, Jeż–Skunks. Zastępuje starą macierz projektowo, bez edycji Resources na tym etapie. Przepisy lvl3 wymagają przeprojektowania. Kolejna para warsztatu: Gepard+Królik; propozycje niezatwierdzone w HYBRID_DOMINANCE_WORKSHOP.md.

## Stan warsztatu po uzupełnieniu rozmowy — 2026-09-28
Kierunki i nazwy pierwszych sześciu par opisano w HYBRID_DOMINANCE_WORKSHOP.md. Parametry i oznaczone szczegóły pozostają otwarte. Gehip/Hipard i Małkuns/Skunpa zatwierdzeni. Aktualnie czekamy na ocenę propozycji Małpa+Hipopotam (para 7). To zapis ustaleń, nie implementacja.

Para 7 Małpa+Hipopotam ma zaakceptowane kierunki (szczegóły w HYBRID_DOMINANCE_WORKSHOP.md). Wyjaśnione: Małpowiedź i Skunpa bez zmian; utrata leczenia drużyny dotyczy tylko dominującego Hipopotama w parze Małpa+Hipopotam. Nie jest globalną regułą dominacji.

