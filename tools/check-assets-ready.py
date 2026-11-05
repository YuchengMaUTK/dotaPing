#!/usr/bin/env python3
"""Fail early with useful instructions when a source checkout lacks game assets."""
import hashlib
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
for entry in json.loads((root / 'ASSET_IMPORT.json').read_text())['files']:
    path = root / entry['path']
    if not path.is_file():
        raise SystemExit('Game assets are not included in this source release. Import an authorized local set with: python3 tools/import-assets.py --source /absolute/path/to/DotaPing')
    data = path.read_bytes()
    if len(data) != entry['bytes'] or hashlib.sha256(data).hexdigest() != entry['sha256']:
        raise SystemExit(f'Asset integrity mismatch: {entry["path"]}')
print('Local asset set is complete and checksum-verified.')
