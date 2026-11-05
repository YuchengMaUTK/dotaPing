#!/usr/bin/env python3
"""Validate bundled ping sounds: provenance hashes, WAV headers, native macOS decode and event mapping against ping_wheel.vdata."""
import hashlib
import json
import re
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sounds = root / 'Sources' / 'DotaPing' / 'Resources' / 'Sounds'
manifest = json.loads((root / 'SOUND_SOURCES.json').read_text())
catalog = json.loads((sounds / 'sound_events.json').read_text())
excerpts = manifest['soundEventSource']['excerpts']

scratch = Path(tempfile.gettempdir())

listed = {entry['file'] for entry in manifest['files']}
bundled = {path.name for path in sounds.glob('*.wav')}
if listed != bundled:
    raise ValueError(f'Bundled WAVs differ from manifest: {sorted(listed ^ bundled)}')

for entry in manifest['files']:
    path = (sounds / entry['file']).resolve()
    if not path.is_relative_to(sounds.resolve()):
        raise ValueError(f'Sound path escapes resource folder: {entry["file"]}')
    data = path.read_bytes()
    if len(data) != entry['bytes'] or hashlib.sha256(data).hexdigest() != entry['sha256']:
        raise ValueError(f'Sound mismatch: {entry["file"]}')
    if data[:4] != b'RIFF' or data[8:12] != b'WAVE':
        raise ValueError(f'Not a WAV: {entry["file"]}')
    if entry['gameResource'] != f'sounds/ui/{path.stem}.vsnd_c' or entry['gameResourceListing']['bytes'] <= len(data):
        raise ValueError(f'Implausible game resource for {entry["file"]}')
    info = subprocess.run(['afinfo', str(path)], capture_output=True, text=True, check=True).stdout
    duration = float(re.search(r'estimated duration: ([\d.]+)', info).group(1))
    if duration < 0.3:
        raise ValueError(f'Too short: {entry["file"]}')
    with tempfile.TemporaryDirectory(dir=scratch) as folder:
        decoded = Path(folder) / 'decoded.caf'
        subprocess.run(['afconvert', '-f', 'caff', '-d', 'LEF32', str(path), str(decoded)], check=True, capture_output=True)
        if decoded.stat().st_size < len(data):
            raise ValueError(f'Decode truncated: {entry["file"]}')

vdata = (root / 'References' / 'ping_wheel.vdata').read_text()
wheel = {}
for key, body in re.findall(r'^\t(\w+) = \n\t\{(.*?)^\t\}', vdata, re.S | re.M):
    match = re.search(r'sSound = (?:soundevent:)?"([^"]+)"', body)
    if match:
        wheel[key] = match.group(1)
expected_pings = {'attention', 'danger', 'onMyWay', 'defend', 'attack', 'enemyVision', 'needVision', 'help', 'heart'}
if set(catalog['pings']) != expected_pings:
    raise ValueError('Catalog does not cover every Ping case')
for ping, entry in catalog['pings'].items():
    if wheel.get(entry['wheelKey']) != entry['event']:
        raise ValueError(f'{ping}: {entry["wheelKey"]} plays {wheel.get(entry["wheelKey"])}, catalog says {entry["event"]}')
    voices = catalog['events'][entry['event']]
    if not voices or voices[0]['event'] != entry['event']:
        raise ValueError(f'{entry["event"]} has no base voice')
    if [voice['event'] for voice in voices[1:]] != excerpts.get(entry['event'], {}).get('layers', []):
        raise ValueError(f'{entry["event"]} layers differ from game sound event record')
    for voice in voices:
        record = excerpts.get(voice['event'])
        if record is None or record['files'] != [f'sounds/ui/{voice["file"]}'] or record['volume'] != voice['volume'] or record['pitch'] != voice['pitch']:
            raise ValueError(f'Voice differs from game sound event record: {voice}')
        if voice['file'] not in bundled or not 0 < voice['volume'] <= 1 or not 0.5 <= voice['pitch'] <= 2:
            raise ValueError(f'Bad voice in {entry["event"]}: {voice}')

print(f'Verified {len(bundled)} original ping WAVs (hash, bytes, RIFF/WAVE, afinfo + afconvert decode) '
      f'and {len(catalog["pings"])} ping -> sound event mappings against ping_wheel.vdata and {len(excerpts)} game sound event records.')
