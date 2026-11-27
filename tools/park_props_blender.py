"""Builds and bakes the low-poly park props in Blender (run inside Blender: exec(open(path).read())).

Each prop is modelled from simple parts that use real procedural materials (wood grain, bark,
worn paint over metal with highlighted edges, iron, leaves from painted textures), then joined
and baked into its own textures for Roblox:
  <Prop>_Color.png  - albedo with ambient occlusion and edge highlights baked in (RGBA for props
                      with leaf cards: the alpha cuts out the leaves)
  <Prop>_Normal.png - tangent-space normal map (rounded edges, grain and bark relief)
Source textures come from tools/park_textures.py (assets/models/park/src). Units are studs,
front = -Y, up = +Z. Writes assets/models/park/ParkProps.fbx and the textures.
"""
import math
import os
import random

import bpy
from mathutils import Vector

ROOT = r"C:\Users\kgkan\Documents\GitHub\Ragdoll Biker 💀🦴\assets\models\park"
SRC = os.path.join(ROOT, "src")
SAMPLES = 24
random.seed(11)

for obj in list(bpy.data.objects):
    bpy.data.objects.remove(obj, do_unlink=True)
for block in (bpy.data.meshes, bpy.data.materials, bpy.data.images):
    for item in list(block):
        if item.users == 0 or block is not bpy.data.images:
            try:
                block.remove(item)
            except Exception:
                pass

scene = bpy.context.scene
try:
    scene.render.engine = "CYCLES"
except TypeError:
    pass
scene.cycles.samples = SAMPLES
scene.cycles.device = "CPU"


# --- node helpers ---------------------------------------------------------------------------------
class Graph:
    """Small wrapper to build node trees tersely."""

    def __init__(self, mat):
        mat.use_nodes = True
        self.tree = mat.node_tree
        self.nodes = self.tree.nodes
        for n in list(self.nodes):
            self.nodes.remove(n)
        self.out = self.add("ShaderNodeOutputMaterial")
        self.bsdf = self.add("ShaderNodeBsdfPrincipled")
        self.link(self.bsdf, 0, self.out, 0)

    def add(self, kind, **props):
        node = self.nodes.new(kind)
        for key, value in props.items():
            setattr(node, key, value)
        return node

    def link(self, a, a_out, b, b_in):
        self.tree.links.new(a.outputs[a_out], b.inputs[b_in])

    def value(self, v):
        node = self.add("ShaderNodeValue")
        node.outputs[0].default_value = v
        return node

    def math(self, op, a, b=None, clamp=False):
        node = self.add("ShaderNodeMath", operation=op, use_clamp=clamp)
        for i, src in enumerate((a, b)):
            if src is None:
                continue
            if isinstance(src, (int, float)):
                node.inputs[i].default_value = src
            else:
                self.link(src[0], src[1], node, i)
        return (node, 0)

    def mix(self, fac, a, b):
        node = self.add("ShaderNodeMix", data_type="RGBA")
        for socket, src in ((0, fac), (6, a), (7, b)):
            if isinstance(src, tuple) and len(src) == 2 and not isinstance(src[0], float):
                self.link(src[0], src[1], node, socket)
            elif isinstance(src, (int, float)):
                node.inputs[socket].default_value = src
            else:
                node.inputs[socket].default_value = (*src, 1) if len(src) == 3 else src
        return (node, 2)

    def ramp(self, fac, stops):
        node = self.add("ShaderNodeValToRGB")
        elems = node.color_ramp.elements
        while len(elems) < len(stops):
            elems.new(0.5)
        for elem, (pos, rgb) in zip(elems, stops):
            elem.position = pos
            elem.color = (*rgb, 1)
        self.link(fac[0], fac[1], node, 0)
        return (node, 0)

    def coords(self, scale=(1, 1, 1), kind="Object"):
        tc = self.add("ShaderNodeTexCoord")
        mp = self.add("ShaderNodeMapping")
        mp.inputs["Scale"].default_value = scale
        self.link(tc, kind, mp, 0)
        return (mp, 0)

    def ao(self, distance=1.0):
        node = self.add("ShaderNodeAmbientOcclusion", samples=16)
        node.inputs["Distance"].default_value = distance
        return (node, 1)

    def edge_mask(self, radius=0.06, strength=10):
        """0 on flat faces, 1 on sharp edges (bevel normal vs true normal)."""
        bevel = self.add("ShaderNodeBevel", samples=8)
        bevel.inputs["Radius"].default_value = radius
        geo = self.add("ShaderNodeNewGeometry")
        dot = self.add("ShaderNodeVectorMath", operation="DOT_PRODUCT")
        self.link(bevel, 0, dot, 0)
        self.link(geo, "Normal", dot, 1)
        inv = self.math("SUBTRACT", 1.0, (dot, "Value"))
        return self.math("MULTIPLY", inv, strength, clamp=True)

    def finish(self, colour, height=None, bump=0.3, roughness=0.8, alpha=None, bevel=0.05):
        """colour = socket for base colour; height = socket for bump; alpha = socket or None."""
        self.link(colour[0], colour[1], self.bsdf, "Base Color")
        self.bsdf.inputs["Roughness"].default_value = roughness
        bev = self.add("ShaderNodeBevel", samples=8)
        bev.inputs["Radius"].default_value = bevel
        normal = (bev, 0)
        if height is not None:
            b = self.add("ShaderNodeBump")
            b.inputs["Strength"].default_value = bump
            self.link(height[0], height[1], b, "Height")
            self.link(bev, 0, b, "Normal")
            normal = (b, 0)
        self.link(normal[0], normal[1], self.bsdf, "Normal")
        # the bake reads alpha from this node (see bake_alpha)
        a = alpha or (self.value(1.0), 0)
        holder = self.add("ShaderNodeMath", operation="ADD", name="AlphaOut")
        holder.name = "AlphaOut"
        self.link(a[0], a[1], holder, 0)
        holder.inputs[1].default_value = 0
        if alpha is not None:
            self.link(a[0], a[1], self.bsdf, "Alpha")


def image(name):
    return bpy.data.images.load(os.path.join(SRC, name), check_existing=True)


def shaded(g, colour, ao_distance=1.2, edge=0.0, edge_colour=(1, 1, 1)):
    """Colour darkened in crevices (AO) and optionally brightened on edges."""
    out = g.mix(g.math("MULTIPLY", g.ao(ao_distance), 0.85), (0.35, 0.35, 0.35), (1, 1, 1))
    out_node = g.add("ShaderNodeMix", data_type="RGBA", blend_type="MULTIPLY")
    out_node.inputs[0].default_value = 1
    g.link(colour[0], colour[1], out_node, 6)
    g.link(out[0], out[1], out_node, 7)
    result = (out_node, 2)
    if edge > 0:
        mask = g.edge_mask()
        result = g.mix(g.math("MULTIPLY", mask, edge), result, edge_colour)
    return result


# --- material library ------------------------------------------------------------------------------
MATS = {}


def material(name, build):
    if name not in MATS:
        mat = bpy.data.materials.new(name)
        g = Graph(mat)
        build(g)
        MATS[name] = mat
    return MATS[name]


def wood(name, light, dark, grain_scale=2.5):
    def build(g):
        co = g.coords((0.35, grain_scale, grain_scale))
        wave = g.add("ShaderNodeTexWave", wave_type="BANDS", bands_direction="Y")
        wave.inputs["Scale"].default_value = 3.0
        wave.inputs["Distortion"].default_value = 7.0
        wave.inputs["Detail"].default_value = 4.0
        wave.inputs["Detail Scale"].default_value = 1.6
        g.link(co[0], co[1], wave, "Vector")
        fibres = g.add("ShaderNodeTexNoise")
        fibres.inputs["Scale"].default_value = 40.0
        co2 = g.coords((0.15, 12, 12))
        g.link(co2[0], co2[1], fibres, "Vector")
        grain = g.math("ADD", (wave, "Fac"), g.math("MULTIPLY", (fibres, "Fac"), 0.25))
        col = g.ramp(grain, [(0.15, dark), (0.55, light), (0.9, tuple(min(1, c * 1.15) for c in light))])
        g.finish(shaded(g, col, edge=0.25, edge_colour=tuple(min(1, c * 1.3) for c in light)), height=grain, bump=0.25, roughness=0.75)
    return material(name, build)


def bark():
    def build(g):
        co = g.coords((3.5, 3.5, 0.5))
        vor = g.add("ShaderNodeTexVoronoi", feature="DISTANCE_TO_EDGE")
        vor.inputs["Scale"].default_value = 3.0
        g.link(co[0], co[1], vor, "Vector")
        noise = g.add("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 6.0
        g.link(co[0], co[1], noise, "Vector")
        ridges = g.math("ADD", g.math("MULTIPLY", (vor, "Distance"), 3.0, clamp=True), g.math("MULTIPLY", (noise, "Fac"), 0.3))
        col = g.ramp(ridges, [(0.05, (0.13, 0.08, 0.05)), (0.5, (0.32, 0.21, 0.13)), (0.95, (0.48, 0.34, 0.22))])
        g.finish(shaded(g, col, ao_distance=2.0), height=ridges, bump=0.8, roughness=0.95)
    return material("Bark", build)


def painted_metal(name, paint):
    def build(g):
        mask = g.edge_mask(0.05, 14)
        wear_noise = g.add("ShaderNodeTexNoise")
        wear_noise.inputs["Scale"].default_value = 18.0
        co = g.coords((1, 1, 1))
        g.link(co[0], co[1], wear_noise, "Vector")
        wear = g.math("GREATER_THAN", g.math("MULTIPLY", mask, (wear_noise, "Fac")), 0.32)
        base = g.mix(g.math("MULTIPLY", (wear_noise, "Fac"), 0.15), paint, tuple(c * 0.85 for c in paint))
        worn = g.mix(wear, base, (0.62, 0.62, 0.66))
        highlight = g.mix(g.math("MULTIPLY", mask, 0.45), worn, (1, 1, 1))
        g.finish(shaded(g, highlight), roughness=0.45, bevel=0.04)
    return material(name, build)


def iron(name="Iron", colour=(0.1, 0.11, 0.13)):
    def build(g):
        mask = g.edge_mask(0.05, 14)
        scratch = g.add("ShaderNodeTexNoise")
        scratch.inputs["Scale"].default_value = 60.0
        co = g.coords((1, 1, 8))
        g.link(co[0], co[1], scratch, "Vector")
        base = g.mix(g.math("MULTIPLY", (scratch, "Fac"), 0.25), colour, (0.25, 0.26, 0.3))
        lit = g.mix(g.math("MULTIPLY", mask, 0.8), base, (0.75, 0.78, 0.82))
        g.finish(shaded(g, lit), roughness=0.35, bevel=0.03)
    return material(name, build)


def leaves():
    def build(g):
        tex = g.add("ShaderNodeTexImage", projection="BOX", projection_blend=0.35)
        tex.image = image("Leaves.png")
        co = g.coords((0.12, 0.12, 0.12))
        g.link(co[0], co[1], tex, "Vector")
        lum = g.add("ShaderNodeRGBToBW")
        g.link(tex, 0, lum, 0)
        g.finish(shaded(g, (tex, 0), ao_distance=4.0), height=(lum, 0), bump=0.6, roughness=0.7)
    return material("Leaves", build)


def leaf_card():
    def build(g):
        uv = g.add("ShaderNodeUVMap", uv_map="UVMap")
        tex = g.add("ShaderNodeTexImage")
        tex.image = image("LeafCard.png")
        g.link(uv, 0, tex, "Vector")
        g.finish(shaded(g, (tex, 0), ao_distance=3.0), roughness=0.7, alpha=(tex, 1))
    return material("LeafCard", build)


def fir():
    def build(g):
        tex = g.add("ShaderNodeTexImage", projection="BOX", projection_blend=0.3)
        tex.image = image("FirNeedles.png")
        co = g.coords((0.09, 0.09, 0.09))
        g.link(co[0], co[1], tex, "Vector")
        lum = g.add("ShaderNodeRGBToBW")
        g.link(tex, 0, lum, 0)
        g.finish(shaded(g, (tex, 0), ao_distance=3.0), height=(lum, 0), bump=0.7, roughness=0.8)
    return material("Fir", build)


def petal(name, colour):
    def build(g):
        geo = g.add("ShaderNodeNewGeometry")
        sep = g.add("ShaderNodeSeparateXYZ")
        tc = g.add("ShaderNodeTexCoord")
        g.link(tc, "Generated", sep, 0)
        tip = g.mix((sep, 2), tuple(c * 0.75 for c in colour), tuple(min(1, c * 1.15 + 0.1) for c in colour))
        g.finish(shaded(g, tip, ao_distance=0.5), roughness=0.6, bevel=0.02)
    return material(name, build)


def plain(name, colour, roughness=0.8, edge=0.0):
    def build(g):
        noise = g.add("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 25.0
        col = g.mix(g.math("MULTIPLY", (noise, "Fac"), 0.2), colour, tuple(c * 0.85 for c in colour))
        g.finish(shaded(g, col, edge=edge), roughness=roughness)
    return material(name, build)


def glass():
    def build(g):
        tc = g.add("ShaderNodeTexCoord")
        sep = g.add("ShaderNodeSeparateXYZ")
        g.link(tc, "Generated", sep, 0)
        col = g.ramp((sep, 2), [(0.0, (1.0, 0.82, 0.45)), (1.0, (1.0, 0.97, 0.8))])
        g.finish(col, roughness=0.1)
    return material("LampGlass", build)


# --- primitives ------------------------------------------------------------------------------------
def finish(obj, mat, location=(0, 0, 0), rotation=(0, 0, 0)):
    obj.location = location
    obj.rotation_euler = rotation
    obj.data.materials.append(mat)
    return obj


def cylinder(mat, radius, depth, location, rotation=(0, 0, 0), sides=8, radius2=None):
    bpy.ops.mesh.primitive_cone_add(vertices=sides, radius1=radius, radius2=radius if radius2 is None else radius2, depth=depth)
    return finish(bpy.context.object, mat, location, rotation)


def cone(mat, radius, depth, location, sides=10, jag=0.0):
    bpy.ops.mesh.primitive_cone_add(vertices=sides, radius1=radius, radius2=0, depth=depth)
    obj = bpy.context.object
    for v in obj.data.vertices:  # ragged bottom edge so the tiers look like branches
        if v.co.z < 0 and jag:
            v.co.z -= random.uniform(0, jag)
            v.co.x *= 1 + random.uniform(-0.08, 0.12)
            v.co.y *= 1 + random.uniform(-0.08, 0.12)
    return finish(obj, mat, location)


def box(mat, size, location, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1)
    obj = bpy.context.object
    obj.scale = size
    bpy.ops.object.transform_apply(scale=True)
    return finish(obj, mat, location, rotation)


def blob(mat, radius, location, squash=0.85, jitter=0.18, subdivisions=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=radius)
    obj = bpy.context.object
    for v in obj.data.vertices:
        v.co *= 1 + random.uniform(-jitter, jitter)
        v.co.z *= squash
    return finish(obj, mat, location)


def tube(mat, a, b, radius, sides=8):
    a, b = Vector(a), Vector(b)
    obj = cylinder(mat, radius, (b - a).length, (a + b) / 2, sides=sides)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = (b - a).to_track_quat("Z", "Y")
    return obj


def card(mat, centre, size, normal):
    """A square leaf card facing `normal`."""
    bpy.ops.mesh.primitive_plane_add(size=size)
    obj = bpy.context.object
    obj.location = centre
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector(normal).to_track_quat("Z", "Y")
    obj.data.materials.append(mat)
    return obj


def leafy(blob_specs, mat_blob, mat_card, cards_per_blob, card_size):
    """Canopy: leaf-textured lumps with leaf cards poking out of their surface."""
    parts = []
    for (x, y, z, r) in blob_specs:
        parts.append(blob(mat_blob, r, (x, y, z), subdivisions=1))
        for _ in range(cards_per_blob):
            d = Vector((random.uniform(-1, 1), random.uniform(-1, 1), random.uniform(-0.4, 1))).normalized()
            centre = Vector((x, y, z)) + d * r * random.uniform(0.75, 0.95)
            tilt = (d + Vector((random.uniform(-0.6, 0.6), random.uniform(-0.6, 0.6), random.uniform(-0.6, 0.6)))).normalized()
            parts.append(card(mat_card, centre, card_size * random.uniform(0.8, 1.2), tilt))
    return parts


def join(name, parts):
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)  # origin = ground centre
    return obj


# --- props -----------------------------------------------------------------------------------------
def oak_tree():
    parts = [cylinder(bark(), 1.3, 10, (0, 0, 5), radius2=0.8, sides=9)]
    parts.append(tube(bark(), (0, 0, 7), (2.4, 0.5, 10), 0.45))
    parts.append(tube(bark(), (0, 0, 7.5), (-2, -0.8, 10.5), 0.4))
    parts += leafy([(0, 0, 13, 5.2), (2.8, 0.6, 11.5, 3.8), (-2.6, -0.9, 12, 4.0), (0.4, 2.2, 15, 3.4)], leaves(), leaf_card(), 9, 3.6)
    return join("OakTree", parts)


def fir_tree():
    parts = [cylinder(bark(), 0.9, 4, (0, 0, 2), radius2=0.7, sides=8)]
    for z, r, h in [(6, 5.2, 7), (10, 4, 6), (13.5, 2.8, 5), (16.3, 1.6, 3.6)]:
        parts.append(cone(fir(), r, h, (0, 0, z), sides=14, jag=0.9))
    return join("FirTree", parts)


def bush():
    parts = leafy([(0, 0, 1.6, 2.1), (1.6, 0.4, 1.3, 1.6), (-1.4, -0.6, 1.2, 1.4), (0.3, -1.4, 1.1, 1.2)], leaves(), leaf_card(), 6, 1.8)
    return join("Bush", parts)


PETALS = [("PetalPink", (0.98, 0.45, 0.68)), ("PetalPurple", (0.62, 0.42, 0.95)), ("PetalYellow", (1.0, 0.82, 0.25))]


def flower(x, y, petal_mat, height):
    stem = plain("Stem", (0.2, 0.5, 0.18))
    parts = [tube(stem, (x, y, 0), (x, y, height), 0.07, sides=5)]
    for i in range(5):
        a = i * math.tau / 5
        parts.append(blob(petal_mat, 0.32, (x + math.cos(a) * 0.35, y + math.sin(a) * 0.35, height), squash=0.45, jitter=0.05, subdivisions=1))
    parts.append(blob(plain("FlowerCentre", (0.95, 0.75, 0.2)), 0.2, (x, y, height + 0.06), squash=0.6, jitter=0, subdivisions=1))
    parts.append(blob(stem, 0.35, (x + 0.25, y, height * 0.4), squash=0.35, jitter=0, subdivisions=1))
    return parts


def flower_patch():
    parts = []
    for i in range(9):
        name, colour = PETALS[i % 3]
        parts += flower(random.uniform(-2.2, 2.2), random.uniform(-2.2, 2.2), petal(name, colour), random.uniform(0.9, 1.6))
    return join("FlowerPatch", parts)


def bench():
    plank = wood("WoodPlank", (0.62, 0.42, 0.24), (0.36, 0.22, 0.12))
    frame = iron()
    parts = []
    for y in (-0.5, 0, 0.5):
        parts.append(box(plank, (6, 0.45, 0.18), (0, y, 1.9)))
    for z in (2.6, 3.2):
        parts.append(box(plank, (6, 0.16, 0.45), (0, 0.85, z), rotation=(math.radians(-12), 0, 0)))
    for x in (-2.5, 2.5):
        parts.append(box(frame, (0.25, 1.4, 0.25), (x, 0, 1.75)))
        parts.append(box(frame, (0.25, 0.25, 1.8), (x, -0.5, 0.9)))
        parts.append(box(frame, (0.25, 0.25, 3.3), (x, 0.65, 1.65), rotation=(math.radians(-10), 0, 0)))
    return join("Bench", parts)


def picnic_table():
    plank = wood("WoodPlank", (0.62, 0.42, 0.24), (0.36, 0.22, 0.12))
    legs = wood("WoodDark", (0.45, 0.3, 0.17), (0.25, 0.15, 0.08))
    parts = []
    for y in (-0.9, -0.3, 0.3, 0.9):
        parts.append(box(plank, (7, 0.55, 0.22), (0, y, 3.2)))
    for y in (-2.6, 2.6):
        for dy in (-0.3, 0.3):
            parts.append(box(plank, (7, 0.55, 0.2), (0, y + dy, 1.8)))
    for x in (-2.8, 2.8):
        for s in (-1, 1):
            parts.append(tube(legs, (x, s * 2.9, 0), (x, 0, 3.1), 0.2, sides=4))
        parts.append(box(legs, (0.3, 6, 0.3), (x, 0, 1.6)))
    return join("PicnicTable", parts)


def lamp():
    metal = iron("LampIron", (0.08, 0.09, 0.1))
    parts = [cylinder(metal, 0.6, 0.6, (0, 0, 0.3), sides=10), cylinder(metal, 0.22, 11, (0, 0, 5.8), radius2=0.16, sides=10)]
    parts.append(box(metal, (1.6, 1.6, 0.25), (0, 0, 11.4)))
    parts.append(box(glass(), (1.2, 1.2, 1.6), (0, 0, 12.4)))
    parts.append(cone(metal, 1.3, 0.9, (0, 0, 13.65), sides=4))
    for x, y in ((0.65, 0.65), (-0.65, 0.65), (0.65, -0.65), (-0.65, -0.65)):
        parts.append(box(metal, (0.15, 0.15, 1.7), (x, y, 12.4)))
    return join("Lamp", parts)


def swing_set():
    legs = painted_metal("PaintBlue", (0.2, 0.45, 0.85))
    bar = painted_metal("PaintRed", (0.85, 0.22, 0.18))
    seat = painted_metal("PaintYellow", (0.95, 0.72, 0.15))
    chain = iron("Chain", (0.3, 0.3, 0.33))
    parts = []
    w, h = 7, 9
    for x in (-w, w):
        for s in (-1, 1):
            parts.append(tube(legs, (x, s * 3, 0), (x, 0, h), 0.28))
    parts.append(tube(bar, (-w - 0.5, 0, h), (w + 0.5, 0, h), 0.34))
    for x in (-3.2, 3.2):
        for dx in (-0.8, 0.8):
            parts.append(tube(chain, (x + dx, 0, h), (x + dx, 0, 2.2), 0.06, sides=4))
        parts.append(box(seat, (2.2, 0.9, 0.2), (x, 0, 2.1)))
    return join("SwingSet", parts)


def jungle_gym():
    yellow = painted_metal("PaintYellow", (0.95, 0.72, 0.15))
    red = painted_metal("PaintRed", (0.85, 0.22, 0.18))
    blue = painted_metal("PaintBlue", (0.2, 0.45, 0.85))
    deck = wood("WoodPlank", (0.62, 0.42, 0.24), (0.36, 0.22, 0.12))
    parts = []
    size, levels = 3, 2
    for i in range(3):
        for j in range(3):
            x, y = (i - 1) * size, (j - 1) * size
            parts.append(tube((yellow, red)[(i + j) % 2], (x, y, 0), (x, y, size * levels), 0.16))
    for k in range(1, levels + 1):
        z = k * size
        for i in range(3):
            parts.append(tube(blue, ((i - 1) * size, -size, z), ((i - 1) * size, size, z), 0.14))
            parts.append(tube(blue, (-size, (i - 1) * size, z), (size, (i - 1) * size, z), 0.14))
    parts.append(box(deck, (size * 2, size * 2, 0.25), (0, 0, size + 0.1)))
    parts.append(box(red, (2.2, 7, 0.2), (size + 3.0, 0, size * 0.55), rotation=(0, math.radians(30), math.radians(90))))
    return join("JungleGym", parts)


# --- baking ----------------------------------------------------------------------------------------
def unwrap_for_bake(obj):
    mesh = obj.data
    bake_uv = mesh.uv_layers.get("Bake") or mesh.uv_layers.new(name="Bake")
    mesh.uv_layers.active = bake_uv
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.006, area_weight=0.6)
    bpy.ops.object.mode_set(mode="OBJECT")


def set_target(obj, img):
    for mat in obj.data.materials:
        nodes = mat.node_tree.nodes
        node = nodes.get("BakeTarget") or nodes.new("ShaderNodeTexImage")
        node.name = "BakeTarget"
        node.image = img
        for n in nodes:
            n.select = False
        node.select = True
        nodes.active = node


def bake(obj, kind, size, colour_space="sRGB"):
    img = bpy.data.images.new(f"{obj.name}_{kind}", size, size, alpha=False)
    img.colorspace_settings.name = colour_space
    set_target(obj, img)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    if kind == "Color":
        bpy.ops.object.bake(type="DIFFUSE", pass_filter={"COLOR"}, margin=8, use_clear=True)
    elif kind == "Normal":
        bpy.ops.object.bake(type="NORMAL", normal_space="TANGENT", margin=8, use_clear=True)
    elif kind == "Alpha":
        bpy.ops.object.bake(type="EMIT", margin=2, use_clear=True)
    return img


def alpha_to_emission(obj, on):
    """For the alpha bake: route each material's AlphaOut into an emission shader (and back)."""
    for mat in obj.data.materials:
        g = mat.node_tree
        out = next(n for n in g.nodes if n.type == "OUTPUT_MATERIAL")
        bsdf = next(n for n in g.nodes if n.type == "BSDF_PRINCIPLED")
        if on:
            em = g.nodes.get("AlphaEmit") or g.nodes.new("ShaderNodeEmission")
            em.name = "AlphaEmit"
            g.links.new(g.nodes["AlphaOut"].outputs[0], em.inputs[0])
            g.links.new(em.outputs[0], out.inputs[0])
        else:
            g.links.new(bsdf.outputs[0], out.inputs[0])


def save_png(img, path, alpha_img=None):
    img.filepath_raw = path
    img.file_format = "PNG"
    if alpha_img is None:
        img.save()
        return
    w, h = img.size
    px = list(img.pixels)
    apx = list(alpha_img.pixels)
    for i in range(w * h):
        px[i * 4 + 3] = apx[i * 4]
    rgba = bpy.data.images.new(img.name + "_RGBA", w, h, alpha=True)
    rgba.colorspace_settings.name = "sRGB"
    rgba.pixels = px
    rgba.filepath_raw = path
    rgba.file_format = "PNG"
    rgba.save()


PROPS = [  # builder, texture size, has leaf cards
    (oak_tree, 1024, True), (fir_tree, 1024, False), (bush, 512, True), (flower_patch, 512, False),
    (bench, 512, False), (picnic_table, 512, False), (lamp, 512, False), (swing_set, 512, False),
    (jungle_gym, 512, False),
]

built = []
for i, (builder, size, cards) in enumerate(PROPS):
    obj = builder()
    unwrap_for_bake(obj)
    colour = bake(obj, "Color", size)
    alpha = None
    if cards:
        alpha_to_emission(obj, True)
        alpha = bake(obj, "Alpha", size, "Non-Color")
        alpha_to_emission(obj, False)
    save_png(colour, os.path.join(ROOT, f"{obj.name}_Color.png"), alpha)
    normal = bake(obj, "Normal", size, "Non-Color")
    save_png(normal, os.path.join(ROOT, f"{obj.name}_Normal.png"))
    # export uses the bake UVs only
    mesh = obj.data
    for layer in [l for l in mesh.uv_layers if l.name != "Bake"]:
        mesh.uv_layers.remove(layer)
    obj.location = (i * 22, 0, 0)
    built.append(obj)
    print("baked", obj.name)

bpy.ops.object.select_all(action="DESELECT")
for obj in built:
    obj.select_set(True)
bpy.ops.export_scene.fbx(filepath=os.path.join(ROOT, "ParkProps.fbx"), use_selection=True, object_types={"MESH"}, apply_unit_scale=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "ParkProps.blend"), copy=True)
print("done", [o.name for o in built])
