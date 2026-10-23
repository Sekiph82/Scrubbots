import json,os,re
def walk(o,f):
    if isinstance(o,dict):
        f(o)
        for v in o.values(): walk(v,f)
    elif isinstance(o,list):
        for v in o: walk(v,f)
for p in ['ASSET_GENERATION_MANIFEST.json','assets/ui/HOME_ASSET_MANIFEST.json','assets/art/references/inventory.json']:
    d=json.load(open(p,encoding='utf-8')); ids=[]; refs=[]; paths=[]
    def f(o):
        if isinstance(o.get('id'),str): ids.append(o['id'])
        for k,v in o.items():
            if k=='references' and isinstance(v,list): refs.extend(x for x in v if isinstance(x,str))
            if isinstance(v,str) and re.match(r'^(assets|res://assets)/',v) or (isinstance(v,str) and v.startswith('res://')): paths.append((k,v))
            if k in('candidate_paths','supplementary_paths') or k=='supplementary_references':
                paths.extend((k,x) for x in v)
    walk(d,f)
    dup={i for i in ids if ids.count(i)>1}
    print(p,'ids',len(ids),'dups',dup,'unresolved refs',[r for r in refs if r not in ids])
    miss=sorted({(k,v) for k,v in paths if not os.path.exists(v.replace('res://',''))})
    for k,v in miss: print('  MISSING',k,v)
