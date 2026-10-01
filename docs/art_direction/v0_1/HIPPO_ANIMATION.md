# Hipopotam — animacja z części v1

Zakres zlecony przez użytkownika: jeden Hipopotam jako próba wyższej jakości ruchu, zintegrowany z walką.

## Implementacja

- Osobna scena `scenes/units/hippo_rig.tscn`: cztery poruszane niezależnie nogi, tułów, głowa i ogon.
- Rysowane części i pięć wariantów mimiki: spoczynek, wysiłek, radość/krzyk, mrugnięcie, oberwanie. Raster wygenerowany wbudowanym imagegen, alpha zachowana.
- Chód zależy od przebytej drogi. Osobne fazy nóg, unoszenie stopy, kołysanie tułowia, opóźniona głowa i ogon, niewielki kurz spod nóg.
- Ciężki cios: obniżenie tułowia i cofnięcie ciężaru, podniesienie przedniej nogi, przyspieszenie pod koniec zamachu, uderzenie głową/ramieniem, deformacja brzucha i wygaszany powrót. Parametry czasu odczytywane z prawdziwej akcji/skilla.
- Potwierdzone trafienie daje akcent i krótko utrzymaną pozę; pudło nie generuje iskier trafienia. Zmienia się tylko prezentacja, bez odrzutu lub pauzy symulacji.
- Trafienia zwykłe i skille: flinch. DOT ograniczony, aby nie powodować ciągłego szarpania. Ogłuszenie przerywa prezentację zamachu. W wariancie T osłona/prowokacja mają gest obronny, nie udają ofensywnego ciężkiego ciosu.
- Podgląd w menu: „HIPOPOTAM • ANIMACJE”. Sekwencja i wybór stanów, pauza, tempo 1×/0,35×, postać powiększona oraz w skali walki. Podgląd jest inscenizacją animacji; w meczu sterują nią prawdziwe dane.
- Animowany Hipopotam także na ekranie głównym. Pozostałe zwierzęta i hybrydy nie zostały przebudowane.

## Weryfikacja

Godot Compatibility 1280×720: renderer i klatki wszystkich stanów. Test niezależnego ruchu nóg względem tułowia, zatrzymania przy tej samej próbce czasu oraz synchronizacji prawdziwego heavy hit w walce Hipopotam–Niedźwiedź. Istniejący test draft→walka i Teamfight UI również PASS. Nagrano 12 sekund / 720 klatek w silniku; przegląd klatek sekwencji i eksport MP4: reports/hippo-animation.mp4.

## Granice tej wersji

To animacja wycinankowa z rysowaną mimiką, nie ręcznie rysowana klatka po klatce. Postać obraca się w lewo/prawo; nie ma osobnych widoków pleców. Nogi mają pojedyncze segmenty, bez pełnego szkieletu stawów kolanowych. W normalnym meczu Hipopotam zachowuje dotychczasowe liczby i skilla; healerzy pozostają osobną próbą T. Podgląd ułatwia ocenę jakości bez rozszerzania tej metody na resztę rosteru przed playtestem.

## Assety

`assets/cartoon/hippo/parts.png`, `faces.png`; regiony atlasów są stałymi w hippo_rig.gd. Pliki PNG nie były modyfikowane skryptem. Prostokąty wyznaczono odczytem kanału alpha. Oryginały imagegen zachowano.

## Heavy hit audio / contact — 2026-09-27
Original synthesized WAV foley (tools/make_hippo_audio.py), shared four-channel voice budget. Grunt and swish follow active windup; impact only follows positive damage. Directional contact flash replaces the generic heavy ring. Stunned targets sway for their actual stun duration. Showcase includes Pudło. Playback follows pause and simulation speed. Tests cover real damage/audio/contact synchronization, zero damage, miss and pause. Audio samples checked for clipping; subjective mix requires player feedback.
