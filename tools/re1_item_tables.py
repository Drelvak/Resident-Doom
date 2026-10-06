"""Read normal USA item tables from the supplied decomp, without evaluating C++."""
from pathlib import Path
import re, json
ROOT = Path(__file__).resolve().parents[1]
SUPPORTED = (2, 3, 11, 12, 47, 0x33, 0x44, 0x47, 0x4a)

def array(source, name):
    match = re.search(r'\b' + name + r'\s*\[.*?\]\s*=\s*\{(.*?)\};', source, re.S)
    if not match:
        raise ValueError(f'Missing source table: {name}')
    body = re.sub(r'//[^\n]*', '', match[1])
    return [int(x, 16) for x in re.findall(r'0x([0-9a-fA-F]+)', body)]

def read_tables():
    base = ROOT / 'resident-evil-pc-decomp-main/src'
    globals_source = (base / 'Globals.cpp').read_text()
    menu_source = (base / 'game/MenuData.cpp').read_text()
    lookup = array(globals_source, 'g_ItemImageLookupTable')
    heal = array(menu_source, 'g_ItemHealTable')
    maximum = array(menu_source, 'g_ItemMaxQty')
    data = array(menu_source, 'g_ItemCombineData')
    image_types = array(menu_source, 'g_ItemImageTypeTable')
    ptr = re.search(r'g_ItemCombinePtrs\s*\[.*?\]\s*=\s*\{(.*?)\};', menu_source, re.S)[1]
    offsets = [int(x) for x in re.findall(r'g_ItemCombineData\s*\+\s*(\d+)', ptr)]
    recipes = []
    for item in SUPPORTED:
        table_index = lookup[item * 4 + 1]
        if table_index >= len(offsets):
            continue  # 0x80 sentinel: no combine table for this item.
        offset = offsets[table_index]
        for n in range(data[offset]):
            other, new_a, new_b, effect = data[offset + 1 + n * 4:offset + 5 + n * 4]
            if other in SUPPORTED:
                assert new_a in (*SUPPORTED, 0) and new_b in (*SUPPORTED, 0)
                recipes.append((item, other, new_a, new_b, effect))
    return dict(ids=SUPPORTED, heal=[heal[i] & 15 for i in SUPPORTED],
                maximum=[maximum[i * 4] for i in SUPPORTED], recipes=recipes,
                lookup=lookup, image_types=image_types)

def generate():
    tables = read_tables()
    fields = {'IDs': tables['ids'], 'Heal': tables['heal'], 'MaxQty': tables['maximum']}
    for n, name in enumerate(('RecipeA', 'RecipeB', 'NewA', 'NewB', 'Effect')):
        fields[name] = [r[n] for r in tables['recipes']]
    text = '// Generated from USA Globals.cpp/MenuData.cpp; do not hand-edit.\nclass RESliceItems : Object {\n'
    for name, values in fields.items():
        text += f'static const int {name}[] = {{' + ','.join(map(str, values)) + '};\n'
    text += 'static int Healing(int id) { for(int i=0;i<9;i++)if(RESliceItems.IDs[i]==id)return RESliceItems.Heal[i];return 0; }\n'
    text += f'static int Recipe(int a,int b) {{ for(int i=0;i<{len(tables["recipes"])};i++)if(RESliceItems.RecipeA[i]==a&&RESliceItems.RecipeB[i]==b)return i;return -1; }}\n'
    source=(ROOT/'resident-evil-pc-decomp-main/src/Globals.cpp').read_text()
    strings={name: value.replace(r'\\n','\n') for name,value in re.findall(r'static constexpr auto (s_idesc\d+) = STR\("(.*?)"\);',source)}
    ptrs=re.search(r'g_ItemDescriptions\s*\[.*?\]\s*=\s*\{(.*?)\};',source,re.S)
    if ptrs is None: raise ValueError('Missing original item description pointers')
    refs=re.findall(r'\(unsigned char\*\)(s_idesc\d+)\.bytes',ptrs[1])
    text += 'static String Description(int id) {\n'
    for item in SUPPORTED:
        text += f'if(id=={item})return '+json.dumps(strings[refs[item-1]])+';\n'
    text += 'return ""; }\n}\n'

    # Rendering.cpp message_item_name_lookup selects the generic category until
    # the corresponding original examination flag is set.
    menu_source=(ROOT/'resident-evil-pc-decomp-main/src/game/MenuData.cpp').read_text()
    names={name: value.replace(r'\x07','') for name,value in re.findall(r'static constexpr auto (s_item\w+)\s*= STR\("(.*?)"\);',menu_source)}
    def pointers(table):
        body=re.search(r'\b'+table+r'\s*\[.*?\]\s*=\s*\{(.*?)\};',menu_source,re.S)[1]
        return re.findall(r'\(unsigned char\*\)(s_item\w+)\.bytes',body)
    known=pointers('g_ItemNamePointers');unknown=pointers('g_UnknownItemNamePointers')
    flags=[tables['lookup'][item*4+2] for item in SUPPORTED]
    text=text[:-2]+'static const int ExamineFlags[]={'+','.join(map(str,flags))+'};\n'
    text+='static int ExamineFlag(int id) { for(int i=0;i<9;i++)if(RESliceItems.IDs[i]==id)return RESliceItems.ExamineFlags[i];return 128; }\n'
    text+='static String Name(int id,bool examined) {\n'
    for item,flag in zip(SUPPORTED,flags):
        name=names[known[item-1]]
        if flag<128:text+=f'if(id=={item})return examined?'+json.dumps(name)+':'+json.dumps(names[unknown[flag]])+';\n'
        else:text+=f'if(id=={item})return '+json.dumps(name)+';\n'
    text+='return ""; }\n}\n'

    (ROOT / 'mod/items.zs').write_text(text)

if __name__ == '__main__':
    generate()
