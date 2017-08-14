/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   rt.h.cl                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: agrumbac <agrumbac@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2017/06/18 23:53:40 by agrumbac          #+#    #+#             */
/*   Updated: 2017/06/27 22:00:32 by agrumbac         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#ifndef RT_H_CL
# define RT_H_CL

/*
** ********************************** rt ***************************************
*/

# include "vector.h.cl"
# include "hit.h.cl"

/*
** ********************************** camera ***********************************
*/

typedef struct			s_uv
{
	float				u;
	float				v;
}						t_uv;

typedef struct			s_cam
{
	t_vector			origin;
	t_uv				direction;
	float				fov;
	float				aspect;
}						t_cam;

typedef struct			s_light
{
	t_vector			position;
	float				intensity;
	t_vector			color;
	char				is_limited;
	t_vector			direction;
	float				angle;
}						t_light;

/*
** ********************************** misc *************************************
*/

# define GLOBAL_X	1
# define GLOBAL_Y	0

typedef struct			s_yx
{
	int					y;
	int					x;
}						t_yx;

typedef union 			s_64_color
{
	unsigned long		color;
	struct				s_64_c
	{
		unsigned short	r;
		unsigned short	g;
		unsigned short	b;
		unsigned short	a;
	}					c;
}						t_64_color;

/*
** ********************************* scene *************************************
*/

typedef struct			s_scene
{
	struct s_cam		camera;
	t_vector			ambient;
	char				nb_light;
	char				nb_triangle;
	char				nb_sphere;
	char				nb_cone;
	char				nb_plan;
	struct s_triangle	triangles[4];
	struct s_sphere		spheres[10];
	struct s_cone		cones[4];
	struct s_plane		plans[4];
	struct s_light		lights[10];
}						t_scene;

#endif
