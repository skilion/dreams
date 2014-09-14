module dreams.world_mesh;

import dreams.world;
import renderer, mesh, vector;

// struct that creates the chunk meshes
struct WorldMesh
{
	private const(WorldNode)* root;
	private uint maxCoord;

	Mesh mesh;
	alias mesh this;

	void setWorldRoot(const WorldNode* root)
	{
		assert(root);
		this.root = root;
		maxCoord = root.level * chunkSize * 2;
	}

	void create(const WorldChunk* chunk, uint x0, uint y0, uint z0)
	{
		mesh.clear();
		x0 &= ~chunkSizeMask;
		y0 &= ~chunkSizeMask;
		z0 &= ~chunkSizeMask;
		uint x1 = x0 + chunkSize;
		uint y1 = y0 + chunkSize;
		uint z1 = z0 + chunkSize;

		// helper function to retrieve the world blocks
		auto getBlock(uint x, uint y, uint z)
		{
			if (x >= maxCoord || y >= maxCoord || z >= maxCoord) {
				// out of range
				return WorldBlock();
			}
			if ((x ^ x0 & ~chunkSizeMask) == 0 && (y ^ y0 & ~chunkSizeMask) == 0 && (z ^ z0 & ~chunkSizeMask) == 0) {
				// the block is in the current chunk
				return chunk.getBlock(x, y, z);
			}
			return root.getBlock(x, y, z);
		}

		WorldBlock[27] near;
		for (uint x = x0; x < x1; x++) {
			float f_x = x - x0;
			for (uint y = y0; y < y1; y++) {
				float f_y = y - y0;
				near[00] = getBlock(x - 1, y - 1, z0 - 1);
				near[09] = getBlock(x + 0, y - 1, z0 - 1);
				near[18] = getBlock(x + 1, y - 1, z0 - 1);
				near[03] = getBlock(x - 1, y + 0, z0 - 1);
				near[12] = getBlock(x + 0, y + 0, z0 - 1);
				near[21] = getBlock(x + 1, y + 0, z0 - 1);
				near[06] = getBlock(x - 1, y + 1, z0 - 1);
				near[15] = getBlock(x + 0, y + 1, z0 - 1);
				near[24] = getBlock(x + 1, y + 1, z0 - 1);
				near[01] = getBlock(x - 1, y - 1, z0 + 0);
				near[10] = getBlock(x + 0, y - 1, z0 + 0);
				near[19] = getBlock(x + 1, y - 1, z0 + 0);
				near[04] = getBlock(x - 1, y + 0, z0 + 0);
				near[13] = getBlock(x + 0, y + 0, z0 + 0);
				near[22] = getBlock(x + 1, y + 0, z0 + 0);
				near[07] = getBlock(x - 1, y + 1, z0 + 0);
				near[16] = getBlock(x + 0, y + 1, z0 + 0);
				near[25] = getBlock(x + 1, y + 1, z0 + 0);
				for (uint z = z0; z < z1; z++) {
					near[02] = getBlock(x - 1, y - 1, z + 1);
					near[11] = getBlock(x + 0, y - 1, z + 1);
					near[20] = getBlock(x + 1, y - 1, z + 1);
					near[05] = getBlock(x - 1, y + 0, z + 1);
					near[14] = getBlock(x + 0, y + 0, z + 1);
					near[23] = getBlock(x + 1, y + 0, z + 1);
					near[08] = getBlock(x - 1, y + 1, z + 1);
					near[17] = getBlock(x + 0, y + 1, z + 1);
					near[26] = getBlock(x + 1, y + 1, z + 1);
					if (near[13].isOpaque()) {
						float f_z = z - z0;
						addBlock(f_x, f_y, f_z, near);
					}
					near[00] = near[01];
					near[09] = near[10];
					near[18] = near[19];
					near[03] = near[04];
					near[12] = near[13];
					near[21] = near[22];
					near[06] = near[07];
					near[15] = near[16];
					near[24] = near[25];
					near[01] = near[02];
					near[10] = near[11];
					near[19] = near[20];
					near[04] = near[05];
					near[13] = near[14];
					near[22] = near[23];
					near[07] = near[08];
					near[16] = near[17];
					near[25] = near[26];
				}
			}
		}
	}

	private void addBlock(float x, float y, float z, const ref WorldBlock[27] near)
	{
		uint visibleFaces = testVisibleFaces(
			near[04], near[22], near[10], near[16], near[12], near[14]
		);
		ushort texture = near[13].data0;
		ushort s = (texture & 15) * tileSize; // texture % 16 * tileSize;
		ushort t = cast(ushort) ((texture >> 4) * tileSize); // texture / 16 * tileSize);
		int base = 0; // base index in blockVertices[]
		Vertex vertex;
		int ao[4]; // ambient occlusion for each vertex
		ushort faceVertices[4]; // index of each vertex in the mesh
		foreach (face; 0 .. 6) {
			if (visibleFaces & 1) {
				foreach (i; 0 .. 4) { // foreach vertex
					ao[i] = vertexAmbientOcclusion(base + i, near);
					vertex = blockVertices[base + i];
					vertex.position[0] += x;
					vertex.position[1] += y;
					vertex.position[2] += z;
					vertex.texcoord[0] += s;
					vertex.texcoord[1] += t;
					vertex.color[0 .. 3] = cast(byte) (ao[i] * 30 + 37);
					faceVertices[i] = addVertex(vertex);
				}
				if (ao[0] + ao[2] > ao[1] + ao[3]) {
					// normal quad
					indices ~= [
						faceVertices[0],
						faceVertices[1],
						faceVertices[2],
						faceVertices[0],
						faceVertices[2],
						faceVertices[3]
					];
				} else {
					// flipped quad
					indices ~= [
						faceVertices[0],
						faceVertices[1],
						faceVertices[3],
						faceVertices[3],
						faceVertices[1],
						faceVertices[2]
					];
				}
			}
			base += 4; // 4 vertices for each face
			visibleFaces >>= 1; // next face
		}
	}
}

private uint testVisibleFaces(WorldBlock left, WorldBlock right, WorldBlock bottom, WorldBlock top, WorldBlock back, WorldBlock front)
{
	uint visibleFaces;
	if (left.isTransparent())   visibleFaces |= 0b000001;
	if (right.isTransparent())  visibleFaces |= 0b000010;
	if (bottom.isTransparent()) visibleFaces |= 0b000100;
	if (top.isTransparent())    visibleFaces |= 0b001000;
	if (back.isTransparent())   visibleFaces |= 0b010000;
	if (front.isTransparent())  visibleFaces |= 0b100000;
	return visibleFaces;
}

private int vertexAmbientOcclusion(int vertex, const ref WorldBlock[27] near)
{
	WorldBlock side0, side1, corner;
	final switch (vertex) {
	case 00: side0 = near[01]; side1 = near[03]; corner = near[00]; break;
	case 01: side0 = near[05]; side1 = near[01]; corner = near[02]; break;
	case 02: side0 = near[07]; side1 = near[05]; corner = near[08]; break;
	case 03: side0 = near[03]; side1 = near[07]; corner = near[06]; break;
	case 04: side0 = near[21]; side1 = near[19]; corner = near[18]; break;
	case 05: side0 = near[25]; side1 = near[21]; corner = near[24]; break;
	case 06: side0 = near[23]; side1 = near[25]; corner = near[26]; break;
	case 07: side0 = near[19]; side1 = near[23]; corner = near[20]; break;
	case 08: side0 = near[09]; side1 = near[01]; corner = near[00]; break;
	case 09: side0 = near[19]; side1 = near[09]; corner = near[18]; break;
	case 10: side0 = near[11]; side1 = near[19]; corner = near[20]; break;
	case 11: side0 = near[01]; side1 = near[11]; corner = near[02]; break;
	case 12: side0 = near[07]; side1 = near[15]; corner = near[06]; break;
	case 13: side0 = near[17]; side1 = near[07]; corner = near[08]; break;
	case 14: side0 = near[25]; side1 = near[17]; corner = near[26]; break;
	case 15: side0 = near[15]; side1 = near[25]; corner = near[24]; break;
	case 16: side0 = near[09]; side1 = near[03]; corner = near[00]; break;
	case 17: side0 = near[15]; side1 = near[03]; corner = near[06]; break;
	case 18: side0 = near[21]; side1 = near[15]; corner = near[24]; break;
	case 19: side0 = near[09]; side1 = near[21]; corner = near[18]; break;
	case 20: side0 = near[11]; side1 = near[05]; corner = near[02]; break;
	case 21: side0 = near[23]; side1 = near[11]; corner = near[20]; break;
	case 22: side0 = near[17]; side1 = near[23]; corner = near[26]; break;
	case 23: side0 = near[05]; side1 = near[17]; corner = near[08]; break;
	}
	if (side0.isOpaque() && side1.isOpaque()) return 0;
	return 3 - (side0.isOpaque() + side1.isOpaque() + corner.isOpaque());
}

// mesh of a single block
private enum tileSize = ushort.max / 16;
private enum a = 4;
private enum b = tileSize - 4;
private immutable Vertex[24] blockVertices = [
	// left
	{[0, 0, 0], [-128, 0, 0, 0], [a, a], [127, 127, 127, 127]},
	{[0, 0, 1], [-128, 0, 0, 0], [b, a], [127, 127, 127, 127]},
	{[0, 1, 1], [-128, 0, 0, 0], [b, b], [127, 127, 127, 127]},
	{[0, 1, 0], [-128, 0, 0, 0], [a, b], [127, 127, 127, 127]},
	// right
	{[1, 0, 0], [127, 0, 0, 0], [b, a], [127, 127, 127, 127]},
	{[1, 1, 0], [127, 0, 0, 0], [b, b], [127, 127, 127, 127]},
	{[1, 1, 1], [127, 0, 0, 0], [a, b], [127, 127, 127, 127]},
	{[1, 0, 1], [127, 0, 0, 0], [a, a], [127, 127, 127, 127]},
	// bottom
	{[0, 0, 0], [0, -128, 0, 0], [a, a], [127, 127, 127, 127]},
	{[1, 0, 0], [0, -128, 0, 0], [b, a], [127, 127, 127, 127]},
	{[1, 0, 1], [0, -128, 0, 0], [b, b], [127, 127, 127, 127]},
	{[0, 0, 1], [0, -128, 0, 0], [a, b], [127, 127, 127, 127]},
	// top
	{[0, 1, 0], [0, 127, 0, 0], [a, a], [127, 127, 127, 127]},
	{[0, 1, 1], [0, 127, 0, 0], [b, a], [127, 127, 127, 127]},
	{[1, 1, 1], [0, 127, 0, 0], [b, b], [127, 127, 127, 127]},
	{[1, 1, 0], [0, 127, 0, 0], [a, b], [127, 127, 127, 127]},
	// back
	{[0, 0, 0], [0, 0, -128, 0], [b, a], [127, 127, 127, 127]},
	{[0, 1, 0], [0, 0, -128, 0], [b, b], [127, 127, 127, 127]},
	{[1, 1, 0], [0, 0, -128, 0], [a, b], [127, 127, 127, 127]},
	{[1, 0, 0], [0, 0, -128, 0], [a, a], [127, 127, 127, 127]},
	// front
	{[0, 0, 1], [0, 0, 127, 0], [a, a], [127, 127, 127, 127]},
	{[1, 0, 1], [0, 0, 127, 0], [b, a], [127, 127, 127, 127]},
	{[1, 1, 1], [0, 0, 127, 0], [b, b], [127, 127, 127, 127]},
	{[0, 1, 1], [0, 0, 127, 0], [a, b], [127, 127, 127, 127]},
];
