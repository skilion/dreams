module dreams.view;

import matrix, vector;

struct View
{
	float fov;
	float aspect; // width/height
	float near, far;
	Vec3f position;
	Vec3f forward, side, up;
	Mat4f vp; // projection * view matrix

	void computeViewProjectionMatrix()
	{
		auto proj = perspectiveMatrix(fov, aspect, near, far);
		auto rotation = lookAtMatrix(forward, side, up);
		auto translation = translationMatrix(-position.x, -position.y, -position.z);
		vp = proj * rotation * translation;
	}
}
