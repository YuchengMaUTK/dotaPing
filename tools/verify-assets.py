#!/usr/bin/env python3
"""Validate downloaded source assets against their checked-in provenance manifests."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
resources = root / 'Sources' / 'DotaPing' / 'Resources'
checked = 0
for manifest in ('ASSET_SOURCES.json', 'V06_ASSET_SOURCES.json', 'V07_ASSET_SOURCES.json', 'V082_ASSET_SOURCES.json'):
    document = json.loads((root / manifest).read_text())
    entries = document['textures'] if isinstance(document, dict) else document
    for entry in entries:
        relative = Path(entry['file'])
        if manifest == 'ASSET_SOURCES.json':
            relative = Path('Pings') / relative
        path = (resources / relative).resolve()
        if not path.is_relative_to(resources.resolve()):
            raise ValueError(f'Asset path escapes resource folder: {relative}')
        data = path.read_bytes()
        if len(data) != entry['bytes'] or hashlib.sha256(data).hexdigest() != entry['sha256']:
            raise ValueError(f'Asset mismatch: {relative}')
        if not data.startswith(b'\x89PNG\r\n\x1a\n'):
            raise ValueError(f'Not a PNG: {relative}')
        checked += 1
print(f'Verified {checked} original PNGs: hashes, byte counts and PNG headers.')

bronze = json.loads((root / 'V082_ASSET_SOURCES.json').read_text())['atlas']
metadata = (root / 'References/hero_level.json').read_bytes()
if hashlib.sha256(metadata).hexdigest() != bronze['sha256']:
    raise ValueError('Hero level atlas metadata mismatch')
atlas = json.loads(metadata)
if atlas['sequences'][0]['frames'][0][:4] != bronze['bronzeFrameTopLeft']:
    raise ValueError('Bronze tier frame mismatch')
if (atlas['width'], atlas['height']) != (bronze['width'], bronze['height']):
    raise ValueError('Hero level atlas dimensions mismatch')
print('Verified bronze atlas metadata: dimensions, sequence 0 frame and SHA256.')
