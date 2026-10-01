> **Aktualizacja po playteście 2026-09-25:** sekcja 39 GAME_DESIGN_V0_2.md zastępuje wcześniejsze zapisy tego planu o natychmiastowych skillach i przenikaniu sojuszników. Obowiązuje początkowa blokada aktywnych skilli 2 s, kolizje obu drużyn i lokalne obchodzenie własnych jednostek. Pozostały zakres i architektura pozostają w mocy.

# Combat Prototype v0.1 — przygotowanie do implementacji

## Status i hierarchia dokumentów

Dokument analityczny i plan prac. Nie zawiera implementacji ani wyników symulacji. Plan, architektura, zakres, propozycje reguł i weryfikacji zostały zatwierdzone przez użytkownika 2026-09-24. Opisane pliki, typy i testy nadal są przyszłą pracą, nie istniejącymi funkcjami gry. Sformułowania „proponowane” lub „rekomendowane” w analizie opisują zatwierdzony kierunek; nie wymagają ponownej zgody. Nieustalone wartości liczbowe pozostają parametrami roboczymi do zapisania w T0/T1.

Źródło prawdy: `../GAME_DESIGN_V0_2.md`, łącznie z zaakceptowanymi decyzjami sekcji 35 i Visual Direction v0.1 w sekcji 36. Zatwierdzone rozstrzygnięcia odnotowano także w briefie, w tym w sekcji 37. Implementację wolno rozpocząć dopiero w osobnym tasku.

Przeczytany kontekst: cały brief, `AGENTS.md`, `README.md`, `docs/kierunek.md`, ustawienia Godot, scena startowa i skrypt kontroli projektu; uwzględniono wcześniejsze ustalenia o MCP, kosztach assetów, zakresie i autonomii agenta.

Stan zastany: Godot 4.7.2, GDScript, Compatibility, baza 1280 × 720, `canvas_items`/`expand`. `main.tscn` wyświetla komunikat gotowości. Brak kodu combat i własnych definicji jednostek. Godot MCP Toolkit 1.0.2 jest narzędziem edytora, nie fundamentem logiki gry. Istniejący `check` sprawdza import i krótki start; nie weryfikuje mechanik ani balansu. Repo nie ma jeszcze zapisanej historii commitów.

## 1. Wniosek o gotowości i granice zakresu

Brief wystarcza do zaplanowania prototypu, ale kilka reguł musi zostać rozstrzygniętych przed implementacją odpowiednich systemów. Nie ma potrzeby rozszerzania designu o ekonomię, nowe jednostki lub nowe kontry.

Rekomendowany wynik v0.1: jedna arena, dwa automatycznie ustawiane zespoły po 1–6 jednostek, wszystkie osiem lvl1, ręcznie zapisane składy testowe, pełna walka, podstawowy podgląd i raport. „Ręcznie skonfigurowane składy” oznacza wybór składu w danych, nie ręczne ustawianie pozycji przez gracza. Start od dwóch jednostek jest etapem technicznym, nie końcowym zakresem v0.1.

Prosty panel deweloperski: wybór presetu, start/reset, pauza/krok i wynik. Nie jest to finalne menu ani pełny local multiplayer z draftem. Dwie strony lokalnej symulacji są podstawą późniejszej gry 1v1. Zakres ośmiu jednostek jest rekomendowany, ponieważ wymagane mechaniki i analiza ról obejmują niemal cały roster.

Poza zakresem: draft, rundy i wynik całego meczu, hybrydy, lvl2/lvl3, online, progression, sklep, finalne grafiki, finalny UI, nowy system pancerza, leczenia lub anti-heal. Wspomniane w briefie osie kontr nie są nakazem ich implementowania teraz.

## 2. Przegląd zasad i problemów

### P1. Równoczesne trafienia i koniec walki — blokuje resolver obrażeń

Sekcja 20 ustala priorytet kolców wewnątrz jednej wymiany, ale nie kolejność dwóch śmiertelnych basic attacków, pocisków lub trafień dwóch Jeży. Przetwarzanie jednostek kolejno według strony lub ID może stworzyć systematyczną przewagę pierwszej drużyny. Sam stały seed tego nie naprawia.

Zatwierdzone D1: trafienia zaplanowane na ten sam krok symulacji rozliczać partią. Najpierw kolce od kwalifikujących się melee, później pozostałe obrażenia. Śmierć od kolców anuluje nadchodzące trafienie jego autora, zgodnie z briefem. Zwykłe trafienia z tej samej partii są równoczesne; zwykła śmierć w tej partii nie anuluje już należącego do niej zwykłego trafienia. Po partii zero żywych po obu stronach oznacza remis. Dwa Jeże mogą zginąć od wzajemnych kolców w tej samej partii — reguła nie faworyzuje jednego z nich.

Wynik sprawdzamy po całej partii, nie po pierwszym zdarzeniu. Pocisk wystrzelony wcześniej może działać po śmierci strzelca, dopóki walka trwa. Po rozstrzygnięciu końca walki nie czekamy na przyszłe trafienia pozostałych pocisków. Ta granica rundy została zatwierdzona wraz z D1.

### P2. Baseline TTK — blokuje kryteria balansu, nie tworzenie infrastruktury

Sekcje 21–22 mieszają teoretyczne HP/DPS, czas kontaktu i długość pojedynku. 100 / 10 = 10 s oznacza ciągłe zadawanie obrażeń bez przerw i skilli, a nie gwarantowany czas dowolnej pary lvl1. Dodatkowe obrażenia same w sobie skracają TTK.

Zatwierdzone D2: zachować staty jako startowe; 10–12 s traktować jako cel czasu całego wybranego wyrównanego pojedynku, a 20–30 s jako cel reprezentatywnego pełnego 6v6. Osobno mierzyć czas od startu do pierwszego trafienia i od pierwszego trafienia otrzymanego przez jednostkę do jej śmierci. Ocalałych nie traktować jako zabitych w chwili końca rundy.

Nie zakładać, że pełne 6v6 musi trwać dłużej od 1v1: równoległe obrażenia i focus fire mogą je skracać. Rozrzut archetypów jest pożądany; wszystkie 1v1 nie muszą trwać 10–12 s ani mieć wyniku 50/50.

### P3. Budżet skilli a wstępne liczby — ryzyko balansowe, nie błąd do automatycznej korekty

Przy uproszczeniu „bonus dodany do nieprzerwanego basic DPS” Niedźwiedź otrzymuje 25/5 = 5 DPS ponad 9 (+56%), Małpa 18–20/4 = 4,5–5 ponad 10 (+45–50%), Hipopotam 40/6 ≈ 6,67 ponad 6 (+111%). To obliczenia orientacyjne, nie pomiary. Nie uwzględniają utraty czasu basiców, wind-upu, zasięgu, chybień i aktywacji na początku walki. Pokazują, dlaczego 20–30% efektywnej wartości z sekcji 22 nie jest zapewnione przez same staty.

Nie zmieniać HP/DPS na tym etapie. W danych trzeba rozdzielić attack damage, attack interval oraz wind-up/recovery skilli. Po pomiarach porównywać wariant ze skillem i bez skilla, nie tylko sumować damage/cooldown. 25 obrażeń jednorazowego dive to 25% neutralnego HP; jego wartość rośnie przez omijanie frontu, lecz nie jest stałym bonusem DPS.

### P4. Gepard i Skunks mają warianty, a Małpa nie ma rozdzielonego basica i skilla

Gepard: seria trafień albo buff attack speed daje różne interakcje z kolcami. Zatwierdzone D3: osobna szybka seria trzech trafień melee; każde uruchamia kolce, seria zajmuje slot akcji i zastępuje basici na czas wykonania. Cooldown startowy do testu 5 s (w ramach briefu). Obrażenia i czasy ustalić w zadaniu kalibracji, bez obiecywania końcowego balansu. Buff utrzymujący się po castowaniu wymagałby osobnej definicji, kiedy wolno wznowić basic attack.

Skunks: rekomendowany wariant D3 to chmura aplikująca wyłącznie -25% outgoing attack/skill damage na 3 s, cooldown 6 s; bez równoczesnego spowolnienia attack speed. Roboczo jednorazowe sprawdzenie przeciwników w promieniu przy aktywacji (wizualna chmura nie jest dodatkowym trwającym polem obrażeń). Ponowna aplikacja odświeża czas, nie kumuluje siły; stałe kolce nie są atakiem ani skillem ofensywnym i pozostają 2. Ten wariant briefu został zatwierdzony jako baza v0.1.

Małpa: proponowane basic ranged oraz odrębny mocniejszy rzut bananem na cooldownie; mocniejszy rzut zadaje 18–20 zamiast obrażeń basica, nie oba pakiety jednocześnie. Wizualnie rozróżnić mocny rzut rozmiarem pocisku i zamachem. Zwykły basic nadal daje nominalne 10 DPS, gdy nie przerywa go skill lub ruch. Dokładny wygląd basica nie blokuje logiki.

### P5. Kontakt z frontem a target i dash

Sekcje 11, 15–16 nie mówią, co robi melee z celem za nieprzechodnim frontem. Propozycja: kontakt z blokującym wrogiem czyni go poprawnym celem melee; zmiana celu ma powód `blocked_by_enemy`. „Wiąże się w walce” nie oznacza nowego statusu root ani tauntu. Królik może odejść dashem, jeśli istnieje wolna droga. Dive omija front wyłącznie podczas skilla.

Sojusznicy nie blokują się fizycznie. Może to powodować nakładanie sprite'ów; nie naprawiać czytelności przez dodanie niezamówionych sojuszniczych kolizji. Najpierw rozstaw automatycznego spawnu, sortowanie i czytelne oznaczenia, a dopiero po obserwacji dyskusja o zmianie reguł.

### P6. Brak parametrów zachowań — decyzje robocze implementatora

Do zapisania w danych przed pierwszym testem: damage i attack interval przy zachowaniu basic DPS, moment pierwszego basica, wind-up/recovery, prędkości, zasięgi, promienie kolizji, pasmo dystansu Małpy, długość/czas dashu, próg „wróg blisko”, czas dive i legalne lądowanie, promień chmury, priorytety targetów.

Proponowane jednolite zasady: basic pierwszy raz trafia po jednym pełnym attack interval od wejścia w zasięg; w czasie castowania basic nie kumuluje zaległych trafień. Śmierć przerywa wind-up i pozostałe trafienia serii. Melee sprawdza zasięg przy trafieniu, więc dash może uniknąć przyszłego ciosu, ale nie cofa już otrzymanego. Dive ma krótki czas lotu, brak startowego oczekiwania, legalne lądowanie obok celu i bez dodatkowej niewrażliwości. Śmierć celu podczas lotu nie daje drugiego dive; lądowanie i zwykły retarget. Docelowy punkt dashu jest obcięty przez granicę areny lub pierwszego wroga.

Robocza propozycja pocisków: celowane, przechodzą przez inne jednostki, zadają obrażenia raz wskazanemu żywemu celowi; po utracie celu wygasają, bez darmowego retargetu. Silniejszy banan w v0.1 używa tej samej reguły. Infrastruktura może przyjąć flagę blokowania przez pierwszy cel, ale nie dodawać takiego skilla, skoro żaden lvl1 go jeszcze nie wymaga.

Reguły zostały zatwierdzone; brakujące wartości parametrów trzeba dobrać i zapisać jawnie w T0/T1 jako robocze, bez pytania użytkownika o każdy piksel.

### P7. Scope „kilka lub wszystkie”

Lista wymaganych umiejętności obejmuje niemal cały roster, a badanie kontr wymaga różnorodności. Rekomendacja: końcowy odbiór v0.1 obejmuje osiem lvl1; implementacja przyrostowa. Duplikaty w składach mogą być wyłącznie fixture'ami testowymi (np. stress focus fire); nie ustala to legalności duplikatów w przyszłym drafcie.

### P8. Hybrydy i późniejsze systemy — nie blokują v0.1

Macierz lvl2: 12 par, każde zwierzę ma trzech partnerów. Warunek bez wspólnego zwierzęcia dla lvl3 jest spójny, ale nie zastępuje macierzy i mapowania wyników. Zachowanie „podstawowej funkcji” jest nadal nieostre dla defensywnego dashu zmienionego na ofensywny oraz ciężkiego ciosu ograniczonego do pierwszego trafienia po dive. Ocenimy to przed lvl2, bez modyfikowania zaakceptowanych archetypów teraz.

Połączenie dwóch jednostek w jedną o mocy +15–25% może być nieopłacalne poniżej limitu sześciu slotów, jeśli rodzice są zużywani. Zasady zużycia rodziców, rezerwy i uzupełniania składu nie są jeszcze ustalone. To temat etapu draft/hybrydy, nie powód do tworzenia ekonomii w prototypie combat.

Nie ma konfliktu między brakiem limitu czasu a celem 20–30 s: pierwszy jest zasadą końca walki, drugi celem pomiarowym. Anti-stall nie powstaje bez danych.

## 3. Decyzje zatwierdzone przez użytkownika — 2026-09-24

Zatwierdzono następujące trzy decyzje:

1. **D1 — równoczesność i remis:** przyjęto partię trafień, pierwszeństwo kolców i remis przy obustronnym wybiciu w tym samym kroku, wraz z granicą końca walki opisaną w P1.
2. **D2 — pomiar czasu:** 10–12 s jako cel całego wyrównanego 1v1, osobne metryki kontaktu/TTK; 20–30 s jako cel pełnego 6v6, bez wymuszania go na każdej parze.
3. **D3 — warianty umiejętności:** Gepard = trzy trafienia zamiast buffa attack speed; Skunks = -25% damage przez 3 s, odświeżanie bez stackowania; Małpa = basic ranged i osobny mocny rzut. Przyjąć opisane w P4 warianty jako bazę testową.

Pozostałe rekomendacje techniczne przyjęto jako plan prototypu. Konkretne brakujące wartości parametrów zostaną zapisane w T0/T1. D1–D3 są zatwierdzone; zgoda na rozpoczęcie kodowania nadal wymaga osobnego taska.

## 4. Rekomendowana architektura

### 4.1. Jeden rdzeń walki, dwa sposoby uruchomienia

Prosty `CombatSimulation` w GDScript, jako stan i logika niezależne od rysowania. Scena Godot wyświetla stan i zdarzenia tej samej symulacji, którą runner uruchamia bez okna. Nie tworzyć osobnego uproszczonego kalkulatora balansu z innymi regułami.

Rekomendowany stały krok 1/60 s. W grze kontroler wywołuje krok z `_physics_process`; runner wykonuje te same kroki w pętli bez czekania na realny czas. UI/animacje nie decydują o momencie obrażeń. Stały krok i kontrolowana kolejność ułatwiają powtarzalność; nie gwarantują deterministycznego online między różnymi platformami. Online pozostaje poza zakresem.

Nie budować ECS, drzewa zachowań, edytora skilli ani uniwersalnego języka efektów. Kilka typowanych klas i funkcji wystarczy przy maksymalnie 12 jednostkach.

### 4.2. Struktura scen — planowane

- `scenes/main.tscn`: punkt wejścia; docelowo instancja `CombatPrototype`.
- `scenes/combat/combat_prototype.tscn`, root `Node2D`:
  - `CombatController` (`Node`): preset, start/pauza/reset, stałe kroki i wynik.
  - `ArenaView` (`Node2D`): tło i granice; roboczy widok z góry/lekko z góry bez fizyki grawitacyjnej.
  - `Units` (`Node2D`, sortowanie po Y): instancje widoku jednostki.
  - `Projectiles` i `Effects` (`Node2D`): wyłącznie prezentacja pocisków/zdarzeń.
  - `HUD` (`CanvasLayer`): wybór presetu i podstawowe dane walki.
- `scenes/units/unit_view.tscn`, root `Node2D`: `Visual` (`Sprite2D` lub prosta grafika tymczasowa), oznaczenie drużyny, HP, ikona statusu, `AnimationPlayer` do ruchów/akcentów wizualnych.

Jedna scena widoku jednostki z różnymi danymi; bez osobnej rozbudowanej sceny AI dla każdego zwierzęcia. Grafika cartoon jest etapem czytelności, nie produkcją finalnych assetów. Pole walki nie powinno rozszerzać się wraz z szerokością okna: zmienia się prezentacja, nie geometria symulacji.

### 4.3. Resources / definicje danych

- `UnitDefinition`: stabilne ID, nazwa, HP, attack damage, attack interval, move speed, attack range, radius, rola, preferred range min/max, targeting policy, lista `SkillDefinition`, referencja wizualna. Basic DPS jest wyliczany z damage/interval, nie edytowany jako trzecia niezależna liczba.
- `SkillDefinition`: ID, behavior ID, tryb (active/conditional/passive/once), cooldown, wind-up, recovery, damage, liczba/odstęp trafień jeśli potrzebne, range/radius, priorytet, ewentualny status, parametry ruchu. Walidacja zależna od behavior ID; nie tworzyć parametrów wszystkich przyszłych mechanik.
- `StatusDefinition`: ID, zmieniana statystyka, mnożnik, duration i refresh policy; w v0.1 wystarczy debuff Skunksa.
- `MatchDefinition`: składy, arena, seed, identyfikator reguł; zwykłe presety mają automatyczny spawn. Kontrolowane pozycje są dozwolone tylko w fixture'ach testowych, nie jako mechanika gracza.
- `CombatRules`: tick rate, granice, parametry automatycznego spawnu, progi targetowania i identyfikator wersji reguł. Nie dubluje wartości statów jednostek.

Pliki `.tres` w `resources/units`, `resources/skills`, `resources/statuses`, `resources/matches`. Definicje są traktowane jako niezmienne podczas walki. Resource może być współdzielony przez instancje, więc HP, cooldownów i czasu statusu nie zapisujemy do definicji. To zgodne z modelem [Resources w Godot](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html).

### 4.4. Runtime Unit i stan meczu

`UnitState` (`RefCounted`): ID instancji, team, definition ID, current HP, pozycja, velocity, target ID, alive, stan AI, zegar basica, aktywna akcja i jej faza, instancje skilli/cooldowny, statusy, flaga zużytego dive. Efektywne staty wyliczamy z definicji i statusów. Brak bezpośrednich referencji do sprite'ów.

`CombatState`: tick, match ID, jednostki, pociski, oczekujące zdarzenia, wynik. `CombatSimulation` posiada ten stan, generator losowy jeśli potrzebny oraz mały zestaw usług. Brak konieczności nowych globalnych autoloadów.

### 4.5. AI i targetowanie

Mała maszyna stanów: idle/seek, move, basic attack, cast, dash/dive, dead. Najpierw walidacja celu, potem wybór dostępnej akcji, dopiero potem ruch/basic. W trakcie zablokowanej aktywnej akcji brak drugiego aktywnego skilla. Pasywne kolce obsługuje resolver trafień, nie scheduler AI.

Polityki w danych, wykonywane przez `Targeting`:
- melee/front: najbliższy osiągalny wróg; blokujący front może przejąć priorytet;
- ranged: preferuj poprawny cel w zasięgu; jeśli brak, wybierz cel do podejścia; dystans ucieczki uwzględnia najbliższe zagrożenie melee, nie tylko ostrzeliwany cel;
- dive: na start najwyższy priorytet dla backline/ranged, potem najdalszy sensowny wróg; po zużyciu dive polityka melee;
- utility: cel/mejsce umożliwiające użycie chmury, bez biegania między równorzędnymi celami;
- rabbit: podstawowy cel melee, dash warunkowy od najbliższego zagrożenia.

Histereza: żywy sensowny cel zostaje, dopóki nowy nie przekroczy jawnego progu przewagi. Śmierć celu powoduje retarget w tej samej fazie aktualizacji, bez czekania na cooldown ataku. Przy idealnym remisie użyć jawnego tie-breaku niezależnego od drużyny i logować seed; nie wprowadzać losowych obrażeń lub uników.

### 4.6. Movement i kolizje

Dla pustej prostokątnej areny rekomendowane proste okręgi w `CombatSimulation`: pozycje, promienie i ograniczenie przemieszczenia względem granic oraz wrogów. Sojusznicy pomijani przy blokowaniu. Weryfikacja odcinka ruchu zapobiega przechodzeniu przez wroga przy szybkim dashu. Konflikty proponowanych ruchów przeciwników rozstrzygane symetrycznie na podstawie poprzedniego stanu, nie „pierwsza drużyna porusza się pierwsza”.

Mała liczba jednostek pozwala sprawdzać wszystkie pary bez spatial hash i navmesha. Przy kontakcie melee atakuje blokującego przeciwnika zamiast potrzebować pełnego pathfindingu. Ranged stosuje pasmo odległości: podejdź / stój i strzelaj / wycofaj się; różne progi wejścia/wyjścia ograniczają drganie. Ściana ogranicza ucieczkę, nie teleportuje jednostki.

Dive ma jawny wyjątek od blokady podczas przeskoku, lecz poprawny punkt lądowania. Dash Królika zachowuje blokowanie przez przeciwników. Brak sojuszniczych kolizji i limitu napastników. Jeśli proste okręgi nie przejdą testów ruchu, wrócić do oceny architektury; nie utrzymywać równocześnie drugiej autorytatywnej fizyki w `CharacterBody2D`.

### 4.7. Skille, statusy i kolejność kroku

`SkillSystem` wybiera zachowanie z niewielkiego rejestru: heavy hit, multi-hit, projectile, dive, dash, thorns, debuff burst. Zachowania są osobnymi funkcjami/klasami GDScript, a liczby pochodzą z Resource. To składanie mechanik, nie warunki typu „jeśli nazwa == niedźwiedź”. Jednostka od początku ma listę skilli, ale v0.1 daje lvl1 dokładnie jeden charakterystyczny skill, poza basic attackiem.

Cooldown liczony w tickach od rozpoczęcia, akcja ma osobno wind-up, impact i recovery. Zgon kończy przyszłe zdarzenia akcji; gotowy cooldown nie omija blokady aktywnej akcji. Działający efekt po zakończeniu castu nie zajmuje bez końca slotu akcji. Status ma źródło, cel, start/end tick, modifier i refresh policy; zero mutacji bazowych statów Resource.

Proponowana faza kroku, zależna od D1:
1. Wygaszenie statusów, aktualizacja gotowości i czasów akcji.
2. Retarget, decyzje oraz proponowane ruchy na podstawie wspólnego stanu.
3. Rozstrzygnięcie ruchu, pocisków i kwalifikacji trafień.
4. Zebranie partii trafień; kwalifikujące się kolce rozliczone przed normalnymi obrażeniami, bez rekursji.
5. Zgony, anulowanie odpowiednich akcji, aplikacja statusów i warunki reakcji Królika po przeżytym trafieniu.
6. Natychmiastowe unieważnienie martwych celów/retarget, ocena wyniku, zapis telemetrii i zdarzeń dla prezentacji.

Dokładne znaczenie „tick jednoczesności” musi zostać zapisane i przetestowane. To celowo jawna reguła symulacji, a nie przypadkowa kolejność sygnałów Godot. Stan po zakończeniu meczu jest zamrożony.

### 4.8. Telemetry i symulacje

`CombatRecorder` zbiera zdarzenia i podsumowania bez wpływu na decyzje walki. Tryb pełnego śladu tylko dla debug/reprodukcji; duże serie zapisują głównie agregaty. Eksport JSONL dla zdarzeń i JSON/CSV dla wyników, w ignorowanym katalogu raportów lub `user://`, nie przez modyfikację danych źródłowych.

`SimulationRunner` tworzy ten sam `CombatSimulation` bez widoków i wykonuje kroki aż do wyniku. Uruchamiany z Godot headless; odseparowany od MCP i otwartego edytora. Możliwości uruchomienia bez okna opisuje [Godot CLI](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html). Częstotliwość logiki jest stała, niezależna od renderowania; Godot rozróżnia [processing i physics processing](https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html).

Watchdog wyłącznie runnera: przykładowo 120 s czasu symulacji albo limit pracy procesu, wynik `inconclusive/stalled`, pełny ślad do diagnozy. Nie przyznaje wygranej ani remisu, nie jest limitem walki gracza ani anti-stall. Zwiększanie liczby symulacji ma następować po działającej walce i testach reguł.

### 4.9. Gotowość na lvl2/lvl3 bez budowania ich teraz

Lista skilli, osobne instancje cooldownów, jawne typy obrażeń/reakcji i priorytety wystarczają do późniejszego dodania 2/4 mechanik. Nie tworzyć teraz receptur, finalnych formuł statów ani grafiki hybryd. Późniejsze lvl2/lvl3 dostaną własne definicje danych; nie sumować rodzicielskiego HP. Brak deklaracji, że obecna symulacja jest już gotowa do sieciowego lockstepu.

## 5. Plan implementacji i zależności

Każde zadanie poniżej jest przyszłą pracą, nie uruchomionym zadaniem subagenta.

### T0 — zamknięcie kontraktu combat

Zależności: osobny task implementacji; D1–D3 już zatwierdzono. Rezultat: zatwierdzone reguły kolejności zdarzeń i pomiarów, osiem jednostek w zakresie odbioru, lista parametrów roboczych z uzasadnieniem. Właściciel: główny agent z użytkownikiem. Bez finalnego balansowania.

### T1 — dane, walidacja i stan

Po T0. Definicje Resource i ich walidacja, `UnitState`, `CombatState`, fixture neutralny, format zdarzeń. Weryfikacja HP/range/cooldown, zgodności damage/interval z DPS i niezależności stanów dwóch instancji tej samej definicji. Wszystkie umowy danych zapisane przed delegowaniem.

### T2 — minimalna walka i resolver

Po T1. Stały krok, basic melee, kwalifikacja trafień, partie kolców/obrażeń, śmierć, wynik i remis zgodnie z D1. Telemetria od pierwszej walki: nie odkładać logowania na koniec. Odbiór: dwa neutralne testowe obiekty kończą walkę i spełniają oczekiwany kontrakt liczbowy.

### T3 — arena, pozycjonowanie i AI

Po T2. Automatyczne rozstawienie, kolizje, targetowanie ról, focus fire, ranged distance keeping, pociski. Testy kontaktu/blokowania, ścian, braku drgań i zamiany stron. Brak nowych zasad placementu dla gracza.

### T4 — skille i osiem lvl1

Po T3. Najpierw Niedźwiedź i Hipopotam (wind-up/recovery), potem Małpa i Gepard (pocisk/seria), dalej Jeż (pełna integracja kolców), Orzeł, Królik i Skunks. Każdy behavior ma testy przed zbiorczymi symulacjami. Zapis jawnych wartości startowych bez zmiany bazowych HP/DPS w ukryciu.

### T5 — widok i czytelność

Może zaczynać po kontrakcie zdarzeń w T1, integrowany po T2–T4. Sceny Godot, tymczasowe sylwetki ośmiu jednostek, podstawowe animacje, HP/statusy, panel presetów. Prezentacja odczytuje stan, nie oblicza obrażeń. Odbiór wizualny przy 6v6, nie tylko w zbliżeniu na jedną postać.

### T6 — runner i agregacja

Prosty harness testowy powstaje w T2, właściwe serie i agregaty po T4 oraz integracji T5. Ten sam rdzeń bez renderowania, konfiguracja zestawu walk, reprodukcja pojedynczego przypadku, watchdog i eksport metryk. Najpierw test zgodności headless/widok, potem setki walk.

### T7 — kalibracja, raport i odbiór

Po T4–T6. Baseline, macierz 1v1, role w drużynach, 6v6, analiza biasu i outlierów; dopiero wtedy małe korekty 5–15% z opisem przyczyny i ponownym porównaniem na tych samych scenariuszach. Raport wraz z przypadkami niespełniającymi kryteriów. Nie dodawać anti-stall automatycznie.

Ścieżka zależności: T0 → T1 → T2 → T3 → T4 → T6 → T7; T5 startuje po T1 i jest wymagane przed końcowym odbiorem T7.

### Proponowana delegacja później

- Główny agent: T0, model czasu i obrażeń w T2, kontrakty danych, integracja i decyzje o balansie.
- Subagent danych/testów: T1 i fixture'y po ustaleniu interfejsów; później runner/metriki T6. Konkretne katalogi własności ograniczają konflikty.
- Subagent zachowań: wydzielone skille/statusy T4 po ustabilizowaniu T2–T3; nie zmienia resolvera samodzielnie.
- Subagent prezentacji: T5 na kontrakcie snapshotów/zdarzeń, bez modyfikacji symulacji.

Nie uruchamiać wszystkich od pierwszego dnia; zależności ograniczają sensowną równoległość. Review wyników testów można delegować po ukończeniu modułów, bez równoczesnego zmieniania tych samych plików. Żadnych subagentów implementujących w ramach obecnego taska.

## 6. Plan weryfikacji

### 6.1. Testy poprawności przed balansem

1. Dane: komplet ośmiu lvl1, unikalne ID, jeden skill na lvl1, dodatnie wymagane staty, walidacja typu skilla i referencji, brak modyfikacji wspólnych Resources.
2. Neutralny basic: przy 100 HP, 10 damage co 1 s i pierwszym trafieniu po 1 s śmierć po dziesiątym trafieniu około 10 s (tolerancja jeden tick). Osobny test cooldownów/recovery i braku zaległych salw.
3. Kolce: 2 za kwalifikujące się melee, wielohit liczy trafienia osobno, śmiertelne kolce anulują cios, pocisk/DoT/odbicie nie uruchamiają kolców, Jeż kontra Jeż nie zapętla się. Testy równoczesności zależne od D1.
4. Ruch: wrogowie blokują, sojusznicy przepuszczają, jednostki nie opuszczają areny, szybki dash nie tuneluje przez wroga, dive omija front i ląduje legalnie; brak niepoprawnych odległości/NaN.
5. AI: utrzymanie sensownego celu, przejęcie blokującego wroga, natychmiastowy retarget po śmierci, dozwolony focus fire, ranged reaguje na najbliższe zagrożenie i nie oscyluje na progu dystansu.
6. Skille: Orzeł dive raz bez startowego cooldownu; Królik dopiero po przeżytym trafieniu i przy zagrożeniu, bez cofania damage; Hipopotam nie trafia przed końcem wind-upu; seria przerywana przez śmierć; Skunks poprawnie odświeża i wygasza status bez stackowania siły.
7. Pociski: przenikanie przez inne jednostki, jeden damage na właściwy cel, śmierć celu/strzelca, działanie końca walki; żadnych trafień po zakończeniu symulacji.
8. Wynik: zero/żywi po obu stronach, podwójne zabicie, ostatni Jeż, brak podwójnych komunikatów zakończenia. Niepoprawny pusty preset odrzucony przed rozpoczęciem.
9. Powtarzalność: identyczny preset/seed/wersja daje identyczny ślad stanu na tej samej platformie; test zamiany stron i permutacji ID. Render włączony/wyłączony nie zmienia stanu po N tickach.
10. Reset: po powtórzeniu meczu nie zostają cooldowny, statusy, pociski lub poprzednie cele.

Testy GDScript uruchamiane headless, kod wyjścia niezerowy przy błędzie. Bez nowego frameworka, jeśli mały harness z asercjami wystarczy. Obecny `tools/godot.ps1 check` pozostaje smoke checkiem, a nie dowodem poprawności combat.

### 6.2. Dane i jednoznaczne definicje metryk

Każdy przebieg: run ID, wersja silnika, hash kodu/danych lub snapshot przy braku commita, seed, preset, składy, pozycje, dt, wynik (A/B/draw/inconclusive), czas symulacji oraz oddzielnie czas wykonania na komputerze.

Zdarzenie: tick, source/target ID, typ (basic/skill/thorns/status), attempted i applied damage, powód anulowania, start/impact/end skilla, zmiana targetu z powodem, status apply/refresh/expire, ruch specjalny i zgon. Applied damage ograniczone do faktycznie utraconego HP; overkill zapisany osobno. Suma applied damage dealt musi zgadzać się z damage taken; dla anulowanego ciosu applied = 0.

Agregaty:
- wynik i win rate z jawnym mianownikiem; remisy osobno, opcjonalnie score = (wins + 0,5 × draws) / zakończone walki;
- inconclusive osobno i jako udział wszystkich uruchomień, nigdy automatyczna przegrana;
- średnia, mediana, p90 czasu walki; odsetek w oknie 20–30 s dla 6v6;
- czas do pierwszego trafienia w walce; dla każdej zabitej jednostki czas od pierwszego otrzymanego damage do zgonu; także czas od startu do zgonu, przeżycie i końcowe HP;
- dealt/taken według źródła, basic i skill damage, overkill, damage anulowany przez kolce;
- liczba aktywacji skilla, liczba okazji spełniających warunki, śmierć przed pierwszą okazją i śmierć mimo dostępnej okazji;
- uptime statusu / czas życia celu, osobno od czasu castowania; jednorazowemu dive nie przypisywać pozornego „uptime”;
- target changes na sekundę życia z powodami;
- czas Małpy w preferowanym paśmie wśród czasu z żywym zagrożeniem oraz czas w zwarciu;
- udział obrażeń w sytuacjach focus fire: w roboczym oknie 1 s co najmniej dwa różne źródła atakują ten sam cel; raportować overkill i czas do zabicia, bez twierdzenia, że sam udział dowodzi korzyści przyczynowej;
- częstość końcówki dokładnie 1 żywa jednostka vs 1, jej czas i wynik; nie liczyć testów startujących 1v1 jako „powstałej końcówki”;
- healing = nie dotyczy w v0.1, bez dopisywania systemu leczenia.

Ocalałe jednostki są obserwacjami bez zdarzenia śmierci, więc nie włączać ich jako sztucznych TTK do średniej zgonów. Uptime i target changes bez poprawnego mianownika nie są porównywalne.

### 6.3. Zestawy walk

Etap A: neutralne fixture'y i testy wymienione wyżej. Staty fixture'a nie dodają dziewiątego zwierzęcia do gry.

Etap B: wszystkie 28 różnych nieuporządkowanych par lvl1, każda po obu stronach = 56 walk; osiem self-matchupów = osiem kolejnych, łącznie 64 walki na scenariusz. Pięć jawnych wariantów odległości/offsetu startowego daje 320 przypadków. Pozycje testowe są osobne od domyślnego spawnu gry.

Ponowne uruchomienie identycznego deterministycznego przypadku sprawdza reprodukcję, nie daje nowej niezależnej próby win rate. Seed ma sens tylko tam, gdzie faktycznie zmienia zdefiniowane tie-breaki; nie dodawać losowości do obrażeń dla statystyki. Wynik macierzy to udział zwycięstw w określonym zestawie scenariuszy, nie estymacja populacji graczy.

Etap C: role i interakcje:
- Gepard vs Jeż oraz kontrola równego DPS przy różnej częstotliwości trafień;
- Niedźwiedź + Małpa vs Hipopotam + Gepard: front i ranged;
- Niedźwiedź + Małpa vs Hipopotam + Orzeł: dive kontra tyły;
- Królik vs Hipopotam: wind-up, odejście i nieodwracanie trafień;
- Jeż + Skunks vs Gepard + Niedźwiedź: utility i wiele źródeł obrażeń;
- trzy jednostki skupiające ogień vs front z ranged: blokowanie i focus, bez limitu atakujących;
- Królik vs Królik, Małpa vs Małpa, Niedźwiedź vs Hipopotam: potencjalne zastoje i granice areny.

Etap D: składy mieszane 3v3 i 6v6, wersje lustrzane i zamiana stron. Dla 6v6 bez duplikatów istnieje 28 składów z ośmiu zwierząt (wybieramy sześć). 28 × 28 = 784 uporządkowane pary składów na scenariusz. Uruchomić po poprawnych etapach A–C; rozszerzyć o warianty położenia dopiero, jeśli dane tego wymagają. Osobno test przepełnienia wizualnego 6v6, nie tylko agregaty.

Etap E: porównania skilla włączonego/wyłączonego i zastąpienia jednej jednostki przy tym samym przeciwniku i ustawieniu. Wariant bez skilla to wyłącznie narzędzie badania wpływu. Brak symulacji lvl2/lvl3 w v0.1.

### 6.4. Outliery — alerty, nie automatyczny nerf

- >70% zwycięstw lub <30% w jawnie określonej macierzy przeciwników po zamianie stron: kandydat do analizy; nie oczekiwać 50% w każdym matchupie.
- Przewaga lewej/prawej strony lub niższego ID przy symetrycznym układzie: najpierw błąd kolejności lub spawnu, nie balans jednostek.
- Brak aktywacji mimo co najmniej jednej poprawnej okazji: błąd/priorytet AI; zgony przed pierwszą okazją agregowane oddzielnie.
- Utrata backline przed pierwszym możliwym działaniem w >80% celowanych testów dive: roboczy alarm, wymaga przeglądu śladu.
- >2 zmiany celu/s przez co najmniej 2 s bez śmierci celu i bez istotnego zdarzenia: roboczy alarm oscylacji, nie narzucony limit retargetu.
- Małpa stale w zwarciu albo stale ucieka bez atakowania: sprawdzić pasma, ściany i prędkości, zanim zwiększymy HP/DPS.
- Mediana/średnia reprezentatywnych 6v6 poza 20–30 s, p90 >45 s albo choć jeden watchdog: raportować rozkład i przyczyny. 45 s jest progiem analizy, nie limitem gry.
- Kolce dominują także nad wolnymi heavy hitters: sprawdzić obrażenia na hit, częstotliwość i anulowanie śmiertelnych ciosów, nie zakładać, że stałe 2 gwarantuje dobry balans.

Każda zmiana danych: przyczyna, hipoteza, wartość przed/po, scenariusze kontrolne, wynik. Preferować krok 5–15%; większy wymaga konkretnych danych. Nie przypisywać przyczynowości samemu skorelowanemu win rate jednostki w składzie.

### 6.5. Kryteria odbioru

Techniczne, wymagane:
- Wszystkie testy reguł przechodzą; osiem lvl1 i 1–6 jednostek na stronę działa bez błędów skryptów, nielegalnych stanów i przenikania wrogów poza dive.
- Zgodność wyniku i śladu stanu przy identycznym wejściu w trybie wizualnym i headless na tym samym środowisku; brak biasu wynikającego z kolejności drużyn.
- Każdy skill ma poprawną demonstrację w przeznaczonym scenariuszu, właściwe telemetrie i testy wyjątków.
- Pełna referencyjna seria kończy się legalnym wynikiem bez watchdogów; jeśli nie, prototyp jest częściowy i raport wskazuje przypadki, zamiast ukrywać je w statystyce.
- Raport umożliwia odtworzenie wskazanej walki i powiązanie wyników z wersją danych.

Gameplay i czytelność, wymagane do uznania celu za udowodniony:
- Wspólny przegląd z użytkownikiem/designerem przy normalnej prędkości oraz 6v6: można rozpoznać drużyny i role, zauważyć dive, dash, wind-up, kolce i debuff oraz wyjaśnić przyczynę śmierci bez czytania logów. Proponowana próba: pięć krótkich scenariuszy, poprawne wskazanie kluczowej roli/mechaniki w co najmniej czterech po krótkim przedstawieniu rosteru.
- Przynajmniej trzy kontrolowane zmiany składu dają zrozumiałą zmianę przebiegu (dostęp do backline, przeżycie frontu, czas/opłacalność szybkich ataków); nie wystarczy kosmetyczna zmiana wyniku.
- Zgodnie z zatwierdzonym D2 reprezentatywna seria 6v6 ma medianę w 20–30 s; wybrane wyrównane 1v1 mają medianę 10–12 s. Raport pokazuje też średnią, p90 i odstępstwa. Niespełnienie tych celów oznacza potrzebę kalibracji lub świadomej rewizji celu, nie automatyczne dodanie limitu czasu.
- Brak niewyjaśnionych outlierów; świadomie silne/słabe matchupy wynikają z mechanik. Nie wymaga to perfekcyjnego balansu.
- Użytkownik/designer potwierdza, że walka jest przyjemna do oglądania i daje zrozumiały wpływ wyboru składu. Tego nie zastąpi win rate ani decyzja AI.

Technicznie działający prototyp oraz udany prototyp gameplayowy to dwa osobno raportowane wyniki. Progi odbioru powyżej są zatwierdzonymi celami planu, nie istniejącymi wynikami testów.

## 7. Zalecana kolejność dalszych działań

D1–D3 zatwierdzono. Następny krok wymaga osobnego taska implementacji. Następnie dane/kontrakt → neutralny combat i resolver → movement/targetowanie → osiem lvl1 → czytelny widok → serie symulacji → kalibracja i wspólny odbiór. Nie zaczynać od finalnych ilustracji ani od hybryd.

W obecnym tasku zmieniono wyłącznie dokumentację. Nie utworzono klas, scen combat, skilli, testów gry ani runnera i nie zlecono ich implementacji subagentom.

## 8. Realizacja w kolejnym tasku

Powyższe zdanie opisuje etap planowania. W kolejnym, osobnym prompcie użytkownik zlecił implementację pełnego zakresu Combat Prototype v0.1 oraz testy, symulacje i raport. Implementację opisuje `COMBAT_IMPLEMENTATION.md`; instrukcje testów są w `TESTING.md`, a wynik odbioru technicznego, dane i ograniczenia w `COMBAT_PROTOTYPE_V0_1_REPORT.md`. Pierwotny plan i kryteria pozostają punktem odniesienia; nie zmniejszono celów balansu w celu dopasowania ich do wyniku.
