"""Builds assets/models/cars/SuperLowPolyCars.glb from the SuperLowPolyCars pack's FBX files.
Usage: python3 tools/cars_glb.py assets/models/cars/SuperLowPolyCars assets/models/cars/SuperLowPolyCars.glb
No Blender needed (pure Python + Pillow; includes a small binary FBX reader).

One mesh per car variant: body + its wheels merged (the pack keeps wheels as separate FBXs that share
the body's origin), flat shaded, each face's UVs snapped to the centre of its 32x16 palette cell (no
colour bleeding) with the palette upscaled 8x nearest-neighbour and embedded. Ground at y=0, units =
metres. Roblox's glTF import turns the cars to face +Z, so Studio turns each Body 180 degrees and
scales it 4x (see assets/models/cars/README.md)."""
import io, json, os, struct, sys, zlib

from PIL import Image

# --- minimal binary FBX reader -------------------------------------------------------------------
def read_fbx(path):
    data = open(path,'rb').read()
    assert data[:20] == b'Kaydara FBX Binary  ', 'not binary'
    ver = struct.unpack_from('<I', data, 23)[0]
    big = ver >= 7500
    pos = 27
    def prop(p):
        t = chr(data[p]); p += 1
        if t == 'Y': return struct.unpack_from('<h',data,p)[0], p+2
        if t == 'C': return bool(data[p]), p+1
        if t == 'I': return struct.unpack_from('<i',data,p)[0], p+4
        if t == 'F': return struct.unpack_from('<f',data,p)[0], p+4
        if t == 'D': return struct.unpack_from('<d',data,p)[0], p+8
        if t == 'L': return struct.unpack_from('<q',data,p)[0], p+8
        if t in 'SR':
            n = struct.unpack_from('<I',data,p)[0]; p+=4
            b = data[p:p+n]; return (b.decode('utf8','replace') if t=='S' else b), p+n
        if t in 'fdlib':
            n, enc, clen = struct.unpack_from('<III',data,p); p+=12
            raw = data[p:p+clen]; p+=clen
            if enc: raw = zlib.decompress(raw)
            fmt = {'f':'f','d':'d','l':'q','i':'i','b':'?'}[t]
            return list(struct.unpack('<%d%s'%(n,fmt), raw)), p
        raise ValueError(t)
    def node(p):
        if big:
            end, nprops, plen = struct.unpack_from('<QQQ',data,p); p+=24
        else:
            end, nprops, plen = struct.unpack_from('<III',data,p); p+=12
        nl = data[p]; p+=1
        name = data[p:p+nl].decode(); p+=nl
        if end == 0: return None, p
        props=[]
        for _ in range(nprops):
            v,p = prop(p); props.append(v)
        kids=[]
        while p < end:
            k, p2 = node(p)
            if k is None: p = p2; break
            kids.append(k); p = p2
        return (name, props, kids), end
    top=[]
    while pos < len(data):
        n, pos = node(pos)
        if n is None: break
        top.append(n)
    return top
def find(n, name): return [k for k in n[2] if k[0]==name]
def one(n, name):
    r = find(n,name); return r[0] if r else None
def props70(n):
    out={}
    p=one(n,'Properties70')
    if p:
        for P in find(p,'P'): out[P[1][0]] = P[1][4:]
    return out

# --- cars ----------------------------------------------------------------------------------------


PACK, OUT = sys.argv[1], sys.argv[2]
PAL = os.path.join(PACK, 'Textures', 'LowPolyCarTexturePalette.png')
PW, PH = 32, 16
SCALE_UP = 8  # palette upscaled nearest-neighbour


# (car name, body mesh, wheel meshes) - from the pack's Unity prefabs (Car<Type><Colour>.prefab)
WHEELS = {k: ['Wheel%sBack.fbx' % k, 'Wheel%sFrontLeft.fbx' % k, 'Wheel%sFrontRight.fbx' % k]
          for k in ('Default', 'PickUp', 'Truck', 'Van', 'Ambulance')}
TYPES = [  # name, wheels, {colour: body}
    ('Sedan', 'Default', {'': 'Sedan', 'Blue': 'SedanBlue', 'Brown': 'SedanBrown', 'Green': 'SedanGreen', 'Red': 'SedanRed', 'Yellow': 'SedanYellow'}),
    ('Coupe', 'Default', {'': 'Coupe', 'Blue': 'Coupe.002', 'Brown': 'Coupe.005', 'Green': 'Coupe.003', 'Red': 'Coupe.001', 'Yellow': 'Coupe.004'}),
    ('Sport', 'Default', {'': 'SportCar.000', 'Blue': 'SportCar.000', 'Brown': 'SportCar.003', 'Green': 'SportCar.001', 'Red': 'SportCar.006', 'Yellow': 'SportCar.002'}),
    ('Wagon', 'Default', {'': 'StationWagon', 'Blue': 'StationWagon.002', 'Brown': 'StationWagon.005', 'Green': 'StationWagon.003', 'Red': 'StationWagon.001', 'Woody': 'StationWagon.006', 'Yellow': 'StationWagon.004'}),
    ('Pickup', 'PickUp', {'': 'PickUp', 'Brown': 'PickUp.008', 'Blue': 'PickUp.005', 'Green': 'PickUp.006', 'Red': 'PickUp.004', 'Yellow': 'PickUp.007'}),
    ('Truck', 'Truck', {'': 'Truck', 'Blue': 'Truck.002', 'Brown': 'Truck.005', 'Green': 'Truck.003', 'Red': 'Truck.001', 'Yellow': 'Truck.004'}),
    ('Van', 'Van', {'': 'Van', 'Blue': 'Van.003', 'Brown': 'Van.006', 'Green': 'Van.004', 'Red': 'Van.002', 'Yellow': 'Van.005'}),
    ('Police', 'Default', {'': 'PoliceCar'}),
    ('Ambulance', 'Ambulance', {'': 'Ambulance'}),
]
cars = [(name + colour, body + '.fbx', WHEELS[wheels]) for name, wheels, bodies in TYPES for colour, body in bodies.items()]

def geometry(fname):
    top = read_fbx(os.path.join(PACK, 'Models', fname))
    objs = [n for n in top if n[0] == 'Objects'][0]
    g = [o for o in objs[2] if o[0] == 'Geometry'][0]
    v = one(g, 'Vertices')[1][0]
    idx = one(g, 'PolygonVertexIndex')[1][0]
    uvl = one(g, 'LayerElementUV')
    uv = one(uvl, 'UV')[1][0]
    uvi = one(uvl, 'UVIndex')[1][0]
    polys, cur, curuv = [], [], []
    for k, i in enumerate(idx):
        end = i < 0
        vi = ~i if end else i
        cur.append(vi); curuv.append(uvi[k])
        if end:
            polys.append((cur, curuv)); cur, curuv = [], []
    verts = [(v[i], v[i+1], v[i+2]) for i in range(0, len(v), 3)]
    uvs = [(uv[i], uv[i+1]) for i in range(0, len(uv), 2)]
    return verts, uvs, polys

def sub(a, b): return (a[0]-b[0], a[1]-b[1], a[2]-b[2])
def cross(a, b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])

meshes = []
for name, body, wheels in cars:
    P, N, T = [], [], []
    for f in [body] + wheels:
        verts, uvs, polys = geometry(f)
        for vids, uids in polys:
            # face colour = palette cell under the UV centroid
            cu = sum(uvs[u][0] for u in uids) / len(uids)
            cv = sum(uvs[u][1] for u in uids) / len(uids)
            cx = min(PW - 1, max(0, int(cu * PW))); cy = min(PH - 1, max(0, int(cv * PH)))
            tu, tv = (cx + 0.5) / PW, 1 - (cy + 0.5) / PH  # glTF v is flipped
            pts = [(-verts[i][0], verts[i][1], -verts[i][2]) for i in vids]  # 180 deg about Y
            n = (0.0, 0.0, 0.0)
            for j in range(1, len(pts) - 1):
                c = cross(sub(pts[j], pts[0]), sub(pts[j+1], pts[0]))
                n = (n[0]+c[0], n[1]+c[1], n[2]+c[2])
            l = (n[0]**2 + n[1]**2 + n[2]**2) ** 0.5 or 1
            n = (n[0]/l, n[1]/l, n[2]/l)
            for j in range(1, len(pts) - 1):
                for p in (pts[0], pts[j], pts[j+1]):
                    P.append(p); N.append(n); T.append((tu, tv))
    miny = min(p[1] for p in P)
    xs = [p[0] for p in P]; zs = [p[2] for p in P]
    ox, oz = (min(xs)+max(xs))/2, (min(zs)+max(zs))/2
    P = [(p[0]-ox, p[1]-miny, p[2]-oz) for p in P]
    meshes.append((name, P, N, T))

# palette, upscaled
img = Image.open(PAL).convert('RGB').resize((PW*SCALE_UP, PH*SCALE_UP), Image.NEAREST)
buf = io.BytesIO(); img.save(buf, 'PNG'); png = buf.getvalue()

bin_ = bytearray(); views = []; accs = []; gmeshes = []; nodes = []
def add_view(b, target=None):
    while len(bin_) % 4: bin_.append(0)
    off = len(bin_); bin_.extend(b)
    v = {'buffer': 0, 'byteOffset': off, 'byteLength': len(b)}
    if target: v['target'] = target
    views.append(v); return len(views) - 1
for name, P, N, T in meshes:
    ids = []
    for arr, typ in ((P, 'VEC3'), (N, 'VEC3'), (T, 'VEC2')):
        flat = [c for a in arr for c in a]
        vw = add_view(struct.pack('<%df' % len(flat), *flat), 34962)
        acc = {'bufferView': vw, 'componentType': 5126, 'count': len(arr), 'type': typ}
        if arr is P:
            acc['min'] = [min(p[i] for p in P) for i in range(3)]
            acc['max'] = [max(p[i] for p in P) for i in range(3)]
        accs.append(acc); ids.append(len(accs) - 1)
    gmeshes.append({'name': name, 'primitives': [{'attributes': {'POSITION': ids[0], 'NORMAL': ids[1], 'TEXCOORD_0': ids[2]}, 'material': 0}]})
    nodes.append({'name': name, 'mesh': len(gmeshes) - 1})
imgview = add_view(png)
gltf = {
    'asset': {'version': '2.0', 'generator': 'ragdoll-biker build_cars_glb.py'},
    'scene': 0, 'scenes': [{'nodes': list(range(len(nodes)))}], 'nodes': nodes, 'meshes': gmeshes,
    'accessors': accs, 'bufferViews': views, 'buffers': [{'byteLength': 0}],
    'materials': [{'name': 'LowPolyCarPalette', 'pbrMetallicRoughness': {'baseColorTexture': {'index': 0}, 'metallicFactor': 0, 'roughnessFactor': 0.8}}],
    'textures': [{'source': 0, 'sampler': 0}], 'samplers': [{'magFilter': 9728, 'minFilter': 9728}],
    'images': [{'bufferView': imgview, 'mimeType': 'image/png', 'name': 'LowPolyCarTexturePalette'}],
}
while len(bin_) % 4: bin_.append(0)
gltf['buffers'][0]['byteLength'] = len(bin_)
js = json.dumps(gltf, separators=(',', ':')).encode()
while len(js) % 4: js += b' '
out = struct.pack('<III', 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(bin_))
out += struct.pack('<II', len(js), 0x4E4F534A) + js + struct.pack('<II', len(bin_), 0x004E4942) + bytes(bin_)
open(OUT, 'wb').write(out)
img.save(os.path.splitext(OUT)[0] + '_Palette.png')
for name, P, N, T in meshes:
    print(name, len(P)//3, 'tris', 'size', [round(max(p[i] for p in P) - min(p[i] for p in P), 2) for i in range(3)])
