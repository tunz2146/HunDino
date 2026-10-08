"""Replace the training area only; preserve Studio-authored lobby/terrain XML."""
import sys,uuid,shutil,json,hashlib
from pathlib import Path
import xml.etree.ElementTree as E

ROOT=Path(__file__).resolve().parents[1]
SOURCE=Path(r'C:\Users\khanh\OneDrive\Desktop\game roblox\HunDino\HunDino_DarkJungle_v2_1.rbxlx')
OUTPUT=ROOT/'HunDino_DarkJungle_v2_2.rbxlx'
def prop(item,key):
    v=item.find(f"Properties/*[@name='{key}']")
    assert v is not None, (item.get('referent'),key)
    return v
def child(parent,name):
    return next(i for i in parent.findall('Item') if prop(i,'Name').text==name)
def digest(data): return hashlib.sha256(data).hexdigest()

sys.stdout.reconfigure(encoding='utf-8')
data=SOURCE.read_bytes(); before=digest(data)
(ROOT/'backups').mkdir(exist_ok=True)
manifest_path=ROOT/'TrainingSanctuary_manifest.json'
if OUTPUT.exists():
    assert manifest_path.exists(), 'Output exists without a build manifest; preserve it before rebuilding'
    previous=json.loads(manifest_path.read_text(encoding='utf-8'))
    assert digest(OUTPUT.read_bytes())==previous['outputSHA256'], 'Output has manual changes; save them separately before rebuilding'
backup=ROOT/'backups'/f'v2_1_before_training_{before[:12]}.rbxlx'
if not backup.exists(): shutil.copy2(SOURCE,backup)
assert digest(backup.read_bytes())==before
root=E.fromstring(data)
# Repair reversible UTF-8-as-Latin-1 corruption in existing signs as well.
# Correct Vietnamese (including the valid word BÃI) is left alone.
repaired=0
for item in root.iter('Item'):
    for key in ('Text','ActionText','ObjectText'):
        node=item.find(f"Properties/*[@name='{key}']")
        if node is None or not node.text: continue
        for _ in range(3):
            try: clean=node.text.encode('latin-1').decode('utf-8')
            except (UnicodeEncodeError,UnicodeDecodeError): break
            if clean==node.text: break
            node.text=clean; repaired+=1
    if item.get('class') in ('TextLabel','TextButton','ProximityPrompt'):
        value=item.find("Properties/bool[@name='AutoLocalize']")
        if value is not None: value.text='false'
world=child(root,'Workspace'); main=child(world,'HunDinoL0')
preserved={i.get('referent'):E.tostring(i) for i in world.findall('Item') if i is not main}
preserved_main={i.get('referent'):E.tostring(i) for i in main.findall('Item') if prop(i,'Name').text!='Training'}
old_training=child(main,'Training'); main.remove(old_training)
added=E.parse(ROOT/'TrainingSanctuary.rbxmx').getroot()
items=added.findall('Item')
# Namespaced references prevent collisions with original imported models.
refs={i.get('referent'):'RBX'+uuid.uuid4().hex for top in items for i in top.iter('Item')}
for top in items:
    for node in top.iter():
        if node.tag=='Item': node.set('referent',refs[node.get('referent')])
        if node.tag=='Ref' and node.text in refs: node.text=refs[node.text]
main.append(child(added,'Training'))
storage=child(root,'ServerStorage')
for item in list(storage.findall('Item')):
    if prop(item,'Name').text=='TrainingWeapons': storage.remove(item)
storage.append(child(added,'TrainingWeapons'))
sources={
    child(child(root,'ServerScriptService'),'HunDinoTraining'):ROOT/'src/dark-jungle/Training.server.luau',
    child(child(child(root,'StarterPlayer'),'StarterPlayerScripts'),'HunDinoTraining'):ROOT/'src/dark-jungle/Training.client.luau',
}
shared=child(child(root,'ReplicatedStorage'),'Shared')
for name in ('Weapons','TrainingRules'):
    item=E.SubElement(shared,'Item',{'class':'ModuleScript','referent':'RBX'+uuid.uuid4().hex})
    properties=E.SubElement(item,'Properties')
    E.SubElement(properties,'string',{'name':'Name'}).text=name
    E.SubElement(properties,'ProtectedString',{'name':'Source'})
    sources[item]=ROOT/f'src/dark-jungle/{name}.luau'
for item,path in sources.items(): prop(item,'Source').text=path.read_text(encoding='utf-8')
for item in world.findall('Item'):
    ref=item.get('referent')
    if ref in preserved: assert preserved[ref]==E.tostring(item),prop(item,'Name').text
for item in main.findall('Item'):
    ref=item.get('referent')
    if ref in preserved_main: assert preserved_main[ref]==E.tostring(item),prop(item,'Name').text
# A bad shell encoding step used to corrupt UI text. Reject controls/mojibake.
text_count=0
for item in root.iter('Item'):
    if item.get('class') in ('TextLabel','TextButton','ProximityPrompt'):
        properties=item.find('Properties')
        auto=properties.find("bool[@name='AutoLocalize']")
        if auto is None: auto=E.SubElement(properties,'bool',{'name':'AutoLocalize'})
        auto.text='false'
    for key in ('Text','ActionText','ObjectText'):
        node=item.find(f"Properties/*[@name='{key}']")
        if node is None or not node.text: continue
        text_count+=1
        assert not any(0x80<=ord(c)<=0x9f or c=='\ufffd' for c in node.text),repr(node.text)
E.ElementTree(root).write(OUTPUT,encoding='utf-8',xml_declaration=False)
report={'input':str(SOURCE),'inputSHA256':before,'backup':str(backup),'output':str(OUTPUT),
        'outputSHA256':digest(OUTPUT.read_bytes()),'trainingSize':[460,420],'weaponCount':7,'dummyCount':7,
        'validatedTextFields':text_count,'repairedEncodingPasses':repaired,'lobbyGeometryAndTerrainPreserved':True}
(ROOT/'TrainingSanctuary_manifest.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
