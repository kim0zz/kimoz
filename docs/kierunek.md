# Kierunek projektu Kimoz

## Nadrzędna specyfikacja

`../GAME_DESIGN_V0_2.md` — Auto Battler Zoo, Project Brief v0.2 — jest źródłem prawdy dla projektu. Poniższy kontekst techniczny jest pomocniczy; nie zmienia zasad briefu.

## Ustalone

- Silnik: Godot 4.7.2, GDScript.
- Gra 2D; w rozmowie preferowano grafikę rysunkową.
- Visual Direction v0.1 zatwierdzone jako wstępny kierunek: 2D cartoon, duże sylwetki, przerysowane proporcje, spójny obrys, mało detalu, kontrast i proste czytelne animacje. Pełne zasady: sekcja 36 briefu; to nie jest final art direction.
- Praca z pomocą AI, bez kupowania gotowych assetów.

## Kierunek gry

- Auto battler 1v1 ze zwierzętami i docelową hybrydyzacją.
- Pierwszy prototyp: core combat z ręcznie skonfigurowanymi składami lvl1, zgodnie z sekcjami 29–30 briefu.
- Draft, hybrydy i online są poza zakresem pierwszego prototypu.

2026-09-25, kolejny playtest: Małpa złapana w zwarciu staje i walczy z bliskim napastnikiem (kontakt 12 px, zwolnienie po odsunięciu wszystkich zagrożeń melee ponad 40 px lub ich śmierci). Dystans utrzymuje przed kontaktem i po uwolnieniu. Lot dive nie jest kontaktem. Orzeł: basic 11 zamiast 10; po samej poprawce ruchu przegrywał z samotną Małpą pozostawiając jej 5 HP. Po korekcie wygrywa pięć celowanych wariantów i ich lustra z 7 HP; nie ma gwarancji wygranej przeciw chronionej Małpie.

Preferencje pracy: małe taski bez pełnej serii 300+ testów i 1000+ symulacji; celowane regresje oraz wymagany check Godot. Proste delegacje preferencyjnie Luna high; delegowanie tylko gdy opłaca się względem wykonania lokalnie.

## Nadal do ustalenia

2026-09-25: użytkownik zlecił próbę Skunksa jako drugiego ranged. Wariant v0.1.3: zielone pociski, max range 150 px, preferowane 70–100 px; chmura nadal wokół siebie, HP i damage bez zmian. Małpa pozostaje strzelcem dalekiego zasięgu. Cel: zróżnicowanie linii walki. Sprawdzone 8 presetów i ich lustra, 24 celowane sprawdzenia bez błędów. Pełny preset 6v6 trwa 18,917 s, lustrzany 26,983 s; nie jest to pełna kalibracja balansu.

- Perspektywa, paleta, kontur, proporcje i grafiki referencyjne.
- Platformy docelowe i sterowanie.

## Baza techniczna

- Scena startowa: `scenes/main.tscn` — lokalny mecz z draftem, łączeniem i areną 2D; Combat Lab dostępny przyciskiem.
- Rozmiar bazowy: 1280 × 720; skalowanie `canvas_items`, proporcje `expand`.
- Renderer: Compatibility, zgodnie z istniejącym projektem.

Latarnik, wędrowna osada i karcianka były przykładami w rozmowie, nie wybranym projektem gry.

Plan przygotowania Combat Prototype v0.1: `COMBAT_PROTOTYPE_V0_1_PLAN.md`. Zawiera propozycje i otwarte decyzje, nie zgodę na implementację.

2026-09-24: użytkownik zatwierdził plan Combat Prototype v0.1, w tym D1–D3, architekturę, zakres i weryfikację. Implementacja oczekuje osobnego prompta. Szczegóły: sekcja 37 briefu.

2026-09-24, kolejny task: użytkownik wyraźnie zlecił implementację Combat Prototype v0.1. Poprzednia blokada implementacji została spełniona tym zleceniem. Powstały dane ośmiu lvl1, wspólny silnik symulacji i prezentacji, laboratorium walki, testy oraz runner. Prototyp wykorzystuje robocze rysowane w kodzie sylwetki; nie jest to decyzja o finalnych assetach. Instrukcja weryfikacji: `TESTING.md`; wyniki i ograniczenia: `COMBAT_PROTOTYPE_V0_1_REPORT.md`.

2026-09-25, playtest użytkownika: aktywne skille (w tym dive/dash) zablokowane przez pierwsze 2 s, ruch/basic/thorns od początku. Orzeł najpierw idzie do zwykłego celu; sojusznicy również blokują ruch. Dodano lokalne obchodzenie sojuszników i legalne lądowanie względem całej obsady. Liczbowy zasięg Niedźwiedzia 18 vs Królik 8. Grafiki i animacje nadal placeholderowe; finalne assety wymagają osobnego etapu. Sekcja 39 briefu zastępuje poprzednie sprzeczne reguły.

v0.1.4: odnawialny dive Orła, pierwszy po 2 s, kolejne co 6 s od startu, 25 obrażeń, najdalszy żywy cel wybierany dopiero na starcie skoku. Bez preferencji ranged i bez niewrażliwości; przy jednym wrogu działa z bliska. Między skokami zwykła walka melee. 25 celowanych sprawdzeń PASS, 8 presetów i ich lustra bez utknięć/rozbieżności. Domyślny 6v6 trwa 25,167 s, oba Orły wykonują po dwa skoki. Starsze wzmianki o jednorazowym dive są nieaktualne.

Aktualna przebudowa skilli: obowiązuje sekcja 42 GAME_DESIGN. Niedźwiedź25 AOE w stałym stożku100°; Hipopotam30+stun1s; Skunks chmura55px,3s,4 dmg/0,5s skierowana na zapamiętaną pozycję celu; Królik zrywa aggro wszystkich aktualnych napastników na1s przy alternatywach i przeskakuje za plecy autora trafienia. Poprzednie opisy osłabienia Skunksa i defensywnego odskoku Królika są historyczne. Gameplay implementowany lokalnie, wizualizacje delegowane do Luna high.

Zatwierdzono design wszystkich 12 lvl2 opisany w sekcji 7 GAME_DESIGN: dwie odziedziczone mechaniki mogą tworzyć jedną akcję. Priorytetem są zabawne pełne sylwetki; większy wygląd nie narzuca kolizji. Więcej HP/bazowych obrażeń, moc skilla i cooldown dobierane razem. Zachwianie nie kasuje akcji; własne chmury nie mnożą DOT, slow i zachwiania nie kumulują się. Orzeł–Jeż początkowo zwiększa HP bez nowego systemu pancerza. Śmierć celu kończy serię Geparda–Orła. Hipopotam–Królik reaguje na trafienie. To akceptacja designu, jeszcze bez implementacji lvl2; lvl1 pozostaje obecną bazą.

Pełny mecz zatwierdzony do implementacji: GAME_DESIGN sekcja43. Start2lvl1 i5żyć, draft4oferty bez duplikatów/uzupełniania, startABBA, dalej naprzemiennie od przegranego;1/2/3akcje przy odpowiednio3+ /2 /1życiu. Akcja dobiera lub łączy2rodziców.6aktywnych+3ławka, bezpłatne wyrzucanie i zarządzanie składem. Lvl2 ma być silny względem2lvl1, czasem3, nigdy przegrywać z singlelvl1 w wymaganym pokryciu. Odrębny subagent Luna high wykonuje liczbową kalibrację i raportuje rzeczywiste kontry; żadnej ukrytej reguły autowygranej.

Czytelność po pierwszym pełnym meczu: zaakceptowane wyróżnienie aktywnego gracza, kontekstowe podświetlenie partnerów fuzji (także ławka), oznaczenia pasujących ofert i podgląd wyniku ze skillem. Paski aktywnych skilli pod HP czytają rzeczywisty cooldown z symulacji, osobno dla każdej aktywnej umiejętności; pasywne kolce bez paska ładowania. Bez zmiany balansu i CD. Szczegóły: sekcja 44 briefu. Rekomendacja kolejności grafiki: wcześnie mała próba stylu na 1–2 zwierzętach i hybrydzie, pełny zestaw po ustabilizowaniu pętli gry; nie rozpoczęto produkcji finalnych assetów.

Kolejny playtest: wyraźny komunikat zwycięstwa rundy/meczu i remisu. Użytkownik chce mocniej odczuwalnych skilli, nawet rzadszych. Najpierw audyt aktualnych obrażeń i wpływu aktywnych umiejętności oraz porównanie z praktyką opisaną przez twórców gier; bez automatycznych buffów ani dodawania odrzutu. Wyniki i propozycja oddzielnego porównania feedbacku i mocy: `SKILL_IMPACT_REVIEW.md`. Konkretne docelowe udziały damage i nowe mechaniki nie zostały jeszcze zaakceptowane.

Zatwierdzono i zlecono pilotaż v0.2: Orzeł–Hipopotam, Małpa–Hipopotam, Niedźwiedź–Gepard. Osobny początkowy cooldown, więcej mocy w skillach kosztem basiców, mocniejszy feedback na placeholderach i robocze dźwięki. Combat Lab porównuje A (stare liczby) i B (nowe), przy wspólnych efektach; pełny mecz używa B. Bez mechanicznego odrzutu. Szczegóły §46 briefu i `BURST_PILOT_NUMBERS.md`. Pozostały roster dopiero po playteście.

Balans nie oznacza 50/50 każdej hybrydy w pojedynkach. Liczą się odmienne role, kontry i uzupełnianie składu. Jednostka wymagająca obrony albo robiąca silny początkowy impact i ginąca może być poprawnie zbalansowana. Wynik 1v1 to diagnostyka; sam nie uzasadnia buffa. Szczegóły w końcowym doprecyzowaniu §46 briefu.

Użytkownik po próbie zlecił pełne rozszerzenie: wszystkie 8 lvl1 i 12 lvl2 mają spójnie odczuwalne skille i indywidualnie dobrane początkowe cooldowny. Mechaniki i role pozostają różne; nie zamieniamy utility, DOT, kolców i uników w identyczny burst. Pełny mecz korzysta z nowego B, A w laboratorium to stan sprzed rozszerzenia (z trzema już poprawionymi hybrydami). Zatwierdzony zakres: §47 GAME_DESIGN. Dane: FULL_ROSTER_SKILLS.md, zespołowe wyniki: FULL_ROSTER_RESULTS.md.

Czytelność wyboru zwierząt: każda oferta pokazuje rolę, opis działania, wszystkich partnerów fuzji i posiadanych partnerów (także ławkę). Osobny bezpłatny podgląd pokazuje aktualne statystyki, skille, początkowe i kolejne cooldowny oraz wynikowe hybrydy. Podgląd dostępny też ze składu i przed połączeniem, bez zmiany wyboru lub zużywania akcji. Liczby pochodzą z Resources; bez zmian balansu.

Skunks przebudowany na ruchomy ślad smrodu (§49 GAME_DESIGN). Skunks, Jeż–Skunks i Skunks–Królik bez basiców; ślad powstaje na rzeczywistej trasie, nie na pozycji celu. Jeż zachowuje kolce i zachwiania, Królik również emituje smród w odskoku. Małpa–Skunks pozostaje dystansowym dostawcą spowalniających chmur. Bez niewrażliwości i sumowania obrażeń własnych chmur. Opisy draftu aktualizowane razem z mechaniką.

v0.6.1: zaakceptowane przenikanie obu drużyn tylko podczas aktywnej emisji śladu smrodu. Nadal trafialny i ogłuszalny; po przerwaniu/końcu przywrócenie kolizji i wolne miejsce. Bez korekty obrażeń/CD. Celowane testy: tests/skunk_phase_tests.gd.

Dodano podsumowanie obrażeń na wyniku każdej rundy i końcu meczu: ranking obu drużyn, TOP RUNDY, rozbicie źródeł, udział, otrzymane obrażenia i przeżycie. Niezależny snapshot zakończonej symulacji. Sprawdzenie w rendererze 1280×720 na 12 jednostkach, kopiach jednostek, wynikach rundy/końcu meczu i resecie nowego meczu; bez zmiany walki.

Czytelność HP: osobna warstwa nad walką, rozsuwanie pasków z łącznikiem i panel ostatniej pary 1v1 z nazwami oraz HP. Sprawdzone obrazy Compatibility 6v6/1v1, celowany test pauzy/resetu/końca, zgodność prezentacji z symulacją. Bez zmian balansu.

Użytkownik odrzucił ostatnią zmianę HP: przywrócono poprzednie paski przy jednostkach, usunięto rozsuwanie i panel 1v1.

Stały blok HP+CD nad głową, wyższa warstwa rysowania i ciemny obrys (§52). Bez automatycznego rozsuwania/łączników/panelu 1v1. Zachowany ślad utraconego HP, stała szerokość paska. Przy górnej krawędzi ograniczenie do areny.


Zatwierdzono i zlecono pełną pulę 8 lvl1, 2 akcje przy 3–5 życiach oraz 3 przy 1–2 życiach. Start ABBA nadal po 2 jednostki. Dodajemy 12 lvl3 według §53 GAME_DESIGN: dwa kompatybilne lvl2 bez wspólnych zwierząt, każdy lvl2 ma 2 partnerów. Cztery odziedziczone mechaniki mogą tworzyć sekwencje/pasywki, bez wymogu 4 oddzielnych skilli. Balans lvl3 roboczy, bez nakazu wygranej nad dowolną parą lvl2.


Implementacja §53 gotowa: 12 Resources lvl3 i 28 definicji faz/skilli, 8 ofert w siatce 4×2, liczba akcji 2/3, fuzja lvl2→lvl3, podglądy partnerów i skilli, oznaczenie III oraz trzy presety lvl3 w Combat Lab. Sekwencje mają wspólny startowy cooldown rodzica; kolejne fazy nie są niezależnymi automatycznymi skillami. A/B zachowuje identyczne nowe lvl3 (brak historycznego wariantu A).
Weryfikacja: import i start Godot PASS; celowane testy lvl3, istniejące testy wariantów i śladu/przenikania Skunksa PASS. Automatyczne interakcje i zrzuty w prawdziwym rendererze Compatibility 1280×720 potwierdziły osiem ofert, 32 podglądy, 24 linki lvl2→lvl3 i zużycie akcji przez fuzję. To nie zastępuje ręcznego playtestu przyjemności ani pełnego balansu. Wyniki dobranych walk: docs/LVL3_RESULTS.md i reports/lvl3/lvl3_simulations_2026-09-25.json.

Naprawa podsumowania obrażeń po zmianie draftu: usunięto wewnętrzne ScrollContainer list jednostek, które zapadały się do zerowej wysokości wewnątrz przewijanej strony. Wiersze zwierząt znów wyznaczają wysokość paneli; przewijana jest cała strona wyniku rundy/meczu. Liczenie obrażeń bez zmian.


2026-09-25: zatwierdzono i wdrożono prywatny mecz online po IP/UDP (24567), host A i gość B. Host waliduje decyzje i prowadzi walkę; gość otrzymuje stan i zdarzenia, bez własnej symulacji. Obustronna gotowość przed walką, kolejnym draftem i rewanżem. Rozłączenie kończy sesję; brak reconnectu i usług zewnętrznych. Szczegóły §54 briefu i docs/ONLINE.md. Poprawiono oddzielne oznaczenie wybranej jednostki i partnera oraz zachowanie przewijania. Balans bez zmian.

Comeback osłabiony decyzją użytkownika: 2 akcje standardowo, +1 tylko raz po spadku do 2 HP i +1 tylko raz po spadku do 1 HP. Osobny stan dla każdego gracza, reset na nowy mecz/rewanż, synchronizacja online; protokół v2 odrzuca starszą wersję zasad. §55 briefu.


2026-09-26: Teamfight Lab — wariant T. Użytkownik zaakceptował próbę sześciu ról (Hipopotam tank, Małpa healer, Jeż osłona, Gepard DPS, Skunks kontrola, Orzeł asasyn), po dwa skille i sytuacyjne AI. Stabilny zamiar przez około 2,5 s, reakcje na zagrożenie, odwrót do osłony i odpuszczanie pościgu zależne od roli. Unik reaguje z opóźnieniem na widoczne zagrożenie, bez nieomylności i niewrażliwości. Osobna próba w Combat Lab, bez przebudowy pełnego meczu/hybryd. §56 briefu, docs/TEAMFIGHT_LAB_V0_1.md. Priorytet: oglądalna współpraca i czytelne ratunki, nie równy damage wszystkich jednostek.


Naprawa wejścia do Combat Lab: ukrywany jest cały panel meczu wraz z pełnoekranowym MarginContainer, który wcześniej pozostawał niewidoczną przeszkodą dla myszy. Dodano bezpośredni przycisk „NOWE: role i ratunki”; wybór wariantu dostępny także w trakcie walki i resetuje próbę. Regresja sprawdzana zdarzeniami kliknięcia, nie samymi wywołaniami metod.


Czytelność walki — zaakceptowane uproszczenie: nad postacią pozostaje tylko HP w kolorze drużyny. Cooldowny z pełnymi nazwami są w jednym panelu po najechaniu na jednostkę, tarcza jako osłona wokół ciała z pęknięciem po zużyciu, bez osobnego paska. Usunięto drobne etykiety ról; rolę nadal pokazuje panel. Roboczy zamach poprzedza trafienie, bez paska decyzji/przygotowania. W T Małpa utrzymuje odstęp za obrońcą, Jeż osłania z niewielkiej odległości; wejście przeciwnika w kontakt nie daje automatycznej ucieczki.

2026-09-26: Użytkownik wybrał kierunek A — Kreskówkowa zadyma, z jeszcze weselszymi postaciami. Miękkie pełne sylwetki, gruby spójny obrys, ciepłe soczyste kolory, przerysowane proporcje, różne komiczne osobowości i sprężysty ruch. Arkusz Hipopotama, Małpy, Orła i Hiporła: docs/art_direction/v0_1/A2-wesola-ekipa-pozy.png. To koncepcje wyglądu i póz, jeszcze nie assety animowane w Godocie; nie zmieniają mechanik.

Wdrożono pierwszą wersję oprawy Kreskówkowa zadyma: atlas wszystkich 32 form, dodatkowe pozy czterech głównych postaci, leśna arena, menu, portrety draftu/fuzji/składów/wyników i motyw UI. Mechaniki bez zmian. To jeszcze nie pełne animacje każdego skilla całego rosteru. Szczegóły i prompty: docs/art_direction/v0_1/IMPLEMENTED.md.

Użytkownik zlecił jednego dopracowanego Hipopotama jako próbę animacji. Wdrożono osobną animację z części (cztery nogi, tułów, głowa, ogon), mimikę/mruganie, chód, przygotowanie ciężkiego ciosu, zsynchronizowane trafienie, reakcje i podgląd w menu z pauzą/slow motion. Dane walki bez zmian; hybrydy nie dziedziczą tego rigu automatycznie. Szczegóły: docs/art_direction/v0_1/HIPPO_ANIMATION.md.

- 2026-09-27: Hipopotam dostał dźwięki kroków, zamachu, trafienia i oberwania, smugę zamachu oraz punktowy błysk kontaktu. Efekty wynikają ze zdarzeń symulacji; bez zmiany balansu. Podgląd zawiera również pudło.

- 2026-09-27: Online IP: widoczny panel statusu, adres i licznik 0–10 s, osobne błędy braku odpowiedzi i uzgadniania wersji, walidacja pustego adresu, blokada ponawiania podczas aktywnej próby. Timeout nie udaje diagnozy routera. Sprawdzono render, timeout/retry i lokalny handshake; nie potwierdza to dostępności przez dwie sieci.

- 2026-09-27: development_view.gd zastępuje stare listy draftu/prep. Układ single-screen 1280×720. Na prośbę użytkownika duże drzewko wyłącznie na jawne otwarcie (i/prawy klik/Y), bez automatycznego hovera. Weryfikacja renderu pełnych składów, przepisów lvl3, callbacków zakupu/fuzji i symulowanych zdarzeń pada; fizycznego pada nie testowano.

- 2026-09-27: Usunięto automatyczne kite'owanie ranged w normalnym symulatorze; do ataku wystarcza wejście w attack_range. Wersja reguł combat-v0.8-no-ranged-kiting, nowy fingerprint sieci (obie strony wymagają nowej paczki). Test czterech rangedów oraz dash Królika i phasing Skunksa: PASS. Poprzednie dane zachowane w reports/balance_before_no_kiting.

2026-09-27: Królik lvl1 przebudowany na skaczącego obrońcę zgodnie z §61 briefu. Osłona 30/4 s, CD5 s, otwarcie2,5 s; bez kumulacji. Jasnoniebieski segment w istniejącym HP. Hybrydy bez zmian.

2026-09-27: Użytkownik zlecił pokoje z kodem przez darmowe EOS, bez Tailscale, wynajmu serwera i ręcznego przekierowywania portów. Device ID bez logowania graczy do Epic, host A prowadzi mecz. Dodano EOSG 2.3.1, pokoje i transport z fragmentacją. Lokalny test dwóch procesów, pełny mecz i eksport Windows PASS; prawdziwe EOS i połączenie przez dwie sieci jeszcze niepotwierdzone. Konfiguracja i zakres: docs/EOS_SETUP.md.

2026-09-27: Po uzupełnieniu konfiguracji potwierdzono prawdziwe logowanie Device ID do EOS, tworzenie lobby, wyszukanie po kodzie, usunięcie lobby i czyste zakończenie procesu. Dodano lifecycle z EOS release/shutdown i usuwanie cyklu referencji lobby/członków EOSG. Dołączenie drugiego komputera, relay oraz mecz przez dwie sieci nadal wymagają testu.

2026-09-27: Użytkownik zaakceptował kierunek więzi między różnymi hybrydami o wspólnych bazowych zwierzętach i zlecił staranne planowanie. Lvl3 może czerpać do czterech bonusów ze wspierającego składu. Plan: docs/GENE_BONDS_PLAN.md. Szczegółowe efekty/liczby pozostają propozycją; nie wdrożono mechaniki ani nie zmieniono ekonomii. Plan obejmuje ryzyko późnego osiągania pełnego buildu i wiele genów aktywowanych przez jedną parę.

2026-09-27: Korekta planu więzi: użytkownik chce bonus także dla dwóch zwykłych zwierząt. Plan upraszcza próg do dwóch osobnych wystawionych jednostek ze wspólnym genem, wliczając lvl1 i identyczne kopie. Fuzje nadal według dotychczasowej macierzy. Zaktualizowano GENE_BONDS_PLAN.md; mechanika jeszcze niewdrożona.

2026-09-27: Użytkownik ustalił kolejność warsztatu: wyraźne role inspirowane Teamfight Lab → genotypy → dominacja rodzica wraz z zachowaniem, możliwymi nazwami i wyglądem. Zlecił prowadzenie pytaniami i kompletowanie dokumentacji. Liczenie lvl1 do genotypów ponownie otwarte; efekty i zachowanie genów przy dominacji nierozstrzygnięte. Osobne buffy/debuffy między rundami poza zakresem. Bieżący rejestr: docs/ROLES_GENOTYPES_WORKSHOP.md. Poprzedni plan więzi jest materiałem do warsztatu, nie finalną specyfikacją.

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

2026-09-28: Zatwierdzono nową macierz 12 par lvl2, po 3 partnerów na zwierzę: Niedźwiedź–Gepard, Niedźwiedź–Małpa, Niedźwiedź–Jeż, Gepard–Królik, Gepard–Hipopotam, Małpa–Skunks, Małpa–Hipopotam, Orzeł–Jeż, Orzeł–Królik, Orzeł–Skunks, Hipopotam–Królik, Jeż–Skunks. Zastępuje starą macierz projektowo, bez edycji Resources na tym etapie. Przepisy lvl3 wymagają przeprojektowania. Kolejna para warsztatu: Gepard+Królik; propozycje niezatwierdzone w HYBRID_DOMINANCE_WORKSHOP.md.

2026-09-28: Gepard+Królik, dominujący Gepard: użytkownik wybrał furię na 5 s, zwiększającą szybkość ataków, dającą wampiryzm i zwiększającą otrzymywane obrażenia. Zastępuje proponowany reaktywny skok z serią. Warunki aktywacji, źródła wampiryzmu i wartości otwarte; wariant dominującego Królika jeszcze niezatwierdzony. Bez implementacji.

2026-09-28: Gepard+Królik: zaakceptowano aktywację 5-sekundowej furii przy gotowym CD i celu w zasięgu, wampiryzm z faktycznie zabranego HP basicami oraz upływ furii podczas stuna; zaakceptowano wygląd wściekłego Geparda z króliczymi uszami. Dominujący Królik: bardzo niski HP, większy damage i attack speed; jego ataki odbijają się na dwa kolejne cele z malejącym damage. Procenty/zasięgi, zachowanie samego odskoku i nazwy otwarte. Bez implementacji.

2026-09-28: Gepard+Królik, dominujący Królik: użytkownik zatwierdził pozostawienie podstawowego obronnego odskoku Królika z cooldownem, bez dodatkowej serii po lądowaniu. Zachowuje papierowy profil i ataki odbijające się na dwa kolejne cele. Bez implementacji.

2026-09-28: Zatwierdzone nazwy Gepard+Królik: Geplik — dominuje Gepard; Króg — dominuje Królik. Mechaniki bez zmian. Bez implementacji.

2026-09-28: Uzupełniono decyzje z okresu dostępu tylko do odczytu. Gepard+Hipopotam: Gehip (dominuje Gepard) to umiarkowanie wytrzymały i mocno bijący bruiser przywołujący Gehipki, maks. 2 żywe na rodzica, uzupełniane po cooldownie. Gehipki mają własne HP, podstawowe ataki melee, bez skilli, pozostają po śmierci rodzica. Hipard (dominuje Hipopotam) wykonuje 3 brykające skoki z lekkim obszarowym ministunem i symbolicznym damage. Małpa+Skunks: Małkuns rzuca przejrzały banan tworzący stacjonarną leczniczą chmurę; Skunpa zostawia ruchomy ślad leczący sojuszników i zadający lekki DOT oraz slow wrogom. Oba warianty leczą tylko innych, własne nakładające się chmury nie mnożą efektu. Nazwy zaakceptowane. Para Małpa+Hipopotam pozostaje niezatwierdzoną propozycją, nie decyzją. Szczegóły i otwarte kwestie: docs/HYBRID_DOMINANCE_WORKSHOP.md. Bez implementacji.

2026-09-28: Para Małpa+Hipopotam zatwierdzona kierunkowo: dominująca Małpa rzuca ciężkiego banana mocno leczącego sojusznika i krótko ogłuszającego pobliskich wrogów. Dominujący Hipopotam zachowuje stomp i zjada ukrytego banana dla self-heala, bez leczenia drużyny. Warunki jedzenia, liczby i nazwy otwarte. Szersza wypowiedź o utracie leczenia drużyny przy niedominującej Małpie wymaga doprecyzowania wobec zatwierdzonych Małpowiedzia i Skunpy; ich nie zmieniono. Bez implementacji.

2026-09-28: Użytkownik potwierdził pozostawienie Małpowiedzia i Skunpy bez zmian, z leczeniem sojuszników. Brak leczenia drużyny i self-heal dotyczy dominującego Hipopotama w parze Małpa+Hipopotam, nie jest globalnym ograniczeniem niedominującej Małpy.

2026-09-28: Zatwierdzone nazwy pary Małpa+Hipopotam: Małpotam — dominuje Małpa; Hipopa — dominuje Hipopotam. Następny warsztat: Orzeł+Jeż; dwa kierunki zapisane w HYBRID_DOMINANCE_WORKSHOP.md wyłącznie jako propozycje. Bez implementacji.
