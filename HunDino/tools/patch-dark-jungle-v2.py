"""Patch an existing Studio-saved v2 without rebuilding its user-edited geometry.

Usage: python tools/patch-dark-jungle-v2.py INPUT.rbxlx OUTPUT.rbxlx
UTF-8 XML is handled directly so unknown/new Roblox properties remain intact.
"""
from pathlib import Path
from collections import defaultdict
import argparse
import copy
import hashlib
import json
import shutil
import sys
import uuid
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
WATER_LEVEL = 2.0
TEXT_FIXES = {
    "Workspace.DarkJungle.Landmarks.ThreeTierWaterfall.GrottoMarker.SignGui.Text": {"Text": "ĐỀN SAU THÁC"},
    "Workspace.HunDinoL0.Lobby.ToTraining.ToTrainingPrompt": {"ActionText": "Vào bãi tập", "ObjectText": "Cổng thợ săn"},
    "Workspace.HunDinoL0.Training.ToLobby.SignGui.Text": {"Text": "TRỞ VỀ TRẠI"},
    "Workspace.HunDinoL0.Training.ToLobby.ToLobbyPrompt": {"ActionText": "Về sảnh", "ObjectText": "TRỞ VỀ TRẠI"},
    "Workspace.HunDinoL0.Training.EquipmentRack.ArmorPrompt": {"ActionText": "Mặc / tháo giáp mẫu", "ObjectText": "Giá trang bị"},
    "Workspace.HunDinoL0.Training.ResetPost.SignGui.Text": {"Text": "BẮT ĐẦU LƯỢT TẬP MỚI"},
    "Workspace.HunDinoL0.Training.ResetPost.ResetPrompt": {"ActionText": "Xóa thống kê của tôi", "ObjectText": "Bảng luyện tập"},
}

def prop(item, name):
    value = item.find(f"Properties/*[@name='{name}']")
    assert value is not None, (item.get('referent'), name)
    return value

def name(item):
    return prop(item, "Name").text

def index_paths(root):
    result = {}
    def walk(parent, prefix):
        for item in parent.findall("Item"):
            path = prefix + name(item)
            result[path] = item
            walk(item, path + ".")
    walk(root, "")
    return result

def xyz(value):
    return tuple(float(value.findtext(axis)) for axis in "XYZ")

def set_xyz(value, values):
    for axis, number in zip("XYZ", values):
        value.find(axis).text = str(number)

def patch(source, destination):
    assert source.resolve() != destination.resolve(), "Keep the original map intact"
    data = source.read_bytes()
    source_hash = hashlib.sha256(data).hexdigest()
    backup = ROOT / "backups" / f"{source.stem}_before_v2_1_{source_hash[:12]}.rbxlx"
    backup.parent.mkdir(exist_ok=True)
    if not backup.exists():
        shutil.copy2(source, backup)
    assert hashlib.sha256(backup.read_bytes()).hexdigest() == source_hash
    root = ET.fromstring(data)
    paths = index_paths(root)
    # Snapshots verify all original properties outside the explicit change list.
    original = {i.get('referent'): ET.tostring(i.find('Properties')) for i in root.iter('Item')}
    changed = set()
    for path, fields in TEXT_FIXES.items():
        item = paths[path]
        for field, value in fields.items():
            prop(item, field).text = value
        changed.add(item.get('referent'))
    for path, filename in {
        "StarterPlayer.StarterPlayerScripts.HunDinoTraining": "Training.client.luau",
        "ServerScriptService.HunDinoTraining": "Training.server.luau",
    }.items():
        item = paths[path]
        prop(item, 'Source').text = (ROOT / 'src/dark-jungle' / filename).read_text(encoding='utf-8')
        changed.add(item.get('referent'))

    rivers = paths['Workspace.DarkJungle.Rivers']
    swamp = paths['Workspace.DarkJungle.Landmarks.WestWhisperingMire']
    template = copy.deepcopy(paths['Workspace.DarkJungle.Rivers.RiverWater'])
    smooth_material = prop(paths['Workspace.DarkJungle.Landmarks.ThreeTierWaterfall.WaterCurtain'], 'Material').text
    removed = set()
    for parent, names in [(rivers, ('RiverWater', 'MoonPool', 'WaterSurface')), (swamp, ('ShallowWater',))]:
        for item in list(parent.findall('Item')):
            if name(item) in names:
                removed.update(i.get('referent') for i in item.iter('Item'))
                parent.remove(item)

    # Match the carved tile boundaries, rather than the narrower river centreline.
    # Merge contiguous cells in each row into one surface with no overlapping faces.
    rows = defaultdict(list)
    cells = []
    for tile in paths['Workspace.DarkJungle.TerrainRock'].findall('Item'):
        if name(tile) != 'ForestFloor':
            continue
        x, y, z = xyz(prop(tile, 'CFrame'))
        sx, sy, sz = xyz(prop(tile, 'size'))
        top = y + sy / 2
        if abs(top + 9) < .02 or abs(top - 1) < .02:
            assert abs(sx - 60) < .02 and abs(sz - 60) < .02, 'Review resized river tiles before patching'
            kind = 'river' if top < 0 else 'swamp'
            rows[kind, z].append(x)
            cells.append((x, z, top))
    assert len(cells) > 20, 'No carved lake/river bed found'
    surfaces = []
    for (kind, z), xs in sorted(rows.items()):
        xs.sort()
        runs = [[xs[0]]]
        for x in xs[1:]:
            if abs(x - runs[-1][-1] - 60) < .02:
                runs[-1].append(x)
            else:
                runs.append([x])
        for run in runs:
            x = (run[0] + run[-1]) / 2
            width = run[-1] - run[0] + 60
            item = copy.deepcopy(template)
            item.set('referent', 'RBX' + uuid.uuid4().hex.upper())
            # Roblox encodes the leading random component as a signed int64.
            prop(item, 'UniqueId').text = '0' + uuid.uuid4().hex[1:]
            prop(item, 'Name').text = 'WaterSurface'
            prop(item, 'shape').text = '1'
            cf = prop(item, 'CFrame')
            set_xyz(cf, (x, WATER_LEVEL - .2, z))
            for row in range(3):
                for col in range(3):
                    cf.find(f'R{row}{col}').text = '1' if row == col else '0'
            set_xyz(prop(item, 'size'), (width, .4, 60))
            prop(item, 'Material').text = smooth_material
            prop(item, 'Transparency').text = '.22'
            prop(item, 'Reflectance').text = '.12'
            prop(item, 'CastShadow').text = 'false'
            for field in ('CanCollide', 'CanTouch', 'CanQuery'):
                prop(item, field).text = 'false'
            if kind == 'swamp':
                prop(item, 'Color3uint8').text = str(0xff000000 | (40 << 16) | (85 << 8) | 65)
            rivers.append(item)
            surfaces.append((x, z, width, 60))

    # The bottom foam must sit on the raised pool instead of disappearing below it.
    for item in paths['Workspace.DarkJungle.Landmarks.ThreeTierWaterfall'].iter('Item'):
        if name(item) == 'Foam':
            cf = prop(item, 'CFrame')
            if float(cf.findtext('Y')) < 3:
                cf.find('Y').text = str(WATER_LEVEL + .3)
                changed.add(item.get('referent'))

    # All cut cells are covered exactly once and no water extends over dry tiles.
    covered_area = sum(w * d for _, _, w, d in surfaces)
    assert abs(covered_area - len(cells) * 3600) < .01
    for x, z, _ in cells:
        assert sum(abs(x-a) < w/2 and abs(z-b) < d/2 for a,b,w,d in surfaces) == 1
    remaining = {i.get('referent'): i for i in root.iter('Item')}
    for ref, before in original.items():
        if ref in removed:
            assert ref not in remaining
        elif ref not in changed:
            assert ET.tostring(remaining[ref].find('Properties')) == before, ref
    destination.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(root).write(destination, encoding='utf-8', xml_declaration=False)
    # Parse the delivered file and verify Unicode survived the actual save.
    saved = index_paths(ET.parse(destination).getroot())
    for path, fields in TEXT_FIXES.items():
        for field, value in fields.items():
            assert prop(saved[path], field).text == value
    report = dict(source=str(source), sourceSHA256=source_hash, backup=str(backup),
                  output=str(destination), outputSHA256=hashlib.sha256(destination.read_bytes()).hexdigest(),
                  correctedTextObjects=len(TEXT_FIXES), waterLevel=WATER_LEVEL,
                  coveredBedTiles=len(cells), waterSurfaces=len(surfaces),
                  preservedOriginalObjects=len(original)-len(changed)-len(removed))
    (ROOT / 'DarkJungle_v2_1_patch.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('destination', type=Path)
    args = parser.parse_args()
    patch(args.source, args.destination)
