# Prywatny mecz online

Gra obsługuje prywatny mecz dwóch osób przez bezpośrednie połączenie IP. Gospodarz gra jako **Gracz A**, a osoba dołączająca jako **Gracz B**. Gospodarz zatwierdza akcje i prowadzi symulację meczu. Gra nie wymaga konta i nie ma matchmakingu ani serwera pośredniczącego.

## Uruchomienie gry

1. Rozpakuj `kimoz-windows-x64.zip` do wybranego folderu.
2. Uruchom `kimoz.exe`. Nie trzeba instalować Godota.
3. Obie osoby muszą użyć tej samej wersji gry.

## Połączenie

1. W menu gry wybierz **Graj online**.
2. Gospodarz wybiera **Utwórz mecz**. Domyślny **Port UDP** to `24567`. Gra pokaże lokalne adresy IP komputera gospodarza; gospodarz czeka na znajomego.
3. Druga osoba wpisuje adres IP gospodarza i ten sam port UDP, po czym wybiera **Dołącz**.
4. Po połączeniu obie osoby grają w jednej wspólnej partii. Przed walką każdy wybiera **GOTOWY DO WALKI**. Po wyniku rundy wybierzcie **GOTOWY — DALEJ**. Gra przechodzi dalej, gdy obie osoby zatwierdzą.

W tej samej sieci domowej gość może wpisać lokalny adres IP gospodarza widoczny w oknie połączenia. Przy połączeniu przez internet gospodarz musi zezwolić grze na ruch przychodzący w zaporze systemowej oraz przekierować **UDP 24567** z routera na lokalny adres IP swojego komputera, port `24567`. Gość wpisuje publiczny adres IP gospodarza. Nie twórz reguły TCP — gra używa UDP.

Podczas walki gospodarz może wstrzymać lub wznowić grę oraz zmienić jej szybkość. Po każdej walce ekran wyniku pokazuje podsumowanie obrażeń obu drużyn.

## Ograniczenia połączenia

Gospodarz musi być osiągalny na porcie UDP `24567`. Przy CGNAT samo przekierowanie portu w routerze nie wystarczy; potrzebny jest publiczny adres IP od dostawcy internetu. Połączenie nie zadziała też w sieciach blokujących UDP. Gra nie ma serwera pośredniczącego ani automatycznego obchodzenia NAT.

Jeśli ktoś się rozłączy, bieżący mecz zostaje przerwany. Nie można wznowić przerwanej partii. Po ponownym połączeniu rozpoczyna się nowy mecz.

Połączenie sprawdzono lokalnie na `127.0.0.1`. Test połączenia przez internet, w tym konfiguracji routera i CGNAT, nie został wykonany.

## Pokoje przez EOS — nowa implementacja
Menu zawiera tworzenie pokoju i dołączanie kodem. Wymaga jednorazowej konfiguracji autora opisanej w EOS_SETUP.md. Dotychczasowe IP/UDP pozostaje w rozwijanej sekcji. Testy lokalne oraz eksport Windows przeszły; połączenie przez prawdziwe EOS wymaga jeszcze konfiguracji i weryfikacji na dwóch komputerach.
