import json,collections,statistics,csv
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
REPORTS=ROOT/'reports'
BASE=REPORTS/'balance_before_no_kiting'
def load_rows(folder):
 return json.loads((folder/'monkey_rabbit_balance.json').read_text())['records']+json.loads((folder/'monkey_rabbit_peer_teams.json').read_text())+json.loads((folder/'monkey_rabbit_diverse.json').read_text())
def key(r):return (r['family'],r['id'],tuple(r['a']),tuple(r['b']),r['slot'],r['layout'],r['mirror'],r['mode'])
def run():
 before=json.loads((BASE/'monkey_rabbit_summary.json').read_text());after=json.loads((REPORTS/'monkey_rabbit_summary.json').read_text())
 old=load_rows(BASE);new=load_rows(REPORTS)
 assert len(old)==len(new)==2774
 a={key(r):r for r in old}; b={key(r):r for r in new}; assert a.keys()==b.keys()
 changed=[key(r) for r in old if a[key(r)]['outcome']!=b[key(r)]['outcome']]
 source_changes=[path for path in before['source_hashes'] if before['source_hashes'][path]!=after['source_hashes'].get(path)]
 assert [p.replace(chr(92),'/') for p in source_changes]==['scripts/combat/combat_simulation.gd'],source_changes
 deltas={}
 for group,value in after['aggregates'].items():
  prev=before['aggregates'][group];assert prev['n']==value['n']
  deltas[group]={'before':prev,'after':value,'damage_delta':round(value['damage']-prev['damage'],3),'win_pp':round(value['win_pct']-prev['win_pct'],3),'duration_delta':round(value['duration']-prev['duration'],3)}
 result={'cases_each':2774,'additional_dash_observations_each':80,'changed_results':len(changed),'source_changes':source_changes,'stalls_after':after['stalls'],'mirror_mismatches_after':len(after['mirror_outcome_mismatches']),'deltas':deltas}
 (REPORTS/'no_kiting_balance_comparison.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
 with (REPORTS/'no_kiting_balance_comparison.csv').open('w',encoding='utf-8-sig',newline='') as f:
  fields=['group','n','damage_before','damage_after','win_before','win_after','life_before','life_after','duration_before','duration_after']
  w=csv.DictWriter(f,fieldnames=fields);w.writeheader()
  for group,d in deltas.items():
   prev=d['before'];cur=d['after'];w.writerow(dict(group=group,n=cur['n'],damage_before=prev['damage'],damage_after=cur['damage'],win_before=prev['win_pct'],win_after=cur['win_pct'],life_before=prev['life'],life_after=cur['life'],duration_before=prev['duration'],duration_after=cur['duration']))
 print('Changed results',len(changed),'of',len(old),'stalls',after['stalls'],'mirror mismatches',len(after['mirror_outcome_mismatches']))
 for family in ['duel','teams','peer_teams','peer_diverse']:
  print('\n'+family)
  for id in ['monkey','rabbit','bear_monkey','monkey_hippo','monkey_skunk','cheetah_rabbit','hippo_rabbit','skunk_rabbit','lvl3_04','lvl3_11','lvl3_08']:
   if family+'/'+id not in deltas:continue
   d=deltas[family+'/'+id];p=d['before'];c=d['after'];print(id,'n',c['n'],'damage',p['damage'],'->',c['damage'],'win',p['win_pct'],'->',c['win_pct'],'life',p['life'],'->',c['life'])
if __name__=='__main__':run()
