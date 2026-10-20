#!/usr/bin/env python3
"""Package original symbol artwork as native PECS Maker topic directories."""
import html
import json
import re
import shutil
import uuid
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] / 'ScreenshotBoards'
catalog = json.loads((ROOT / 'catalog.json').read_text())
namespace = uuid.UUID('9b14153e-ceb6-48f9-8957-b2cbf0992515')
def safe_name(value):
    return re.sub(r'[\x00-\x1f/\\:*?"<>|]', '', value).strip().rstrip('.')

manifest = []
sections = []
for locale, title_index, label_index in [('en', 1, 3), ('es', 2, 4)]:
    for board in catalog:
        slug, title, labels = board[0], board[title_index], board[label_index]
        board_id = str(uuid.uuid5(namespace, locale + '/' + slug)).upper()
        folder_name = f'{safe_name(board[1])} - {board_id}'
        directory = ROOT / locale / 'topics' / folder_name
        old_directory = ROOT / locale / 'topics' / board_id
        if old_directory.exists() and not directory.exists():
            old_directory.rename(directory)
        directory.mkdir(parents=True, exist_ok=True)
        cards = []
        preview_cards = []
        for number, label in enumerate(labels, 1):
            card_id = str(uuid.uuid5(namespace, locale + '/' + slug + '/' + str(number))).upper()
            image_name = f'{safe_name(label)} - PhotoItem-{card_id}.png'
            old_image = directory / f'PhotoItem-{card_id}.png'
            if old_image.exists():
                old_image.rename(directory / image_name)
            source = ROOT / 'symbols' / slug / f'{number:02}.png'
            assert source.exists(), source
            shutil.copyfile(source, directory / image_name)
            cards.append(dict(id=card_id, title=label, fitzgeraldKey='none', imageFileName=image_name,
                              assetId=None, audioFileName=None, isPlaceholder=False, hasPhoto=True))
            preview_cards.append(f'<figure><img src="symbols/{slug}/{number:02}.png" alt="{html.escape(label, quote=True)}"><figcaption>{html.escape(label)}</figcaption></figure>')
        shutil.copyfile(ROOT / 'symbols' / slug / '01.png', directory / 'TopicImage.png')
        data = dict(version=1, layout=dict(width=3, height=3), pageSize='A4', orientation='portrait',
                    generateTopicThumbnail=False, generatedThumbnailNeedsUpdate=False,
                    topic=dict(topicCategory='Other', topicName=title, hasSkin=False, hasSoundTheme=False,
                               imageFileName='TopicImage.png', topicDirectoryName=folder_name),
                    photos=dict(photoItems=cards),
                    checkmarks=dict(didPageLayout=True, didTitles=True, didPrint=False))
        (directory / 'index.json').write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
        manifest.append(dict(language=locale, topic=title, slug=slug, directory=f'{locale}/topics/{folder_name}', cards=len(cards)))
        sections.append(f'<section lang="{locale}"><h2>{html.escape(title)}</h2><div class="grid">{"".join(preview_cards)}</div></section>')
    archive = ROOT / f'ScreenshotBoards-{locale}.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for path in sorted((ROOT / locale).rglob('*')):
            if path.is_file(): z.write(path, path.relative_to(ROOT / locale))
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        assert len([n for n in z.namelist() if n.endswith('/index.json')]) == 15
(ROOT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
preview = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Screenshot boards · English & Español</title>
<style>*{box-sizing:border-box}body{margin:0;background:#f4f6f8;color:#17232d;font:16px system-ui,sans-serif}header{padding:32px max(24px,calc((100vw - 1240px)/2));background:#153e49;color:white}h1{margin:0 0 8px;font-size:32px}p{line-height:1.5}button{padding:10px 18px;border:1px solid #b7d8dc;background:white;border-radius:8px;margin:4px 8px 0 0;font:inherit;cursor:pointer}button[aria-pressed=true]{background:#c5f2e9}main{max-width:1280px;margin:auto;padding:24px;display:grid;grid-template-columns:repeat(auto-fit,minmax(330px,1fr));gap:24px}section{background:white;border:1px solid #dde3e7;border-radius:16px;padding:20px;box-shadow:0 3px 12px #1232}h2{margin:0 0 16px;font-size:23px}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:8px}figure{margin:0;border:1px solid #cad5da;border-radius:8px;overflow:hidden;background:var(--card,white)}img{display:block;width:100%;height:115px;object-fit:contain;padding:7px}figcaption{min-height:48px;display:flex;align-items:center;justify-content:center;text-align:center;font-size:13px;font-weight:600;padding:4px;background:#ffffffdb}body[data-language=en] section[lang=es],body[data-language=es] section[lang=en]{display:none}@media print{header{display:none}main{display:block}section{page-break-after:always;box-shadow:none}img{height:180px}}</style>
<body data-language="en"><header><h1>Everyday communication</h1><p>15 topics · 9 cards each · Original transparent symbols · Editable English and Spanish labels</p><button id="en" aria-pressed="true" onclick="language('en')">English</button><button id="es" aria-pressed="false" onclick="language('es')">Español</button><button onclick="document.body.style.setProperty('--card',this.dataset.on?'white':'#a4dcd5');this.dataset.on=this.dataset.on?'':'yes'">Toggle colour behind symbols</button></header><main>'''+''.join(sections)+'''</main><script>function language(l){document.body.dataset.language=l;document.documentElement.lang=l;for(const id of ['en','es'])document.getElementById(id).setAttribute('aria-pressed',String(id===l));}</script></body></html>'''
(ROOT / 'preview.html').write_text(preview)
# Validate every native index and image reference after packaging.
ids = set()
for entry in manifest:
    directory = ROOT / entry['directory']
    data = json.loads((directory / 'index.json').read_text())
    assert data['topic']['topicDirectoryName'] == directory.name
    assert data['layout'] == {'width': 3, 'height': 3}
    assert len(data['photos']['photoItems']) == 9
    for card in data['photos']['photoItems']:
        assert card['id'] not in ids
        ids.add(card['id'])
        assert card['title'] and (directory / card['imageFileName']).is_file()
    assert (directory / data['topic']['imageFileName']).is_file()
print(f'Validated {len(manifest)} boards, {len(ids)} card records, all image references, and both ZIP archives.')

bundle = ROOT.parent / 'PECS Maker' / 'Resources' / 'StarterBoards'
for locale in ('en', 'es'):
    shutil.copytree(ROOT / locale, bundle / locale, dirs_exist_ok=True)
english_bytes = sum(p.stat().st_size for p in (ROOT / 'en' / 'topics').rglob('*') if p.is_file())
print(f'English topics: {english_bytes:,} bytes ({english_bytes / 1_000_000:.2f} MB; {english_bytes / 1024**2:.2f} MiB).')
