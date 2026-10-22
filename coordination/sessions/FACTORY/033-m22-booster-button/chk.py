import sys,struct,zlib,glob,re,os
def png(p):
    d=open(p,'rb').read(); w,h,bd,ct=struct.unpack('>IIBB',d[16:26]); return w,h,ct
def imp(p):
    t=open(p+'.import').read(); g=lambda k:(re.search(k+r'=(.*)',t) or [0,'?'])[1]
    return g('compress/mode'),g('mipmaps/generate'),g('process/fix_alpha_border')
tot=0
for scope in ('assets/ui/final/boosters/**/*.png','assets/ui/final/**/*.png'):
    fs=sorted(set(glob.glob(scope,recursive=True)));tot=0;bad=[];noalpha=[]
    for f in fs:
        w,h,ct=png(f);tot+=w*h*4
        if ct not in(4,6):noalpha.append(f)
        if not os.path.exists(f+'.import'):bad.append(f)
        elif scope.startswith('assets/ui/final/boosters'):print(f,w,h,'ct',ct,imp(f))
    print(scope,len(fs),'png; est MiB',round(tot/2**20,2),'no-alpha:',len(noalpha),'missing .import:',bad[:3],len(bad))
    if scope.endswith('**/*.png'):
        from collections import Counter;print(Counter(imp(f) for f in fs if f not in bad))
