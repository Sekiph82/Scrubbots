"""Check every M53 corpus diff against two float->text models of Godot 4.7.2 JSON.stringify
(String::num(x, max(1, 14 - floor(log10|x|))) -> C runtime snprintf("%.<p>lf")):
  glibc  : exact decimal value of the double, correctly rounded (Linux build)
  msvcrt : first 17 significant digits (correctly rounded), then rounded half-up to <p> decimals
           (MinGW-w64 / msvcrt.dll printf, the official Windows build)
then Godot strips trailing zeros (keeping one after the point)."""
import json, math, sys
from decimal import Decimal, ROUND_HALF_UP, ROUND_HALF_EVEN

def prec(x):
    return max(1, 14 - math.floor(math.log10(abs(x))))

def strip(s):
    if '.' in s:
        s = s.rstrip('0')
        if s.endswith('.'):
            s += '0'
    return s

def glibc(x):
    return strip('%.*f' % (prec(x), x))      # CPython uses correctly rounded conversion like glibc

def msvcrt(x):
    d17 = Decimal('%.16e' % x)                # 17 significant digits, correctly rounded
    q = Decimal(1).scaleb(-prec(x))
    return strip(format(d17.quantize(q, rounding=ROUND_HALF_UP), 'f'))

data = json.load(open(sys.argv[1]))['fixtures']
total = ok = 0
bad = []
for fx, diffs in data.items():
    for d in diffs:
        total += 1
        if d.get('kind') != 'value' or 'fresh_exact' not in d:
            bad.append((fx, d)); continue
        x = float(d['fresh_exact'])
        if msvcrt(x) == d['committed_text'] and glibc(x) == d['fresh_text']:
            ok += 1
        else:
            bad.append((fx, d, msvcrt(x), glibc(x)))
per = {k: len(v) for k, v in data.items() if v}
print('fixtures', len(data), 'fixtures_with_diffs', len(per), 'diffs', total, 'explained_by_platform_printf', ok, 'unexplained', len(bad))
print('per_fixture', per)
for b in bad[:10]:
    print('UNEXPLAINED', b)
