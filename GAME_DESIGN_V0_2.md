# Auto Battler Zoo — Project Brief v0.2

> Aktualny draft i lvl3 opisuje sekcja 53; ruchomy Skunks jest opisany w sekcji 49. Mechaniki wcześniejszych skilli opisują sekcje 42–43, a rozszerzenie mocniejszych skilli i indywidualnych początkowych cooldownów na cały roster — sekcja 47. Sekcja 46 dokumentuje wcześniejszą próbę trzech hybryd. Nowsze decyzje zastępują starsze sprzeczne liczby, pozostawione jako historia baseline'u.

## Cel projektu

Tworzymy nową grę 2D w Godot.

Gra to auto battler 1v1:
- gracze podejmują decyzje między rundami,
- sama walka odbywa się automatycznie,
- docelowo local multiplayer + online,
- na start local 1v1.

Najważniejsze na początku jest sprawdzenie, czy:
1. automatyczna walka jest czytelna i przyjemna do oglądania,
2. role jednostek są wyraźnie odczuwalne,
3. wybory składu faktycznie wpływają na przebieg walki.

Nie rozszerzać scope bez potrzeby.

---

# 1. Core koncept

Motyw gry: zabawne zwierzęta oraz ich hybrydy.

Styl:
- lekki,
- czytelny,
- humorystyczny,
- przyjazny wizualnie,
- spójne assety 2D produkowane docelowo z użyciem AI.

Nie kopiujemy TFT ani Hearthstone Battlegrounds.

Głównym wyróżnikiem ma być hybrydyzacja zwierząt.

---

# 2. Draft między rundami

Istnieje dokładnie 8 bazowych zwierząt lvl1.

Cała ósemka jest dostępna jako wspólna pula wyborów.

Gracze wybierają naprzemiennie.

Wybrane zwierzę znika z aktualnej puli.

Przegrany poprzednią rundę wybiera jako pierwszy w kolejnej fazie draftu.

To jest podstawowy comeback mechanism.

Maksymalny skład gracza:
- 6 aktywnych jednostek.

Obserwowanie wyborów przeciwnika jest częścią gry, a nie czymś, co próbujemy ukrywać.

---

# 3. System poziomów i hybryd

## Lvl1
- jedno bazowe zwierzę,
- dokładnie 1 charakterystyczny skill,
- prosta rola,
- łatwe do zrozumienia.

## Lvl2
Powstaje z połączenia dwóch kompatybilnych lvl1.

Lvl2:
- dziedziczy oba główne mechanizmy,
- dziedziczy dwie główne mechaniki, realizowane oddzielnie lub jako jedna połączona akcja,
- zaczyna tworzyć wyraźny archetyp gameplayowy.

Dziedziczenie może zmieniać sposób użycia mechaniki i łączyć obie w jedną akcję; nie dodaje niezależnej trzeciej głównej mechaniki. Zatwierdzone adaptacje opisuje sekcja 7. Przykład: ciężki cios Hipopotama może stać się ciężkim rzutem Małpy, zachowując wyraźny wind-up i burst.

## Lvl3
Powstaje z połączenia dwóch kompatybilnych lvl2.

Łączymy wyłącznie lvl2 bez wspólnego bazowego zwierzęcia. Cztery różne zwierzęta bazowe dają cztery skille, bez duplikatów i bez dodatkowych zasad wzmacniania powtórzonych skilli. Brak wspólnego zwierzęcia jest warunkiem koniecznym, a nie zgodą na wszystkie takie połączenia: nadal obowiązuje wybrana macierz kompatybilności.

Lvl3:
- dziedziczy mechaniki rodziców,
- ma docelowo 4 skille,
- jest znacznie bardziej złożoną i charakterystyczną jednostką.

Nie używać klasycznego:
„zbierz kilka kopii → kolejna gwiazdka”.

Poziom wynika z hybrydyzacji.

---

# 4. Matematyka rosteru

Zakładamy:

- 8 lvl1,
- każdy lvl1 ma dokładnie 3 kompatybilnych partnerów,
- daje to 12 unikalnych lvl2.

Następnie:

- każdy lvl2 ma dokładnie 2 kompatybilnych partnerów lvl2,
- daje to dokładnie 12 nieuporządkowanych par połączeń; docelowo około 12 unikalnych lvl3.

Macierz lvl3 wymaga późniejszej weryfikacji: każdy lvl2 ma mieć dwóch partnerów bez wspólnego bazowego zwierzęcia. Liczba unikalnych form zależy również od tego, czy różne pary rodziców mogą prowadzić do tej samej formy. Nie projektować macierzy lvl3 w pierwszym prototypie.

Docelowo około:

- 8 lvl1,
- 12 lvl2,
- 12 lvl3,
- około 32 form.

Nie projektować każdej możliwej kombinacji każdego z każdym.

---

# 5. Bazowe zwierzęta lvl1

## Niedźwiedź
Rola:
tank / bruiser

Ruch:
wolny

Skill:
mocny cios łapą

Target:
najbliższy sensowny wróg

Charakter:
dużo HP, niska mobilność

---

## Gepard
Rola:
szybki melee DPS

Ruch:
szybki

Skill:
szybka seria pazurów

Target:
najbliższy sensowny wróg

Charakter:
wysoki DPS, niska przeżywalność

---

## Małpa
Rola:
ranged DPS

Ruch:
normalny

Skill:
rzut bananem

Target:
najbliższy sensowny cel w zasięgu

Charakter:
utrzymuje dystans, słaba w zwarciu

---

## Orzeł
Rola:
diver / assassin

Ruch:
specjalny przez dive

Skill:
po 2 sekundach początkowej blokady aktywnych skilli wykonuje dive na najdalszego żywego przeciwnika; ponawia co 6 s

Target:
najdalszy żywy przeciwnik przy rozpoczęciu dive; między skokami zwykły pobliski cel melee

Charakter:
najpierw maszeruje z drużyną, po odblokowaniu dive atakuje tyły przeciwnika

---

## Jeż
Rola:
punish / anti-fast-melee

Ruch:
normalny

Skill:
pasywne kolce: 2 obrażenia zwrotne za każde trafienie bezpośrednim atakiem melee, bez cooldownu; szczegóły w sekcjach 19 i 20

Charakter:
niski własny DPS, skuteczny przeciw szybkim melee

---

## Hipopotam
Rola:
heavy burst frontliner

Ruch:
wolny

Skill:
bardzo mocne uderzenie z wyraźnym wind-upem

Target:
najbliższy sensowny wróg

Charakter:
duży burst, mała szybkość

---

## Skunks
Rola:
ranged utility / control, średni zasięg

Ruch:
normalny

Skill:
śmierdząca chmura osłabiająca przeciwników w pobliżu

Basic attack: zielony pocisk, 6 obrażeń co 1 s. Zasięg maksymalny 150 px, preferowany dystans 70–100 px, krótszy niż u Małpy. Chmura pozostaje wokół Skunksa (100 px od krawędzi ciała), a nie przy trafionym celu. Po złapaniu w zwarciu staje i walczy zgodnie z regułą ranged. Orzeł rozpoznaje go jako cel backline.

Charakter:
mało obrażeń, dużo utility

---

## Królik
Rola:
mobile / evasion

Ruch:
szybki

Skill:
dash / unik po spełnieniu określonego warunku

Charakter:
bardzo mobilny, niski HP

---

# 6. Matrix lvl2

Dozwolone połączenia:

- Niedźwiedź + Gepard
- Niedźwiedź + Małpa
- Niedźwiedź + Jeż
- Gepard + Orzeł
- Gepard + Królik
- Małpa + Skunks
- Małpa + Hipopotam
- Orzeł + Jeż
- Orzeł + Hipopotam
- Hipopotam + Królik
- Jeż + Skunks
- Skunks + Królik

Każdy lvl1 ma dokładnie 3 partnerów.

---

# 7. Zatwierdzony design lvl2 — wariant do prototypowania

Status: użytkownik zlecił implementację wszystkich 12 lvl2 wraz z pełną pętlą meczu i osobną kalibracją liczbową. Macierz 12 par z sekcji 6 pozostaje bez zmian. Aktualny lvl1 zostaje bazą do dalszej pracy.

## Zasady wspólne

- Priorytet wizualny: zabawne, charakterystyczne hybrydy, czytelne pełne sylwetki i animacje. Obecne głowy są placeholderami; finalne assety powstaną później. Lvl2 może być większy wizualnie, ale rozmiar kolizji dobieramy osobno.
- Lvl2 jest zwykle wytrzymalszy i ma więcej bazowych obrażeń niż lvl1. Nie sumujemy statystyk rodziców. Założenie 15–25% przewagi zostało zastąpione: lvl2 ma wygrywać z pojedynczym lvl1, wygrywać z dobranymi parami i czasem trójkami lvl1, ale przegrywać z kontrującymi parami.
- Dziedziczymy dwie główne mechaniki, niekoniecznie dwa niezależne skille. Dopuszczalna jest jedna połączona akcja realizująca obie mechaniki.
- Moc i cooldown różnicują tempo: częste słabsze efekty, krótkie serie, rzadkie potężne uderzenia. Liczby obrażeń i cooldownów lvl1 nie przechodzą automatycznie na lvl2.
- Zachwianie jest krótkim zatrzymaniem bez anulowania rozpoczętej akcji; po nim akcja jest kontynuowana. Pełne ogłuszenie pozostaje mocniejszym efektem. Zachwiania z nakładających się chmur nie sumują się.
- Spowolnienie od chmur nie sumuje się. Kilka chmur tej samej jednostki nie mnoży obrażeń na jednym celu; częstsze rzuty zwiększają pokrycie. Interakcje chmur różnych hybryd pozostają do doprecyzowania przed implementacją.
- Pierwszy prototyp Orła–Jeża opiera dodatkową wytrzymałość na HP; nie dodajemy jeszcze osobnego systemu pancerza.

## 1. Niedźwiedź + Gepard

Trzy szybkie uderzenia stożkowe. Każde zadaje obrażenia obszarowe i zachwianie roboczo 0,1 s, bez kasowania zamachu ofiary. Jedna krótka seria, po niej wyraźna przerwa. Obrażenia i cooldown do ustalenia.

## 2. Niedźwiedź + Małpa

Gruba małpa melee z głową niedźwiedzia. Zamaszysty stożek, a następnie po jednym bananie w każdego trafionego przeciwnika. Jedna czytelna sekwencja łapy i dodatkowych pocisków. Liczby do ustalenia.

## 3. Niedźwiedź + Jeż

Wytrzymały frontliner z mocniejszymi kolcami i szeroką łapą. Więcej HP, karanie skupienia ataków melee. Siła kolców i łapy do ustalenia.

## 4. Gepard + Orzeł

Trzy szybkie ataki na ten sam cel z naprzemiennych stron: lewa, prawa, lewa. Seria stanowi jeden skill ze wspólnym cooldownem i wysokimi obrażeniami pojedynczego celu. Śmierć celu kończy serię; nie przenosi pozostałych skoków na następnego przeciwnika. Reguła wyboru pierwszego celu do doprecyzowania.

## 5. Gepard + Królik

Po otrzymaniu trafienia: dash za przeciwnika, zerwanie aggro i trzy mocne ciosy. Częsta agresywna reakcja, ale cooldown i seria pozostawiają okno odpowiedzi. Bez niewrażliwości; szczegółowe liczby do testów.

## 6. Małpa + Skunks

Ranged rzucający specjalnymi zgniłymi bananami. Każdy specjalny banan tworzy obszar obrażeń w czasie i spowolnienia. Mały cooldown, duże pokrycie terenu; brak mnożenia obrażeń własnych nakładających się chmur i brak sumowania spowolnienia. Zwykły atak nie jest automatycznie kolejną chmurą. Czasy, obrażenia i siła spowolnienia do ustalenia.

## 7. Małpa + Hipopotam

Ranged z potężnym bananem zadającym duże obrażenia i ogłuszającym. Wyraźne przygotowanie, długi cooldown; między specjalnymi rzutami zwykłe pociski. Obrażenia i czas ogłuszenia do ustalenia.

## 8. Orzeł + Jeż

Powtarzalny desant na tyły, wysoka wytrzymałość i kolce. Główna korzyść to przetrwanie wśród wrogów, nie duży wzrost zadawanych bezpośrednio obrażeń. Pierwszy test używa większego HP zamiast nowego systemu pancerza. Bez dodatkowego AoE po lądowaniu. Dokładne targetowanie i liczby do ustalenia.

## 9. Orzeł + Hipopotam

Ciężkie lądowanie na pojedynczym celu: duże obrażenia i ogłuszenie na 2 s. Dłuższy cooldown. Nie jest to obszarowe ogłuszenie. Dokładne obrażenia, cooldown i wybór celu do ustalenia.

## 10. Hipopotam + Królik

Reakcja po otrzymaniu trafienia: zerwanie aggro, skok do najdalszej jednostki przeciwnika, następnie przygotowanie ciężkiego ciosu z ogłuszeniem. Lądowanie nie zadaje automatycznie ciosu — istnieje osobny zamach. Liczby do ustalenia.

## 11. Jeż + Skunks

Ranged z niewielkimi pasywnymi kolcami. Kolczasta chmura zadaje większe obrażenia i okresowo wywołuje krótkie zachwiania bez kasowania rozpoczętych akcji. Nakładanie chmur nie sumuje zachwiań; brak permanentnego przerywania zamachów. Częstotliwość impulsów i liczby do ustalenia.

## 12. Skunks + Królik

Po otrzymaniu trafienia duży skok w bok, zerwanie aggro i dalsze używanie chmur. Odskok ma cooldown, nie daje niewrażliwości ani nie cofa otrzymanego trafienia. W 1v1 nie usuwa celu przeciwnikowi. Ogłuszenie może go zatrzymać; obowiązują granice areny i legalne lądowanie. Bez nieśmiertelności wynikającej z ciągłego uniku.

## Co pozostaje przed implementacją

Dokładne staty i cooldowny, brakujące reguły targetowania oraz czasy kontroli tłumu. Oddzielnie zasady łączenia jednostek i koszt dla składu. Nie projektujemy jeszcze lvl3 ani draftu. Zmiana liczby niezależnych skilli lvl2 wymaga późniejszego przeglądu starego założenia czterech skilli lvl3; nie rozstrzygamy tego teraz.

---
# 8. Ogólna filozofia kontr

Nie używać hard counterów typu:
„A zawsze wygrywa z B”.

Kontry powinny wynikać z mechanik.

Przykładowe osie:

- tank / armor vs burst,
- fast attacks vs thorns,
- ranged vs dive,
- mobilność vs control,
- sustain vs anti-heal,
- single target vs swarm / AoE.

Nie wszystkie osie muszą istnieć na lvl1.

Lvl1 ma być prosty.

Prawdziwa głębia ma pojawiać się głównie na lvl2 i lvl3.

---

# 9. Arena

Arena:
- swobodna przestrzeń 2D,
- szeroki prostokąt,
- orientacyjnie proporcje 16:9.

Nie używamy sztywnej planszy liniowej.

Mimo swobodnego movementu walka ma zachowywać wyraźny sens:
front / backline / ranged / dive.

---

# 10. Startowe pozycje

Dwie drużyny zaczynają po przeciwnych stronach areny.

Automatyczne ustawienie na podstawie roli:

- frontlinerzy bliżej centrum,
- ranged dalej od centrum,
- jednostki mobilne według swojej roli,
- diver może zaczynać z tyłu; najpierw maszeruje ze zwykłym pobliskim celem, a dive odblokowuje się po 2 s.

Na obecnym etapie gracz NIE ustawia jednostek ręcznie.

---

# 11. AI — targetowanie

Każda rola ma własną regułę targetowania.

Nie używać globalnej zasady:
„wszyscy zawsze atakują najbliższego”.

Jednostka wybiera cel zgodnie z rolą.

Target jest utrzymywany, dopóki nadal jest sensowny.

Jednostka może zmienić target, jeśli:
- cel zginie,
- cel stanie się niewłaściwy dla jej roli,
- sytuacja zmieni się na tyle, że nowy cel ma wyraźnie wyższy priorytet.

Po śmierci aktualnego targetu:
natychmiastowy retarget.

---

# 12. AI — ranged

Ranged nie stoi bezmyślnie w miejscu.

Ranged ma preferowany dystans.

Jeśli przeciwnik:
- jest za daleko → ranged podchodzi,
- jest w dobrym dystansie → atakuje,
- podejdzie za blisko, ale jeszcze nie złapał ranged w zwarciu → ranged cofa się,
- złapie ranged w zwarciu → ranged zatrzymuje się i atakuje pobliskiego napastnika; nie ucieka do ściany.

Roboczo kontakt to maksymalnie 12 px między krawędziami ciał. Stan zwarcia utrzymuje się, dopóki żywy wróg melee jest w odległości do 40 px; większy próg wyjścia zapobiega ciągłemu przełączaniu ruchu. Po śmierci lub odejściu zagrożenia wraca utrzymywanie dystansu. Orzeł w locie nie wiąże walką; robi to po lądowaniu. Ataki Małpy nadal są pociskami, bez dodawania nowego melee skilla.

Nie robić agresywnego ciągłego kitingu po każdym strzale.

---

# 13. AI — dive

Diver, np. Orzeł:

- przez pierwsze 2 s wybiera zwykły najbliższy sensowny cel i idzie do walki,
- po 2 s wybiera najdalszego żywego przeciwnika i wykonuje dive, następnie ponawia po cooldownie 6 s,
- może przeskoczyć front.

Dive podlega wspólnej początkowej blokadzie aktywnych skilli przez 2 s. Nie jest to powtarzalny globalny cooldown: po otwarciu każdy skill używa własnych reguł.

Dive zadaje roboczo 25 obrażeń, cooldown 6 s liczy się od rozpoczęcia skoku. Cel jest wybierany na nowo przy każdym rozpoczęciu, bez preferowania ranged: najdalszy według odległości między krawędziami ciał. Między skokami Orzeł walczy zwykłymi atakami melee z pobliskim sensownym celem. Jeśli został jeden przeciwnik, dive działa również na niego z bliska. Nie daje niewrażliwości. Śmierć celu w locie nie zeruje cooldownu; obowiązuje legalne lądowanie.

---

# 14. AI — dash

Dash nie jest globalnie ofensywny ani defensywny.

Zależy od konkretnej jednostki.

Przykładowo:

Królik:
defensywny dash / unik.

Dash Królika jest zablokowany przez pierwsze 2 s. Trafienia sprzed odblokowania nie są kolejkowane; po odblokowaniu potrzebne jest nowe trafienie spełniające warunek. Po otrzymaniu bezpośredniego trafienia, jeśli Królik przeżył i wróg melee jest blisko, wykonuje krótki dash od niego. Cooldown: 5 s od rozpoczęcia dashu. Dash nie cofa otrzymanych obrażeń, nie daje niewrażliwości i nie przechodzi przez żywe jednostki żadnej drużyny. Próg bliskości i długość dashu pozostają parametrami do testów.

Hipopotam + Królik:
ofensywny doskok.

---

# 15. Kolizje

Przeciwnicy:
blokują ruch.

Sojusznicy:
także blokują ruch; żywe jednostki nie mogą zajmować tego samego miejsca.

Powód:
front ma faktycznie chronić backline, a sylwetki mają pozostawać rozdzielone. Zwykły ruch lokalnie obchodzi blokujących sojuszników; dash jest zatrzymywany przez ciała. Dive omija ciała w locie, ale musi lądować poza wszystkimi żywymi jednostkami. Martwe jednostki nie blokują ruchu.

---

# 16. Blokowanie jednostek

Frontliner:
po kontakcie z przeciwnikiem wiąże się z nim w walce.

Assassin / diver:
może ominąć lub przeskoczyć blokadę, jeśli wynika to z jego skilla.

---

# 17. Focus fire

Dozwolone.

Kilka jednostek może atakować ten sam cel.

Nie wprowadzać sztucznego limitu liczby atakujących jeden target.

---

# 18. Pociski

Zwykłe basic ranged attacks:
mogą przechodzić przez inne jednostki.

Wybrane specjalne skille:
mogą być blokowane przez pierwszy trafiony cel.

To ma być cecha konkretnego skilla, a nie globalna reguła.

---

# 19. Skille

Skille dzielą się na aktywne powtarzalne, warunkowe oraz pasywne lub jednorazowe. Nie każdy skill ma cooldown.

## Aktywne powtarzalne

Niedźwiedź, Gepard, Małpa, Hipopotam i Skunks:
- przez pierwsze 2 s aktywne skille są zablokowane; później użycie wymaga odpowiedniego celu i zasięgu,
- każda umiejętność ma własny cooldown według sekcji 23,
- cooldown zaczyna się w momencie rozpoczęcia umiejętności,
- wykonywanie umiejętności ofensywnej zajmuje czas atakowania: basic attack nie jest wykonywany równocześnie.

## Warunkowe

Dash Królika wymaga spełnienia warunku oraz gotowego cooldownu. Obowiązują zasady z sekcji 14.

## Pasywne i dive

- Jeż: kolce działają bez cooldownu, nie przerywają jego ataków i mogą działać podczas aktywnej umiejętności.
- Kolce zadają roboczo 2 obrażenia za każde trafienie bezpośrednim atakiem melee. Pociski, obrażenia okresowe i inne odbicia nie uruchamiają kolców. Kolce nie wywołują kolejnych kolców ani rekurencyjnego odbicia.
- Większa liczba trafień przy tym samym DPS oznacza więcej obrażeń zwrotnych. Wartość 2 jest punktem startowym do testów, nie gwarancją balansu.
- Orzeł: powtarzalny dive po 2 s początkowej blokady, cooldown 6 s, zgodnie z sekcją 13.

Jednostka wykonuje tylko jedną akcję specjalną naraz.

Powyższy limit dotyczy aktywnych umiejętności; pasywki mogą działać w ich trakcie.

Jeżeli kilka skilli jest gotowych:
AI wybiera ten bardziej odpowiedni do aktualnej sytuacji.

Reguły mają być:
- proste,
- czytelne,
- przewidywalne.

Przykładowo:
- AoE ma wyższy priorytet, gdy może trafić kilka celów,
- dash ma sens, jeśli trzeba skrócić / zwiększyć dystans,
- skill defensywny może mieć priorytet przy niskim HP.

Część skilli działa:
- po cooldownie.

Część:
- po warunku.

Przykładowe warunki:
- liczba otrzymanych hitów,
- poziom HP,
- sytuacja po dive,
- liczba pobliskich przeciwników.

---

# 20. Koniec walki

Na start:
walka trwa aż jedna drużyna zostanie całkowicie wybita.

Nie używać limitu czasu.

Chcemy umożliwić epickie końcówki 1v1.

Jeśli testy pokażą problemy typu:
dwa tanki biją się bardzo długo,
dopiero wtedy dodać mechanizm anti-stall.

## Pierwszeństwo kolców

Kolce uruchamia faktyczne trafienie melee, nie samo rozpoczęcie zamachu. Obrażenia rozliczamy w kolejności:
1. Atak melee trafia jednostkę z kolcami.
2. Atakujący otrzymuje obrażenia od kolców.
3. Jeśli atakujący ginie, jego nadchodzący atak nie zadaje obrażeń.
4. Jeśli przeżyje, obrażenia ataku są zadawane normalnie.

Jeśli zarówno kolce, jak i nadchodzący atak byłyby śmiertelne, Jeż wygrywa tę wymianę. Zasada dotyczy również hybryd dziedziczących kolce; nie oznacza automatycznej wygranej całej drużyny, gdy inni wrogowie nadal żyją.

Trafienia z tego samego kroku rozliczamy partią: najpierw kolce, potem zwykłe obrażenia. Śmierć od kolców anuluje nadchodzące trafienie jego autora; zwykłe śmiertelne obrażenia nie anulują zwykłego trafienia już zakwalifikowanego do tej samej partii. Wynik sprawdzamy po całej partii. Obustronne wybicie oznacza remis, również gdy dwa Jeże zginą od wzajemnych kolców. Wcześniej wystrzelony pocisk może działać po śmierci strzelca, dopóki walka trwa; po rozstrzygnięciu końca walki nie czekamy na przyszłe trafienia pozostałych pocisków.

---

# 21. Docelowy czas walki

Typowa pełna walka:
około 20–30 sekund.

Pojedynczy wyrównany pojedynek lvl1 vs lvl1:
około 10–12 sekund.

To jest ważny baseline do balansu.

---

# 22. Balance baseline v0.1

Nie ustawiać statów losowo.

Najpierw użyć wspólnego punktu odniesienia.

Neutralny lvl1:

- 100 HP,
- 10 DPS z basic attacku,
- orientacyjny TTK przeciw neutralnemu lvl1: około 10 sekund bez dodatkowych efektów,
- cel czasu całego wybranego wyrównanego 1v1: około 10–12 sekund; osobno mierzymy czas do pierwszego trafienia i czas od pierwszego otrzymanego trafienia do śmierci jednostki. Ocalałych nie wliczamy jako zgonów do średniego TTK. Cel 20–30 sekund dotyczy reprezentatywnego pełnego 6v6, nie każdej pary jednostek.

Skill powinien wnosić orientacyjnie:
około 20–30% dodatkowej efektywnej wartości jednostki względem samego basic attacku.

Ta wartość może pochodzić z:
- damage,
- survivability,
- CC,
- mobility,
- debuffów,
- utility.

Nie traktować 20–30% jako sztywnego wymogu matematycznego.
To baseline do pierwszych testów.

---

# 23. Wstępne staty lvl1 v0.1

To NIE są finalne wartości.

Mają dać spójny pierwszy model.

## Niedźwiedź
HP:
150

Basic DPS:
około 9

Skill:
mocny cios

Orientacyjny cooldown:
5 s

Orientacyjny skill damage:
około 25

Ruch:
wolny

---

## Gepard
HP:
80

Basic DPS:
około 15

Skill:
szybka seria trzech trafień melee; każde osobno uruchamia kolce; seria zastępuje basic attack na czas wykonania i jest przerywana przez śmierć

Orientacyjny cooldown:
5 s

Ruch:
szybki

---

## Małpa
HP:
90

Basic DPS:
około 10

Typ:
ranged

Skill:
rzut bananem

Orientacyjny cooldown:
4 s

Orientacyjny skill damage:
około 18–20

Ruch:
normalny

---

## Orzeł
HP:
85

Basic DPS:
około 11 (korekta po playteście: basic damage 10 → 11, interwał 1 s)

Skill:
powtarzalny dive co 6 s; pierwszy po 2 s, między skokami basic melee

Orientacyjny dive damage:
około 25

Ruch:
specjalny

---

## Jeż
HP:
120

Basic DPS:
około 7

Skill:
thorns

Robocze obrażenia zwrotne:
2 za każde trafienie bezpośrednim atakiem melee, bez cooldownu.

Zastępuje wcześniejsze odbicie 25% obrażeń. Kolce mają pierwszeństwo zgodnie z sekcją 20 i nie uruchamiają kolejnego odbicia.

Ruch:
normalny

---

## Hipopotam
HP:
160

Basic DPS:
około 6

Skill:
ciężkie uderzenie

Orientacyjny cooldown:
6 s

Orientacyjny damage:
około 40

Wyraźny wind-up.

Ruch:
wolny

---

## Skunks
HP:
105

Basic DPS:
około 6

Skill:
debuffująca chmura

Orientacyjny cooldown:
6 s

Orientacyjny efekt:
-25% obrażeń ataków i ofensywnych skilli przez 3 s, bez zmiany attack speed. Jednorazowe sprawdzenie przeciwników w promieniu przy aktywacji; chmura nie jest trwającym polem obrażeń. Ponowna aplikacja odświeża czas, nie kumuluje siły. Stałe obrażenia kolców pozostają 2.

Wariant zatwierdzony jako baza prototypu; wartości podlegają późniejszej kalibracji na podstawie testów.

Ruch:
normalny

---

## Królik
HP:
75

Basic DPS:
około 11

Skill:
dash / unik

Orientacyjny cooldown:
5 s; najpierw wspólna blokada 2 s, aktywacja warunkowa według sekcji 14

Ruch:
szybki

---

# 24. Zasada skalowania lvl2 i lvl3

Lvl2 NIE może być prostą sumą statów rodziców.

Przykład błędnego podejścia:
Niedźwiedź 150 HP + Gepard 80 HP = 230 HP.

Nie robić tego.

Aktualne założenie lvl2 (zastępuje wcześniejszą przewagę 15–25%):
- dwie odziedziczone mechaniki, oddzielne lub połączone w jedną akcję;
- wyraźny wzrost bazowej mocy, bez prostego sumowania statystyk rodziców;
- przy pełnym HP i świeżych cooldownach wygrywa z każdym pojedynczym lvl1;
- wygrywa z dobranymi parami i czasem trójkami lvl1, ale kontrujące pary mogą go pokonać.

Koszt i ograniczenie rozwoju wynikają z zużycia rodziców oraz akcji draftu. Kryteria testów: sekcja43.

Lvl3:
kolejny wzrost mocy, ale duża część przewagi powinna wynikać z synergii 4 skilli, nie tylko z większych statów.

Nie projektować jeszcze finalnej formuły lvl2/lvl3 przed testami prototypu.

---

# 25. Balans — sposób pracy

Astra nie ma próbować „idealnie zbalansować gry” przed implementacją.

Kolejność:

1. stworzyć spójny model liczb,
2. uruchomić działający combat prototype,
3. umożliwić symulowanie walk,
4. zebrać dane,
5. dopiero wtedy iterować balans.

---

# 26. Symulacje balansowe

Po działającym prototypie Astra powinna przygotować możliwość automatycznego uruchamiania dużej liczby walk.

Testować:
- każdy lvl1 vs każdy lvl1,
- różne składy,
- mirrored matchups,
- później lvl2.

Zbierać przynajmniej:

- win rate,
- średni czas walki,
- średni TTK,
- damage dealt,
- damage taken,
- healing jeśli pojawi się później,
- liczba użyć skilli,
- skill uptime,
- target changes,
- przeżywalność,
- skuteczność focus fire,
- częstotliwość sytuacji 1v1 na końcu.

---

# 27. Analiza balansu

Astra powinna wskazywać outliery.

Przykładowo:

- jednostka wygrywa 70%+ równych matchupów,
- skill prawie nigdy się nie odpala,
- jednostka umiera zanim użyje głównego skilla,
- średni combat time jest znacznie poza zakresem 20–30 s,
- ranged nie potrafi utrzymać dystansu,
- dive prawie zawsze natychmiast usuwa backline,
- tanki powodują ekstremalnie długie walki.

Nie zmieniać balansu bez raportowania przyczyny.

---

# 28. Zasada zmian balansu

Zmiany robić małymi krokami.

Preferowane:
5–15% zmiany statów.

Unikać:
nagłych zmian typu +100% HP bez wyraźnej przyczyny.

Każda większa zmiana powinna mieć uzasadnienie na podstawie testów.

---

# 29. Scope pierwszego prototypu

Pierwszy prototyp implementuje tylko:

- jedną arenę,
- dwie drużyny,
- ręcznie skonfigurowane składy,
- wszystkie osiem lvl1 na odbiór v0.1, wdrażane stopniowo,
- movement,
- targetowanie,
- melee,
- ranged distance keeping,
- dive Orła,
- dash Królika,
- thorns Jeża,
- debuff Skunksa,
- heavy hit Hipopotama,
- focus fire,
- HP,
- damage,
- cooldowny,
- śmierć,
- pełne wybicie drużyny,
- podstawowe telemetry / combat stats.

---

# 30. Czego pierwszy prototyp NIE implementuje

Na tym etapie NIE implementować:

- pełnego draftu,
- pełnego systemu między rundami,
- lvl2,
- lvl3,
- wszystkich hybryd,
- online,
- finalnego UI,
- progression meta,
- finalnych assetów,
- kosmetyki,
- zaawansowanych efektów,
- ekonomii.

---

# 31. Architektura prototypu

Projekt powinien być data-driven.

Staty i definicje jednostek nie powinny być zakodowane na sztywno w logice AI.

Preferowany podział:

UnitDefinition / Resource:
- HP,
- attack damage,
- attack speed,
- move speed,
- attack range,
- role,
- preferred range,
- targeting rules,
- skille.

Runtime Unit:
- current HP,
- current target,
- cooldowny,
- aktualny stan AI,
- aktywne status effects.

Skill:
osobne definicje zachowania.

Dzięki temu balans można zmieniać bez przepisywania logiki.

---

# 32. Astra i subagenci

Astra jest głównym koordynatorem.

Może samodzielnie:
- analizować architekturę,
- dzielić zadania,
- tworzyć subagentów,
- delegować implementację,
- delegować testy,
- delegować analizę balansu.

Nie chcę ręcznie narzucać liczby i ról subagentów, jeśli Astra może dobrać je sensownie do aktualnego zadania.

Preferencja użytkownika z playtestu: proste delegowane zadania kierować do Luna z reasoning high, gdy to wystarczy; nie używać automatycznie Astry do wszystkich podzadań. Małe poprawki weryfikować celowanymi testami, pełną serię testów i symulacji uruchamiać przy większym etapie zmian.

---

# 33. Instrukcja dla Astry przed implementacją

Astra powinna:

1. przeczytać cały dokument,
2. traktować go jako source of truth,
3. wskazać ewentualne sprzeczności lub braki techniczne,
4. NIE wymyślać nowych mechanik bez potrzeby,
5. zaproponować prostą architekturę Godot,
6. rozpisać implementation plan,
7. dobrać subagentów według potrzeby,
8. zaimplementować prototyp,
9. uruchomić testy,
10. sprawdzić działanie archetypów,
11. zebrać telemetry,
12. przeprowadzić pierwszą analizę balansu,
13. podsumować wyniki i problemy.

---

# 34. Najważniejsza zasada projektu

Najpierw udowodnić, że core combat jest:
- czytelny,
- zabawny do oglądania,
- przewidywalny,
- daje poczucie wpływu decyzji gracza.

Dopiero potem:
- draft,
- hybrydy,
- lvl2,
- lvl3,
- większa liczba systemów.

Nie over-engineerować pierwszego prototypu.

---

# 35. Wnioski z przeglądu i zaakceptowane decyzje

Zaakceptowane zasady zostały wprowadzone także do odpowiednich sekcji powyżej:
- Jeż: stałe 2 obrażenia od kolców za trafienie melee zamiast procentowego odbicia; bez cooldownu i bez łańcuchów odbić.
- Aktywne powtarzalne skille: po zmianie z 2026-09-25 pierwsze 2 s są zablokowane; później własne cooldowny liczone od rozpoczęcia, brak równoczesnego basic attacku podczas wykonywania ofensywnej umiejętności.
- Królik: defensywny dash po otrzymaniu trafienia i przy pobliskim wrogu melee, 5 s cooldownu, bez niewrażliwości i bez przenikania przez przeciwników.
- Orzeł: pierwszy dive po 2 s, kolejne co 6 s na najdalszego żywego przeciwnika, roboczo 25 obrażeń; między skokami basic melee.
- Hybrydy: adaptacja sposobu użycia przy zachowaniu podstawowej funkcji mechaniki; Orzeł + Jeż zachowuje dive i pasywne kolce, bez dodatkowego AoE.
- Lvl3: rodzice lvl2 nie mogą mieć wspólnego bazowego zwierzęcia.
- Kolce rozliczane przed nadchodzącymi obrażeniami melee; śmierć atakującego od kolców anuluje obrażenia jego trafienia.

Wszystkie liczby są bazą prototypu, a nie potwierdzonym wynikiem testów balansu. Szczególnie sprawdzić początkowy burst Orła i kolce przeciw Gepardowi.

## Otwarte kwestie — nie zastępować domysłami

- Rozstrzygnięte przez D2: rozdzielono czas całego pojedynku i TTK w sekcji 22; bazowe HP/DPS pozostają bez zmian.
- Rozstrzygnięte przez D1: partie trafień i remis przy obustronnym wybiciu, zgodnie z sekcją 20.
- Draft: odświeżanie puli, liczba wyborów, pierwszeństwo w pierwszej rundzie i obsługa pełnego składu — poza pierwszym prototypem.
- Macierz lvl3: weryfikacja dwóch partnerów bez wspólnych zwierząt i liczby unikalnych wynikowych form — poza pierwszym prototypem.

Zakres bieżącej aktualizacji: dokumentacja decyzji. Nie jest to rozpoczęcie implementacji.

---

# 36. Visual Direction v0.1

Wstępny kierunek wizualny dla Combat Prototype v0.1:

- 2D cartoon.
- Duże, czytelne sylwetki, rozpoznawalne przy docelowej skali walki.
- Lekko absurdalne, przerysowane proporcje podkreślające charakter zwierząt.
- Spójna grubość obrysu przy porównywalnej skali ekranowej.
- Mało detalu; kształt i najważniejsze cechy mają pierwszeństwo przed dekoracją.
- Wyraźne kolory, dobry kontrast jednostek względem areny i czytelne oznaczenie drużyn.
- Proste, ale czytelne animacje ruchu, przygotowania ataku, trafienia, użycia skilla i śmierci.

To NIE jest jeszcze final art direction. Czytelność walki jest ważniejsza niż finalna jakość artworku. Prototyp może używać uproszczonych, tymczasowych grafik zgodnych z tym kierunkiem; finalne assety pozostają poza jego zakresem.

Role jednostek muszą być rozpoznawalne na pierwszy rzut oka: sylwetka, proporcje, postawa i sposób poruszania się powinny odróżniać frontlinera, ranged, divera oraz jednostki mobilne i utility. Oznaczenia drużyn nie powinny zacierać cech jednostki; sam kolor nie powinien być jedynym nośnikiem informacji.

Animacja i efekty mają wyjaśniać przebieg walki: kierunek dive i dashu, wind-up Hipopotama, trafienie pocisku, aktywację kolców i działanie debuffu. Efekty nie powinny zasłaniać sylwetek ani HP.

Hybrydy mają docelowo być zabawne, charakterystyczne i czytelne wizualnie. Łączą rozpoznawalne cechy rodziców w jedną spójną sylwetkę, bez mnożenia drobnych detali. Ta wskazówka nie włącza hybryd do Combat Prototype v0.1.

Dokładna perspektywa, paleta, proporcje i wzorce graficzne wymagają późniejszego dopracowania. Kierunek wizualny nie zmienia rozmiarów kolizji ani statów jednostek sam przez się.

## Dokument przygotowania implementacji

Analiza, proponowana architektura, zadania i plan weryfikacji: `docs/COMBAT_PROTOTYPE_V0_1_PLAN.md`.
Plan został zatwierdzony przez użytkownika 2026-09-24, wraz z D1–D3, architekturą, zakresem ośmiu lvl1, kolejnością prac i planem weryfikacji. Uzupełnia brief; rozstrzygnięcia gameplayowe zapisano także tutaj. Implementacja nadal wymaga osobnego taska użytkownika.

---

# 37. Zatwierdzenie planu Combat Prototype v0.1 — 2026-09-24

Użytkownik zatwierdził propozycje z `docs/COMBAT_PROTOTYPE_V0_1_PLAN.md` jako obowiązujący plan prototypu. D1 (partie trafień i remisy), D2 (rozdzielenie czasu walki i TTK) oraz D3 (warianty skilli) są rozstrzygnięte i nie wymagają ponownego potwierdzenia.

Małpa ma basic ranged oraz osobny mocniejszy rzut bananem: 18–20 obrażeń zamiast obrażeń basica, nie oba pakiety jednocześnie. Pociski są celowane, przechodzą przez inne jednostki i trafiają raz wskazany żywy cel; po utracie celu wygasają bez retargetu.

Przyjęto także robocze reguły kontaktu z blokującym przeciwnikiem, targetowania, ruchu, faz kroku, wind-up/recovery i telemetry opisane w planie. Konkretne nieustalone jeszcze liczby (np. promienie, prędkości, czasy animacji i obrażenia serii Geparda) implementator dobierze i jawnie zapisze w T0/T1 jako parametry do testów. Nie są to wyniki kalibracji.

Architektura: jeden rdzeń symulacji, Resources z definicjami, oddzielny stan runtime, prezentacja Godot oraz runner headless korzystające z tej samej logiki. Przyjęto plan zadań, zależności, późniejszej delegacji i kryteria weryfikacji. Draft i lvl2/lvl3 nadal pozostają poza v0.1.

Zatwierdzenie planu NIE jest zgodą na implementację. Czekamy na osobny prompt użytkownika; w obecnej aktualizacji zmieniono wyłącznie dokumentację.

---

# 38. Implementacja Combat Prototype v0.1 — osobne zlecenie użytkownika

Po zatwierdzeniu planu użytkownik zlecił implementację w osobnym prompcie. Historyczne zastrzeżenie z sekcji 37 zostało tym samym spełnione. Zaimplementowany zakres pozostaje ograniczony do areny, ręcznych składów, ośmiu lvl1, ich walki i podstawowej prezentacji oraz testów i telemetry. Draft, hybrydy, lvl2/lvl3, online, ekonomia i meta progression pozostają poza zakresem.

Konkretne początkowe parametry techniczne i umiejętności zapisano w `resources/README.md` oraz Resources. Nie zmienia to znaczenia Balance baseline v0.1: nominalny basic DPS jest oddzielny od rzeczywistej wydajności przy ruchu, castowaniu i statusach. Wyniki serii, ograniczenia oraz ewentualne korekty dokumentuje `docs/COMBAT_PROTOTYPE_V0_1_REPORT.md`, a odtwarzanie testów opisuje `docs/TESTING.md`.

Akceptacja implementacji technicznej nie zastępuje odbioru czytelności, przyjemności oglądania i balansu przez użytkownika/designera.

---

# 39. Korekta otwarcia i czytelności po playteście — 2026-09-25

Na podstawie zlecenia użytkownika zastąpiono wcześniejszą zasadę natychmiastowego dive oraz przenikania sojuszników:
- Wspólna blokada aktywnych skilli przez pierwsze 2 s: ofensywne skille, dive i warunkowy dash. Ruch i basic attacks działają od startu; pasywne kolce nie są blokowane.
- Orzeł przed odblokowaniem idzie do zwykłego pobliskiego celu; cel backline wybiera dopiero przy gotowości dive. Nie wymuszamy sztucznego rozdzielania obrażeń ani limitu atakujących cel.
- Kolizje wszystkich żywych jednostek. Lokalne obchodzenie sojusznika pomaga formować front. Lądowanie i dash respektują własną drużynę; lot dive pozostaje wyjątkiem.
- Zasięg jest liczbą w pikselach, mierzoną między krawędziami ciał. Pierwszy wariant do testów: Niedźwiedź 18 (basic i łapa), Królik 8. Pozostałe wartości pozostają bez zmian. To różnica zasięgu, nie nowy typ obrażeń lub nowy skill.
- Obecne rysunki oraz proste animacje to placeholdery. Docelowa dopracowana grafika, sylwetki i animacje są planowane w osobnym etapie; nie powstają w tej poprawce.

Wyniki sprzed tej zmiany są historycznym baseline'em. Nie należy ich przedstawiać jako wyniku bieżącego modelu kolizji i otwarcia.

# 40. Próba drugiego ranged — 2026-09-25

Na zlecenie użytkownika Skunks został przeniesiony z melee utility do ranged utility. Ma zapewnić drugą linię ognia i drugi cel dla dive. Parametry: zasięg 150 px, preferowany dystans 70–100 px; Małpa zachowuje 230 px i 125–205 px. HP 105, basic 6/s oraz chmura (-25% obrażeń przez 3 s, cooldown 6 s, zasięg 100 px wokół siebie) bez zmian. Basic jest pociskiem i nie aktywuje kolców. Targetowanie: najbliższy sensowny cel ranged zamiast preferowania skupiska przeciwników; start z tyłu według roli ranged. To wariant do playtestu, nie finalny balans.

# 41. Odnawialny dive na najdalszy cel — playtest v0.1.4

Użytkownik zatwierdził powtarzalny dive: pierwszy po 2 s, kolejne co 6 s od rozpoczęcia, 25 obrażeń. Najdalszy żywy wróg bez priorytetu ranged jest wybierany dopiero przy aktywacji; między skokami normalna walka melee. Przy jednym wrogu skok działa także z bliska. Ta decyzja zastępuje wszystkie starsze odniesienia do jednorazowego skoku i priorytetu backline, w tym w opisach hybryd, które nadal nie są implementowane. Pozostałe staty Orła bez zmian.

# 42. Przebudowa skilli — zatwierdzona implementacja

Ta sekcja zastępuje wcześniejsze opisy skilli Niedźwiedzia, Hipopotama, Skunksa i Królika. Pozostałe mechaniki pozostają bez zmian. Wartości są wariantem do playtestu, nie wynikiem pełnej kalibracji.

## Niedźwiedź — zamaszysta łapa

25 obrażeń wszystkim przeciwnikom, których środki znajdują się w stożku 100 stopni przed Niedźwiedziem. Promień od środka Niedźwiedzia 114 px (29 ciała + 85 zasięgu skilla). Kierunek i pozycja stożka ustalone przy rozpoczęciu, bez śledzenia celu podczas zamachu. Telegraphed obszar jest widoczny przez zamach 0,45 s, potem uderzenie i 0,55 s recovery. Cooldown 5 s. Wyjście ze stożka pozwala uniknąć trafienia. To melee: każdy trafiony Jeż uruchamia kolce; obowiązuje pierwszeństwo kolców.

## Hipopotam — ogłuszający cios

30 obrażeń (wcześniej 40) w pojedynczy cel plus ogłuszenie na 1 s po skutecznym trafieniu. Zamach 1 s, recovery 0,75 s, cooldown 6 s. Stun blokuje ruch/ataki/skille, przerywa rozpoczętą akcję bez zwracania cooldownu; już wypuszczone pociski i istniejące chmury działają dalej. Ogłuszonego lotnika sprowadza na legalną pozycję. Ogłuszenie jest widoczne przez cały czas trwania, a nie tylko jako krótki napis. Jednoczesne trafienia z tego samego kroku pozostają rozliczane partią.

## Skunks — skierowana chmura z obrażeniami w czasie

Zastępuje dawny debuff -25% obrażeń. Skunks odwraca się tyłem i wypuszcza chmurę w stronę wybranego przeciwnika. Środek chmury to pozycja celu zapamiętana na początku przygotowania; obszar nie śledzi ruchu przeciwnika. Zasięg aktywacji 150 px od krawędzi ciał, promień chmury 55 px. Przygotowanie 0,25 s, recovery 0,35 s, cooldown 6 s. Chmura trwa 3 s, zadaje 4 obrażenia co 0,5 s (maksymalnie 24 przy pozostaniu przez cały czas); pierwszy tick po 0,5 s od utworzenia. Obrażenia tylko w obszarze: środek jednostki musi znajdować się wewnątrz koła. Wyjście zatrzymuje obrażenia, wejście umożliwia kolejny tick. Nie rani sojuszników, nie uruchamia kolców ani reakcji Królika. Pozostaje po śmierci Skunksa, jeśli walka jeszcze trwa. Chmury różnych Skunksów zadają obrażenia niezależnie.

## Królik — zerwanie aggro i skok za plecy

Po przeżytym bezpośrednim trafieniu, przy gotowym cooldownie, przeskakuje za plecy autora trafienia. Cooldown 5 s, czas skoku 0,25 s; pierwsze odblokowanie po 2 s. Dotyczy również napastnika ranged. Nie daje niewrażliwości, nie cofa trafienia, nie daje premii do obrażeń od tyłu. Kolce i DOT nie wywołują skoku, stun blokuje reakcję. Przy równoczesnych trafieniach wybierany jest żywy autor największego trafienia (remis rozstrzygany deterministycznie).

Wszyscy przeciwnicy aktualnie skupieni na Króliku wybierają inne dostępne cele i ignorują Królika przez 1 s przy istnieniu alternatywy. W 1v1 i gdy brak alternatywy pozostaje normalnym celem. Rozpoczęte zamachy na niego są przerywane bez zwracania cooldownu; już lecące pociski i rozpoczęte skoki nie znikają. Skok Królika może ominąć ciała w locie, ale lądowanie musi być legalne; przy zajętych plecach wybierane jest pobliskie wolne miejsce. Ta zasada zastępuje wcześniejszy odskok od wroga bez przenikania.

## Czytelność pozostałych skilli

Gepard: widoczne cięcia serii. Małpa: specjalny pocisk odróżniony od basica. Jeż: widoczne kolce oraz efekt obrażeń zwrotnych. Orzeł: bez zmian w gameplayu. Nadal są to proceduralne placeholdery, a nie finalne assety.

# 43. Pełna pętla meczu i wymagania balansu lvl2 — zatwierdzone

Ta sekcja zastępuje historyczne ograniczenie do Combat Prototype v0.1 oraz wcześniejsze niewielkie skalowanie lvl2. Implementujemy lokalny mecz dwóch graczy, wszystkie 12 hybryd z sekcji7, draft, ławkę i życia. Bez golda, lvl3, online i meta progression.

## Mecz i draft

- Każdy gracz zaczyna z 5 życiami. Przegrana walka zabiera 1 życie; 0 kończy mecz. Remis nie zabiera życia.
- Startowa wspólna pula to 4 losowe różne lvl1. Losowany pierwszy gracz; wybory ABBA dają każdemu 2 jednostki. Łączenie niedostępne przed pierwszą walką.
- Przed kolejnymi walkami nowa wspólna pula 4 różnych lvl1, bez uzupełniania w trakcie draftu. Kopie w składzie i identyczne hybrydy dozwolone; brak duplikatów dotyczy tylko bieżących 4 ofert.
- Standardowo 1 akcja na gracza. Przy 2 życiach 2 akcje, przy 1 życiu 3 akcje, w KAŻDYM kolejnym drafcie przy tym stanie życia. Bonusy mogą przysługiwać obojgu.
- Jedna akcja to dobranie 1 oferty ALBO połączenie 2 posiadanych kompatybilnych lvl1. Nie ulepsza się pojedynczego zwierzęcia bez rodzica.
- Wybory naprzemienne, zaczyna przegrany poprzedniej walki. Remis zachowuje wcześniejsze pierwszeństwo. Po wykorzystaniu akcji jednego gracza drugi wykonuje pozostałe.
- Pusta pula i brak legalnego połączenia wymuszają pas. Pozostałe niewykonalne akcje przepadają, nie przechodzą do kolejnej rundy. Nie ma dobrowolnego pomijania legalnej akcji.

## Skład, ławka i łączenie

- Do 6 aktywnych jednostek i do 3 na ławce. Co najmniej 1 aktywna jednostka na stronę przed walką.
- Połączenie zużywa rodziców i daje 1 lvl2 zajmujący 1 miejsce; jest nieodwracalne. Rodzice mogą pochodzić ze składu lub ławki.
- Przed walką można bezpłatnie zmieniać aktywne jednostki i ławkę. Pozycje na arenie nadal wynikają z roli i kolejności, nie z ręcznego ustawiania punktów.
- Wyrzucenie całej jednostki jest bezpłatne, nie zwraca akcji ani rodziców. Przy pełnych 9 miejscach przed doborem trzeba zwolnić miejsce lub zużyć akcję na legalne połączenie.
- Po walce cały skład i ławka zostają. Przed kolejną walką wszystkie wystawione jednostki wracają z pełnym HP i świeżymi cooldownami, włącznie z początkową blokadą 2 s.

## Kalibracja lvl2

- Lvl2 jest potężny; koszt to 2 rodziców, zużyta akcja oraz niedobranie dodatkowego lvl1. Dawne +15–25% siły nie obowiązuje.
- Twarde kryterium: każdy lvl2 wygrywa z każdym pojedynczym lvl1 w testowanych geometriach i po obu stronach. Bez automatycznego zwycięzcy zależnego od poziomu.
- W starciach z parami lvl1 muszą występować zarówno wygrane hybryd, jak i wygrane kontrujących par. Wybrane lvl2 mogą pokonać trójkę lvl1; to nie jest gwarancja przeciw każdej trójce.
- Lvl2vsLvl2: sprawdzamy osobno każdą hybrydę, bez pozornej oceny na podstawie globalnego50% z symetrycznej macierzy.
- Mierzymy wyniki, czas walki, TTK zabitych, damage dealt/taken, użycia skilli i przeżywalność. Badamy osie: wielotrafienia kontra kolce; mobilność kontra ranged; kontrola kontra burst; obszarówki kontra grupy.
- Wyniki są skończonym deterministycznym pokryciem scenariuszy. Brak kontrprzykładu nie dowodzi uniwersalnego zwycięstwa dla dowolnych możliwych pozycji, ale znaleziony kontrprzykład singlelvl1 wyklucza akceptację kalibracji.
- Dodatkowe mechaniki liczbowe: zachwianie przesuwa w czasie trwającą akcję zamiast kasować; slow działa wewnątrz obszaru i nie sumuje się; własne chmury nie mnożą DOT na jednym celu. Chmury różnych właścicieli mogą zadawać obrażenia niezależnie, ale slow pozostaje najsilniejszy, nie sumowany.

## Stan implementacji i pierwsza kalibracja — 2026-09-25

Zaimplementowano lokalną pętlę meczu, draft, ławkę i wszystkie 12 hybryd. Aktualne liczby znajdują się w Resources oraz raporcie `docs/LVL2_BALANCE_REPORT.md`. Nie zmieniano parametrów lvl1 podczas kalibracji hybryd.

Przykłady docelowej na ten etap relacji siły do cooldownu: Niedźwiedź–Gepard 3 × 14 obrażeń / 7 s; Niedźwiedź–Małpa stożek 25 + banan 12 na trafionego / 7 s; Orzeł–Hipopotam 40 obrażeń + stun 2 s / 12 s. Są to liczby prototypu, podlegające dalszemu balansowaniu.

Końcowe pokrycie obejmuje 1996 scenariuszy: 576 pojedynków lvl2–lvl1, 864 walk z parami lvl1, 72 z trzema wybranymi składami trójek, 420 lvl2–lvl2, 16 mieszanych drużyn i 48 kontroli pojedynczych mechanik. Wszystkie pojedynki lvl2–lvl1 wygrywa hybryda; w testach par wygrywa 766 hybryd i 98 par, w testach trójek 10 hybryd i 62 trójki. Brak utknięć; niezależny audyt wszystkich 998 par lustrzanych potwierdza zgodny wynik i identyczny czas.

Nie uznajemy balansu za finalny: Niedźwiedź–Małpa i Skunks–Królik są słabsi w pojedynkach między hybrydami, Hipopotam–Królik pozostaje mocniejszy. Niedźwiedź–Małpa ma jednak potwierdzoną wygraną przeciw wybranej trójce lvl1. Następny playtest powinien ocenić wartość tych ról w drużynach i decyzjach draftu; sam wynik 1v1 nie rozstrzyga ich pełnej wartości.

# 44. Czytelność draftu i gotowości skilli — po playteście

Użytkownik zaakceptował wykonanie tych elementów już w prototypie:

- Wyraźna ramka aktywnego gracza, przyciemnienie nieaktywnej połowy oraz duże wskazanie tury i pozostałych akcji przy ofertach.
- Wybór własnego zwierzęcia podświetla kompatybilnych partnerów w składzie i na ławce. Podgląd pary pokazuje rodziców, wynik oraz krótki opis skilla hybrydy.
- Oferta pasująca do posiadanego zwierzęcia otrzymuje oznaczenie możliwego połączenia. Jest to podpowiedź planowania, nie darmowa fuzja ani zniesienie zakazu łączenia przed pierwszą walką.
- Pod HP jednostki widoczne są paski ładowania aktywnych skilli: fioletowy/niebieski podczas ładowania, złoty przy gotowym cooldownie, pomarańczowy podczas użycia. Dwa aktywne skille mają niezależne paski; same pasywne kolce nie dostają sztucznego cooldownu.
- Paski odczytują czas symulacji i jej terminy cooldownów. Początkowa blokada 2 s jest odróżniona od kolejnych pełnych cooldownów. Pauza zatrzymuje także wskaźniki. Pełny pasek oznacza gotowość cooldownu, a nie pominięcie warunku zasięgu, trafienia lub ogłuszenia; szczegóły są w podglądzie jednostki.

To zmiana prezentacji, bez nowej kalibracji walki. Orzeł–Hipopotam zachowuje cooldown 12 s. Placeholdery nadal służą ocenie czytelności i rozgrywki; finalne grafiki i animacje pozostają osobnym etapem.

# 45. Czytelny wynik i odczuwalna siła skilli — kolejny playtest

- Wynik walki ma jednoznacznie i dużym komunikatem wskazywać zwycięskiego gracza, utratę życia oraz aktualny stan żyć. Zwycięstwo rundy, remis i zwycięstwo całego meczu muszą być rozróżnione.
- Użytkownik oczekuje wyraźnie odczuwalnych momentów użycia skilli: mocne trafienie, czytelny rytm serii i zauważalny skutek. Rzadszy skill może być potężniejszy; nie sprowadzamy różnorodności do szybszego odnawiania wszystkich umiejętności.
- Bieżący etap obejmuje analizę udziału basiców, bezpośrednich obrażeń skilli, DOT i kolców oraz osobną ocenę CC i mobilności. Raport: `docs/SKILL_IMPACT_REVIEW.md`. Nie ustalamy jednakowego procentu obrażeń skilli dla wszystkich ról.
- Nie zmieniono w tym etapie balansu ani nie dodano mechanicznego odrzutu. Rozdzielenie wizualnej reakcji na trafienie od rzeczywistego przesunięcia ciała jest istotne: to drugie zmienia przebieg walki. Konkretne korekty mocy i nowe mechaniki pozostają do uzgodnienia po analizie.

# 46. Mocne i czytelne skille v0.2 — zatwierdzona próba

Użytkownik zatwierdził plan i zlecił implementację pierwszej próby na trzech hybrydach: Orzeł–Hipopotam, Małpa–Hipopotam i Niedźwiedź–Gepard. Ta sekcja zastępuje wspólne 2 s otwarcia dla tych trzech umiejętności. Pozostałe jednostki zachowują dotychczasowe liczby.

- Każdy aktywny skill ma osobny początkowy cooldown, niezależny od czasu odnowienia kolejnych użyć. Gotowość nie pomija celu, zasięgu ani warunków reakcji. Pasywne kolce działają od początku.
- Moc trzech hybryd przesuwamy częściowo z basiców do charakterystycznej akcji. Późniejsze pierwsze użycie ma równoważyć mocniejsze trafienie. Dokładne liczby i wyniki prób zapisujemy w `docs/BURST_PILOT_NUMBERS.md`; nie stosujemy jednego procentu damage dla wszystkich ról.
- W Combat Lab są dwa porównywalne warianty: A — wcześniejsze liczby i otwarcie po 2 s; B — nowe liczby i indywidualne otwarcie. Oba mają nowy feedback. Przełączenie resetuje walkę, zachowując składy. Pełny mecz używa B.
- Feedback obejmuje przygotowanie, mocny moment trafienia, czytelną serię, wyróżnione obrażenia, porcję utraconego HP i roboczy dźwięk. Reakcja trafienia wynika z rzeczywiście zadanych obrażeń. Ruch reakcji sylwetki nie zmienia pozycji ani kolizji w symulacji. Bez mechanicznego odrzutu i globalnego hit-stop.
- Weryfikacja obejmuje udział skilli, całe użycia, czas pierwszego skilla, zgony przed nim, skuteczność i czas walki. Zachowujemy wymagania lvl2 kontra lvl1 oraz kontry. Po celowanych próbach jedna szersza seria dla wybranego wariantu.
- Odbiór satysfakcji wymaga playtestu użytkownika w 1×. Rozszerzenie na resztę rosteru nastąpi po ocenie tej próby; nie produkujemy jeszcze finalnych assetów.

## Zasada oceny balansu — doprecyzowanie użytkownika

Nie dążymy do 50/50 w pojedynkach każdej hybrydy z pozostałymi ani do jednakowej samowystarczalności. Jednostki mają się uzupełniać: część jest dobra solo, część wymaga osłony, a część może wykonać ważną akcję na początku i następnie zginąć. Porażki w 1v1 albo niska przeżywalność same w sobie nie uzasadniają wzmocnienia.

Ocenę opieramy na roli, kontrach i wkładzie w wynik drużyny: obrażeniach, kontroli, odciąganiu przeciwników i momencie wywarcia wpływu. Porównania zespołowe powinny uwzględniać osłonę kontra jej brak, odpowiednie i niekorzystne cele oraz zamianę jednostki przy zachowaniu pozostałego składu. Równość wszystkich ze wszystkimi zatarłaby pożądane różnice. Wymaganie przewagi lvl2 nad pojedynczym lvl1 pozostaje w mocy.

# 47. Mocniejsze skille całego rosteru — zatwierdzona implementacja

Po playteście użytkownik zlecił rozszerzenie kierunku na wszystkie 8 lvl1 i 12 lvl2, ponieważ mieszany stan trzech poprawionych hybryd nie pozwalał ocenić rytmu całej walki. Zastępuje to ograniczenie pilotażu z sekcji 46.

- Dobieramy osobno moc basica, moc skilla, pierwszy cooldown i odnowienie kolejnych użyć. Gotowość nadal wymaga właściwego celu, zasięgu i możliwości działania.
- Ciężkie uderzenia mają wyraźne przygotowanie i mocny skutek; serie zachowują rytm trafień, chmury obrażenia w czasie i kontrolę terenu, kolce karanie wielotrafień, a uniki wartość mobilności i zerwania aggro. Nie wymagamy większości obrażeń ze skilla od każdej roli.
- Nie dodajemy nowych mechanik, niewrażliwości, fizycznego odrzutu ani globalnego zatrzymywania walki. Efekty, wizualna reakcja sylwetek, ślad utraconego HP oraz robocze dźwięki obejmują cały roster. Powtarzalne DOT/kolce mają spokojniejsze efekty niż mocny pojedynczy hit.
- Pełny mecz używa nowego wariantu B. Laboratoryjny A zachowuje stan bezpośrednio sprzed tego rozszerzenia, włącznie z trzema hybrydami poprzedniego pilotażu. A/B mają wspólną nową prezentację; dawne raporty pilotażu opisują inne znaczenie A i pozostają historyczne.
- Nie balansujemy hybryd do 50/50 w pojedynkach. Weryfikujemy podstawowe relacje poziomów, kontry oraz przydatność w konkretnych drużynach i ustawieniach. Śmierć po istotnej akcji albo potrzeba osłony nie oznacza automatycznie słabej jednostki.
- Aktualne parametry i uzasadnienie ról: `docs/FULL_ROSTER_SKILLS.md`. Wyniki zespołowego porównania i ograniczenia: `docs/FULL_ROSTER_RESULTS.md`. Finalne assety i nowe systemy pozostają poza zakresem.

# 48. Informacje przed wyborem zwierzęcia

Oferty pokazują rolę, krótki opis skilla i wszystkich partnerów hybrydyzacji. Wyróżnieni są partnerzy już posiadani, także na ławce. Osobny przycisk otwiera bezpłatny podgląd statystyk, działania skilli i ich aktualnych liczb, czasu pierwszej gotowości oraz odnowienia. Można przejść do opisu każdej wynikowej hybrydy i wrócić. Podgląd jest dostępny także przy jednostkach w składzie oraz przed zatwierdzeniem fuzji. Przeglądanie nie wybiera oferty ani nie zużywa akcji. Macierz połączeń i liczby są odczytywane z zasobów gry; zasady draftu i balans nie zmieniają się.

# 49. Skunks — ruchomy ślad smrodu

Na zlecenie użytkownika zastępujemy stacjonarne rzucanie chmur przez bazowego Skunksa oraz Jeża–Skunksa i Skunksa–Królika. Te trzy jednostki nie wykonują zwykłych ataków: podchodzą do walki i podczas aktywnej umiejętności obiegają przeciwnika, zostawiając chmury na faktycznej trasie ruchu. Nie biegają losowo po arenie. Zwykły ruch respektuje kolizje, ogłuszenie blokuje działanie; brak niewrażliwości. Własne nakładające się chmury nie mnożą obrażeń.

- Skunks: obrażenia wyłącznie ze śladu smrodu, bez dodatkowego spowolnienia.
- Jeż–Skunks: ten sam kierunek ruchu, pasywne kolce i zachwiania w chmurach.
- Skunks–Królik: dodatkowo reaktywny odskok z zerwaniem aggro i śladem smrodu; nadal można go trafić i zabić.
- Małpa–Skunks: zachowuje ataki dystansowe i specjalne zgniłe banany tworzące spowalniające chmury. To świadomy wyjątek wynikający z połączenia z Małpą.

Liczby są robocze i pochodzą z Resources. Historyczne raporty obrażeń poprzedniego Skunksa nie opisują tego zachowania. Wariant A laboratorium zachowuje historyczne zachowanie ranged; pełny mecz używa nowego B.

## Przenikanie podczas emisji — v0.6.1

Skunks, Jeż–Skunks i Skunks–Królik przenikają przez żywe jednostki obu drużyn tylko podczas aktywnej akcji śladu smrodu. Nie zyskują niewrażliwości ani odporności na kontrolę. Koniec akcji (także przerwanie ogłuszeniem lub zerwaniem celu) przywraca kolizje i rozdziela ciała na wolnej pozycji; pozostawione chmury nie przedłużają przenikania. Granice areny obowiązują. Małpa–Skunks bez zmian. Liczby obrażeń i cooldownów bez zmian.

# 50. Podsumowanie obrażeń po rundzie

Ekran wyniku rundy i końca meczu pokazuje osobne listy obu graczy, posortowane malejąco według faktycznie zadanych obrażeń. Każda walcząca jednostka ma osobny wiersz (także kopie, oznaczone miejscem w składzie), udział w obrażeniach drużyny, wspólną skalę pasków, podział basic/skill/DOT/kolce, otrzymane obrażenia i informację o przeżyciu. Najwyższy wynik w rundzie jest wyróżniony, także ex aequo. Suma drużyny i czas walki uzupełniają wynik. Ławka nie jest liczona; nadmiar ponad HP nie zawyża wyniku. Snapshot pochodzi z zakończonej symulacji, więc wejście do Combat Lab go nie nadpisuje. Nowy mecz czyści podsumowanie. To prezentacja, bez wpływu na balans.

# 51. Wycofanie zmiany pasków HP

Na prośbę użytkownika wycofano osobną warstwę, rozsuwanie pasków oraz panel 1v1. Przywrócono poprzednie paski przy jednostkach. Czytelność HP pozostaje tematem do ponownego zaprojektowania.

# 52. Stały blok HP nad głową

Zatwierdzona prostsza prezentacja: HP i ładowanie aktywnych skilli tworzą stały kompaktowy blok nad postacią, na warstwie nad stworkami i efektami, z ciemną obwódką. Bez rozsuwania względem innych pasków, kresek i panelu 1v1. Przy górnej krawędzi blok pozostaje w arenie. Możliwe nakładanie dwóch bloków jest zaakceptowanym ograniczeniem tego wariantu; priorytetem jest stabilne powiązanie z właścicielem. Brak zmian w walce.


# 53. Pełna pula, dwie akcje i lvl3 — zatwierdzona implementacja

Użytkownik zatwierdził propozycję 12 form lvl3 i zlecił implementację. Ta sekcja zastępuje starsze ograniczenie do lvl2, pulę 4 ofert oraz poprzednie progi liczby akcji.

## Draft

- Każdy draft ma wspólną pulę wszystkich 8 różnych lvl1, w stałej kolejności dla czytelności. Wybór usuwa ofertę; bez uzupełniania w tej rundzie. Kolejny draft przywraca całą ósemkę.
- Start nadal daje po 2 zwierzęta w kolejności ABBA, bez fuzji przed pierwszą walką. Niewybrane oferty nie przechodzą na następny draft.
- W kolejnych rundach każdy ma 2 akcje. Zgodnie z późniejszą decyzją (§55), bonus +1 przysługuje jednorazowo po spadku do 2 żyć i osobno jednorazowo po spadku do 1 życia; nie powtarza się co rundę.
- Akcja to dobór jednego lvl1 lub jedna legalna fuzja: lvl1+lvl1→lvl2 albo lvl2+lvl2→lvl3. Można dobrać rodzica i połączyć go w tej samej fazie, jeśli pozostała akcja.
- Pozostałe zasady (5 żyć, kolejność od przegranego, brak dobrowolnego pasa, 6 aktywnych+3 ławka, bezpłatne zarządzanie, nieodwracalność fuzji) bez zmian.

## Lvl3

Każdy lvl2 ma dokładnie dwóch partnerów. Każda z 12 par ma cztery różne zwierzęta bazowe; żadne lvl3 nie ma dalszej fuzji. Dziedziczymy cztery mechaniki, ale nie wymagamy czterech niezależnych skilli: sekwencje i pasywki mogą je łączyć. Ten zapis zastępuje dawny sztywny wymóg czterech skilli.

1. Niedźwiedź–Gepard + Małpa–Skunks: trzy stożki; każdy trafiony dostaje zgniłego banana z chmurą i spowolnieniem. Moc przeciw grupie, długa przerwa po serii.
2. Małpa–Skunks + Orzeł–Jeż: skok na najdalszy cel z chmurą przy lądowaniu, zgniłe banany z dystansu, pasywne kolce.
3. Orzeł–Jeż + Małpa–Hipopotam: ciężki ogłuszający banan, niezależny skok na najdalszy cel i kolce. Bez gwarantowanej kombinacji stun→skok.
4. Małpa–Hipopotam + Gepard–Królik: trzy ciężkie banany, tylko ostatni ogłusza; reaktywny skok za napastnika zrywa aggro i może przerwać własną serię. Już wystrzelone banany pozostają.
5. Gepard–Królik + Jeż–Skunks: po trafieniu zrywa aggro i trzykrotnie przeskakuje wokół tego samego napastnika, zostawiając smród z zachwianiem. Kolce; brak bezpośredniego burstu serii.
6. Jeż–Skunks + Niedźwiedź–Małpa: szeroki cios, w trafionych lecą zgniłe kolczaste banany z chmurą i zachwianiem. Pasywne kolce, wolny front.
7. Niedźwiedź–Małpa + Orzeł–Hipopotam: ciężki skok na najdalszy cel z pojedynczym stunem, następnie osobny zamach stożkowy z bananami. Zamach można przerwać.
8. Orzeł–Hipopotam + Skunks–Królik: ciężki skok z ogłuszeniem, potem ruchomy ślad smrodu; osobny reaktywny odskok z zerwaniem aggro. Bez niewrażliwości.
9. Skunks–Królik + Niedźwiedź–Jeż: ruchomy ślad i kolce; po trafieniu krótki odskok z zerwaniem aggro, potem zamach łapą w stronę napastnika. Mniejsza mobilność.
10. Niedźwiedź–Jeż + Gepard–Orzeł: trzy skoki wokół tego samego najdalszego celu; każde lądowanie uderza stożkiem. Kolce. Śmierć celu kończy serię.
11. Gepard–Orzeł + Hipopotam–Królik: po trafieniu zerwanie aggro i skok do najdalszego celu, potem trzy naprzemienne uderzenia/skoki; tylko ostatnie ogłusza. Śmierć celu kończy serię.
12. Hipopotam–Królik + Niedźwiedź–Gepard: reaktywny skok do najdalszego celu, wyraźny zamach i trzy stożki; pierwsze dwa zachwianie, ostatni ogłusza trafionych. Długi cooldown.

Robocze liczby znajdują się w Resources. Nie dodajemy automatycznej przewagi lvl3 nad dwoma lvl2 ani reguły 50/50 między formami. Mierzymy czas walki, obrażenia, użycia skilli, kontrolę i przeżywalność w dobranych scenariuszach; liczby wymagają playtestu.

Sekwencja działa na oryginalny żywy cel. Śmierć celu, stun lub przerwanie akcji nie uruchamiają kolejnej fazy i nie zwracają cooldownu. Jedna aktywna faza naraz; pasywne kolce działają niezależnie. Chmury własne nie mnożą obrażeń na jednym celu. Przenikanie tylko podczas lotu i aktywnej emisji śladu; bez niewrażliwości. Placeholdery i robocze animacje pozostają obowiązujące.


# 54. Prywatny mecz online i wybór jednostek

Użytkownik zatwierdził prywatne online dla dwóch osób. Host tworzy nowy mecz jako A, gość dołącza po adresie i porcie jako B. Domyślny port UDP: 24567. Host jest jedynym autorytetem draftu, zmian składu, symulacji i wyników. Gość wysyła decyzje i wyświetla otrzymaną walkę; nie symuluje niezależnie jej wyniku.

- Każdy edytuje tylko własny skład; kolejność draftu i koszty akcji pozostają bez zmian.
- Obaj potwierdzają rozpoczęcie walki, kolejnej rundy i rewanżu. Zmiana składu w przygotowaniu resetuje gotowość obu stron.
- Pauzą i prędkością prezentacji steruje host; nie zmienia to wyniku symulacji.
- Rozłączenie przerywa mecz. Ponowne połączenie zaczyna nowy; brak reconnectu, kont, matchmakingu, serwera pośredniczącego i kodów pokoju.
- Obie strony otrzymują to samo podsumowanie obrażeń per jednostka i wynik. Mechaniki i balans zwierząt bez zmian.
- Połączenie przez internet wymaga osiągalnego portu hosta; nie dodajemy automatycznej konfiguracji routera ani zapory. Wersje gry muszą być zgodne.
- Nadal dostępna jest gra lokalna i lokalny Combat Lab.

Wybrana jednostka ma złote wyróżnienie i napis „WYBRANA”; pasujący partner ma osobne, słabsze oznaczenie „PASUJE DO PARY”. Odświeżenie tego samego ekranu zachowuje przewinięcie strony oraz obu składów. Nowa faza/runda zaczyna się od góry.


# 55. Jednorazowe bonusy comeback

Na gracza przypadają maksymalnie dwie dodatkowe akcje w całym meczu: +1 w pierwszym drafcie po spadku do 2 HP oraz osobne +1 po spadku do 1 HP. W tych draftach gracz ma łącznie 3 akcje, a w pozostałych 2. Wygrana albo remis na tym samym poziomie życia nie odnawia bonusu. Niewykorzystany bonus nie przechodzi na kolejną rundę. Progi liczymy oddzielnie dla obu graczy; nowy mecz/rewanż resetuje ich wykorzystanie. Ta decyzja zastępuje wcześniejsze bonusy powtarzane przy niskim HP. Zasady obowiązują lokalnie i online.


# 56. Teamfight Lab — prototyp ról i sytuacyjnego AI

Zatwierdzono osobny wariant T w Combat Lab, służący ocenie walk przypominających drużynowy teamfight. To próba zachowań i współpracy, przed przebudową pełnego meczu i hybryd. Warianty A/B i pełny mecz zachowują dotychczasowe zasady.

- Sześć bazowych jednostek, każda z dwoma aktywnymi skillami: Hipopotam — tank, Małpa — healer, Jeż — osłona sojuszników, Gepard — DPS, Skunks — kontrola, Orzeł — asasyn. Liczby i przypisanie tych kompetencji są robocze na potrzeby próby.
- AI utrzymuje obrany zamiar przez krótki okres (roboczo 2,5 s), a śmierć celu, prowokacja i bezpośrednie zagrożenie uzasadniają reakcję wcześniej. Nie zmienia celu co klatkę dla minimalnie lepszego wyniku.
- Zagrożone delikatne jednostki szukają osłony i próbują wyjść spod presji; tank utrzymuje front. Przeciwnik ocenia sens kontynuowania pościgu, przy czym asasyn jest bardziej uparty. Odwrót nie oznacza niewrażliwości ani automatycznego usunięcia aggro.
- Ratunki wynikają z rzeczywistego zagrożenia i brakującego HP. Nakładanie pomocy jest możliwe. W prototypie leczenie nie obejmuje samego healera.
- Reakcja obronna Orła korzysta z widocznego przygotowania ataku lub istniejącej chmury, ma opóźnienie i własny cooldown. Nie zna przyszłych decyzji ani wyniku ataku; ogłuszenie i zaangażowanie w inną akcję ograniczają możliwość reakcji.
- Telemetria rozdziela faktycznie przywrócone HP, faktycznie pochłonięte obrażenia, damage, przerwania oraz odwroty. Osłona jest przypisywana jednostce, która ją utworzyła. Niska liczba zadanych obrażeń sama nie oznacza słabej jednostki wsparcia.
- Weryfikacja: kilka małych scenariuszy, celowane testy mechanik i czytelność w rendererze. Nie wyrównujemy wszystkich ról do wyniku 50/50 w 1v1. Odbiór walk i następna iteracja wymagają playtestu.

Instrukcja, robocze zachowania i wyniki: `docs/TEAMFIGHT_LAB_V0_1.md`.


# 57. Uproszczenie informacji podczas walki

Na prośbę użytkownika nad każdą jednostką pozostaje wyłącznie jeden pasek HP w kolorze drużyny. To zastępuje stałe pokazywanie cooldownów opisane w §44 i §52. Nazwy umiejętności i ich odnowienie pokazujemy w jednym panelu po wskazaniu jednostki; gotowość nadal nie gwarantuje natychmiastowego użycia. Tarcza jest widoczną osłoną wokół postaci, pękającą po zużyciu, bez dodatkowego paska. Usuwamy małe podpisy ról pod jednostkami; rola pozostaje dostępna w panelu. Przygotowanie skilla komunikujemy ruchem, bez dodatkowego wskaźnika.

W Teamfight Lab poprawiamy odstęp wsparcia od frontu: Małpa pozostaje za żywym obrońcą, Jeż utrzymuje odległość umożliwiającą osłanianie. Jednostka złapana w zwarciu nadal może zostać zaatakowana i nie zrywa automatycznie aggro. To etap czytelności na placeholderach, przed docelowymi animacjami.

# 58. Kreskówkowa zadyma — zaakceptowany styl i pierwsze wdrożenie

Użytkownik wybrał kierunek A z weselszymi postaciami i zlecił wdrożenie. Pełne sylwetki, miękkie przesadzone proporcje, radosne różne osobowości, ciemny obrys, ciepłe kolory i spokojna leśna arena. Rysunki obejmują cały roster 32 form, menu oraz portrety w wyborze i fuzjach. Cztery postacie mają dodatkowe rysowane pozy; reszta korzysta z animowanych transformacji. To zastępuje ograniczenie do proceduralnych głów, ale nie stanowi ukończenia finalnych animacji wszystkich skilli. Dane walki, kolizje i zasady pozostają bez zmian. Szczegóły: docs/art_direction/v0_1/IMPLEMENTED.md.

# 59. Ekran rozwoju na jednym ekranie
Pula 4×2 u góry; niżej Gracz 1 po lewej i Gracz 2 po prawej, po sześć większych miejsc aktywnych i trzy mniejsze rezerwowe. Bez przewijania faz wyboru i przygotowania w 1280×720. Informacje na kartach ograniczone do portretu, nazwy, poziomu i stanu wyboru. Złote wypełnienie oznacza wybór; zielona ramka zgodnego partnera; osobny focus. Właściciel i aktualna tura pozostają widoczne.
Późniejsza decyzja użytkownika: pełne drzewko NIE otwiera się na hoverze. Otwiera je przycisk i, prawy klik lub Y na padzie; zamknięcie przez przycisk, Esc lub B przywraca focus. Modalne okno pokazuje wszystkie dalsze przepisy lvl1 → lvl2 → lvl3, partnerów i łączniki, bez scrollowania. Wskazanie węzła wewnątrz okna aktualizuje wspólne szczegóły. Złota ramka przepisu oznacza posiadanie rodziców, nie automatyczną dostępność akcji; panel pokazuje fazę i liczbę akcji. Mechanika wyboru, fuzji, rezerwy i online pozostaje bez zmian.

# 60. Ranged bez automatycznego trzymania odległości
2026-09-27: zwykłe jednostki ranged podchodzą do zasięgu ataku i walczą, również w zwarciu. Nie wycofują się do preferred_min/preferred_max. Celowy ruch umiejętności (dash, dive, obieganie smrodem) pozostaje. Odrębne sytuacyjne AI wariantu T zachowuje własne decyzje ruchu. Wcześniejszy raport balansu opisuje stan przed zmianą; wymagane porównanie na tej samej macierzy.


# 61. Królik lvl1 — skaczący obrońca
2026-09-27: bazowy Królik skacze po cooldownie do sojusznika, priorytetyzując brakujące HP i presję przeciwników; osłonięte cele mają niższy priorytet. Ląduje obok po stronie własnej drużyny, daje tarczę i przy skoku zrywa własne aggro na 1 s, jeżeli przeciwnik ma inny cel. Bez niewrażliwości. Samotny Królik osłania siebie bez przemieszczania. Między użyciami zachowuje drobne podstawowe ataki.
Roboczo 30 osłony na 4 s, CD 5 s od rozpoczęcia, pierwszy skok po 2,5 s, lot 0,25 s. Osłona odnawia się do 30, bez kumulacji od wielu Królików. Śmierć celu w locie nie zwraca CD; jeśli nie zostało innych sojuszników, osłania siebie. Stun przerywa skok.
Jeden pasek HP: kolor drużyny oznacza życie, jasnoniebieski dodatkowy segment tarczę; skala obejmuje większe z max HP i bieżące HP+tarcza. Osłona wokół ciała pozostaje. Telemetria rozdziela osłonę nadaną i faktycznie pochłonięte obrażenia od damage. Hybrydy zachowują dawne skille do osobnej przebudowy. Wariant A zachowuje dawny dash.

# 62. Warsztat nowego systemu drużyn — kierunek zatwierdzony
2026-09-27: Projektujemy kolejno wyraźne role bazowe inspirowane Teamfight Lab, genotypy oraz dominującego/pomocniczego rodzica przy fuzji. Tank ma niskie obrażenia i dużą wytrzymałość, DPS wysokie obrażenia i małą przeżywalność, wsparcie odrębne funkcje. Konkretna obsada, skille, efekty genotypów, udział lvl1 i zasady dominacji wymagają warsztatów z użytkownikiem. Rozważamy również nazwy i wygląd wariantów. Osobne nagrody/buffy/debuffy między rundami poza zakresem. Rejestr: docs/ROLES_GENOTYPES_WORKSHOP.md. Zapis nie zmienia jeszcze działania gry; wcześniejsze mechaniki pozostają stanem implementacji do zastąpienia zamkniętymi ustaleniami.

## Pierwsze ustalenia obsady nowego rosteru
2026-09-27: Warsztat ról: Królik ma zostać pełnoprawnym ranged DPS atakującym z daleka, skaczącym i cofającym się, bez dawnej tarczy. Małpa wyłącznie leczy. Jeż daje sojusznikom kolczastą tarczę zapewniającą osłonę i odbicie obrażeń. Szczegóły targetowania, leczenia, ruchu i odbicia pozostają otwarte. Kierunek projektowy, jeszcze bez implementacji. Rejestr: docs/ROLES_GENOTYPES_WORKSHOP.md.

2026-09-27: Kolejne decyzje warsztatowe: Małpa regularnie leczy jednego innego sojusznika, bez samoleczenia. Kolczasta osłona Jeża odbija wszystkie ataki, nie tylko melee; udział DOT/chmur pozostaje do doprecyzowania. Królik atakuje ciałem, nie strzałą; dokładna trajektoria ataku i powrotu do ustalenia. Bez implementacji.

2026-09-27: Zamknięto wybór Królika: marchewki jako atak dystansowy i obronny odskok z cooldownem, bez niewrażliwości; zastępuje wcześniejszy pomysł ataku ciałem. Zatwierdzono zakres kolczastej osłony Jeża: bezpośrednie ciosy, skoki i pociski uruchamiają odbicie, DOT/chmury i inne odbicia nie. Parametry liczbowe nadal otwarte. Dokumentacja warsztatu zaktualizowana, bez zmian mechaniki gry.

2026-09-27: Jeż osłania jednego zagrożonego sojusznika. Kolczasta tarcza odbija procent faktycznie pochłoniętych obrażeń bezpośredniego trafienia, nie całego nadchodzącego damage. Jeż ma też własne lekkie pasywne odbicie; parametry i zakres jego wyzwalania otwarte. Samocelowanie tarczy wymaga doprecyzowania, nie wynika automatycznie z decyzji o kolcach. Ustalenia projektowe, bez implementacji.

2026-09-27: Użytkownik potwierdził, że Jeż daje kolczastą tarczę wyłącznie innym, a siebie chroni lekkimi pasywnymi kolcami. Hipopotam ma krótki stun obszarowy zamiast proponowanej prowokacji. Pozostaje wytrzymałym tankiem o niskich obrażeniach; warunki użycia i parametry stuna do warsztatu. Bez implementacji.

2026-09-27: Hipopotam używa tupnięcia przy pierwszej możliwości po cooldownie, z co najmniej jednym wrogiem w zasięgu, bez czekania na okazję; dokładne czasy i promień otwarte. Niedźwiedź zatwierdzony jako ofensywny frontliner z mocnym szerokim zamachem obszarowym bez stuna, mniej wytrzymały i mocniej bijący niż Hipopotam, twardszy i wolniejszy od Geparda. Zmiana dokumentacji, bez implementacji.

2026-09-27: Zatwierdzono Geparda: delikatny DPS melee, szybkie basici i powtarzalna seria pazurów na pojedynczy najbliższy cel, bez przeskakiwania frontu i bez osobnej egzekucji z T. Większa złożoność na hybrydach. Orzeł: powtarzalny skok z mocnym pojedynczym trafieniem na najdalszego przeciwnika, zwykła walka między skokami; bez targetowania najniższego HP. Parametry nadal do dobrania, bez implementacji.

2026-09-27: Skunks zatwierdzony jako kontroler z ruchomym śladem smrodu, niewielkimi obrażeniami w czasie i lekkim spowolnieniem ruchu w chmurze. Bez dodatkowego stuna. Dokładne wartości do kalibracji. Kierunki ośmiu ról określone; nadal warsztat zachowań i reguł, bez implementacji.

2026-09-27: Korekta warsztatu: każda jednostka ma basic niezależnie od roli, także Małpa, Jeż i Skunks. Wsparcie walczy po podejściu wroga, bez automatycznego odwrotu i bez dodatkowych skilli ucieczki na lvl1. Zastępuje wcześniejszy całkowity brak ataków Małpy/Skunksa. Role nadal różnią się siłą obrażeń. Dotychczasowy zaakceptowany odskok Królika pozostaje jako jego konkretna umiejętność. Bez implementacji.

2026-09-27: Nowa propozycja warsztatowa użytkownika: trzy poziomy więzi zależnie od poziomów jednostek ze wspólnym genem (zwykłe → I, lvl2+ → II, para lvl3 → III). Reguła dla mieszanych składów i beneficjentów jeszcze niezamknięta. Asystent proponuje liczenie na podstawie dwóch najwyższych poziomów, żeby dodatkowy lvl1 nie obniżał istniejącej więzi. Szczegóły w ROLES_GENOTYPES_WORKSHOP.md; bez implementacji.

2026-09-27: Zatwierdzono trzy poziomy więzi liczone z dwóch najwyżej rozwiniętych wystawionych nosicieli genu (poziom niższego z pary). Jeden wynik dotyczy wszystkich nosicieli, także lvl1; słabsza dodatkowa jednostka nie obniża więzi. Użytkownik wskazał ryzyko spamu i proponuje mocniejszy skok lvl2→lvl3. Dokładna moc, efekty i ewentualne warunki dotyczące kopii pozostają warsztatem; bez automatycznej reguły wygranej lvl3. Bez implementacji.

## Roadmapa po ponownej ocenie zakresu
2026-09-28: Zmiana roadmapy: użytkownik chce osobne iteracje i stały feedback zamiast jednoczesnego wdrożenia ról, więzi i dominacji. Dominacja jest pewnym docelowym kierunkiem; więzi drużynowe odkładamy poza pierwszy shipping, bez zobowiązania do późniejszego wdrożenia. Do rozstrzygnięcia granica pierwszego wydania: role osobno czy z dominacją. Rekomendacja i koszt dostosowania obecnych hybryd opisane w docs/ROLES_GENOTYPES_WORKSHOP.md. Bez implementacji.

2026-09-28: Ostateczna korekta zakresu pierwszego delivery: użytkownik wybiera role + dominację razem, projektując od razu dwa kierunki hybryd. Paczka ma obejmować spójne lvl1/lvl2/lvl3 i pełny mecz. Więzi drużynowe zostają na później. Zastępuje propozycję osobnego shippingu ról z jednym wynikiem fuzji. Szczegółowe warianty i dziedziczenie dominacji na lvl3 wymagają warsztatu; bez implementacji.

2026-09-28: Warsztat dominacji prowadzimy para po parze. Zaakceptowano Niedźwiedź+Gepard: dominujący Niedźwiedź — trzy szerokie szybkie ciosy, wytrzymały melee AoE, bez stuna; dominujący Gepard — dwa szybkie cięcia i ciężki finisher w jeden cel, szybki i delikatniejszy melee DPS. Użytkownik chce podpowiedzi profilu hybrydy przy wyborze dominującego genotypu. Wybór ma być spójny z charakterem rodziców i wyglądem. Szczegóły: docs/HYBRID_DOMINANCE_WORKSHOP.md. Bez implementacji.

2026-09-28: Zatwierdzone nazwy pary Niedźwiedź + Gepard: Niepard przy dominującym Niedźwiedziu; Łapard przy dominującym Gepardzie. Zastępują robocze nazwy tej pary. Zachowania bez zmian.

2026-09-28: Para Niedźwiedź+Małpa: dominujący Niedźwiedź ma stałą aurę niewielkiego leczenia wokół siebie z widocznym glow źródła i odbiorców (sugestia zielonego feedbacku HP). Dominująca Małpa to wytrzymalszy healer z falą leczenia odbijającą się między różnymi sojusznikami w ograniczonym zasięgu od źródła. Dokładne reguły, nazwy i pozostałe skille do warsztatu. Użytkownik preferuje bardziej twórcze przekształcenia mechanik rodziców. Bez implementacji.

2026-09-28: Doprecyzowanie pary Niedźwiedź+Małpa: wariant z dominującym Niedźwiedziem zachowuje swoje stożkowe uderzenie łapą, równolegle ze stałą aurą leczenia. Bez implementacji.

2026-09-28: Para Niedźwiedź+Małpa: użytkownik zatwierdził aurę leczącą tylko innych sojuszników (bez właściciela) oraz najwyżej jedno uleczenie każdego odbiorcy na użycie odbijającej się fali Małpy. Bez implementacji.

2026-09-28: Zatwierdzono nazwy pary Niedźwiedź+Małpa: Małpowiedź przy dominującym Niedźwiedziu, Niedźwipa przy dominującej Małpie. Następna para warsztatu: Niedźwiedź+Jeż; jej warianty w HYBRID_DOMINANCE_WORKSHOP.md są dopiero propozycją.

2026-09-28: Para Niedźwiedź+Jeż zmieniona przez użytkownika: Niedźwjeż (dominuje Niedźwiedź) to tank z self tarczą o mocniejszych kolcach oraz stałym umiarkowanym odbiciem. Jeżdźwiedź (dominuje Jeż; najnowsza nazwa) ma dwa niezależne skille/CD: kolczasta osłona i futerko leczące w czasie, możliwe oba na jednym sojuszniku. Futerko zastępuje pomysł eksplozji tarczy. Wcześniej dopuszczone samocelowanie tarczy z priorytetem kumpli pozostaje; samocelowanie futerka otwarte. Szczegóły w HYBRID_DOMINANCE_WORKSHOP.md; bez implementacji.

2026-09-28: Jeżdźwiedź może nakładać leczące futerko także na siebie przy niskim HP, zachowując pierwszeństwo potrzebujących sojuszników. Próg HP do kalibracji. Dwa skille nadal mają niezależne cooldowny. Bez implementacji.

## Nowa macierz par dla rosteru z dominacją
2026-09-28: Zatwierdzono nową macierz 12 par lvl2, po 3 partnerów na zwierzę: Niedźwiedź–Gepard, Niedźwiedź–Małpa, Niedźwiedź–Jeż, Gepard–Królik, Gepard–Hipopotam, Małpa–Skunks, Małpa–Hipopotam, Orzeł–Jeż, Orzeł–Królik, Orzeł–Skunks, Hipopotam–Królik, Jeż–Skunks. Zastępuje starą macierz projektowo, bez edycji Resources na tym etapie. Przepisy lvl3 wymagają przeprojektowania. Kolejna para warsztatu: Gepard+Królik; propozycje niezatwierdzone w HYBRID_DOMINANCE_WORKSHOP.md.

2026-09-28: Gepard+Królik, dominujący Gepard: użytkownik wybrał furię na 5 s, zwiększającą szybkość ataków, dającą wampiryzm i zwiększającą otrzymywane obrażenia. Zastępuje proponowany reaktywny skok z serią. Warunki aktywacji, źródła wampiryzmu i wartości otwarte; wariant dominującego Królika jeszcze niezatwierdzony. Bez implementacji.

2026-09-28: Gepard+Królik: zaakceptowano aktywację 5-sekundowej furii przy gotowym CD i celu w zasięgu, wampiryzm z faktycznie zabranego HP basicami oraz upływ furii podczas stuna; zaakceptowano wygląd wściekłego Geparda z króliczymi uszami. Dominujący Królik: bardzo niski HP, większy damage i attack speed; jego ataki odbijają się na dwa kolejne cele z malejącym damage. Procenty/zasięgi, zachowanie samego odskoku i nazwy otwarte. Bez implementacji.

2026-09-28: Gepard+Królik, dominujący Królik: użytkownik zatwierdził pozostawienie podstawowego obronnego odskoku Królika z cooldownem, bez dodatkowej serii po lądowaniu. Zachowuje papierowy profil i ataki odbijające się na dwa kolejne cele. Bez implementacji.

2026-09-28: Zatwierdzone nazwy Gepard+Królik: Geplik — dominuje Gepard; Króg — dominuje Królik. Mechaniki bez zmian. Bez implementacji.

## Uzupełnienie warsztatu po dostępie tylko do odczytu
2026-09-28: Uzupełniono decyzje z okresu dostępu tylko do odczytu. Gepard+Hipopotam: Gehip (dominuje Gepard) to umiarkowanie wytrzymały i mocno bijący bruiser przywołujący Gehipki, maks. 2 żywe na rodzica, uzupełniane po cooldownie. Gehipki mają własne HP, podstawowe ataki melee, bez skilli, pozostają po śmierci rodzica. Hipard (dominuje Hipopotam) wykonuje 3 brykające skoki z lekkim obszarowym ministunem i symbolicznym damage. Małpa+Skunks: Małkuns rzuca przejrzały banan tworzący stacjonarną leczniczą chmurę; Skunpa zostawia ruchomy ślad leczący sojuszników i zadający lekki DOT oraz slow wrogom. Oba warianty leczą tylko innych, własne nakładające się chmury nie mnożą efektu. Nazwy zaakceptowane. Para Małpa+Hipopotam pozostaje niezatwierdzoną propozycją, nie decyzją. Szczegóły i otwarte kwestie: docs/HYBRID_DOMINANCE_WORKSHOP.md. Bez implementacji.

2026-09-28: Para Małpa+Hipopotam zatwierdzona kierunkowo: dominująca Małpa rzuca ciężkiego banana mocno leczącego sojusznika i krótko ogłuszającego pobliskich wrogów. Dominujący Hipopotam zachowuje stomp i zjada ukrytego banana dla self-heala, bez leczenia drużyny. Warunki jedzenia, liczby i nazwy otwarte. Szersza wypowiedź o utracie leczenia drużyny przy niedominującej Małpie wymaga doprecyzowania wobec zatwierdzonych Małpowiedzia i Skunpy; ich nie zmieniono. Bez implementacji.

2026-09-28: Użytkownik potwierdził pozostawienie Małpowiedzia i Skunpy bez zmian, z leczeniem sojuszników. Brak leczenia drużyny i self-heal dotyczy dominującego Hipopotama w parze Małpa+Hipopotam, nie jest globalnym ograniczeniem niedominującej Małpy.

2026-09-28: Zatwierdzone nazwy pary Małpa+Hipopotam: Małpotam — dominuje Małpa; Hipopa — dominuje Hipopotam. Następny warsztat: Orzeł+Jeż; dwa kierunki zapisane w HYBRID_DOMINANCE_WORKSHOP.md wyłącznie jako propozycje. Bez implementacji.
