/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   hit.h.cl                                           :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: agrumbac <agrumbac@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2017/07/12 10:38:58 by agrumbac          #+#    #+#             */
/*   Updated: 2017/07/12 10:39:00 by agrumbac         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#ifndef HIT_H_CL
# define HIT_H_CL

# include "vector.h.cl"
# include "rt.h.cl"

typedef union 			s_color
{
	unsigned int		color;
	struct				s_c
	{
		unsigned char	r;
		unsigned char	g;
		unsigned char	b;
		unsigned char	a;
	}					c;
}						t_color;

typedef struct	s_material
{
	t_vector		color;
	float			diffuse;
	float			specular;
	float			specular_strength;
	float			reflectivity;
	float			transparency;
	float			refractivity;
	char			is_textured;
	char			is_bumped;
	char			is_pited;
	unsigned int	text_i;
	unsigned int	bump_i;
	unsigned int	pit_i;
}					t_material;

/*
** ********************************** shapes ***********************************
*/

# define SPHERE		1
# define PLANE		2
# define TRIANGLE	3

typedef struct		s_obj
{
	t_material		material;
}					t_obj;

typedef struct		s_sphere
{
	t_material		material;
	t_vector		center;
	float			radius;
}					t_sphere;

typedef struct		s_plane
{
	t_material		material;
	t_vector		point;
	t_vector		normal;
}					t_plane;

typedef struct		s_cone
{
	t_material		material;
	t_vector		tip;
	t_vector		axis;
	float			angle;
}					t_cone;

typedef struct		s_triangle
{
	t_material		material;
	t_vector		a;
	t_vector		b;
	t_vector		c;
}					t_triangle;

/*
** ********************************** ray **************************************
*/

typedef struct			s_ray
{
	t_vector			origin;
	t_vector			direction;
}						t_ray;

/*
** ********************************** hit **************************************
*/

typedef struct			s_hit
{
	float				t;
	float				delta;
	t_vector			point;
	t_vector			normal;
}						t_hit;

typedef struct			s_node
{
	char				active;
	t_vector			res_color;
	float				power;
	t_ray				new_ray;
}						t_node;

int			hit_sphere(const void *sphere, const t_ray *ray, t_hit *record);
int			hit_plane(const void *plane, const t_ray *ray, t_hit *record);
int			hit_cone(const void *cone, const t_ray *ray, t_hit *record);
int			hit_cylinder(const void *cylinder, const t_ray *ray, t_hit *record);
int			hit_triangle(const void *triangle, const t_ray *ray, t_hit *record);

#endif
