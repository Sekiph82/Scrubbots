import json,sys,os,collections
root=sys.argv[1]
def walk(o,f):
    if isinstance(o,dict):
        for k,v in o.items(): f(k,v); walk(v,f)
    elif isinstance(o,list):
        for v in o: walk(v,f)
for m in ["ASSET_GENERATION_MANIFEST.json","assets/ui/HOME_ASSET_MANIFEST.json","assets/art/references/inventory.json"]:
    d=json.load(open(os.path.join(root,m),encoding="utf-8"))
    ids=[];paths=[];refs=[]
    def f(k,v):
        if k in("id",) and isinstance(v,str): ids.append(v)
        if k in("path","repository_path","repositoryPath","target_path") and isinstance(v,str): paths.append((k,v))
        if k=="candidate_paths": paths.extend((k,x) for x in v)
        if k=="references" and isinstance(v,list): refs.extend(v)
    walk(d,f)
    dup=[i for i,c in collections.Counter(ids).items() if c>1]
    print(m,"ids",len(ids),"dups",dup,"paths",len(paths))
    print(" unknown refs",[r for r in refs if r not in ids])
    miss=[(k,p) for k,p in paths if not os.path.exists(os.path.join(root,p))]
    print(" missing",len(miss)); [print("  ",x) for x in miss[:40]]
