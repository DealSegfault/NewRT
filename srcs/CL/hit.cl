/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   hit.c                                              :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: agrumbac <agrumbac@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2017/07/10 22:54:41 by agrumbac          #+#    #+#             */
/*   Updated: 2017/07/10 22:54:43 by agrumbac         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

# include "hit.h.cl"

//pitmap to add

float2		uv_mapping(float3 normal)
{
	float2		uv;

	uv.x = atan2(normal.x, normal.z) / (2 * M_PI) + 0.5;
	uv.y = normal.y * 0.5 + 0.5;
	return (uv);
}

bool		is_pited_tmp(float2 uv)
{
	if (((int)(uv.x * 5) % 2) ^ ((int)(uv.y * 5) % 2))
		return (0);
	else
		return (1);
}

# define DEBUG_CONDITION get_global_id(0) == 500 && get_global_id(1) == 500
float3		bump_map_tmp(float2 uv, float3 normal)
{
	if (DEBUG_CONDITION)
		printf("%lf %lf\n", uv.x, uv.y);
	normal.y += (int)(uv.y * 1000) % 100 * 0.002;
	normal.x += (int)(uv.x * 1000) % 100 * 0.002;
	return (normalize(normal));
}

int			hit_sphere(const void *sphere, const t_ray *ray, t_hit *record)
{
	const t_vector	RayToCenter = ray->origin - ((t_sphere*)sphere)->center;
	const float		a = 1 / dot(ray->direction, ray->direction);
	const float		b = dot(RayToCenter, ray->direction);
	const float		c = dot(RayToCenter, RayToCenter) -
						((t_sphere*)sphere)->radius * ((t_sphere*)sphere)->radius;
	const float		d = b * b - a * c;
	if (d < 0)
		return (0);
	const float Square = sqrt(d);
	const float t1 = (-b - Square) * a;
	const float t2 = (-b + Square) * a;
	//CALC POINT AND PITMAP
	//IF TRANPARENT CALC 2 POINT AND RETURN VALUE OF TRANSPARENCY
	const float t = (t1 < t2 && t1 > 0 ? t1 : t2);
	if (t < 0)
		return (0);
	record->delta = d;
	record->t = t;
	record->point = ray->origin + t * ray->direction;
	//BUMP MAP
	record->object_normal = normalize(((t_sphere*)sphere)->center - record->point);
	float2	uv = uv_mapping(record->object_normal);
	if (is_pited_tmp(uv) && ((t_sphere *)sphere)->material.is_pited == 1)
	{
		if (t != t1)
			return (0);
		else
		{
			record->t = t2;
			record->point = ray->origin + t2 * ray->direction;
			record->normal = normalize(((t_sphere *)sphere)->center - record->point);
			record->object_normal = normalize(((t_sphere *)sphere)->center - record->point);
			uv = uv_mapping(record->object_normal);
			if (is_pited_tmp(uv))
				return (0);
		}
	}
	else
	{
		record->object_normal = normalize(record->point - ((t_sphere *)sphere)->center);
		if (t1 < t2 && t1 > 0)
			record->normal = normalize(record->point - ((t_sphere*)sphere)->center);
		else
			record->normal = normalize(((t_sphere*)sphere)->center - record->point);
	}
	if (((t_sphere *)sphere)->material.is_bumped == 1)
	{
		record->normal = bump_map_tmp(uv, record->normal);
		record->object_normal = bump_map_tmp(uv, record->object_normal);
	}
	record->object_color = ((t_sphere *)sphere)->material.color;
	record->object_reflection = ((t_sphere *)sphere)->material.reflectivity;
	record->object_transparency = ((t_sphere *)sphere)->material.transparency;
	return (1);
}

// int			hit_cone(const void *cone, const t_ray *ray)
// {
// 	const t_vector	co = vector(((t_cone*)cone)->tip, ray->origin);
// 	const float		t = pow(cos(((t_cone*)cone)->angle), 2);
// 	const float		a = pow(dot(ray->direction, ((t_cone*)cone)->axis), 2) - t;
// 	const float		b = 2 * (dot(ray->direction, ((t_cone*)cone)->axis) * \
// 					dot(co, ((t_cone*)cone)->axis) - \
// 					dot(ray->direction, co) * t);
// 	const float		c = pow(dot(co, ((t_cone*)cone)->axis), 2) - dot(co, co) * t;
// 	const float		d = b * b - 4 * a * c;
//
// 	return (d >= 0);
// }
//
//
