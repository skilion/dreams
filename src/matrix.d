module matrix;

import std.conv: to;
import std.math;
import std.traits: isFloatingPoint;
import vector;

alias Matrix!(2, float) Mat2f;
alias Matrix!(3, float) Mat3f;
alias Matrix!(4, float) Mat4f;

struct Matrix(int size, T)
if (size >= 2 && size <= 4 && isFloatingPoint!T)
{
	union
	{
		/*
		m11 = 1, m21 = 0, ...
		m12 = 0, m22 = 1, ...
		m13 = 0, ...
		*/
		mixin(genMatrixStruct(size));
		T[size * size] array;
	}

	auto ptr() inout nothrow
	{
		return array.ptr;
	}

	auto ref opIndex(size_t index) inout
	{
		return array[index];
	}

	auto ref opBinary(string op: "*")(const auto ref Matrix rhs) const nothrow
	{
		Matrix matrix = void;
		/*
		matrix.m11 = this.m11 * rhs.m11 + this.m12 * rhs.m21 + ...
		matrix.m12 = this.m11 * rhs.m12 + this.m12 * rhs.m22 + ...
		matrix.m13 = ...
		*/
		mixin(genMatrixMul("this", "rhs", "matrix", size));
		return matrix;
	}

	unittest
	{
		Mat2f matrix1 = Mat2f(1, 2, 3, 4);
		Mat2f matrix2 = Mat2f(4, 3, 2, 1);
		assert(matrix1 * matrix2 == Mat2f(13, 20, 5, 8));
	}

	auto ref opBinary(string op: "*")(const auto ref Vector!(size, T) rhs) const nothrow
	{
		Vector!(size, T) vector = void;
		/*
		vector[0] = this.m11 * rhs[0] + this.m12 * rhs[1] + ...
		vector[1] = this.m21 * rhs[0] + this.m22 * rhs[1] + ...
		vector[2] = ...
		*/
		mixin(genMatrixVectorMul("this", "rhs", "vector", size));
		return vector;
	}

	unittest
	{
		Mat3f matrix = Mat3f(1, 1, 1, 1, 1, 1, 1, 1, 1);
		Vec3f vector = Vec3f(1, 1, 1);
		assert(matrix * vector == Vec3f(3, 3, 3));
	}

	auto ref opBinaryRight(string op: "*")(const auto ref Vector!(size, T) lhs) const nothrow
	{
		Vector!(size, T) vector = void;
		mixin(genVectorMatrixMul("lhs", "this", "vector", size));
		return vector;
	}

	unittest
	{
		Mat3f matrix = Mat3f(1, 1, 1, 1, 1, 1, 1, 1, 1);
		Vec3f vector = Vec3f(1, 1, 1);
		assert(vector * matrix == Vec3f(3, 3, 3));
	}

	auto ref opMulAssign(const ref Matrix rhs) nothrow
	{
		this = this * rhs;
		return this;
	}

	auto determinant() const nothrow
	{
		assert(0, "TODO");
		return mixin(genMatrixDet(size));
	}

	auto ref transpose() nothrow
	{
		foreach (r; 0 .. size) //row
		{
			foreach (c; r + 1 .. size) //column
			{
				T swap = array[c + r * size];
				array[c + r * size] = array[r + c * size];
				array[r + c * size] = swap;
			}
		}
		return this;
	}

	unittest
	{
		Mat2f matrix = Mat2f(1, 2, 3, 4);
		assert(matrix.transpose() == Mat2f(1, 3, 2, 4));
	}
}

Mat4f translationMatrix(float x, float y, float z)
{
	Mat4f matrix;
	matrix.m14 = x;
	matrix.m24 = y;
	matrix.m34 = z;
	return matrix;
}

Mat4f rotXMatrix(float rad)
{
	Mat4f matrix;
	float c = cos(rad);
	float s = sin(rad);
	matrix.m22 = c;
	matrix.m23 = -s;
	matrix.m32 = s;
	matrix.m33 = c;
	return matrix;
}

Mat4f rotYMatrix(float rad)
{
	Mat4f matrix;
	float c = cos(rad);
	float s = sin(rad);
	matrix.m11 = c;
	matrix.m13 = s;
	matrix.m31 = -s;
	matrix.m33 = c;
	return matrix;
}

Mat4f rotZMatrix(float rad)
{
	Mat4f matrix;
	float c = cos(rad);
	float s = sin(rad);
	matrix.m11 = c;
	matrix.m12 = -s;
	matrix.m21 = s;
	matrix.m22 = c;
	return matrix;
}

Mat4f frustumMatrix(float left, float right, float bottom, float top, float near, float far)
{
	Mat4f matrix;
	float dnear = 2 * near;
	float rpl = right + left;
	float tpb = top + bottom;
	float fpn = far + near;
	float rml = right - left;
	float tmb = top - bottom;
	float fmn = far - near;
	matrix.m11 = dnear / rml;
	matrix.m22 = dnear / tmb;
	matrix.m13 = rpl / rml;
	matrix.m23 = tpb / tmb;
	matrix.m33 = -(fpn / fmn);
	matrix.m43 = -1;
	matrix.m34 = -((2 * far * near) / fmn);
	matrix.m44 = 0;
	return matrix;
}

Mat4f orthoMatrix(float left, float right, float bottom, float top, float near, float far)
{
	Mat4f matrix;
	float rpl = right + left;
	float tpb = top + bottom;
	float fpn = far + near;
	float rml = right - left;
	float tmb = top - bottom;
	float fmn = far - near;
	matrix.m11 = 2 / rml;
	matrix.m22 = 2 / tmb;
	matrix.m33 = -2 / fmn;
	matrix.m14 = -(rpl / rml);
	matrix.m24 = -(tpb / tmb);
	matrix.m34 = -(fpn / fmn);
	return matrix;
}

Mat4f orthoMatrixSimple(int width, int height)
{
	return orthoMatrix(0, width, height, 0, -1, 1);
}

Mat4f perspectiveMatrix(float fov, float aspect, float near, float far)
{
	float height = tan(fov / 2) * near;
	float width = height * aspect;
	return frustumMatrix(-width, width, -height, height, near, far);
}

Mat4f lookAtMatrix(const ref Vec3f forward, const ref Vec3f side, const ref Vec3f up)
{
	Mat4f matrix;
	matrix.m11 = side.x;
	matrix.m12 = side.y;
	matrix.m13 = side.z;
	matrix.m21 = up.x;
	matrix.m22 = up.y;
	matrix.m23 = up.z;
	matrix.m31 = -forward.x;
	matrix.m32 = -forward.y;
	matrix.m33 = -forward.z;
	return matrix;
}

private:

string genMatrixStruct(int size)
{
	assert(size > 0 && size <= 9);
	string code = "struct{";
	foreach (r; 1 .. size + 1) //row
	{
		foreach (c; 1 .. size + 1) //column
		{
			//the matrix is stored in column-major order
			code ~= "T m" ~ to!string(c) ~ to!string(r);
			if (r == c)
			{
				code ~= "=1;";
			}
			else
			{
				code ~= "=0;";
			}
		}
	}
	code ~= "}";
	return code;
}

string genMatrixMul(string lhs, string rhs, string result, int size)
{
	assert(size > 0 && size <= 9);
	lhs ~= ".m";
	rhs ~= ".m";
	result ~= ".m";
	string code;
	foreach (r; 1 .. size + 1) //row
	{
		foreach (c; 1 .. size + 1) //column
		{
			code ~= result ~ to!string(r) ~ to!string(c) ~ "=";
			foreach (n; 1 .. size + 1)
			{
				code ~= lhs ~ to!string(r) ~ to!string(n) ~ "*";
				code ~= rhs ~ to!string(n) ~ to!string(c) ~ "+";
			}
			code.length--;
			code ~= ";";
		}
	}
	return code;
}

string genMatrixVectorMul(string lhs, string rhs, string result, int size)
{
	assert(size > 0 && size <= 9);
	lhs ~= ".m";
	string code;
	foreach (r; 1 .. size + 1) //row
	{
		code ~= result ~ "[" ~ to!string(r - 1) ~ "]=";
		foreach (n; 1 .. size + 1)
		{
			code ~= lhs ~ to!string(r) ~ to!string(n) ~ "*";
			code ~= rhs ~ "[" ~ to!string(n - 1) ~ "]+";
		}
		code.length--;
		code ~= ";";
	}
	return code;
}

string genVectorMatrixMul(string lhs, string rhs, string result, int size)
{
	assert(size > 0 && size <= 9);
	rhs ~= ".m";
	string code;
	foreach (c; 1 .. size + 1) //column
	{
		code ~= result ~ "[" ~ to!string(c - 1) ~ "]=";
		foreach (n; 1 .. size + 1)
		{
			code ~= lhs ~ "[" ~ to!string(n - 1) ~ "]*";
			code ~= rhs ~ to!string(n) ~ to!string(c) ~ "+";
		}
		code.length--;
		code ~= ";";
	}
	return code;
}

string genMatrixDet(int size)
{
	//TODO
	string code = "0";
	return code;
}
