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
//	if (length(ray->origin - ((t_sphere*)sphere)->center) < ((t_sphere*)sphere)->radius)
//		record->normal = -normalize(record->point - ((t_sphere*)sphere)->center);
//	else
		record->normal = normalize(record->point - ((t_sphere*)sphere)->center);
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
