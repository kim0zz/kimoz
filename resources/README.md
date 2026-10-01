# Dane Combat Prototype v0.1

> Poniższe liczby są historią prototypu. Aktualny pełny roster: `docs/FULL_ROSTER_SKILLS.md` i Resources `.tres`, zgodnie z §47 GAME_DESIGN. Początkowy cooldown jest indywidualnym `initial_cooldown`; runtime baseline A/B zapisano w `resources/balance/full_roster_baseline.json`.

Definicje są niezmienne podczas walki. HP runtime, cooldowny, cele i statusy należą do stanu symulacji, nigdy do współdzielonych Resources.

## Parametry początkowe T0/T1 (nie wynik kalibracji)

Zachowano wszystkie HP oraz nominalne basic DPS briefu. Kadencja: Niedźwiedź 9/1 s; Gepard 5/(1/3 s); Małpa 10/1 s; Orzeł 10/1 s; Jeż 7/1 s; Hipopotam 9/1,5 s; Skunks 6/1 s; Królik 5,5/0,5 s. Szybkie małe trafienia Geparda eksponują mechanikę kolców, a ciężkie rzadsze Hipopotama jego rolę. Pierwszy basic po pełnym interwale, bez magazynowania zaległych trafień podczas skilla.

Wszystkie odległości to piksele świata, mierzone pomiędzy krawędziami okręgów. Promienie jednostek 22–30; melee range 8, z wyjątkiem Niedźwiedzia: 18 dla basica i łapy (zmiana po playteście 2026-09-25). Małpa: range 230, pasmo preferowane 125–205. Prędkości: Niedźwiedź/Hipopotam 65, Małpa 75, Jeż/Skunks 85, Orzeł 100, Gepard/Królik 125. Małpa jest wolniejsza od standardowego melee, żeby wycofywanie nie powodowało wiecznej ucieczki. Powolny front nadrabia dystans przy granicy areny.

- Niedźwiedź: 25 obrażeń, CD 5 s, wind-up 0,45 s, recovery 0,55 s.
- Gepard: 3 × 10, CD 5 s, wind-up 0,12 s, odstęp trafień 0,14 s, recovery 0,25 s. Każde trafienie oddzielnie uruchamia kolce.
- Małpa: 19 zamiast basica, CD 4 s, wind-up 0,30 s, recovery 0,35 s, prędkość pocisku 500.
- Orzeł: 25, raz na walkę, zerowy wind-up, prędkość dive 900, recovery 0,30 s. Zasięg 8 oznacza kontakt przy lądowaniu, nie limit wyboru celu startowego.
- Jeż: 2 obrażenia, bez wind-up/recovery/cooldownu.
- Hipopotam: 40, CD 6 s, wind-up 1 s, recovery 0,75 s; wyraźne przygotowanie i utrata czasu basiców.
- Skunks: CD 6 s, wind-up 0,25 s, recovery 0,35 s, zasięg chmury 100. Status weakened: mnożnik 0,75 na 3 s, odświeżanie czasu bez kumulacji siły. Pasywne kolce nie są osłabiane.
- Królik: CD 5 s, próg bliskości melee 45, dash 90 z prędkością 360 (0,25 s przed ograniczeniem kolizją), bez wind-up/recovery. Parametry ruchu nie dodają niewrażliwości.

To jawne parametry robocze, nie obietnica 20–30% wartości skilla. Zmiany balansu wymagają danych i zapisu przed/po w raporcie.

## Ręczna konfiguracja składów

Edytuj `resources/matches/*.tres`: `team_a` i `team_b` to 1–6 ID z `ZooCatalog.ids()`. `ZooCatalog.presets()` ładuje osiem przykładów, obejmujących komplet ośmiu zwierząt. Kolejność w pliku nie daje prawa do ręcznego placementu; symulacja ustawia role automatycznie. Nowy preset należy dopisać do listy w `scripts/data/catalog.gd`. Duplikaty dopuszczone w danych wyłącznie do fixture'ów; nie ustala to zasad przyszłego draftu.

Definicje `ZooUnitDefinition`, `ZooSkillDefinition`, `ZooStatusDefinition` i `ZooMatchDefinition` mają `validate()`. Katalog weryfikuje komplet lvl1 i jeden skill na jednostkę; lista skilli zachowuje możliwość przyszłych 2/4 mechanik bez implementowania hybryd teraz.

## Korekta otwarcia v0.1.1

Przez pierwsze 2 s aktywne skille są zablokowane; pasywne kolce oraz ruch i basic attacks działają od początku. Własny cooldown liczymy od startu castu po odblokowaniu. Wszystkie żywe jednostki blokują ruch; lokalne obchodzenie sojuszników jest częścią movementu. Dive omija ciała tylko w locie, lądowanie i dash respektują obie drużyny. HP, obrażenia, prędkości i własne cooldowny nie zostały zmienione w tej iteracji.
# Korekta v0.1.2 po playteście

Orzeł: basic damage 10 → 11 (+10%), pozostałe staty i dive bez zmian. Sama poprawka ruchu Małpy pozostawiała jej 5 HP w kontrolnym pojedynku; po korekcie Orzeł wygrywa z 7 HP. Ranged ma parametry engage_distance=12 i disengage_distance=40 px: po złapaniu w zwarciu zatrzymuje odwrót i atakuje napastnika, po uwolnieniu wraca do utrzymywania dystansu. Żaden atak nie zmienia rodzaju obrażeń.
# Próba v0.1.3 — Skunks ranged

Skunks: role=ranged, attack_range=150, preferred_min=70, preferred_max=100. Basic nadal 6 obrażeń co 1 s, teraz zielony pocisk; HP=105. Chmura bez zmiany parametrów, działa wokół siebie. Startuje na tyłach i jest celem backline dla Orła; AI i zwarcie korzystają z tych samych reguł ranged co Małpa. Poprzednie opisy Skunksa jako melee utility są historyczne.

## v0.1.4 — odnawialny dive

eagle_dive.cooldown=6 (wcześniej 0/jednorazowy), damage=25 bez zmiany. Wybór najdalszego żywego przeciwnika przy każdej aktywacji, bez bonusu priorytetu ranged; odległość edge-to-edge. Pierwszy dive po wspólnej blokadzie 2 s. Basic Orła nadal 11/s.

## Aktualne skille — combat-v0.2-skills

Autorytatywne reguły i jawne wartości: GAME_DESIGN_V0_2.md sekcja42. bear_slam: cone,25dmg,range85,angle100; hippo_heavy:30dmg,stun_duration1; skunk_cloud:cloud,4dmg/pulse,interval0.5,duration3,area_radius55,range150; rabbit_dash: reaktywny przeskok za plecy napastnika i aggro_duration1. Starsze wpisy opisują historyczne baseline'y. Zasób weakened zachowano dla generycznego systemu statusów, ale Skunks go nie używa.
