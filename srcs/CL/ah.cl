__kernel void raytracer(__global int *pixels, __constant int* cam)
{
	const int		x = get_global_id(0);
	const int		y = get_global_id(1);
	const int		width = get_global_size(0);
	if (x == 0 && y == 0)
		printf("ah\n");
	pixels[y * width + x] = 0xFFFFFF;
}
