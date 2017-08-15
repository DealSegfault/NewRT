
# include "rt.h.cl"
# include "vector.cl"
# include "hit.cl"

# define DEBUG_CONDITION get_global_id(0) == 500 && get_global_id(1) == 500

# define SIZE_OF_6_STAGE_TREE (1 + 2 + 4 + 8 + 16 + 32 + 64)
# define SIZE_OF_5_STAGE_TREE (1 + 2 + 4 + 8 + 16 + 32)
# define SIZE_OF_4_STAGE_TREE (1 + 2 + 4 + 8 + 16)
# define SIZE_OF_3_STAGE_TREE (1 + 2 + 4 + 8)
# define SIZE_OF_2_STAGE_TREE (1 + 2 + 4)
# define SIZE_OF_1_STAGE_TREE (1 + 2)
# define SIZE_OF_0_STAGE_TREE (1)

# define MAX_FLOOR_OF_TREE 6
# define SIZE_OF_TREE SIZE_OF_6_STAGE_TREE
# define D_RAY (float3){0.003, 0.003, 0.003}

static void		put_pixel(__global uint* pixels, \
				const t_yx pixel, const t_yx size, const int color)
{
	pixels[pixel.x + pixel.y * size.x] = color | 0xFF000000;
}

static t_vector		light_hit_object(const t_scene *scene, t_ray ray)
{
	t_hit		record;
	char		light_blur;
	t_obj		*obj;
	t_vector	ratio = (float3)0xFF;

	const int	nb_sphere = scene->nb_sphere;
	const float	vector_length = length(ray.direction) * (float)0.999;
	ray.direction = normalize(ray.direction);
	int			i;
	for (i = 0; i < nb_sphere; i++)
		if (hit_sphere(&scene->spheres[i], &ray, &record))
			if (record.t < vector_length)
			{
				if (record.object_transparency == 0)
					return ((float3)0);
				else
					ratio -= record.object_color * (float3)record.object_transparency;
			}
	return (ratio);
}

static void	*get_object(const t_scene *scene, const t_ray *ray, t_hit *record)
{
	t_obj		*min_obj;
	t_hit		min_record;

	min_obj = 0;
	const int	nb_sphere = scene->nb_sphere;
	int			i;

	for (i = 0; i < nb_sphere; i++)
		if (hit_sphere(&scene->spheres[i], ray, record))
			if (record->t < min_record.t || min_obj == 0)
			{
				min_obj = (void *)&scene->spheres[i];
				min_record = *record;
			}
	*record = min_record;
	return (min_obj);
}

static t_vector		diffuse_light(t_vector color_ratio, const float angle, const float diffuse)
{
	if (angle < 0)
		return ((t_vector){0, 0, 0});
	const float		ratio = angle * diffuse;
	return ((t_vector){
			color_ratio.x * ratio,
			color_ratio.y * ratio,
			color_ratio.z * ratio});
}

static void			add_32_to_64_color(t_64_color *c64, const t_color c32)
{
	c64->c.r += c32.c.r;
	c64->c.g += c32.c.g;
	c64->c.b += c32.c.b;
	c64->c.a += c32.c.a;
}

static t_color	color_substract(t_color light, t_color surface)
{
	t_color		res;

	res.c.r = (light.c.r * surface.c.r) >> 8;
	res.c.g = (light.c.g * surface.c.g) >> 8;
	res.c.b = (light.c.b * surface.c.b) >> 8;
	res.c.a = 0xFF;
	return (res);
}

static t_vector		light_coefficent(const t_scene *scene, const t_material *material, t_hit *record, const t_ray *cam)
{
	const int	nb_light = scene->nb_light;
	t_ray		ray;
	t_vector	hit_color_ratio;
	t_vector	phong_ratio;
	t_vector	phong_act;
	float		phong = 0;
	t_vector	ratio = {0, 0, 0};
	float		angle;
	int			i;
	for (i = 0; i < nb_light; i++)
	{
		ray.direction = vector(record->point, scene->lights[i].position);
		ray.origin = record->point + ray.direction * D_RAY;
		hit_color_ratio = light_hit_object(scene, ray);
		angle = dot(record->normal, normalize(ray.direction));
		hit_color_ratio = diffuse_light(hit_color_ratio, angle, material->diffuse);
		hit_color_ratio = clamp(hit_color_ratio, (float3){0, 0, 0}, scene->lights[i].color);
		hit_color_ratio = clamp(hit_color_ratio, (float3){0, 0, 0}, record->object_color);
		hit_color_ratio *= (float3){scene->lights[i].intensity,
									scene->lights[i].intensity,
									scene->lights[i].intensity};
		if (angle >= 0)
		{
			phong = dot(cam->direction, record->normal * (float3)(angle * material->specular_strength));
			phong = pown(phong,12) * material->specular * scene->lights[i].intensity;
			phong_act = (float3){phong * scene->lights[i].color.x,
								phong * scene->lights[i].color.y,
								phong * scene->lights[i].color.z};
			phong_ratio += //phong_act;
						clamp(phong_act, (float3)0, //(float3)0xFF);
											hit_color_ratio);
		}
		ratio += hit_color_ratio;
	}
	ratio += phong_ratio;
	ratio /= (float3){nb_light, nb_light, nb_light};
	ratio = clamp(ratio, scene->ambient, (float3){0xFF, 0xFF, 0xFF});
	return (ratio);
/*	return ((t_color){.c.r = (unsigned char)ratio.x,
					.c.g = (unsigned char)ratio.y,
					.c.b = (unsigned char)ratio.z,
					.c.a = 0xFF});
*/}

static t_vector reflect(t_vector ray, t_vector normal)
{
		return (normalize(ray - (float3){2.0f, 2.0f, 2.0f} * dot(ray, normal) * normal));
}

/*
static t_vector refract(t_vector ray, t_vector normal, float refraction)
{
	const float cosI = -dot(normal, ray);
	const float cosT2 = 1.0f - refraction * refraction * (1.0f - cosI * cosI);
	return (normalize((refraction * ray) + (refraction * cosI - sqrt(cosT2)) * normal));
}*/
t_vector refract(const t_vector ray, const t_vector normal, const float refraction)
{
	float cosi = clamp((float)-1, (float)1, (float)dot(ray, normal));
	float etai = 1;
	float etat = refraction;
	float tmp;
	t_vector n = normal;
	if (cosi < 0)
		cosi = -cosi;
	else
	{
		tmp = etai;
		etai = etat;
		etat = tmp;
		n = -normal;
	}
	float eta = etai / etat;
	float k = 1 - eta * eta * (1 - cosi * cosi);
	return (k < 0 ? (float3)0 : normalize((float3)eta * ray + (float3)(eta * cosi - sqrt(k)) * n));
}
/*
static t_vector		get_color(const t_scene *scene, const t_ray *ray)
{
	t_hit		record;
	t_sphere	*obj;
	t_vector	coefficient;
	t_ray		new_ray;

	if ((obj = get_object(scene, ray, &record)) != 0)
	{
		coefficient = light_coefficent(scene, &obj->material, &record, ray);
		if (obj->material.reflectivity != 0)
		{
			new_ray.direction = reflect(ray->direction, record.normal);
			new_ray.origin = record.point + new_ray.direction * D_RAY;
			if ((obj = get_object(scene, &new_ray, &record)))
				coefficient = light_coefficent(scene, &obj->material, &record, &new_ray);
		}
		return (coefficient);
	}
	else
		return ((float3)0xaa);
}
*/
static void		fill_tree(const t_scene *scene, const t_ray *ray, t_node *tree)
{
	t_obj		*obj;
	int			etage;
	int			node;

	t_ray		ray_tree;
	t_hit		record;

	int			end;
	t_vector	new_ray;
	t_node		*act_node;
	t_node		*next_node;

	int			off_node;
	t_node		*act;

	node = 0;
	bzero(tree, sizeof(t_node) * SIZE_OF_TREE);
	tree->active = 1;
	tree->new_ray = *ray;
	for (etage = 0; etage < MAX_FLOOR_OF_TREE; etage++)
	{
		node = 0;
		for (end = powr(2.0, etage); node < end; node++)
		{
			act_node = &tree[end - 1 + node];
			if (act_node->active != 0)
			{
				obj = get_object(scene, &act_node->new_ray, &record);
				if (obj)
				{
					act_node->res_color = light_coefficent(scene, &obj->material, &record, &act_node->new_ray);
					act_node->object_color = record.object_color;
					next_node = &tree[end * 2 - 1 + node * 2];
					if (record.object_reflection != 0)
					{
						new_ray = reflect(act_node->new_ray.direction, record.normal);
						next_node[0] = (t_node){1,
							(float3)0,
							(float3)0,
							record.object_reflection,
							(t_ray){record.point + new_ray * D_RAY, new_ray}
						};
					}
					if (record.object_transparency != 0)
					{
						new_ray = refract(act_node->new_ray.direction + D_RAY, record.normal, obj->material.refractivity);
						if (new_ray.x != 0 || new_ray.y != 0 || new_ray.z != 0)
							next_node[1] = (t_node){1,
								(float3)0,
								(float3)0,
								record.object_transparency,
								(t_ray){record.point + new_ray * D_RAY, new_ray}
							};
						/*if (DEBUG_CONDITION)
						{
							printf("intersection pos : %lf %lf %lf\nlength : %lf\nray_info : %lf %lf %lf\n", record.point.x, record.point.y, record.point.z, length(((t_sphere *)obj)->center - record.point), new_ray.x, new_ray.y, new_ray.z);
						}*/
					}
				}
				else
				{
					act_node->res_color = (float3)act_node->new_ray.direction * (float3){0xFF, 0xFF, 0xFF};
					if (((int)(act_node->new_ray.direction.y * 8) % 2
						& (int)(8 * act_node->new_ray.direction.x) % 2
						& (int)(8 * act_node->new_ray.direction.z) % 2))
						act_node->res_color = (float3)0;
					else
						act_node->res_color = (float3)0xFF;
					act_node->object_color = act_node->res_color;
				}
			}
		}
	}
}

static void		resolve_tree(const t_scene *scene, t_node *tree)
{
	int			etage;
	int			node;
	int			end;
	t_vector	color;
	t_vector	node1;
	t_vector	node2;
	t_node		*act;
	t_node		*lower_node;
	float		ret;
	float		reflection;
	float		transparency;

	for (etage = MAX_FLOOR_OF_TREE; etage >= 0; etage--)
	{
		node = 0;
		for (end = (int)powr(2.0, etage); node < end; node++)
		{
			act = &tree[end + node - 1];
			if (act->active != 0)
			{
				color = (float3)0;
				reflection = 0;
				transparency = 0;
				lower_node = &tree[end * 2 + node * 2 - 1];
				reflection = lower_node[0].power;
				if (lower_node[0].active == 1)
				{
					node1 = (float3)lower_node[0].res_color * (float3)reflection;
					color += clamp(node1, (float3)0, act->res_color);
				}
				transparency = lower_node[1].power;
				if (lower_node[1].active == 1)
				{
					node2 = (float3)lower_node[1].res_color * (float3)transparency;
					color += clamp(node2, (float3)0, act->object_color);
				}
				else
					node2 = (float3)0xFF;
				ret = 2 - (transparency + reflection);
				color += act->res_color * (float3)ret;
				color *= 1 - clamp((int)(reflection - transparency), (int)0, (int)1);//(float3)0.5;
				color = clamp(color, (float3)0, act->object_color);
				if (DEBUG_CONDITION)
					printf("%lf %lf %lf\n", color.x, color.y, color.z);
				act->res_color = color;
			}
		}
	}
}

static t_ray	get_ray(__constant t_cam *cam, const float s, const float t)
{
	const float		xf = (2 * s - 1) * cam->aspect * 0.39;
	const float		yf = (1 - 2 * t) * 0.39;
	return ((t_ray){cam->origin,
			normalize((t_vector){
			-cos((float)cam->direction.u) * sin((float)cam->direction.v)
				+ xf * cos((float)cam->direction.v)
				+ yf * sin((float)cam->direction.u) * sin((float)cam->direction.v),
			sin((float)cam->direction.u)
				+ yf * cos((float)cam->direction.u),
			cos((float)cam->direction.u) * cos((float)cam->direction.v)
				+ xf * sin((float)cam->direction.v)
				- yf * sin((float)cam->direction.u) * cos((float)cam->direction.v)}
				)});
}

static t_scene	tmp_init_scene(void)
{
	t_material		base_material;
	t_scene			scene;

	bzero(&scene, sizeof(t_scene));
	base_material = (t_material){(float3){0xFF, 0xFF, 0xFF}, 1, 1, 12, 0.8, 0.8, 1.3, 0, 0, 0, 0, 0, 0};
	scene.nb_sphere = 6;
	scene.ambient = (float3){20, 20, 20};
	scene.spheres[0] = (t_sphere){base_material, {0, 0, -10}, 4};
//	scene.spheres[0].material.color = 0xFF021C1E;
	scene.spheres[1] = (t_sphere){base_material, {0, -5, -5}, 3};
//	scene.spheres[1].material.color = 0xFF004445;
	scene.spheres[2] = (t_sphere){base_material, {-5, -5, -5}, 7};
//	scene.spheres[2].material.color = 0xFF2C7873;
	scene.spheres[3] = (t_sphere){base_material, {5, -5, -5}, 8};
//	scene.spheres[3].material.color = 0xFF6FB98F;
	scene.spheres[4] = (t_sphere){base_material, {0, 0, 5}, 7};
//	scene.spheres[4].material.color = 0xFF6FB98F;
	scene.spheres[5] = (t_sphere){base_material, {5, 0, 0}, 4};
//	scene.spheres[5].material.color = 0xFF0FB98F;

	scene.nb_light = 4;
	scene.nb_sphere = 4;
	scene.spheres[0] = (t_sphere){base_material, {0, 0, 10}, 10};
	scene.spheres[0].material.color = (float3){255, 255, 255};
	scene.spheres[1] = (t_sphere){base_material, {0, 8, 12}, 6};
	scene.spheres[1].material.color = (float3){255, 255, 0};
	scene.spheres[2] = (t_sphere){base_material, {0, 15, 8}, 3};
	scene.spheres[2].material.color = (float3){255, 0, 255};
	scene.spheres[3] = (t_sphere){base_material, {0, 20, 10}, 1};
	scene.spheres[3].material.color = (float3){0, 255, 255};
	scene.lights[0] = (t_light){{0, 10, 40}, 1, {0xFF, 0xFF, 0xFF}, 0, {0, 0, 1}, 0};
	scene.lights[1] = (t_light){{0, 10, 60}, 1, {0xFF, 0, 0xFF}, 0, {0, 0, 1}, 0};
	scene.lights[2] = (t_light){{-20, -10, 20}, 1, {0, 0xFF, 0xFF}, 0, {0, 0, 1}, 0};
	scene.lights[3] = (t_light){{-20, -10, 40}, 1, {0xFF, 0, 0}, 0, {0, 0, 1}, 0};
	return (scene);
}

__kernel void	core(__global uint* pixels, __constant t_cam *cam)
{
	const t_yx	pixel = (t_yx){(int)get_global_id(GLOBAL_Y), \
								(int)get_global_id(GLOBAL_X)};
	const t_yx	size = (t_yx){(int)get_global_size(GLOBAL_Y), \
								(int)get_global_size(GLOBAL_X)};
	const t_ray ray = get_ray(cam, pixel.x / (float)size.x, pixel.y / (float)size.y);
	const t_scene	scene = tmp_init_scene();
	t_node			binary_tree[SIZE_OF_TREE];
	t_color			color;
	t_vector		res;

	if (DEBUG_CONDITION)
		printf("\nDraw %lf %lf %lf\n", ray.direction.x, ray.direction.y, ray.direction.z);
	fill_tree(&scene, &ray, binary_tree);
	resolve_tree(&scene, binary_tree);
	res = binary_tree[0].res_color;
	//res = get_color(&scene, &ray);
	int		i;

	i = -1;
	if (!(DEBUG_CONDITION))
		color = (t_color){.c.r = res.x, .c.g = res.y, .c.b = res.z, .c.a = 0xFF};
	else
		color.color = 0x00000FF;
	put_pixel(pixels, pixel, size, color.color);
}
//asaaasdsasdadabafasdasaasdsdadasdaasdaasddbewbhefeasdaasdaasda
//asasdadasdasddqweasasdaasdadsasdasdddi
