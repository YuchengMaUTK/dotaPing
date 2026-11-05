#!/usr/bin/env python3
"""Import a complete, checksum-matching local asset set without downloading."""
import argparse
import hashlib
import json
import shutil
from pathlib import Path

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source', required=True, type=Path, help='Existing DotaPing project root containing authorized assets')
args = parser.parse_args()
source = args.source.expanduser().resolve()
entries = json.loads((root / 'ASSET_IMPORT.json').read_text())['files']
pending = []
for entry in entries:
    relative = Path(entry['path'])
    src, dst = (source / relative).resolve(), (root / relative).resolve()
    if not src.is_relative_to(source) or not dst.is_relative_to(root):
        raise SystemExit(f'Unsafe asset path: {relative}')
    data = src.read_bytes()
    if len(data) != entry['bytes'] or hashlib.sha256(data).hexdigest() != entry['sha256']:
        raise SystemExit(f'Source checksum mismatch: {relative}')
    if dst.exists() and dst.read_bytes() != data:
        raise SystemExit(f'Destination differs; resolve manually before importing: {relative}')
    pending.append((src, dst))
for src, dst in pending:
    if src == dst:
        continue
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst)
print(f'Imported {len(pending)} verified local files. Game resources remain excluded from Git.')
