# Kimoz — zasady pracy

- Rozmawiaj z użytkownikiem po polsku.
- To projekt Godot 4.7.2, GDScript, gra 2D. Zachowaj renderer Compatibility.
- Przed pracą nad grą przeczytaj cały `GAME_DESIGN_V0_2.md`: to nadrzędna specyfikacja projektu Auto Battler Zoo. W razie rozbieżności z wcześniejszymi notatkami obowiązuje ten brief oraz późniejsze wyraźne decyzje użytkownika.
- `docs/kierunek.md` zawiera kontekst techniczny. Wcześniejsze pomysły latarnika i wędrownej osady nie są częścią projektu.
- Realizuj zlecony zakres. Podejmuj drobne decyzje techniczne samodzielnie; nie dodawaj niezamówionych mechanik ani fabuły.
- Zapisuj zaakceptowane decyzje o stylu i mechanikach w `docs/kierunek.md`.
- Używaj scen `.tscn`, zasobów `.tres` i typowanego GDScript. Ścieżki zasobów zapisuj jako `res://`.
- Sceny: `scenes/`; skrypty: `scripts/`; grafika i audio: `assets/`; dane: `resources/`.
- Nie edytuj wygenerowanego katalogu `.godot/`. Zachowuj pliki `.uid` generowane przez Godot.
- Nie kupuj assetów ani nie podłączaj płatnych usług bez zlecenia użytkownika.
- Po zmianach uruchom `powershell -NoProfile -ExecutionPolicy Bypass -File tools/godot.ps1 check`.
- Sprawdzenie headless nie zastępuje oceny wyglądu i ręcznego testu interakcji. Informuj, co faktycznie przetestowano.
- Projekt może być otwarty w Godot. Przed zmianami ponownie odczytaj pliki; nie nadpisuj niezapisanej pracy w edytorze.
- Zainstalowano Godot MCP Toolkit 1.0.2; serwer Codex: `godot-kimoz`. Używaj MCP do odczytu stanu otwartego edytora i operacji wymagających edytora, plików i terminala do kodu oraz kontroli headless. Bez automatyzacji kursora jako podstawy pracy.
- Przed operacjami MCP potwierdź, że połączenie dotyczy „kimoz”. Kod dodatku w `addons/godot_mcp_toolkit/` jest zależnością zewnętrzną; nie modyfikuj go przy zwykłych zmianach gry.
