from pathlib import Path

p = Path('TASKS.md')
s = p.read_text(encoding='utf-8')

s = s.replace(
'''Correct SCRUBBOTS flow:
  clicked slot -> visible connector -> Scrubbot Railroad -> aligned orthogonal target approach -> clean -> disappear''',
'''Correct SCRUBBOTS flow:
  selectable supply-front batch -> automatic rightmost-empty slot -> unique claim/reservation -> valid route -> exact slot connector -> Scrubbot Railroad -> legal OPEN/CLEARED ingress -> orthogonal interior corridor -> clean -> disappear''')

s = s.replace(
'No routing pathology; fully enclosed matching ACTIVE target remains untargetable until legal aligned/cleared approach exists.',
'No routing pathology; fully enclosed matching ACTIVE target remains untargetable until a legal Railroad ingress plus OPEN/CLEARED orthogonal interior path exists.')

s = s.replace(
'Routing tests including Railroad V1 geometry, connectors and aligned exits.',
'Routing tests including Railroad V1 geometry, connectors, legal ingresses and post-rail orthogonal interior turns.')

for stale in ['clicked slot -> visible connector -> Scrubbot Railroad -> aligned orthogonal target approach',
              'legal aligned/cleared approach exists',
              'connectors and aligned exits']:
    if stale in s:
        raise SystemExit(f'stale wording remains: {stale}')

p.write_text(s, encoding='utf-8', newline='\n')
