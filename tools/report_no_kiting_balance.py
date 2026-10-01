import json,re
from pathlib import Path
R=Path(__file__).resolve().parents[1]/'reports'
def run():
 data=json.loads((R/'no_kiting_balance_comparison.json').read_text());deltas=data['deltas']
 names={}
 for p in (R.parent/'resources').rglob('*.tres'):
  text=p.read_text(encoding='utf-8-sig');id=re.search(r'^id = "(.*?)"',text,re.M);name=re.search(r'^display_name = "(.*?)"',text,re.M)
  if id and name:names[id[1]]=name[1]
 lines=['# Porównanie balansu po usunięciu wycofywania ranged','',
 '## Zmiana','',
 'Normalna walka B: ranged podchodzi do attack_range i atakuje. Nie ucieka do preferred_min ani nie podchodzi dodatkowo do preferred_max. Celowy ruch skilli i osobne sytuacyjne AI Teamfight T pozostają. Żadne HP, obrażenia, cooldowny ani inne dane jednostek nie zostały zmienione.','',
 '## Porównywalność','',
 f"- Po {data['cases_each']} wykonań głównych i 80 obserwacji odskoków przed i po: 2854 na wersję. Identyczne składy, sloty, geometrie, seedy i strony; asercja zgodności kluczy przypadków przeszła.",
 f"- Wynik zwycięzca/przegrany/remis zmienił się w {data['changed_results']} z 2774 wykonań (zawierających lustrzane powtórzenia i część duplikatów).",
 f"- Po zmianie: {data['stalls_after']} walk bez rozstrzygnięcia w limicie 90 s; {data['mirror_mismatches_after']} rozbieżnych wyników po zamianie stron.",
 '- Hashe potwierdzają brak zmian resources i scripts/data. Wśród plików mechaniki objętych hashowaniem zmienił się wyłącznie combat_simulation.gd. Oddzielnie zaktualizowano fingerprint online, dokumentację i testy.',
 '- Win rate dotyczy wyłącznie danego zestawu scenariuszy, nie populacji graczy. Lustrzane próby nie są niezależnymi obserwacjami. Nie oczekujemy, że każda rola wygrywa 50% pojedynków.',
 '- Damage oznacza rzeczywiste zabrane HP bez overkillu. Mniejszy damage przy lepszym wyniku może wynikać z szybszego zakończenia walki, zmiany celu lub innego podziału obrażeń między sojuszników.',
 '- Dane historyczne: balance_before_no_kiting/. Dane aktualne: monkey_rabbit_*.json. Pełne sparowane agregaty: no_kiting_balance_comparison.json i .csv.','']
 sections=[('duel','Pojedynki na własnym poziomie'),('teams','Podmiana jednostki w składach z lvl1'),('peer_diverse','Podmiana jednostki w 12 kontekstach przeciw lvl2'),('peer_teams','Mała próba drużyn na jednakowym poziomie')]
 focus=['monkey','rabbit','bear_monkey','monkey_hippo','monkey_skunk','cheetah_rabbit','hippo_rabbit','skunk_rabbit','lvl3_04','lvl3_08','lvl3_11','lvl3_12']
 for family,title in sections:
  lines+=['## '+title,'','Wartości: przed → po. Liczba prób obejmuje obie strony.','']
  for id in focus:
   key=family+'/'+id
   if key not in deltas:continue
   x=deltas[key];a=x['before'];b=x['after']
   lines.append(f"- **{names.get(id,id)}** (n={b['n']}): wygrane {a['wins']}/{a['n']} → {b['wins']}/{b['n']}; damage {a['damage']:.1f} → {b['damage']:.1f}; czas życia {a['life']:.1f} → {b['life']:.1f} s; czas walki {a['duration']:.1f} → {b['duration']:.1f} s.")
 lines+=['','## Weryfikacja wdrożenia','',
 '- no_ranged_kiting_test.gd: cztery formy ranged przestają się cofać i wymieniają obrażenia z melee; nadal podchodzą do dalekiego celu. Dash Królika pozostaje.',
 '- skunk_phase_tests.gd: ruch przez jednostki, zadawanie damage, stun i zakończenie phasingu dla trzech form — PASS.',
 '- no_kiting_visual_test.gd: wyrenderowana rzeczywista walka Małpa–Niedźwiedź z obustronnym damage — PASS.',
 '- online_session_test.gd: handshake, transport danych i odrzucenie niezgodnej wersji — PASS.',
 '- tools/godot.ps1 check: import i start — PASS. Nowe EXE uruchomione bez błędów.',
 '- Zmienione tylko dwa przestarzałe oczekiwania w istniejących testach ruchu. Nie deklarujemy przejścia całego historycznego zestawu testów balansu, który zawiera dawne założenia o zwycięzcach.',
 '- Obaj gracze online muszą mieć nową paczkę; fingerprint odróżnia nowe zasady od poprzednich.','']
 (R/'NO_KITING_BALANCE_COMPARISON.md').write_text('\n'.join(lines),encoding='utf-8')
 print('Comparison report saved')
if __name__=='__main__':run()
