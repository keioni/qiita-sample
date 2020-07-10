import sys
import json
import base64

with open(sys.argv[1]) as fp:
    pkey = json.load(fp)

print('asn1=SEQUENCE:private_key\n[private_key]')
print('version=INTEGER:0')
for k,v in pkey.items():
    if k == 'kty':
        continue
    missing_padding = 4　-　len(v) % 4
    if missing_padding != 4:
      v = v + ('='*missing_padding)
    v_hex = base64.urlsafe_b64decode(v).hex().upper()
    print('{}=INTEGER:0x{}'.format(k, v_hex))
