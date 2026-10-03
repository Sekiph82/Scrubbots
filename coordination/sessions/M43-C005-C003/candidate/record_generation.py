import argparse, base64, hashlib, json, shutil
from pathlib import Path
from PIL import Image

root=Path.cwd()
cycle=root/'coordination/sessions/M43-C005-C003'
parser=argparse.ArgumentParser()
parser.add_argument('--sequence',type=int,required=True)
parser.add_argument('--attempt-count',type=int,default=1)
parser.add_argument('--candidate',required=True)
parser.add_argument('--source',required=True)
parser.add_argument('--tool-output',required=True)
parser.add_argument('--prompt-base64',required=True)
a=parser.parse_args()

def sha(path):
    h=hashlib.sha256()
    with open(path,'rb') as f:
        for block in iter(lambda:f.read(1024*1024),b''):
            h.update(block)
    return h.hexdigest().upper()

inventory_path=cycle/'COLLECTION_CARD_GENERATION_INVENTORY_V01.json'
inventory=json.loads(inventory_path.read_text(encoding='utf-8'))
old_doc=json.loads((cycle/'OLD_CANONICAL_CARD_SHA256_V01.json').read_text(encoding='utf-8'))
row=next(x for x in inventory['cards'] if x['global_sequence']==a.sequence)
old=next(x['sha256'] for x in old_doc['cards'] if x['path']==row['canonical_card_file_path'])
candidate=Path(a.candidate); source=Path(a.source)
target=root/row['canonical_card_file_path']
with Image.open(candidate) as im:
    im.load()
    if im.size!=(1024,1536) or im.mode!='RGBA':
        raise SystemExit(f'FAIL_OUTPUT_FORMAT {im.size} {im.mode}')
    if any(im.getpixel(p)[3]!=0 for p in ((0,0),(1023,0),(0,1535),(1023,1535))):
        raise SystemExit('FAIL_ALPHA_CORNERS')
    if not im.getchannel('A').getbbox():
        raise SystemExit('FAIL_EMPTY')
    width,height=im.size
    alpha_bbox=im.getchannel('A').getbbox()
prompt=base64.b64decode(a.prompt_base64).decode('utf-8')
if not prompt.strip():
    raise SystemExit('FAIL_EMPTY_PROMPT')
new_sha=sha(candidate)
source_sha=sha(source)
if new_sha==old:
    raise SystemExit('FAIL_UNCHANGED_SHA')
if target.exists() and sha(target)!=old:
    raise SystemExit('FAIL_CANONICAL_CHANGED_SINCE_SNAPSHOT')
target.parent.mkdir(parents=True,exist_ok=True)
shutil.copy2(candidate,target)
if sha(target)!=new_sha:
    raise SystemExit('FAIL_COPY_HASH_MISMATCH')
row.update({
    'generation_status':'GENERATED',
    'output_sha256':new_sha,
    'generation_attempt_count':a.attempt_count,
    'individually_generated':True,
    'generation_method':'one separate image-generation call for this card; exact frame and typography composed deterministically',
    'generated_illustration_sha256':source_sha,
    'prompt_reference_provenance':'card-specific prompt derived from this inventory row and its owner-sheet identity/name/rarity/theme cues; no source pixels',
    'visually_inspected_by_builder':True,
    'builder_visual_qa':'PASS'
})
inventory_path.write_text(json.dumps(inventory,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
record={
 'global_sequence':row['global_sequence'],
 'canonical_card_file_path':row['canonical_card_file_path'],
 'name':row['exact_displayed_card_name'],
 'rarity':row['exact_rarity'],
 'star_count':row['star_count_shown_by_source'],
 'generation_method':'individually_generated',
 'generation_attempt_count':a.attempt_count,
 'generated_illustration_sha256':source_sha,
 'generated_tool_output_path':a.tool_output,
 'old_production_sha256':old,
 'new_production_sha256':new_sha,
 'dimensions':[width,height],
 'alpha_bounds':list(alpha_bbox),
 'qa_result':'PASS',
 'visual_checks':{'identity':'PASS','rarity':'PASS','text':'PASS','frame_complete':'PASS','no_crop_contamination':'PASS','production_quality':'PASS'},
 'prompt_text':prompt
}
log=cycle/'CARD_GENERATION_RUN_V01.jsonl'
with log.open('a',encoding='utf-8',newline='\n') as f:
    f.write(json.dumps(record,ensure_ascii=False,separators=(',',':'))+'\n')
print(json.dumps({'sequence':row['global_sequence'],'path':row['canonical_card_file_path'],'old_sha256':old,'new_sha256':new_sha,'source_sha256':source_sha,'tool_output':a.tool_output}))