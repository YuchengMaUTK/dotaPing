#!/usr/bin/env python3
"""Check tracked and nonignored public files for accidentally included local assets."""
import subprocess
from pathlib import Path
root = Path(__file__).resolve().parents[1]
result = subprocess.run(['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=root, check=True, capture_output=True)
paths = set(result.stdout.decode().split('\0')) - {''}
for name in paths:
    path = Path(name)
    forbidden = (
        name.startswith(('Sources/DotaPing/Resources/Pings/', 'Sources/DotaPing/Resources/Wheel/',
                         'Sources/DotaPing/Resources/Particles/', 'Sources/DotaPing/Resources/Sounds/',
                         '.build/', 'dist/'))
        or (name.startswith('References/') and path.suffix != '.md')
        or path.suffix in {'.wav', '.webm', '.app', '.dmg', '.zip'}
        or path.name in {'.DS_Store', '.env', 'credentials', 'id_rsa', 'id_ed25519'}
    )
    if forbidden:
        raise SystemExit(f'File should not be published: {name}')
    if path.suffix in {'.md', '.swift', '.py', '.sh', '.yml', '.json'}:
        text = (root / path).read_text()
        if ('/' + 'Users' + '/') in text or ('.aki/' + 'aki_workspace') in text:
            raise SystemExit(f'Personal local path found: {name}')
print(f'Public-tree check passed: {len(paths)} files; no excluded game-resource paths or personal macOS paths.')
