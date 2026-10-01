# Warsztat hybryd z dominacją

2026-09-28. Status: projektowanie para po parze, bez implementacji. Pierwsze delivery obejmuje nowe role i dominację; więzi drużynowe pozostają poza zakresem.

## Zatwierdzona macierz lvl2 — 2026-09-28
Zastępuje poprzednią macierz jako projekt nowego rosteru. Obecne Resources gry pozostają niezmienione do implementacji.
1. Niedźwiedź + Gepard
2. Niedźwiedź + Małpa
3. Niedźwiedź + Jeż
4. Gepard + Królik
5. Gepard + Hipopotam
6. Małpa + Skunks
7. Małpa + Hipopotam
8. Orzeł + Jeż
9. Orzeł + Królik
10. Orzeł + Skunks
11. Hipopotam + Królik
12. Jeż + Skunks

Każdy bazowy zwierzak ma dokładnie trzech partnerów. Usunięte pary: Gepard+Orzeł, Orzeł+Hipopotam, Skunks+Królik. Dodane: Gepard+Hipopotam, Orzeł+Królik, Orzeł+Skunks. Omówione pierwsze trzy pary pozostają. Wcześniejsza propozycja dwóch wariantów Gepard+Orzeł jest wycofana z zakresu. Stara macierz lvl3 nie jest zatwierdzoną macierzą nowego rosteru: wymaga przeprojektowania po domknięciu par i zasad dominacji. Nie przenosić automatycznie starych przepisów na nowe formy.

Intencje użytkownika dla późniejszych par: Orzeł+Królik ma pozwolić na bardzo ofensywnego DPS-a, a Orzeł+Jeż zachowujemy dla kierunku doskoku z tarczą. Konkretne warianty jeszcze do warsztatu.

## Zasada i prezentacja wyboru
Użytkownik wybiera jedną z dwóch opcji w oknie „Który genotyp dominuje?”. Dominacja i zachowania mają być spójne z charakterem rodziców oraz wyglądem hybrydy. Każdą parę omawiamy według struktury: dominujący rodzic, rola, basic, skille, słabość, wygląd, robocza nazwa. Akceptacja koncepcji nie oznacza finalnego balansu liczbowego.

Zatwierdzony kierunek UI: podczas wyboru podpowiadamy profil obu wariantów, aby różnica była zrozumiała przed fuzją. Propozycja prezentacji: główna rola i dystans, obrażenia pojedyncze/obszarowe, jedno zdanie o skillu, konkretna słabość; szczegółowe liczby po rozwinięciu. Nie prezentować oceny „lepszy” ani niezweryfikowanych rankingów mocy. Forma UI pozostaje do wdrożenia i oceny.

## Para 1/12: Niedźwiedź + Gepard
Status: użytkownik zaakceptował oba kierunki. Nazwy zatwierdzone przez użytkownika; liczby do kalibracji.

### Niepard — dominuje Niedźwiedź
- Profil: wytrzymały napastnik melee, obrażenia obszarowe.
- Basic: wolniejsze, mocne uderzenia z bliska.
- Skill: krótki zamach, następnie trzy szybkie szerokie ciosy łapami. Niedźwiedź daje siłę i obszar, Gepard tempo serii. Bez stuna.
- Słabość: mała mobilność i przerwa między seriami; trudny dostęp do tyłów.
- Wygląd: masywny niedźwiedź w cętki, długie pazury, ciężki chód i szybkie łapy.
- Zatwierdzona nazwa: Niepard.

### Łapard — dominuje Gepard
- Profil: delikatniejszy DPS melee, obrażenia pojedynczego celu.
- Basic: szybkie ataki z bliska.
- Skill: dwa szybkie cięcia i ciężki kończący cios niedźwiedzią łapą, wszystko w jeden cel. Bez przeskakiwania frontu.
- Słabość: dużo mniejsza wytrzymałość niż wariant Niedźwiedzia; wymaga ochrony, by dokończyć serię.
- Wygląd: smukły gepard z przesadnie dużymi niedźwiedzimi przednimi łapami.
- Zatwierdzona nazwa: Łapard.

## Para 2/12: Niedźwiedź + Małpa
Status: kierunki leczenia i nazwy zatwierdzone; szczegółowe reguły i liczby nadal do domknięcia. Zastępuje wcześniejszą propozycję pojedynczego leczenia obu wariantów. Użytkownik chce bardziej twórczych, ciekawych i zabawnych przekształceń cech rodziców, zamiast tylko dodawania ich podstawowych skilli.

### Małpowiedź — dominuje Niedźwiedź
- Profil: wytrzymała hybryda walcząca z bliska z podtrzymującą aurą leczenia.
- Zatwierdzona mechanika: stale leczy niewielkimi porcjami pobliskich innych sojuszników w obszarze wokół siebie. Zatwierdzone: aura nie leczy właściciela. Wartości i promień do balansu.
- Prezentacja: czytelny glow źródła i faktycznie leczonych jednostek. Użytkownik sugeruje zielony sygnał na HP; dokładna forma do doboru tak, żeby zachować identyfikację drużyny. Efekt otrzymania leczenia powinien odpowiadać rzeczywistemu odzyskaniu HP, nie samemu przebywaniu w aurze.
- Zatwierdzony skill ofensywny: zachowuje stożkowe uderzenie łapą Niedźwiedzia obok aury leczenia. Aura nie zastępuje tego skilla. Bez dodawania stuna.
- Otwarte: działanie podczas stuna, sumowanie kilku aur, dokładny basic, parametry uderzenia i wygląd.
- Zatwierdzona nazwa: Małpowiedź.

### Niedźwipa — dominuje Małpa
- Profil: healer wytrzymalszy od bazowej Małpy.
- Zatwierdzona mechanika: fala/łańcuch leczenia odbijający się między różnymi sojusznikami w ograniczonym zasięgu od healera. Nie jest to równoczesny heal całej grupy. Zatwierdzone: każdy odbiorca może zostać uleczony najwyżej raz przez pojedyncze użycie fali; brak powrotów do wcześniej uleczonego celu.
- Otwarte: samocelowanie, liczba odbić, promień od źródła i dystans między kolejnymi odbiorcami, wybór pierwszego/kolejnego celu, opóźnienie odbić, cooldown i wartość leczenia.
- Propozycja prezentacji: widoczny zielony impuls przechodzący od odbiorcy do odbiorcy, z sygnałem przywróconego HP przy każdym skutecznym leczeniu.
- Wcześniejsza propozycja obronnej łapy nie jest automatycznie zatwierdzona przez wybór nowej fali leczenia.
- Zatwierdzona nazwa: Niedźwipa. Szczegółowy wygląd do dopracowania.

### Granice i pozostałe propozycje
Zatwierdzone: aura leczy tylko innych, a fala odwiedza każdego odbiorcę najwyżej raz na użycie. Cele fali są ograniczone zasięgiem od healera. Propozycja do domknięcia dla fali: brak samoleczenia, wskrzeszania i nadleczenia. Stożkowa łapa dominującego Niedźwiedzia jest już zatwierdzona. Dla Małpy propozycja: fala jako główny skill i słaby basic bez dodatkowej łapy; do potwierdzenia.



## Para 3/12: Niedźwiedź + Jeż
Status: kierunki określone przez użytkownika, parametry i szczegóły do dopracowania. Uwzględnia korektę z poprzedniej, przerwanej odpowiedzi oraz późniejszą zmianę wariantu Jeża.

### Niedźwjeż — dominuje Niedźwiedź
- Zatwierdzona nazwa: Niedźwjeż (dokładna pisownia użytkownika).
- Profil: prawdziwy tank, zwrot Niedźwiedzia w stronę wytrzymałości i odbijania zamiast wysokiego damage.
- Skill: kolczasta tarcza na siebie z mocniejszym odbiciem.
- Pasywka: umiarkowane własne kolce działające stale, niezależnie od tarczy.
- Podstawowy atak zgodnie ze wspólną zasadą rosteru; liczby do kalibracji.
- Dawny pomysł wzmacnianego pochłoniętymi obrażeniami zamachu nie jest częścią zatwierdzonego kierunku. Zachowanie osobnej stożkowej łapy wymagałoby osobnej decyzji; nie dokładamy jej automatycznie.
- Otwarte: dokładna relacja pasywnego odbicia do odbicia tarczy (sumowanie albo zastąpienie), rodzaje trafień dla pasywki, czasy i liczby, finalny wygląd.

### Jeżdźwiedź — dominuje Jeż
- Nazwa według najnowszej wiadomości użytkownika: Jeżdźwiedź; zastępuje wcześniejsze robocze warianty nazwy.
- Profil: protektor z leczeniem w czasie, niski własny damage.
- Skill 1: dotychczasowa kolczasta tarcza nadawana sojusznikowi — pochłania obrażenia i odbija procent faktycznie pochłoniętych obrażeń bezpośrednich. Bez odbić od DOT i innych odbić.
- Skill 2: nakłada na sojusznika niedźwiedzie futerko, które przywraca HP przez pewien czas (HOT).
- Dwa niezależne cooldowny. Każdy skill wybiera potrzebującego odbiorcę; mogą działać na różnych sojusznikach albo oba na tym samym, jeśli sytuacja tego wymaga. Nie łączymy ich w obowiązkową wspólną sekwencję ani jeden cooldown.
- Rezygnujemy z wcześniej proponowanej eksplozji kolców przy pęknięciu osłony.
- Zachowuje drobny basic. Własne lekkie kolce z bazowego Jeża były elementem poprzedniej propozycji; ich obecność w finalnym wariancie do doprecyzowania.
- Zatwierdzone: tarczę może nakładać na siebie, z priorytetem potrzebujących sojuszników. Futerko również może nakładać na siebie przy niskim HP, z pierwszeństwem potrzebujących sojuszników. Dokładny próg niskiego HP do kalibracji.
- Otwarte: czas/ilość leczenia, cooldowny, ponowne nakładanie futerka i osłony, priorytet rozpoczęcia gdy oba skille są gotowe, próg niskiego HP dla własnego futerka, wygląd i czytelny feedback.

Różnica: Niedźwjeż chroni własne ciało i karze napastników, Jeżdźwiedź rozdziela ochronę i regenerację między sojuszników. Leczące futro to jawnie wybrany przez użytkownika motyw tej hybrydy; nie nadaje leczenia bazowemu Niedźwiedziowi ani wszystkim jego hybrydom.


## Para 4/12: Gepard + Królik
Status: oba kierunki określone przez użytkownika. Zasady furii i jej wygląd zatwierdzone; nazwy zatwierdzone, liczby i szczegóły odbić do domknięcia.

### Geplik — dominuje Gepard
- Profil: ofensywny melee berserker; szybkie ataki i samoleczenie kosztem większej podatności na obrażenia.
- Skill: furia przez 5 sekund zwiększa szybkość ataków, daje wampiryzm i zwiększa otrzymywane obrażenia.
- Zatwierdzone: aktywuje przy gotowym cooldownie i przeciwniku w zasięgu ataku. Wampiryzm jest procentem HP faktycznie odebranego podstawowymi atakami, bez leczenia od obrażeń zatrzymanych tarczą, overkillu, DOT i odbić. Zegar pięciu sekund płynie również podczas ogłuszenia.
- Zatwierdzony wygląd: nastroszony gepard z króliczymi uszami; podczas furii kładzie uszy i szaleńczo przebiera łapami.
- Zastępuje wcześniejszy pomysł reaktywnego skoku za napastnika i serii trzech cięć.
- Otwarte: cooldown i pierwsza gotowość, bonus szybkości, procent wampiryzmu, mnożnik i zakres źródeł zwiększonych otrzymywanych obrażeń.
- Użytkownik w pytaniu użył „tygrys”; kontekst dotyczy dominującego Geparda w tej parze, nie zmiany bazowego gatunku.

### Króg — dominuje Królik
- Zatwierdzony profil: bardzo niski HP, wyższe obrażenia i szybkość ataku; papierowy DPS dystansowy. Wartości i dokładny punkt odniesienia do kalibracji.
- Ataki odbijają się od pierwszego celu na dwa kolejne: drugi otrzymuje sporą część damage, trzeci mniejszą. Maksymalnie trzy trafione cele jednym atakiem. Procenty i zasięg odbicia otwarte.
- Propozycja do potwierdzenia: trzy różne cele, każdy najwyżej raz na pocisk, brak ponownego odbicia do wcześniej trafionego przeciwnika. Jeżeli nie ma kolejnego legalnego celu, łańcuch kończy się; nie skupia niewykorzystanych obrażeń na pierwszym.
- Zatwierdzone: zachowuje podstawową mobilność Królika — obronny odskok przy zbliżeniu wroga, z cooldownem, bez niewrażliwości. Bez dodatkowej serii trzech marchewek po lądowaniu. Odbijające się ataki działają niezależnie od odskoku.
- Wygląd propozycja: smukły królik w cętki z gepardzim ogonem. Zatwierdzona nazwa: Króg.

Kontrast: dominujący Gepard musi atakować w zwarciu, by podtrzymywać się wampiryzmem podczas furii; dominujący Królik z dystansu rozprowadza obrażenia po kilku przeciwnikach, ale jest bardzo łatwy do zabicia po dopadnięciu. Bez implementacji.



## Para 5/12: Gepard + Hipopotam
Status: kierunki i nazwy zatwierdzone podczas rozmowy przy dostępie tylko do odczytu; uzupełniono 2026-09-28. Zastępuje wcześniejsze propozycje finiszera głową, szarży z odpychaniem oraz pojedynczego galopu.

### Gehip — dominuje Gepard
- Zatwierdzona nazwa: Gehip.
- Profil: bruiser melee, niezła wytrzymałość i obrażenia bez skrajności.
- Skill: przywołuje dwa małe Gehipki walczące z drużyną.
- Limit: maksymalnie dwa żywe Gehipki na przywoływacza. Po cooldownie uzupełnia brakujące: przy jednym żywym przywołuje jednego, przy braku dwóch; nie dokłada kolejnych przy dwóch żywych.
- Gehipki mają własne HP, podstawowe ataki melee i żadnych dodatkowych skilli. Po śmierci rodzica pozostają i walczą dalej; należy je pokonać, żeby wybić drużynę.
- Przywołania powstają tylko na czas walki i nie zajmują miejsc draftowanego składu (założenie przedstawione w warsztacie, bez trwałego rekrutowania przywołań).
- Otwarte parametry: statystyki rodzica i Gehipków, pierwsza gotowość, cooldown, zasięg/pozycje przywołania, targetowanie. Brak niewidzialnego automatycznego buffa od liczby Gehipków.
- Wygląd propozycja: małe pękate gepardy z hipopotamimi pyskami; dokładna sylwetka rodzica do projektu.

### Hipard — dominuje Hipopotam
- Zatwierdzona nazwa: Hipard.
- Profil: wytrzymały tank z kontrolą obszaru i symbolicznym damage.
- Skill: brykanie — trzy skoki; każde lądowanie powoduje lekki obszarowy ministun i symboliczne obrażenia.
- Propozycja wykonania do domknięcia: krótkie skoki w okolicy aktualnego celu, bez automatycznego przerzucania na tyły. Przerwy między lądowaniami powinny pozwalać przeciwnikom działać; dokładne czasy niezatwierdzone.
- Otwarte: wybór miejsca każdego skoku, reakcja na śmierć celu/przerwanie, cooldown, pierwszy cooldown, promień i długość ministuna. Basic i jego liczby do kalibracji.

## Para 6/12: Małpa + Skunks
Status: oba kierunki, nazwy i wspólne granice leczenia zatwierdzone przez użytkownika. Parametry liczbowe do kalibracji.

### Małkuns — dominuje Małpa
- Zatwierdzona nazwa: Małkuns.
- Profil: healer obszarowy, wsparcie z dystansu.
- Basic: słabe rzuty bananami.
- Skill: rzuca przejrzały banan w okolice rannego sojusznika. Banan tworzy stacjonarną leczniczą chmurę; sojusznicy w jej obszarze odzyskują HP przez pewien czas.
- Chmura pozostaje w miejscu, nie śledzi odbiorcy. Jednostka wychodząca z niej przestaje korzystać z leczenia.
- Słabość: drużyna może wyjść z obszaru; najlepiej wspiera utrzymującą się w jednym miejscu walkę.
- Kierunek wyglądu zaakceptowanej propozycji: małpa z puszystym skunksim ogonem, korzystająca z podejrzanie zgniłych bananów.

### Skunpa — dominuje Skunks
- Zatwierdzona nazwa: Skunpa.
- Profil: mobilne wsparcie i kontrola obszaru, niewielkie obrażenia.
- Basic: drobny atak z bliska.
- Skill: ruchomy ślad pomaga sojusznikom i szkodzi przeciwnikom. Sojusznicy w chmurach otrzymują niewielkie leczenie, wrogowie lekki DOT i spowolnienie ruchu.
- Słabość: wartość zależy od faktycznej trasy biegu i położenia jednostek; nie gwarantuje natychmiastowego ratunku wybranego sojusznika.
- Kierunek wyglądu zaakceptowanej propozycji: Skunks z długimi małpimi rękami i ogonem rozprowadzającym „aromaterapię”.

### Zatwierdzone zasady wspólne
- Leczą wyłącznie innych sojuszników, nigdy siebie.
- Własne nakładające się chmury tej samej jednostki nie mnożą efektu leczenia ani obrażeń; spowolnienie nie jest sumowane.
- Dokładne wartości, promienie, czas chmur, cooldowny, wybór miejsca rzutu Małkunsa i trasy Skunpy do specyfikacji. Interakcje chmur różnych właścicieli oraz działanie po śmierci źródła pozostają do doprecyzowania; nie zakładamy ich zatwierdzenia.

## Para 7/12: Małpa + Hipopotam
Status: oba kierunki zatwierdzone przez użytkownika. Nazwy zatwierdzone; parametry otwarte. Bez implementacji.

### Małpotam — dominuje Małpa
- Zatwierdzona propozycja: wytrzymalszy healer, mocny ratunek pojedynczego celu, słabe rzuty bananami jako basic.
- Po widocznym przygotowaniu rzuca wielkiego ciężkiego banana do rannego sojusznika: mocne leczenie odbiorcy i niewielka fala uderzeniowa krótko ogłuszająca pobliskich przeciwników.
- Słabość: rzadsze leczenie i ryzyko spóźnienia ratunku.
- Wygląd: pękata małpa z hipopotamim pyskiem ciskająca wielkim bananem.
- Otwarte: cooldown, pierwsza gotowość, leczenie, promień i czas stuna, zasięg rzutu i obsługa utraty celu.

### Hipopa — dominuje Hipopotam
- Zatwierdzony kierunek: tank z samoleczeniem, bez leczenia drużyny. Wybór tej dominacji w tej parze oznacza rezygnację ze wsparcia leczniczego Małpy dla innych.
- Zachowuje stomp sprzed fuzji: krótkie ogłuszenie obszarowe, uruchamiane przy gotowym cooldownie i wrogu w zasięgu, bez czekania na specjalną okazję.
- Dodatkowa umiejętność: wyciąga ukrytego banana i zjada go, przywracając sobie HP. Nie leczy innych; heal nie wynika z liczby wrogów trafionych stompem.
- Basic pozostaje zgodnie z regułą wszystkich ról; niski ofensywny profil tanka.
- Zastępuje wcześniejszą propozycję leczenia sojusznika za wrogów trafionych tupnięciem.
- Otwarte: warunek zjedzenia banana, ilość leczenia, cooldown, czas animacji i przerwanie jedzenia, priorytet względem stompa. Ostateczny wygląd do dopracowania.

### Zakres decyzji o utracie leczenia drużyny
Użytkownik potwierdził: Małpowiedź i Skunpa pozostają bez zmian i nadal leczą sojuszników. Utrata leczenia drużyny na rzecz samoleczenia dotyczy dominującego Hipopotama w parze Małpa+Hipopotam. Nie wprowadzamy globalnego zakazu leczenia sojuszników przy niedominującej Małpie.


## Para 8/12: Orzeł + Jeż
Status: propozycja do warsztatu, niezatwierdzona. Wynika z intencji użytkownika zachowania tej pary dla doskoku z tarczą. Nazwy do ustalenia.

### Dominuje Orzeł — propozycja
- Profil: wytrzymalszy diver atakujący tyły, niższy burst niż czysto ofensywne warianty Orła.
- Skill: skok na najdalszego przeciwnika z bezpośrednim trafieniem; przy rozpoczęciu skoku dostaje własną kolczastą tarczę pochłaniającą obrażenia i odbijającą część pochłoniętych obrażeń bezpośrednich.
- Między skokami zwykłe ataki melee. Bez niewrażliwości; po zużyciu tarczy pozostaje narażony na skupienie ataków. Nie dodajemy stuna.
- Wygląd: orzeł z kolczastymi piórami, przy skoku otoczony nastroszoną osłoną.

### Dominuje Jeż — propozycja
- Profil: mobilny protektor docierający do zagrożonych sojuszników.
- Skill: skacze do zagrożonego sojusznika i po lądowaniu nadaje mu oraz sobie kolczastą tarczę. Ląduje obok, od strony zagrożenia, jeśli jest legalne miejsce; nie gwarantuje przechwycenia pocisków ani zmiany aggro.
- Drobne ataki melee między użyciami. Bez niewrażliwości, leczenia i stuna. Warunki samodzielnego użycia bez żywych sojuszników do warsztatu.
- Wygląd: kulisty Jeż z za małymi skrzydłami, lądujący ciężko obok chronionego kumpla.

Kontrast do oceny: Orzeł używa kolców do przeżycia ofensywnego wejścia, Jeż skrzydeł do dostarczenia ochrony. Wartości tarcz, odbić, cooldowny i samocelowanie nieustalone.
