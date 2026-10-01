import json, statistics as st, collections as co, csv, hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def run():
 data=json.loads((ROOT/'reports/monkey_rabbit_balance.json').read_text())
 rows=data['records']; peer_rows=json.loads((ROOT/'reports/monkey_rabbit_peer_teams.json').read_text()) if (ROOT/'reports/monkey_rabbit_peer_teams.json').exists() else []; rows+=peer_rows; rows+=json.loads((ROOT/'reports/monkey_rabbit_diverse.json').read_text()) if (ROOT/'reports/monkey_rabbit_diverse.json').exists() else []; groups=co.defaultdict(list)
 def avg(xs): return round(st.mean(xs),3) if xs else None
 def summary(rs):
  completed=[r for r in rs if r['outcome']!='stall']; f=[r['focal'] for r in rs]
  damage=sum(u['damage_dealt'] for u in f)
  life=[u['death_time'] if u['death_time']>=0 else r['duration'] for r,u in zip(rs,f)]
  ttk=[u['ttk'] for u in f if u['ttk']>=0]
  skills=co.Counter(); kinds=co.Counter(); states=co.Counter()
  for r,u in zip(rs,f): skills.update(u['skill_uses']); kinds.update(u['damage_by_kind']);states.update(r['states'])
  return dict(n=len(rs),wins=sum(r['outcome']=='win' for r in rs),draws=sum(r['outcome']=='draw' for r in rs),stalls=len(rs)-len(completed),win_pct=round(100*sum(r['outcome']=='win' for r in completed)/len(completed),2) if completed else None,damage=avg([u['damage_dealt'] for u in f]),team_damage=avg([r['team_damage'] for r in rs]),taken=avg([u['damage_taken'] for u in f]),survival_pct=100*sum(u['survived'] for u in f)/len(rs),life=avg(life),ttk_deaths_only=avg(ttk),dps_alive=round(damage/sum(life),3),duration=avg([r['duration'] for r in rs]),skill_share_pct=round(100*(damage-kinds.get('basic',0))/damage,2) if damage else 0,skills_per_match={k:round(v/len(rs),3) for k,v in skills.items()},damage_by_kind={k:round(v/len(rs),3) for k,v in kinds.items()},states_seconds={k:round(v/len(rs),3) for k,v in states.items()},cancelled_casts=sum(r['dash_cancellations'] for r in rs),pending_hits_lost=sum(r['pending_hits_lost'] for r in rs),basic_hits=avg([r['basic_hits'] for r in rs]))
 for r in rows:
  if r['family'] in ['duel','upgrade'] or r['mode']!='live':continue
  
  if r['family']!='peer_diverse': groups[('peer_teams' if r['family'].startswith('peer_') else 'teams',r['id'])].append(r)
  groups[(r['family'],r['id'])].append(r)
 for r in rows:
  if r['family']=='duel' and r['b']!=[r['id']]:groups[('duel',r['id'])].append(r)
 aggregated={f'{family}/{id}':summary(rs) for (family,id),rs in groups.items()}
 paired=[]
 def key(r):return (r['family'],r['id'],r['slot'],r['layout'],r['mirror'])
 live={key(r):r for r in rows if r['mode']=='live' and r['family'] not in ['duel','upgrade']}
 for mode in ['no_dash','no_interrupt']:
  for id in data['focus']:
   probes=[r for r in rows if r['id']==id and r['mode']==mode]
   if not probes:continue
   base=[live[key(r)] for r in probes]
   paired.append(dict(id=id,mode=mode,live=summary(base),probe=summary(probes),damage_delta=avg([p['focal']['damage_dealt']-b['focal']['damage_dealt'] for p,b in zip(probes,base)]),changed_outcomes=sum(p['outcome']!=b['outcome'] for p,b in zip(probes,base))))
 upgrades={}
 for id in data['focus']:
  cases=[r for r in rows if r['family']=='upgrade' and r['id']==id]
  if cases: upgrades[id]={','.join(opp):summary([r for r in cases if r['b']==opp]) for opp in [list(x) for x in sorted(set(tuple(r['b']) for r in cases))]}
 mirrors=co.defaultdict(list)
 for r in rows:
  mirrors[(r['family'],r['id'],tuple(r['a']),tuple(r['b']),r['slot'],r['layout'],r['mode'])].append(r)
 mismatch=[]
 for k,pair in mirrors.items():
  if len(pair)!=2:continue
  a,b=pair
  if a['outcome']!=b['outcome']:mismatch.append(dict(key=str(k),a=a['outcome'],b=b['outcome']))
 hashes={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['scripts/combat','scripts/data','resources'] for p in (ROOT/folder).rglob('*') if p.suffix in ['.gd','.tres','.json']}
 out=dict(cases=len(rows),stalls=sum(r['outcome']=='stall' for r in rows),families=dict(co.Counter(r['family'] for r in rows)),aggregates=aggregated,ablations=paired,upgrades=upgrades,mirror_outcome_mismatches=mismatch,source_hashes=hashes)
 (ROOT/'reports/monkey_rabbit_summary.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf-8')
 with (ROOT/'reports/monkey_rabbit_metrics.csv').open('w',newline='',encoding='utf-8-sig') as f:
  fields=['group','n','win_pct','damage','dps_alive','taken','survival_pct','life','ttk_deaths_only','duration','skill_share_pct','basic_hits','cancelled_casts']
  w=csv.DictWriter(f,fieldnames=fields,extrasaction='ignore');w.writeheader()
  for key_,v in aggregated.items():w.writerow(dict(group=key_,**v))
 print('CASES',len(rows),'STALLS',out['stalls'],'MIRROR MISMATCHES',len(mismatch))
 for family in ['duel','teams','peer_teams','peer_diverse']:
  print('\n'+family)
  for key_,v in sorted(aggregated.items(),key=lambda kv:kv[1]['damage'],reverse=True):
   if not key_.startswith(family+'/'):continue
   print(key_.split('/')[1],v['n'],v['win_pct'],v['damage'],v['dps_alive'],v['survival_pct'],v['skill_share_pct'])
 print('\nABLATIONS')
 for p in paired:print(p['id'],p['mode'],'damage delta',p['damage_delta'],'win',p['live']['win_pct'],'->',p['probe']['win_pct'],'interrupted',p['live']['cancelled_casts'])
if __name__=='__main__':run()
