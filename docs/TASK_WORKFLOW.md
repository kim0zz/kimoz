# Prowadzenie i odbiór zadania agenta

Ten standard służy małym zadaniom w Kimoz. Priorytety i źródła: [CURRENT_STATE.md](CURRENT_STATE.md). Dobór kontroli: [VERIFICATION_MAP.md](VERIFICATION_MAP.md).

## Ustalenie zadania

Przed implementacją zapisz krótko w planie zadania:

- **Goal**: co gracz ma móc zrobić lub zrozumieć po zmianie.
- **Context**: wariant A/B/T, aktualny stan, właściwe decyzje, dotknięte pliki i ewentualna referencja.
- **Constraints**: zakres, zachowane kontrakty i otwarte decyzje. Priorytet projektu nie jest zleceniem pełnego wdrożenia.
- **Acceptance criteria**: obserwowalne warunki funkcjonalne i jakościowe; oznacz propozycje agenta jako propozycje.
- **Verification**: celowane testy, scena/scenariusz, dowód wizualny i plan playtestu użytkownika.

Nie wymagaj od użytkownika pisania kompletnego prompta. Wyprowadź znane fakty z repo i rozmowy; pytaj tylko o decyzję, której brakuje do konkretnego zadania. Drobne wybory techniczne podejmuj samodzielnie. Gdy wybrana metoda istotnie ograniczy zamierzony efekt, pokaż ograniczenie i propozycję przed rozszerzaniem pracy.

## Kryteria GUI i informacji o drużynie

Dobierz kryteria do zmienianego ekranu; poniższe są punktem wyjścia do zadania, nie nakazem przebudowy całego UI:

- Widać aktywnego gracza, fazę, liczbę pozostałych akcji oraz własne jednostki aktywne i rezerwowe.
- Gracz odróżnia wybór, zgodnego partnera, legalną akcję i akcję niedostępną; przy blokadzie dostaje przyczynę.
- Przed doborem lub fuzją można zrozumieć rolę i mechanikę opcji oraz wynik wyboru; przy docelowym wyborze hybrydy porównać dostępne rezultaty.
- Informacja o drużynie pomaga zobaczyć role, mocne strony i braki. Nie prezentuj arbitralnej liczbowej oceny siły ani gwarancji wygranej bez uzgodnionego modelu.
- Ekran przy 1280×720 nie ucina istotnych kontrolek; sprawdź zatłoczony skład, brak akcji, nielegalną fuzję, wynik i powrót. Dodaj inne rozdzielczości/wejścia, jeśli obejmuje je zadanie.
- Test odbioru: użytkownik potrafi wskazać, co może teraz zrobić i dlaczego, bez dodatkowego tłumaczenia przez autora zmiany. Zapisz miejsca zawahania jako feedback.

## Kryteria animacji i przebiegu walki

Użytkownik zgłosił, że poprzednie działające animacje były zbyt ubogie. Nie ma jeszcze dostarczonej referencji wyznaczającej oczekiwany poziom jakości. Przy pierwszym takim zadaniu dobierz z nim referencję lub przedstaw jeden reprezentatywny pilot z opisem zamierzonego efektu.

- Zacznij od jednej postaci/jednej charakterystycznej akcji. Nazwij metodę: np. animacja części, osobne rysowane klatki lub transformacje pojedynczego obrazka. Nie utożsamiaj tych metod z jednakową jakością.
- Pokaż efekt w skali walki przy 1×, także w grupie; powiększony showcase jest uzupełnieniem.
- Przygotowanie, uderzenie i powrót tworzą czytelny rytm zgodny z charakterem postaci. Ruch powinien pokazywać zamiar i ciężar akcji; sam puls/skala obrazka nie dowodzi spełnienia tego celu.
- Feedback trafienia, pudła, przerwania, tarczy i śmierci odpowiada rzeczywistemu zdarzeniu, gdy dany stan dotyczy akcji. Gracz widzi źródło, cel i skutek istotnej akcji bez zasłonięcia jednostek/HP.
- Sprawdź pauzę i prędkość; prezentacja nie przesuwa momentu zadania damage ani nie dodaje niewpisanej do designu zmiany mechaniki.
- Przed rozszerzeniem metody na roster uzyskaj odbiór jakości pilota. To punkt odbioru konkretnego efektu, nie dodatkowe pytanie o każdą drobną decyzję implementacyjną.

## Dowód i odbiór

Agent wykonuje celowane kontrole techniczne i wymagany import/start. Dla wyglądu/gameplayu dostarcza krótkie nagranie albo porównanie przed/po z tego samego scenariusza, składu, wariantu, seeda i prędkości. Dla statycznego GUI mogą wystarczyć porównawcze zrzuty oraz dowód interakcji. Audio, timing i feeling wymagają nagrania oraz playtestu, nie pojedynczej klatki.

Podaj commit, scenę/scenariusz, faktycznie wykonane kontrole i ograniczenia. Następnie użytkownik ocenia rezultat i robi playtest. Jeśli dowodu nie udało się przygotować, oznacz go jako brakujący; nie zastępuj go deklaracją jakości.

Status raportuj osobno:

- Technika: PASS / FAIL / niewykonane wraz z zakresem.
- Dowód wizualny: przygotowany / brakujący.
- Odbiór użytkownika: oczekuje / zaakceptowany / wymaga poprawy.

Technicznie działająca wersja może oczekiwać na odbiór; nie oznaczaj jej jako jakościowo zaakceptowanej. Historyczny PASS lub wcześniejsza akceptacja stylu nie potwierdza nowej animacji.

## Lekki zapis do późniejszych porównań

W podsumowaniu PR/zadania zapisz: commit bazowy i wynikowy, model i reasoning (gdy dostępne), delegacje, czas, dostępne tokeny/koszt, wynik kontroli, pierwszy odbiór, liczbę iteracji oraz czas interwencji użytkownika. Nieznane wartości zapisuj jako nieznane, nie zero.

Pierwszy odbiór oznacza pierwszą dostarczoną wersję przed poprawkami po feedbacku; wszystkie wewnętrzne próby agenta nadal wliczają się do czasu i kosztu. Oddziel planowany playtest i twórczą zmianę designu od doprecyzowania naprawczego, ponownych ocen i ręcznej naprawy. Zmianę celu w trakcie zadania oznacz jako zmianę zakresu. Koszt delegacji i review należy do kosztu całego workflow.
