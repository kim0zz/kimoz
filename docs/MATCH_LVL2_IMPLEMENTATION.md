# Lokalny mecz i hybrydy lvl2

## Co działa

- F5 uruchamia mecz dwóch graczy przy jednym komputerze; Combat Lab pozostaje dostępny przyciskiem.
- Początkowe cztery wspólne oferty, wybory ABBA i po dwie jednostki na gracza.
- Kolejne drafty bez uzupełniania puli: wybór jednostki lub fuzja za jedną akcję; dodatkowe akcje przy dwóch i jednym życiu.
- Pięć żyć, przegrany zaczyna następny draft, remis zachowuje życia i pierwszeństwo, zero żyć kończy mecz.
- Sześć aktywnych jednostek i trzy na ławce; bezpłatne zarządzanie oraz odrzucanie, także zwalnianie miejsca przed wyborem z pełnym składem.
- Dwanaście nieodwracalnych fuzji. Interfejs pokazuje nazwę wyniku przed połączeniem. Rodzice są zużywani, hybryda zajmuje jedno miejsce.
- Wszystkie zatwierdzone skille lvl2: serie stożków, dodatkowe banany, kolce, potrójny dive, serie po dashu, chmury DOT i slow, ciężkie pociski/stuny i boczny unik.
- Nowa walka resetuje HP, statusy i cooldowny; zachowuje posiadany skład oraz początkową blokadę aktywnych skilli przez dwie sekundy.

## Technicznie

Reguły meczu są oddzielone od sceny w `scripts/match/match_model.gd`. Scena meczu korzysta z istniejącego kontrolera walki. Widok, testy i balans korzystają z tego samego rdzenia symulacji. Parametry hybryd są w `resources/hybrids/` i `resources/hybrid_skills/`; nie dodano specjalnej reguły przyznającej zwycięstwo na podstawie poziomu.

Potrójny dive zapisuje oś podejścia na początku serii. Nie odczytuje zmieniającego się w tym samym ticku kierunku patrzenia przeciwnika; dzięki temu odbicie stron nie zmienia toru skoku. Osobna regresja porównuje pozycje i HP na każdym ticku dwóch znalezionych problematycznych matchupów.

## Weryfikacja

- Pełna regresja silnika: 326 asercji, zero błędów.
- Celowane testy mechanik hybryd oraz dokładnej symetrii potrójnego skoku: 27 sprawdzeń, zero błędów.
- Test modelu meczu: akcje, priorytet, pas, fuzja, limity ławki, zamiana, pełny skład, comeback i pięć porażek do końca meczu.
- Test podłączenia sceny i przycisków; rzeczywisty renderer 1280×720 dla draftu, przygotowania i walki.
- Pełne podsumowanie walki zgodne z symulacją bez okna przy prędkościach 0,5×, 1× i 4×.
- Odrębne serie liczbowe specjalisty od balansu: [wyniki i korekty](LVL2_BALANCE_REPORT.md).
- Końcowa seria: 1996 scenariuszy, zero utknięć. Wszystkie 576 pojedynków lvl2–lvl1 wygrywa lvl2; pary lvl1 wygrywają 98/864, hybrydy wygrywają z trójkami 10/72. Niezależnie zweryfikowano zgodność wszystkich hashy plików oraz 998 lustrzanych par, także kontroli mechanik.
- Końcowy import i start projektu w Godot: PASS.

## Granice tego etapu

Wygląd pozostaje proceduralnym placeholderem, z cechami obojga rodziców i oznaczeniem II. Duże podpisy i efekty mogą się na siebie nakładać mimo rozdzielenia ciał. Finalne zabawne sylwetki i animacje wymagają osobnego etapu graficznego.

To lokalny prototyp bez online, lvl3, golda i meta progression. Kalibracja opisuje konkretne pełnozdrowe składy i geometrie; nie jest dowodem zwycięstwa dla każdego możliwego stanu walki ani oceną przyjemności grania. Remisy zachowują zatwierdzoną zasadę bez utraty życia.
