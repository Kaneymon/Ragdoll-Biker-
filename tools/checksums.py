# Prints "<studio path> <adler32>" for every Luau file, using the Rojo layout in default.project.json.
import os, zlib, sys
ROOTS = {"src/shared": "ReplicatedStorage.Shared", "src/server": "ServerScriptService.Server", "src/client": "StarterPlayer.StarterPlayerScripts.Client"}
for root, prefix in ROOTS.items():
    for dirpath, _, files in os.walk(root):
        for f in sorted(files):
            if not f.endswith(".luau"):
                continue
            rel = os.path.relpath(os.path.join(dirpath, f), root).replace(os.sep, "/")
            name = rel[:-5].replace(".server", "").replace(".client", "")
            data = open(os.path.join(dirpath, f), "rb").read().replace(b"\r\n", b"\n")
            print(prefix + "." + name.replace("/", "."), zlib.adler32(data))
