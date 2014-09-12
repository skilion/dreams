module mesh;

import renderer: Vertex;

struct Mesh
{
	Vertex[] vertices;
	ushort[] indices;

	size_t getMeshSize()
	{
		return vertices.length * Vertex.sizeof + indices.length * ushort.sizeof;
	}

	/*
		Adds a vertex to the mesh.
		Returns the index of the vertex
	*/
	ushort addVertex(const ref Vertex vertex)
	{
		assert(vertices.length < ushort.max, "Mesh.addVertex: Maximum number of vertices reached");
		ushort index = cast(ushort) vertices.length;
		vertices ~= vertex;
		return index;
	}

	void addIndex(ushort index)
	{
		assert(index < cast(ushort) vertices.length, "Mesh.addIndex: Invalid index");
		indices ~= index;
	}

	void clear()
	{
		vertices.length = 0;
		indices.length = 0;
	}

	void reserve(size_t size)
	{
		vertices.reserve(size);
		indices.reserve(size * 2);
	}
}

/*
	OptimizedMeshData ensures that no duplicated vertices are stored
*/
struct OptimizedMesh
{
	Mesh mesh;
	alias mesh this;
	private ushort[Vertex] hashmap;

	/*
		Adds a vertex to the mesh.
		Returns the index of the vertex
	*/
	ushort addVertex(const ref Vertex vertex)
	{
		assert(vertices.length < ushort.max, "OptimizedMesh.addVertex: Maximum number of vertices reached");
		auto p = vertex in hashmap;
		if (!p)
		{
			ushort index = cast(ushort) vertices.length;
			vertices ~= vertex;
			hashmap[vertex] = index;
			return index;
		}
		import log;
		log.dev("optimized vertex !");
		return *p;
	}

	void clear()
	{
		mesh.clear();
		destroy(hashmap);
	}
}

unittest
{
	OptimizedMesh meshdata;
	Vertex vertex1, vertex2;
	vertex2.position = [1, 0, 0];
	meshdata.addVertex(vertex1);
	meshdata.addVertex(vertex2);
	assert(meshdata.addVertex(vertex1) == 0);
	assert(meshdata.addVertex(vertex2) == 1);
}
