module dreams.world;

import std.algorithm, std.stdio, std.file, std.math;
import renderer, vector;

struct WorldBlock
{
	union {
		struct {
			ubyte id;
			ubyte data0;
			ubyte data1;
			ubyte data2;
		}
		ushort dword;
	}

	bool isSolid()
	{
		return id == 1;
	}

	bool isOpaque()
	{
		return id != 0;
	}

	bool isTransparent()
	{
		return id == 0;
	}
}

enum chunkSize = 16;
enum chunkSizeMask = chunkSize - 1;

struct WorldChunk
{
	Vec3f position = Vec3f(0, 0, 0); // origin of the chunk

	// chunk mesh
	bool needUpdate = true; // true if the mesh needs to be updated
	bool waitingMesher = false; // true if the chunk is in queue for the mesher
	size_t meshSize;
	IndexBuffer indexBuffer;
	int indexCount;
	VertexBuffer vertexBuffer;
	WorldChunk* prev, next; // double linked list to keep track of the allocated meshes

	// actual chunck data
	WorldBlock[chunkSize][chunkSize][chunkSize] blocks;

	this(Vec3f position)
	{
		this.position = position;
	}

	void insertBlock(WorldBlock block, uint x, uint y, uint z) nothrow
	{
		blocks[x & chunkSizeMask][y & chunkSizeMask][z & chunkSizeMask] = block;
	}

	WorldBlock getBlock(uint x, uint y, uint z) const nothrow
	{
		return blocks[x & chunkSizeMask][y & chunkSizeMask][z & chunkSizeMask];
	}
}

struct WorldNode
{
	uint level; // level of the node in the octree, stored as power of 2, increasing from the leaves to the root
	Vec3f center;

	union {
		WorldNode*[8] nodes; // if level > 1
		WorldChunk*[8] chunks; // if level == 1
	}

	this(uint level)
	{
		assert(level > 0);
		this.level = level;
		float extent = getExtent();
		center = Vec3f(extent, extent, extent);
	}

	this(uint level, Vec3f center)
	{
		assert(level > 0);
		this.level = level;
		this.center = center;
	}

	uint getSize() const pure nothrow
	{
		return level * (chunkSize * 2);
	}

	float getExtent() const pure nothrow
	{
		return level * chunkSize;
	}

	/*
		Returns the chunk that contains the given coordinates.
		If the chunk does not exist, the function returns null.
	*/
	WorldChunk* findChunk(uint x, uint y, uint z)
	{
		auto p = &this;
		uint index;
		while (p.level > 1) {
			index = coordToIndex(x, y, z, p.level);
			p = p.nodes[index];
			if (!p) return null;
		}
		index = coordToIndex(x, y, z, 1);
		return p.chunks[index];
	}

	/*
		Returns the chunk that contains the given coordinates.
		If the chunk does not exist a new chunk is allocated.
	*/
	WorldChunk* getChunk(uint x, uint y, uint z)
	{
		auto p = &this;
		uint index;
		while (p.level > 1) {
			index = coordToIndex(x, y, z, p.level);
			if (p.nodes[index]) {
				p = p.nodes[index];
			}
			else {
				auto node = new WorldNode(p.level >> 1, childPosition(p, index));
				p = p.nodes[index] = node;
			}
		}
		index = coordToIndex(x, y, z, 1);
		if (p.chunks[index]) {
			return p.chunks[index];
		}
		auto chunk = new WorldChunk(chunkPosition(p.center, index));
		return p.chunks[index] = chunk;
	}

	WorldBlock getBlock(uint x, uint y, uint z) const
	{
		auto chunk = (cast(WorldNode) this).findChunk(x, y, z); // HACK
		if (!chunk) return WorldBlock();
		return chunk.getBlock(x, y, z);
	}

	void insertBlock(WorldBlock block, uint x, uint y, uint z)
	{
		WorldChunk* chunk = getChunk(x, y, z);
		chunk.needUpdate = true;
		chunk.insertBlock(block, x, y, z);
	}

	private void recursiveSave(File file) const
	{
		file.rawWrite((&level)[0..1]);
		file.rawWrite(center.array);
		if (level > 1) {
			foreach (i; 0..8) {
				if (nodes[i]) {
					file.rawWrite([1]);
					nodes[i].recursiveSave(file);
				} else file.rawWrite([0]);
			}
		} else {
			foreach (i; 0..8) {
				if (chunks[i]) {
					file.rawWrite([1]);
					file.rawWrite(chunks[i].position.array);
					file.rawWrite(chunks[i].blocks);
				} else file.rawWrite([0]);
			}
		}
	}

	private void recursiveLoad(File file)
	{
		file.rawRead((&level)[0..1]);
		file.rawRead(center.array);
		if (level > 1) {
			foreach (i; 0..8) {
				int tmp;
				file.rawRead((&tmp)[0..1]);
				if (tmp) {
					nodes[i] = new WorldNode(1);
					nodes[i].recursiveLoad(file);
				} else nodes[i] = null;
			}
		} else {
			foreach (i; 0..8) {
				int tmp;
				file.rawRead((&tmp)[0..1]);
				if (tmp) {
					chunks[i] = new WorldChunk();
					file.rawRead(chunks[i].position.array);
					file.rawRead(chunks[i].blocks);
				} else chunks[i] = null;
			}
		}
	}
}

private uint coordToIndex(uint x, uint y, uint z, uint level) pure nothrow
{
	level <<= 4;
	uint a = (x & level) != 0;
	uint b = (y & level) != 0;
	uint c = (z & level) != 0;
	return a | (b << 1) | (c << 2);
}

// compute the position of the child node with the given index
private Vec3f childPosition(const WorldNode* node, uint index) pure nothrow
{
	Vec3f c = node.center;
	float d = node.level * (chunkSize / 2);
	final switch (index) {
	case 0: c.x -= d; c.y -= d; c.z -= d; break;
	case 1: c.x += d; c.y -= d; c.z -= d; break;
	case 2: c.x -= d; c.y += d; c.z -= d; break;
	case 3: c.x += d; c.y += d; c.z -= d; break;
	case 4: c.x -= d; c.y -= d; c.z += d; break;
	case 5: c.x += d; c.y -= d; c.z += d; break;
	case 6: c.x -= d; c.y += d; c.z += d; break;
	case 7:	c.x += d; c.y += d; c.z += d; break;
	}
	return c;
}

// compute the origin of a child chunk with the given index
private Vec3f chunkPosition(Vec3f pos, uint index) pure nothrow
{
	final switch (index) {
	case 0: pos.x -= chunkSize; pos.y -= chunkSize; pos.z -= chunkSize; break;
	case 1: pos.y -= chunkSize; pos.z -= chunkSize; break;
	case 2: pos.x -= chunkSize; pos.z -= chunkSize; break;
	case 3: pos.z -= chunkSize; break;
	case 4: pos.x -= chunkSize; pos.y -= chunkSize; break;
	case 5: pos.y -= chunkSize; break;
	case 6: pos.x -= chunkSize; break;
	case 7: break;
	}
	return pos;
}

struct World
{
	Vec3f startPosition;

	uint depth; // max height of the octree
	uint size; // size in block of the world
	Vec3f min, max;
	WorldNode* root;

	this(uint depth)
	{
		this.depth = depth;
		init();
	}

	private void init()
	{
		root = new WorldNode(2 ^^ depth);
		float size = this.size = root.getSize();
		min = Vec3f(0, 0, 0);
		max = Vec3f(size, size, size);
	}

	/*
		Collision test of a ray with the world
		Returns true if the ray touches a block
		start = origin of the ray
		d = direction of the ray
		max = maximum number of blocks to check for collision
		point = collision block coordinate
		face = face of the block which collide with the ray
	*/
	bool rayCollisionTest(Vec3f start, Vec3f d, uint max, out uint[3] point, out uint[3] face)
	{
		// HACK: prevent division by zero
		if (d.x == 0) d.x = float.min_normal;
		if (d.y == 0) d.y = float.min_normal;
		if (d.z == 0) d.z = float.min_normal;
		real tmp;
		int stepX, stepY, stepZ;
		float tMaxX = void, tMaxY = void, tMaxZ = void;
		if (d.x > 0) {
			stepX = 1;
			tMaxX = (1 - modf(start.x, tmp)) / d.x;
		} else {
			stepX = -1;
			tMaxX = -modf(start.x, tmp) / d.x;
		}
		if (d.y > 0) {
			stepY = 1;
			tMaxY = (1 - modf(start.y, tmp)) / d.y;
		} else {
			stepY = -1;
			tMaxY = -modf(start.y, tmp) / d.y;
		}
		if (d.z > 0) {
			stepZ = 1;
			tMaxZ = (1 - modf(start.z, tmp)) / d.z;
		} else {
			stepZ = -1;
			tMaxZ = -modf(start.z, tmp) / d.z;
		}
		float tDeltaX = stepX / d.x;
		float tDeltaY = stepY / d.y;
		float tDeltaZ = stepZ / d.z;
		point = floatToUintCoord(start);
		WorldBlock block;
		uint i = 0;
		while (i < max && point[0] < size && point[1] < size && point[2] < size) {
			block = root.getBlock(point[0], point[1], point[2]);
			if (block.isOpaque()) return true;
			if (tMaxX < tMaxY) {
				if (tMaxX < tMaxZ) {
					point[0] += stepX;
					tMaxX += tDeltaX;
					face = [-stepX, 0, 0];
				} else {
					point[2] += stepZ;
					tMaxZ += tDeltaZ;
					face = [0, 0, -stepZ];
				}
			} else {
				if (tMaxY < tMaxZ) {
					point[1] += stepY;
					tMaxY += tDeltaY;
					face = [0, -stepY, 0];
				} else {
					point[2] += stepZ;
					tMaxZ += tDeltaZ;
					face = [0, 0, -stepZ];
				}
			}
			i++;
		}
		return false;
	}

	/*
		This getBlock() check if position is inside the world
	*/
	WorldBlock getBlock(Vec3f position) const
	{
		foreach (i; 0 .. 3) {
			if (position[i] < min[i] || position[i] > max[i]) {
				return WorldBlock();
			}
		}
		return root.getBlock(cast(uint) position.x, cast(uint) position.y, cast(uint) position.z);
	}

	uint[3] floatToUintCoord(Vec3f vector) const
	{
		foreach (i; 0 .. 3) vector[i] = fmax(fmin(vector[i], max[i]), min[i]);
		return [cast(uint) vector.x, cast(uint) vector.y, cast(uint) vector.z];
	}

	void save(string filename) const
	{
		if (exists(filename)) {
			rename(filename, filename ~ ".backup");
		}
		auto file = File(filename, "wb");
		file.rawWrite(startPosition.array);
		file.rawWrite((&depth)[0 .. 1]);
		root.recursiveSave(file);
		file.close();
	}

	void load(File file)
	{
		file.rawRead(startPosition.array);
		file.rawRead((&depth)[0 .. 1]);
		init();
		root.recursiveLoad(file);
	}
}
