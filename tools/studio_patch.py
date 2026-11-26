"""Build Luau snippets that bring Studio scripts from git HEAD up to the working tree.

Studio can't reach localhost (so no Rojo here); instead each snippet is pasted into the
Studio MCP's execute_luau. Changed files become exact old->new block replacements
(small), new files are sent whole. Usage: python tools/studio_patch.py [outdir]
"""
import difflib
import os
import subprocess
import sys

ROOTS = {
    "src/shared": "ReplicatedStorage.Shared",
    "src/server": "ServerScriptService.Server",
    "src/client": "StarterPlayer.StarterPlayerScripts.Client",
}
CHUNK = 20000

HEADER = '''local function node(path, class)
	local parts = string.split(path, ".")
	local n = game:GetService(parts[1])
	for i = 2, #parts - 1 do
		local c = n:FindFirstChild(parts[i])
		if not c then c = Instance.new("Folder"); c.Name = parts[i]; c.Parent = n end
		n = c
	end
	local s = n:FindFirstChild(parts[#parts])
	if not s then s = Instance.new(class); s.Name = parts[#parts]; s.Parent = n end
	return s
end
local function put(path, class, src) node(path, class).Source = src end
local function patch(path, edits)
	local s = node(path, "ModuleScript")
	local src = s.Source
	for _, e in edits do
		local i, j = string.find(src, e[1], 1, true)
		assert(i, path .. ": block not found: " .. e[1]:sub(1, 60))
		src = src:sub(1, i - 1) .. e[2] .. src:sub(j + 1)
	end
	s.Source = src
end
'''


def studio_path(rel):
    for root, prefix in ROOTS.items():
        if rel.startswith(root + "/"):
            name = rel[len(root) + 1:-5]
            cls = "Script" if name.endswith(".server") else "LocalScript" if name.endswith(".client") else "ModuleScript"
            name = name.replace(".server", "").replace(".client", "")
            return prefix + "." + name.replace("/", "."), cls
    return None, None


def lua_str(text):
    level = 1
    while ("]" + "=" * level + "]") in text:
        level += 1
    eq = "=" * level
    return "[" + eq + "[" + ("\n" if text.startswith("\n") else "") + text + "]" + eq + "]"


def head_text(rel):
    try:
        return subprocess.run(["git", "show", "HEAD:" + rel], capture_output=True, check=True).stdout.decode("utf-8").replace("\r\n", "\n")
    except subprocess.CalledProcessError:
        return None


def edits_for(old, new):
    """Bottom-up block edits; each old block is widened until it is unique in the text it is
    applied to (simulated here exactly as the Luau patch() applies it)."""
    a, b = old.splitlines(keepends=True), new.splitlines(keepends=True)
    current = old
    out = []
    for tag, i1, i2, j1, j2 in reversed(difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes()):
        if tag == "equal":
            continue
        pad = 1
        while True:
            lo, hi = max(0, i1 - pad), min(len(a), i2 + pad)
            # context comes from the old lines above (untouched, since we go bottom-up) and
            # the new lines below (already applied)
            above = "".join(a[lo:i1])
            below = "".join(b[j2:j2 + (hi - i2)])
            old_block = above + "".join(a[i1:i2]) + below
            if current.count(old_block) == 1 or (lo == 0 and hi == len(a)):
                break
            pad += 1
        new_block = above + "".join(b[j1:j2]) + below
        assert current.count(old_block) == 1, "could not make a unique block"
        current = current.replace(old_block, new_block, 1)
        out.append((old_block, new_block))
    assert current == new, "patch simulation mismatch"
    return out


def main():
    outdir = sys.argv[1] if len(sys.argv) > 1 else "."
    changed = subprocess.run(["git", "status", "--porcelain", "--", "src"], capture_output=True, text=True).stdout.splitlines()
    stmts = []
    for line in changed:
        rel = line[3:].strip().strip('"')
        paths = [rel]
        if rel.endswith("/"):
            paths = [os.path.join(dp, f).replace(os.sep, "/") for dp, _, fs in os.walk(rel) for f in fs]
        for p in paths:
            if not p.endswith(".luau") or not os.path.exists(p):
                continue
            spath, cls = studio_path(p)
            new = open(p, encoding="utf-8").read().replace("\r\n", "\n")
            old = head_text(p)
            if old is None:
                stmts.append(f'put("{spath}", "{cls}", {lua_str(new)})\n')
            elif old != new:
                body = ", ".join("{" + lua_str(o) + ", " + lua_str(n) + "}" for o, n in edits_for(old, new))
                stmts.append(f'patch("{spath}", {{{body}}})\n')
    chunks, cur = [], ""
    for s in stmts:
        if cur and len(cur) + len(s) > CHUNK:
            chunks.append(cur)
            cur = ""
        cur += s
    if cur:
        chunks.append(cur)
    for i, c in enumerate(chunks):
        with open(os.path.join(outdir, f"patch_{i:02d}.luau"), "w", encoding="utf-8", newline="\n") as f:
            f.write(HEADER + c + 'return "ok"\n')
    print(len(stmts), "scripts in", len(chunks), "chunks:", [len(c) for c in chunks])


if __name__ == "__main__":
    main()
