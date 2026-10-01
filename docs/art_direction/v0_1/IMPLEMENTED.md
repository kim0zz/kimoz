# Kreskówkowa zadyma — pierwsze wdrożenie

2026-09-26. Użytkownik zlecił przeniesienie zaakceptowanego stylu do gry.

## Zakres

- Pełne sylwetki wszystkich 8 lvl1, 12 lvl2 i 12 lvl3, wspólne dla walki, draftu, składów i podglądów fuzji.
- Hipopotam, Małpa, Orzeł i Hiporzeł: cztery osobne pozy rysowane. Pozostałe formy: jeden rysunek, ożywiony transformacjami.
- Ruch, oddech, zamach, atak, lot, trafienie, zniknięcie po śmierci. Pozy zwycięstwa dostępne dla czterech postaci w laboratorium.
- Leśna arena, ekran główny z działającymi wejściami do meczu lokalnego, online i laboratorium, wspólny turkusowy motyw i pomarańczowy główny przycisk.
- Portrety również w podsumowaniu obrażeń. Jeden pasek HP; odnowienia nadal po najechaniu. Bez zmian danych walki, AI, kolizji lub balansu.

## Technika i ograniczenia

Grafiki powstały wbudowanym imagegen. Oryginały zachowano, pliki używane przez grę są w assets/cartoon. AtlasTexture odczytuje prostokąty z regions.json; granice wyznaczono z kanału alpha z pominięciem prawie przezroczystego szumu. Nie modyfikowano pikseli skryptem. JSON jest jawnie uwzględniony w eksporcie. Przedziały rzędów hybryd uwzględniają faktyczny układ wygenerowanych arkuszy.

To pierwsze wdrożenie zaakceptowanej oprawy, nie pełna finalna animacja całego rosteru. Pozostałe 28 form nie ma jeszcze osobnych klatek kończyn ani dedykowanych animacji każdego skilla. Efekty skilli nadal korzystają z dotychczasowej prezentacji. Gęste grupy mogą nadal zasłaniać się częściowo: rozmiary kolizji nie zostały zmienione dla grafiki. UI draftu zachowuje obecny układ i przewijanie. Wielkość postaci nie zmienia zasięgów ani hitboxów.

Font nagłówków/przycisków: Lilita One, Google Fonts, SIL OFL; licencja w assets/cartoon/FONT-LICENSE.txt. Źródło: https://github.com/google/fonts/tree/main/ofl/lilitaone

## Weryfikacja

- Godot import i start: PASS.
- Rzeczywisty renderer Compatibility, 1280×720: menu, kliknięcie rozpoczęcia gry, draft, rozpoczęcie walki, Teamfight i galeria 32 form.
- Istniejący test Teamfight UI: PASS (leczenie/osłony, hover, raport, powrót do pełnego meczu B).
- Zrzuty w user://cartoon_*.png, test tests/cartoon_visual_test.gd.
- Bez ponownej masowej kalibracji balansu: brak zmian symulacji.

## Prompty atlasów i areny

### lvl1

Production 2D game sprite atlas for KIMOZ. Reference image is visual style only: happy rounded cartoon animals, warm saturated colors, clean consistent dark brown thick outlines, simple cel shading, full bodies, funny exaggerated proportions, cheerful mischievous faces. Transparent background with real alpha, NO background shadows, NO ground, NO text, NO labels, NO effects, NO borders. Strict equally sized grid, each cell contains exactly ONE full character, centered with feet near bottom, generous 12% transparent padding on every side of each cell, no parts crossing cells. All characters face RIGHT in three-quarter side view, standing idle. Consistent drawing size, readable small. Grid: 4 columns x 2 rows. Row1 left to right: brown chunky BEAR with enormous forepaws; slender golden spotted CHEETAH; orange MONKEY with huge yellow banana and curled tail matching reference; brown-white EAGLE with golden beak matching reference. Row2: round brown HEDGEHOG with chunky spikes; huge happy purple HIPPOPOTAMUS matching reference; cheeky black-white SKUNK with huge raised striped fluffy tail; cream RABBIT with enormous ears and big back feet.

### lvl2

Production 2D game sprite atlas for KIMOZ. Reference image is visual style only: happy rounded cartoon animals, warm saturated colors, clean consistent dark brown thick outlines, simple cel shading, full bodies, funny exaggerated proportions, cheerful mischievous faces. Transparent background with real alpha, NO background shadows, NO ground, NO text, NO labels, NO effects, NO borders. Strict equally sized grid, each cell contains exactly ONE full character, centered with feet near bottom, generous 12% transparent padding on every side of each cell, no parts crossing cells. All characters face RIGHT in three-quarter side view, standing idle. Consistent drawing size, readable small. Grid: 4 columns x 3 rows. Row1: bear+cheetah (bulky golden spotted bear with huge claws); bear+monkey (round brown bear head, monkey body, banana and curled tail); bear+hedgehog (huge brown bear with spiky back); cheetah+eagle (sleek spotted feline body with eagle wings and beak). Row2: cheetah+rabbit (spotted agile cat with huge rabbit ears and feet); monkey+skunk (orange monkey with black-white giant striped tail, rotten green banana); monkey+hippo (fat purple monkey with hippo muzzle and giant banana); eagle+hedgehog (round spiny brown bird with white eagle head and small wings). Row3: eagle+hippo (purple spherical belly cream patch, white eagle eyebrows giant golden beak tiny brown wings golden talons, exactly reference Hiporzel); hippo+rabbit (round purple hippo with tall rabbit ears and springy feet); hedgehog+skunk (round black-white skunk with spiky back); skunk+rabbit (black-white rabbit with long ears and giant striped skunk tail).

### lvl3

Production 2D game sprite atlas for KIMOZ. Reference image is visual style only: happy rounded cartoon animals, warm saturated colors, clean consistent dark brown thick outlines, simple cel shading, full bodies, funny exaggerated proportions, cheerful mischievous faces. Transparent background with real alpha, NO background shadows, NO ground, NO text, NO labels, NO effects, NO borders. Strict equally sized grid, each cell contains exactly ONE full character, centered with feet near bottom, generous 12% transparent padding on every side of each cell, no parts crossing cells. All characters face RIGHT in three-quarter side view, standing idle. Consistent drawing size, readable small. Grid: 4 columns x 3 rows. 12 distinct powerful funny four-animal hybrids, each shows all four specified animal traits. Row1: bear+cheetah+monkey+skunk: bulky spotted bear monkey with banana and striped tail; monkey+skunk+eagle+hedgehog: winged spiky monkey with golden beak, banana, striped tail; eagle+hedgehog+monkey+hippo: huge purple spiny winged monkey hippo with golden beak and banana; monkey+hippo+cheetah+rabbit: fat purple spotted monkey with giant rabbit ears and banana. Row2: cheetah+rabbit+hedgehog+skunk: spotted long-eared spiny runner with striped tail; hedgehog+skunk+bear+monkey: giant spiny bear with monkey face banana and striped tail; bear+monkey+eagle+hippo: massive purple bear-monkey holding banana with eagle wings beak and hippo belly; eagle+hippo+skunk+rabbit: huge purple winged long-eared hippo with striped tail and golden beak. Row3: skunk+rabbit+bear+hedgehog: round huge bear with spikes long ears and striped tail; bear+hedgehog+cheetah+eagle: spotted bear griffin with spikes and golden beak; cheetah+eagle+hippo+rabbit: huge purple spotted griffin with long ears and hippo muzzle; hippo+rabbit+bear+cheetah: enormous purple spotted bear-hippo with long ears and huge front paws.

### arena

Production background for a 2D cartoon animal autobattler, matching reference style of warm friendly cartoon forest. Landscape 1536x1024. NO characters, NO UI, NO text, NO bars. Camera near top down three-quarter. Spacious warm pale sandy oval clearing occupying entire central 85% of image, very flat low detail surface so small colorful characters will read. Only outermost 7% edges decorated with lush rounded forest foliage, big mossy stones, a few tiny daisies, wooden posts with teal cloth at left and coral cloth at right. Soft sunlit friendly daytime, cheerful Saturday cartoon, dark brown ink outlines on perimeter props, simple cel shading. Keep middle extremely quiet pale warm sand. No obstacles anywhere within playable central area.

## Prompt póz

Turn the reference character pose sheet into a clean production sprite atlas on REAL TRANSPARENT background. Preserve EXACT same 4 characters, same 4 poses for each, same happy cartoon art and colors. Strict 4 columns x 4 rows equal size cells on square image. Each individual full body comfortably fits entirely inside its own cell with 12 percent padding on every edge, no neighboring overlap. Row1 purple hippo idle, windup crouch, body slam, laughing victory. Row2 orange monkey with banana idle, banana windup, banana throwing extended arm (NO detached banana), joyful victory. Row3 eagle idle wings half open, takeoff crouch, flight wings raised, laughing victory. Row4 purple hippo-eagle idle, crouching windup, midair leap, squashed landing. Remove ALL ground shadows, dust, speed lines, sparkles, detached projectiles, separators and background. Only the character itself in each of the 16 cells, alpha outside character. This is game art matching source exactly, not a redesign. No text.

Druga iteracja póz zachowała postacie i wymusiła mniejsze ilustracje w regularnej siatce 4×4, zajmujące centralne 65% komórki, z szerokimi przezroczystymi odstępami, bez tła i dodatkowych znaków. Cel: usunięcie fragmentów sąsiednich póz z AtlasTexture.
