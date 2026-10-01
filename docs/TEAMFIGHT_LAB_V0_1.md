# Teamfight Lab v0.1

## Uruchomienie

W głównym ekranie wybierz **Combat Lab**, następnie przycisk **NOWE: role i ratunki** u góry i **Start** (można też wybrać wariant **T • Teamfight: role i ratunki**). Wejście w T ładuje pierwszą parę drużyn. Lista scenariuszy zawiera dodatkowe pozycje zaczynające się od „Teamfight”. Można zmienić składy sześciu dostępnych archetypów, zatrzymać walkę i przejść krok po kroku.

**Raport ról** zatrzymuje walkę i pokazuje rzeczywisty wkład każdej jednostki. Najazd na jednostkę otwiera jeden panel z HP, rolą i nazwanymi cooldownami. Nad jednostką pozostaje tylko HP. Tarcza jest niebieską osłoną wokół ciała i pęka po zużyciu; nie ma własnego paska. Statystyki wsparcia i obrażeń są w raporcie. Zielony efekt oznacza odzyskane HP, niebieski — tarczę lub jej pochłonięcie.

To oddzielny eksperyment. Pełny mecz lokalny i online nadal używa B oraz obecnych hybryd. Wyjście z laboratorium i rozpoczęcie meczu przywraca B. Niedźwiedź, Królik i hybrydy nie należą jeszcze do próby T.

## Role i skille tej próby

- **Hipopotam:** 240 HP, basic 7 co 1,2 s. Prowokacja przejmuje napastników pobliskiego sojusznika na 2,2 s i daje mu 18 osłony (CD 7 s). Drugi skill daje 24 osłony zagrożonemu sojusznikowi i 16 sobie (CD 9 s). Bez żywego sojusznika nie odnawia osłon samemu sobie.
- **Małpa:** leczy innego sojusznika o maksymalnie 27 HP (CD 5 s), wybierając rannego w zasięgu. Krzyk reaguje na trwającą akcję przeciwnika, ogłusza pobliskich wrogów na 0,35 s i może ją przerwać (CD 8 s).
- **Jeż:** daje 28 tarczy sojusznikowi pod presją (CD 6,5 s). Odpędzenie ogłusza napastnika sojusznika na 0,4 s (CD 7,5 s). W tej próbie to kontrola i przerwanie, bez fizycznego odrzutu.
- **Gepard:** cztery trafienia po 7,5 (CD 5,5 s), plus dobitka za 19, zwiększona do 29 poniżej 40% HP przeciwnika (CD 8 s). Dobitkę rozważa poniżej 70% HP celu.
- **Skunks:** bez zwykłych ataków; przez 3,5 s biega i zostawia przenikający ślad, którego chmury żyją 2,7 s, spowalniają do 68% szybkości i zadają 5 co 0,55 s (CD 6 s). Własne chmury nie mnożą obrażeń na tym samym celu. Drugi skill ogłusza obszarowo na 0,55 s (CD 10 s), gdy w pobliżu są co najmniej dwaj przeciwnicy albo wróg zagraża jednostce poniżej połowy HP.
- **Orzeł:** skacze na najdalszy cel za 25 obrażeń (CD 7,5 s). Drugi skill to odskok w bok o maksymalnie 82 px, po 0,45 s obserwacji zagrożenia (CD 6 s). Może się spóźnić, nie ma niewrażliwości i nie anuluje automatycznie aggro.

Każdy skill ma także niezależny pierwszy cooldown. Aktualne liczby są w `scripts/data/teamfight_definitions.gd`; wartości powyżej opisują stan tej wersji. Łączna osłona jednostki jest ograniczona do 52. Małe liczby obrażeń tanka i wsparcia są zamierzone.

## Pytania do playtestu

- Czy widzisz, kto kogo ratuje i co przerwało groźny atak?
- Czy tank daje sojusznikom czas i miejsce, mimo niskiego damage?
- Czy asasyn może zagrozić wsparciu, ale obrona ma szansę go powstrzymać?
- Czy odwrót prowadzi do zmiany sytuacji, zamiast biegania bez końca przy ścianie?
- Czy dwa skille na jednostkę dają czytelne akcje, bez zalewania ekranu napisami?

## Architektura i granice

`scripts/combat/teamfight_simulation.gd` rozszerza obecną symulację. Osobne sklonowane definicje z `scripts/data/teamfight_definitions.gd` zapobiegają zmianom statystyk pełnego meczu. Bazowy ruch ma domyślnie nieaktywny punkt rozszerzenia; podstawowa walka nadal korzysta z dotychczasowej ścieżki.

AI ocenia aktualny stan i utrzymuje cel przez około 2,5 s; nie przewiduje przyszłych decyzji. Reakcje zależą od zasięgu, cooldownów, przygotowania i możliwości działania. To robocze reguły konkretnych ról, bez uczenia maszynowego. W pierwszej próbie healer leczy inne jednostki, a nie siebie.

Telemetria liczy faktyczne odzyskane HP bez nadleczenia i faktyczne pochłonięcie tarczy przypisane jej autorowi. „Przerwania” liczą przerwane akcje, a nie każde ogłuszenie. Obrażenia oznaczają utratę HP, więc same nie obejmują obrażeń zatrzymanych tarczą. Użycie skilla oznacza rozpoczęcie, również jeśli przeciwnik je przerwał.

Nie jest to jeszcze pełny balans nowych ról. Krótkie scenariusze i ich odbicia sprawdzają działanie oraz ujawniają impasy; nie stanowią dowodu, że wszystkie drużyny są równie silne.

## Weryfikacja pierwszej wersji, przed uproszczeniem widoku

Weryfikacja końcowa 2026-09-26:

- Obowiązkowy `tools/godot.ps1 check`: import i start PASS.
- `tests/teamfight_tests.gd`: 55 sprawdzeń, 0 błędów; leczenie, przypisanie tarcz, prowokacja, przerwania, odwrót, stabilność celu, odpuszczanie pościgu, opóźnienie uniku i brak niewrażliwości, walidacja definicji.
- `tests/teamfight_ui_test.gd`: PASS w prawdziwym rendererze Compatibility 1280×720. Automatyczne wejście w T, zdarzenia wsparcia, raport i powrót do pełnego meczu B z lvl3. Zrzuty obejrzane. Nie jest to ręczny playtest przyjemności.
- Dotychczasowy `tests/skunk_phase_tests.gd`: PASS. Historyczny `skill_redesign_tests.gd` zgłosił 3 stare oczekiwania dotyczące stacjonarnej chmury Skunksa, sprzeczne z przyjętym wcześniej ruchomym śladem; nie zmieniono tych testów ani designu B, żeby wymusić zielony wynik.
- Końcowa próbka: trzy scenariusze w obu orientacjach, seed 42, limit diagnostyczny 120 s. Wszystkie sześć zakończyło się wybiciem drużyny (w lustrzanym scenariuszu obu jednocześnie), bez limitu wymuszającego koniec.

### Wyniki scenariuszy

- Front i leczenie (Hipopotam/Małpa/Gepard) kontra Hipopotam/Skunks/Orzeł: wygrywa skład z leczeniem w obu orientacjach, 55,6 i 49,6 s. Łącznie 123 przywrócone HP, 515 faktycznie pochłoniętych obrażeń i 2 przerwania w każdej walce. Orzeł użył jednego reaktywnego uniku.
- Asasyni (Orzeł/Gepard/Skunks) kontra Hipopotam/Małpa/Jeż: wygrywają asasyni w obu orientacjach, 43,2 s. Obrona leczy 135 HP i pochłania 390 obrażeń, mimo to przegrywa. Łącznie 6 przerwań. Orzeł nie używa uniku — warunki i czas reakcji nie gwarantują jego odpalenia.
- Lustrzane Hipopotam/Gepard/Skunks: remis przez jednoczesne wybicie, około 55,4 s, 268 pochłoniętych obrażeń łącznie. Nie występuje już nieskończona wymiana osłon.

Pełne dane jednostek, damage, użycia skilli i przeżycie: `reports/teamfight_scenarios.json`. To diagnostyka trzech konkretnych składów, nie statystyczny win rate całego rosteru.

### Korekty i ograniczenia

Pierwsza wersja generowała zbyt dużo osłon i bardzo długie końcówki dwóch tanków. Podniesiono bazowy DPS Hipopotama z 2,76 do 5,83 (nadal znacznie poniżej Geparda z jego skillami), ograniczono jego osłony do 18 oraz 16/24, a tarczę Jeża do 28. Usunięto możliwość podtrzymywania obrony przez samotnego tanka. Poprawiono również konflikt stabilnego planu ze zmianą celu po wejściu na blokującego przeciwnika.

Kontrola i wsparcie są rozliczane po przygotowaniu akcji wszystkich jednostek, przed obrażeniami, a ocena presji korzysta ze wspólnego obrazu początku kroku. Jednoczesne przygotowane trafienia mogą dojść do skutku; ogłuszenie nie cofa już wykonanego trafienia.

Nadal do oceny w playteście: walki trwają 43–56 s, więc są dłuższe niż dawny burst; poruszanie po zatłoczonej arenie jest robocze; paski i podpisy mogą nakładać się w skupisku. Odwrót szuka żywego Hipopotama lub Jeża — samotna jednostka walczy dalej. Nie ma pełnego systemu formacji, wyboru skilli przez gracza ani nowych hybryd. Te elementy wymagają osobnego etapu.



## Aktualizacja czytelności — jeden pasek HP

Nad postacią pozostaje tylko HP. Paski cooldownów i tarczy oraz podpisy ról zostały usunięte; jeden panel po najechaniu pokazuje nazwę, drużynę, rolę, HP, pozostałą tarczę i nazwane cooldowny. Panel jest nad warstwą jednostek, więc postacie go nie zasłaniają. Osłona pęka po zużyciu. Dodano mały roboczy ruch przygotowania ciosu, bez paska decyzji.

W T Małpa utrzymuje pozycję około 155 px za obrońcą, a Jeż około 90 px za osłanianą jednostką; pozycje mają tolerancję, aby ograniczyć drobne korekty. Bezpośredni kontakt z napastnikiem nadal wymusza walkę. To nie jest pełny system formacji i nie eliminuje skupisk przy skoku asasyna ani przenikaniu Skunksa.

Weryfikacja tej aktualizacji: import/start PASS, 55 celowanych sprawdzeń PASS, wskazanie postaci zdarzeniem ruchu myszy i ogląd panelu w rendererze Compatibility PASS. Sześć naturalnych walk zakończyło się w 43,3–68,9 s. Front z leczeniem wygrywa obie orientacje pierwszego scenariusza; obrona z Małpą i Jeżem wygrywa obie orientacje drugiego; identyczne drużyny remisują przez jednoczesne wybicie. Zmiana pozycjonowania wzmacnia użyteczność wsparcia — stare wyniki powyżej nie opisują tej wersji. Liczby HP/damage/CD pozostały bez zmian. Nie przeprowadzano pełnego rebalance.
