#!/usr/bin/env python3
"""Check original icon sizes, ICNS structure and packaged resource references."""
import plistlib
import struct
from pathlib import Path

root = Path(__file__).resolve().parents[1]
for n in [16, 32, 128, 256, 512]:
    for suffix, scale in [('', 1), ('@2x', 2)]:
        data = (root / f'Design/AppIcon.iconset/icon_{n}x{n}{suffix}.png').read_bytes()
        assert data[:8] == b'\x89PNG\r\n\x1a\n'
        assert struct.unpack('>II', data[16:24]) == (n * scale, n * scale)
for suffix, n in [('', 18), ('@2x', 36)]:
    data = (root / f'Sources/DotaPing/Resources/Branding/StatusIcon{suffix}.png').read_bytes()
    assert struct.unpack('>II', data[16:24]) == (n, n)
data = (root / 'Design/AppIcon.icns').read_bytes()
assert data[:4] == b'icns' and struct.unpack('>I', data[4:8])[0] == len(data)
offset = 8
kinds = set()
while offset < len(data):
    kind, length = data[offset:offset+4], struct.unpack('>I', data[offset+4:offset+8])[0]
    assert length >= 8
    kinds.add(kind)
    offset += length
assert offset == len(data)
assert {b'ic07', b'ic08', b'ic09', b'ic10', b'ic11', b'ic12', b'ic13', b'ic14'} <= kinds
app = root / 'dist/DotaPing.app/Contents'
info = plistlib.loads((app / 'Info.plist').read_bytes())
assert info['CFBundleIconFile'] == 'AppIcon'
assert (app / 'Resources/AppIcon.icns').read_bytes() == data
for name in ['StatusIcon.png', 'StatusIcon@2x.png']:
    bundled = app / 'Resources/DotaPing_DotaPing.bundle/Contents/Resources/Branding' / name
    assert bundled.read_bytes() == (root / 'Sources/DotaPing/Resources/Branding' / name).read_bytes()
print('Original icon checks passed: ten app sizes, 1x/2x status icons, ICNS structure, plist reference and packaged bytes.')
