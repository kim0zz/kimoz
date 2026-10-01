# Combat Prototype v0.1.1 — poprawki po playteście

Data: 2026-09-25. Obowiązujące decyzje: GAME_DESIGN_V0_2.md, sekcja 39.

## Zmiany

- Aktywne umiejętności są zablokowane przez pierwsze 2 sekundy walki. Dotyczy to również dive Orła i warunkowego dashu Królika. Ruch, zwykłe ataki i pasywne kolce działają od początku. To jednorazowa blokada otwarcia, nie wspólny cooldown po każdym skillu.
- Orzeł przed odblokowaniem dive idzie do zwykłego pobliskiego celu. Dopiero później wybiera cel na tyłach. Nie wprowadzono limitu liczby napastników ani wymuszonego podziału celów.
- Żywe jednostki obu drużyn blokują ruch. Lokalne obchodzenie sojuszników pozwala tworzyć front zamiast przenikać przez własną drużynę. Dash i lądowanie uwzględniają również sojuszników; sam lot dive pozostaje wyjątkiem.
- Zasięgi są liczbowe, mierzone między krawędziami ciał. Niedźwiedź dostał zasięg 18 px dla zwykłego ataku i łapy, Królik zachował 8 px. Nie zmieniono HP, obrażeń, szybkości ani powtarzalnych cooldownów.
- Kontrola bez skilli wykryła krążenie Małpy przy ścianie. Poprawiono lokalne obchodzenie: sama ściana nie uruchamia objazdu, więc przyciśnięta do niej jednostka może stanąć i strzelać.

## Weryfikacja

- 326 asercji: 0 błędów. W tym granica blokady 119/120 tick, zwykłe ataki i kolce od startu, cele Orła, dash, kolizje sojuszników, lądowania oraz kontrolne pojedynki Małpy bez skilli.
- Prezentacja i ten sam rdzeń uruchomiony bez okna dają identyczne pełne podsumowanie domyślnej walki przy 0,5×, 1× i 4×: wygrana A, tick 1565, czas 26,083 s. Sprawdzone pauza i niezmienność stanu po końcu walki.
- Dziewięć dodatkowych przebiegów sprawdzanych w każdym kroku: osiem jednorodnych składów 6v6 i domyślny skład mieszany. Brak nakładania fizycznych ciał żywych jednostek na ziemi, brak aktywnego skilla przed 2 s. Lot dive jest celowym wyjątkiem od kolizji.
- W domyślnym składzie w pierwszych 5 s obrażenia otrzymało 8 różnych jednostek; na jednego Orła przypadało maksymalnie 2 jednocześnie wybranych napastników. To obserwacja tego scenariusza, nie gwarancja każdego możliwego składu.
- Sprawdzono obraz ze zwykłego renderera w 8. sekundzie walki. Jednostki tworzą kilka kontaktów na arenie zamiast jednej nakładającej się grupy. Nie wykonywano ręcznego testu wszystkich kontrolek; ich działanie sprawdza test prezentacji.
- Końcowy import i start Godot: PASS.

## Końcowa seria symulacji

1180 scenariuszy, wszystkie zakończone bez przekroczenia limitu diagnostycznego 120 s:

Audyt 1174 porównań lustrzanych: identyczny czas i prawidłowo odwrócony wynik we wszystkich przypadkach. Wszystkie 38 zapisanych hashy plików odpowiada bieżącemu kodowi i danym; brak niewykorzystanych zarejestrowanych okazji do skilla.

- 320 pojedynków 1v1: 140 wygranych A, 140 B, 40 remisów; mediana 12,258 s.
- 12 scenariuszy interakcji: 6 wygranych A, 6 B; mediana 19,275 s.
- 784 walki 6v6: 377 wygranych A, 377 B, 30 remisów; mediana 29,575 s, p90 36,117 s. W przedziale 20–30 s zakończyło się 46,94% walk.
- 64 kontrolne pojedynki bez skilli: 26 wygranych A, 26 B, 12 remisów; mediana 14,975 s.

Pozostają sygnały do późniejszego balansu: Orzeł przeżywa tylko 0,68% występów w 6v6 mimo poprawionego otwarcia, Małpa 54,59%. Składy zawierające Królika wygrywają 40,99%, Małpę 55,27%; to korelacja składu, nie izolowany wpływ jednostki. W 1v1 mocne są Hipopotam (82,5%) i Małpa (77,5%), słabe Skunks (0%), Królik (12,5%) oraz Orzeł (25%). Rola wsparcia nie musi wygrywać pojedynków. Nie wykonywano na tej podstawie dodatkowego strojenia liczb poza zamówionym wariantem zasięgu Niedźwiedzia.

Pełne wyniki i metryki jednostek: `outputs/front_v0_1_1/final.json`, `final_matches.csv`, `final_units.csv` w workspace rozmowy. Hash źródeł serii: `41832f9ce402e96fd92b550ff66592f1534a0e3846c99f549ce4637d575f3ea9`.

## Wygląd i ograniczenia

Obecne rysunki i animacje są placeholderami do prototypowania. Docelowy etap obejmie dopracowane sylwetki, artwork, efekty i animacje zgodne z kierunkiem 2D cartoon. Ta poprawka nie tworzy finalnych assetów. Obrysy, skrzydła i podpisy mogą wykraczać poza fizyczne koła jednostek; typografia i odstępy prezentacji nadal wymagają dopracowania.

Zmiany poprawiają otwarcie i kolizje, ale nie oznaczają zatwierdzenia balansu ani przyjemności oglądania. Wyniki v0.1 pozostają historyczne; do obecnego zachowania należy używać serii v0.1.1. Symulacje są deterministycznym pokryciem scenariuszy, nie estymacją wyników graczy.
