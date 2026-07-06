import std/[os, strutils, tables]
import glm

## Parses a Wavefront OBJ file and returns interleaved vertex data and an index buffer.
##
## The returned vertex sequence layout matches GGlib's expectations:
##   position.x, position.y, position.z,
##   normal.x,   normal.y,   normal.z,
##   texcoord.u, texcoord.v
##
## Example usage:
##   let (verts, inds) = parseOBJ("models/cube.obj")
##
proc parseOBJ*(path: string): tuple[vertices: seq[float32], indices: seq[uint32]] =
  ## Load the OBJ file, build a unique vertex list and an index buffer.
  ## Supports "v", "vn", "vt" and "f" lines. Faces are triangulated
  ## using a fan approach if they contain more than three vertices.
  var positions: seq[Vec3f] = @[]
  var normals:   seq[Vec3f] = @[]
  var texcoords: seq[Vec2f] = @[]

  var vertices: seq[float32] = @[]
  var indices:  seq[uint32] = @[]
  var vertexMap = initTable[(int, int, int), uint32]()

  for line in lines(path):
    let trimmed = line.strip()
    if trimmed.len == 0 or trimmed[0] == '#':
      continue
    let parts = trimmed.splitWhitespace()
    if parts[0] == "v":
      # vertex position
      positions.add(vec3(parts[1].parseFloat().float32,
                        parts[2].parseFloat().float32,
                        parts[3].parseFloat().float32))
    elif parts[0] == "vn":
      # vertex normal
      normals.add(vec3(parts[1].parseFloat().float32,
                      parts[2].parseFloat().float32,
                      parts[3].parseFloat().float32))
    elif parts[0] == "vt":
      # texture coordinate (u, v)
      texcoords.add(vec2(parts[1].parseFloat().float32,
                        parts[2].parseFloat().float32))
    elif parts[0] == "f":
      # face – each token may be v/vt/vn (OBJ indices are 1‑based)
      var faceIdx: seq[uint32] = @[]
      for i in 1 ..< parts.len:
        let token = parts[i]
        var vIdx, vtIdx, vnIdx: int
        let comps = token.split('/')
        # position index
        vIdx = comps[0].parseInt()
        # texture index (optional)
        if comps.len > 1 and comps[1].len > 0:
          vtIdx = comps[1].parseInt()
        else:
          vtIdx = 0
        # normal index (optional)
        if comps.len > 2 and comps[2].len > 0:
          vnIdx = comps[2].parseInt()
        else:
          vnIdx = 0
        # OBJ uses 1‑based indexing, convert to 0‑based for our tables
        let key = (vIdx - 1, vtIdx - 1, vnIdx - 1)
        if not vertexMap.hasKey(key):
          let pos = positions[key[0]]
          let norm = if key[2] >= 0: normals[key[2]] else: vec3(0'f, 0'f, 0'f)
          let tex = if key[1] >= 0: texcoords[key[1]] else: vec2(0'f, 0'f)
          # Append interleaved data
          vertices.add(pos.x); vertices.add(pos.y); vertices.add(pos.z)
          vertices.add(norm.x); vertices.add(norm.y); vertices.add(norm.z)
          vertices.add(tex.x); vertices.add(tex.y)
          let newIdx = uint32(vertices.len div 8 - 1) # each vertex adds 8 floats
          vertexMap[key] = newIdx
        faceIdx.add(vertexMap[key])
      # Triangulate the polygon (fan method)
      for i in 1 ..< faceIdx.len - 1:
        indices.add(faceIdx[0])
        indices.add(faceIdx[i])
        indices.add(faceIdx[i+1])
  result = (vertices, indices)

