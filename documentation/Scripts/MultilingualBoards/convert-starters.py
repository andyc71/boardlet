#!/usr/bin/env python3
"""Convert the original paired en/es catalog, verifying card order through image hashes.
Run once against a legacy StarterBoards root; output must be a separate directory.
"""
import hashlib
import json
import pathlib
import shutil
import sys

source, output = map(pathlib.Path, sys.argv[1:])
output.mkdir(parents=True, exist_ok=False)
orders = {lang: json.loads((source / lang / 'order.json').read_text()) for lang in ('en', 'es')}
legacy = {}
for lang in orders:
    extras = sorted(p.name for p in (source / lang / 'topics').iterdir() if p.is_dir() and p.name not in orders[lang])
    orders[lang].extend(extras)
assert len(orders['en']) == len(orders['es']), 'English and Spanish catalogs must contain the same boards'

def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')

for names in zip(orders['en'], orders['es']):
    assert names[0].rsplit(' - ', 1)[0] == names[1].rsplit(' - ', 1)[0]
    folders = {lang: source / lang / 'topics' / name for lang, name in zip(orders, names)}
    docs = {lang: json.loads((folder / 'index.json').read_text()) for lang, folder in folders.items()}
    doc = docs['en']
    target = output / 'topics' / names[0]
    target.mkdir(parents=True)
    shutil.copyfile(folders['en'] / 'TopicImage.png', target / 'TopicImage.png')
    tables = {lang: {'board.title': d['topic']['topicName']} for lang, d in docs.items()}
    assert len(docs['en']['photos']['photoItems']) == len(docs['es']['photos']['photoItems'])
    aliases = {lang: {'canonicalDirectory': names[0], 'language': lang, 'title': d['topic']['topicName'], 'cards': {}} for lang, d in docs.items()}
    for cards in zip(*(d['photos']['photoItems'] for d in docs.values())):
        hashes = [hashlib.sha256((folders[lang] / c['imageFileName']).read_bytes()).hexdigest() for lang, c in zip(docs, cards)]
        assert hashes[0] == hashes[1], (names, cards)
        key = 'card.' + cards[0]['id']
        image = 'images/' + cards[0]['id'] + '.png'
        (target / 'images').mkdir(exist_ok=True)
        shutil.copyfile(folders['en'] / cards[0]['imageFileName'], target / image)
        for lang, card, digest in zip(docs, cards, hashes):
            tables[lang][key] = card['title']
            aliases[lang]['cards'][card['id']] = {'key': key, 'title': card['title'], 'imageSHA256': digest}
        cards[0]['localizedTitle'] = {'key': key, 'sourceLanguage': 'en'}
        cards[0]['imageFileName'] = image
        del cards[0]['title']
    doc['version'] = 2
    doc['id'] = names[0].rsplit(' - ', 1)[1]
    doc['localization'] = {'title': {'key': 'board.title', 'sourceLanguage': 'en'}, 'languages': list(tables)}
    # Topic's framework metadata still requires a title; resolution never uses it.
    doc['topic']['topicName'] = ''
    write(target / 'index.json', doc)
    for lang, table in tables.items():
        write(target / 'locales' / lang / 'strings.json', table)
    legacy.update({name: aliases[lang] for lang, name in zip(orders, names)})
write(output / 'order.json', orders['en'])
write(output / 'legacy.json', legacy)
