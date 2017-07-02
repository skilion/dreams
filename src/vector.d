module vector;

import std.math, std.traits;

alias Vector!(2, float) Vec2f;
alias Vector!(3, float) Vec3f;
alias Vector!(4, float) Vec4f;

struct Vector(int size, T)
if (size >= 2 && size <= 4 && isFloatingPoint!T)
{
	union {
		static if (size >= 2 || size <= 4) {
			struct {
				static if (size > 0) {
					T x = 0;
					alias r = x;
				}
				static if (size > 1) {
					T y = 0;
					alias g = y;
				}
				static if (size > 2) {
					T z = 0;
					alias b = z;
				}
				static if (size > 3) {
					T w = 0;
					alias a = w;
				}
			}
		}
		T[size] array;
	}

	auto ptr() inout nothrow
	{
		return array.ptr;
	}

	auto opUnary(string op: "-")() const
	{
		Vector vector = this;
		vector.array[] = -vector.array[];
		return vector;
	}

	auto opBinary(string op)(T rhs) const
	if (op == "+" || op == "-" || op == "*" || op == "/")
	{
		Vector vector = this;
		mixin("return vector" ~ op ~ "= rhs;");
	}

	auto opBinary(string op)(auto const ref Vector rhs) const
	if (op == "+" || op == "-")
	{
		Vector vector = this;
		mixin("return vector" ~ op ~ "= rhs;");
	}

	auto ref opOpAssign(string op)(T rhs)
	if (op == "+" || op == "-" || op == "*" || op == "/")
	{
		mixin("array[] " ~ op ~ "= rhs;");
		return this;
	}

	auto ref opOpAssign(string op)(auto const ref Vector rhs)
	if (op == "+" || op == "-")
	{
		mixin("array[] " ~ op ~ "= rhs.array[];");
		return this;
	}

	auto ref opIndex(size_t index) inout
	{
		return array[index];
	}

	int opApply(int delegate(ref T) dg)
	{
		int result = 0;
		foreach (ref element; array) {
			result = dg(element);
			if (result) break;
		}
		return result;
	}

	static if (size == 2 || size == 3)
	{
		auto ref normalize()
		{
			this /= magnitude();
			return this;
		}

		auto distance(const ref Vector vector) const
		{
			return (this - vector).magnitude();
		}
	}

	static if (size == 2)
	{
		auto magnitude() const
		{
			return sqrt(x * x + y * y);
		}

		auto dot(const Vector vector) const
		{
			return x * vector.x + y * vector.y;
		}
	}

	static if (size == 3)
	{
		auto magnitude() const
		{
			return sqrt(x * x + y * y + z * z);
		}

		auto dot(const Vector vector) const
		{
			return x * vector.x + y * vector.y + z * vector.z;
		}

		auto cross(const Vector vector) const
		{
			return Vector(
				y * vector.z - z * vector.y,
				z * vector.x - x * vector.z,
				x * vector.y - y * vector.x
			);
		}
	}

	private enum _size = size;
	auto opCast(U)() const
	if (size == U._size)
	{
		U vector;
		foreach (i; 0 .. size) vector.array[i] = array[i];
		return vector;
	}

	unittest
	{
		auto v1 = Vec3f(1, -1, 1);
		auto v2 = Vector!(3, double)(1, -1, 1);
		assert(cast(Vector!(3, double)) v1 == v2);
	}
}

auto mix(V, T)(auto const ref V x, auto const ref V y, T a)
if (isInstanceOf!(Vector, V) && isFloatingPoint!T)
{
	return x * (1 - a) + y * a;
}

unittest
{
	auto a = Vec3f(0, 0, 0);
	auto b = Vec3f(1, 1, 1);
	assert(mix(a, b, 0.5f) == Vec3f(0.5f, 0.5f, 0.5f));
}
