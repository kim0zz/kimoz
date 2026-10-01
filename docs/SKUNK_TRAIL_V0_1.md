# Skunks — ruchomy smród v0.1

## Zmiana

Skunks, Jeż–Skunks i Skunks–Królik nie wykonują basiców. Zbliżają się do przeciwnika i obiegają go także pomiędzy aktywnymi użyciami. Aktywny skill zostawia chmury w rzeczywistych pozycjach po rozliczeniu ruchu. Chmury utrzymują się po odejściu/śmierci autora; własne nakładające się obszary nie mnożą obrażeń. Stun blokuje ruch i emisję, a zachwianie opóźnia akcję. Zwykły bieg respektuje kolizje. Odskok Skunksa–Królika ma dodatkową emisję z osobnym czasem życia chmur, dłuższym niż lot.

Małpa–Skunks pozostaje ranged ze zgniłymi bananami i spowolnieniem. Nie dodano spowolnienia innym Skunksom. Zachowano pasywne kolce oraz zachwiania Jeża–Skunksa. Historyczny wariant A przywraca stare zachowania ranged, B i pełny mecz używają nowych.

## Liczby robocze

- Skunks: 6 obrażeń / 0,5 s, chmura 2,5 s, promień 75 px; bieg z emisją 2,5 s co 6 s, pierwsza gotowość 3,5 s.
- Jeż–Skunks: 6,6 / 0,5 s, chmura 2,5 s; zachwianie 0,12 s i pasywne kolce. Zwiększenie 6 → 6,6 wynika z porażki przeciw samotnej Małpie w ustawieniu offset (Małpie zostało 6 HP).
- Skunks–Królik: 6 / 0,4 s, chmura 2,4 s. Odskok dodatkowo zostawia chmury 4 / 0,35 s, trwające 1,4 s.

## Weryfikacja i ograniczenia

Sprawdzono prezentację w rzeczywistym rendererze Compatibility i zgodność symulacji z prezentacją. Testy mechaniki obejmują brak basiców, poruszanie, ślad w kolejnych pozycjach, blokadę początkową, kontrolę tłumu i emisję przy odskoku. Nie przeprowadzono ręcznego playtestu ani odsłuchu.

Próba drużynowa: sześć kontekstów 2v2/3v3/6v6, pięć podmienianych hybryd, lustra — 60 walk. Po korekcie Jeża powtórzono jego 12 walk. Średnie obrażenia nowych Jeża–Skunksa i Skunksa–Królika wynoszą około 103 i 101. W poprzednim zachowaniu osiągały około 166 i 161 w tych kontekstach. To sygnał utraty siły po odebraniu basiców, nie finalny balans. Nie wyrównywano ich arbitralnie do Małpy–Hipopotama. Obecny etap oddaje nowy sposób gry do oceny; wpływ na wartość draftu i relacje z parami lvl1 wymaga dalszego playtestu.

Starsze testy specyficznie wymagające ranged basiców i stacjonarnej chmury bazowego Skunksa opisują poprzedni design; dla przebudowanej mechaniki punktem odniesienia jest `tests/skunk_trail_tests.gd`.

Końcowe sprawdzenie: 19 testów mechaniki PASS, import/start Godot PASS. Finalne 156 przypadków obejmuje dwie zmienione hybrydy przeciw wszystkim lvl1 oraz pozostałe lvl2 przeciw nowemu Skunksowi: wszystkie wygrywa lvl2, 78 zgodnych par lustrzanych, bez utknięć i nakładania na starcie. Hash źródeł stabilny. Raport: `reports/skunk_rework/final_singles.json`. Pola REVIEW dotyczące par/trójek i macierzy lvl2 w tym raporcie nie były badane i nie stanowią wyniku tych rodzin.
