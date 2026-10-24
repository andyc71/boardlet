"""Import named AppStore attachments exported by xcresulttool."""
import json, pathlib, shutil, sys
source = pathlib.Path(sys.argv[1])
target = pathlib.Path('screenshots/AppStore-2026-10/raw') / sys.argv[2]
target.mkdir(parents=True, exist_ok=True)
for test in json.loads((source / 'manifest.json').read_text()):
    for item in test['attachments']:
        name = item['suggestedHumanReadableName']
        if name.startswith('AppStore-') and name.endswith('.png'):
            slug = name.removeprefix('AppStore-').split('_')[0]
            shutil.copy2(source / item['exportedFileName'], target / (slug + '.png'))
            print(target / (slug + '.png'))
