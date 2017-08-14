/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   sdl_events.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: agrumbac <agrumbac@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2017/07/12 12:49:22 by agrumbac          #+#    #+#             */
/*   Updated: 2017/08/11 06:44:56 by gmonein          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "easy_sdl.h"
#include "rt.h"



static int			ft_move(char *m)
{
	*m = 1;
	return (1);
}

t_vector			uv_to_vec(float u, float v)
{
	return ((t_vector){-cos(u) * sin(v), sin(u), cos(u) * cos(v)});
}

t_vector			add_vec(t_vector a, t_vector b)
{
	return ((t_vector){a.x + b.x, a.y + b.y, a.z + b.z});
}

static int			move_cam(t_cam *cam)
{
	const Uint8		*state = SDL_GetKeyboardState(NULL);
	char			move;

	move = 0;
	if (state[SDL_SCANCODE_W] && ft_move(&move))
		cam->origin = add_vec(cam->origin, uv_to_vec(cam->direction.u, cam->direction.v));
	if (state[SDL_SCANCODE_S] && ft_move(&move))
		cam->origin = add_vec(cam->origin, uv_to_vec(cam->direction.u + M_PI, cam->direction.v));
	if (state[SDL_SCANCODE_A] && ft_move(&move))
		cam->origin = add_vec(cam->origin, uv_to_vec(cam->direction.u + M_PI_2, cam->direction.v));
	if (state[SDL_SCANCODE_D] && ft_move(&move))
		cam->origin = add_vec(cam->origin, uv_to_vec(cam->direction.u - M_PI_2, cam->direction.v));
	if (state[SDL_SCANCODE_Q] && ft_move(&move))
		cam->origin = add_vec(cam->origin, uv_to_vec(cam->direction.u, cam->direction.v + M_PI_2));
	if (state[SDL_SCANCODE_E] && ft_move(&move))
		cam->origin = add_vec(cam->origin, uv_to_vec(cam->direction.u, cam->direction.v - M_PI_2));
	return (move);
}

static int			sdl_keyboard(t_cam *cam)
{
	const Uint8		*state = SDL_GetKeyboardState(NULL);
	char			move;

	move = 0;
	if (state[SDL_SCANCODE_J] && ft_move(&move))
		if ((cam->direction.v += 0.05) > M_PI)
			cam->direction.v = -M_PI;
	if (state[SDL_SCANCODE_L] && ft_move(&move))
		if ((cam->direction.v -= 0.05) < -M_PI)
			cam->direction.v = M_PI;
	if (state[SDL_SCANCODE_I] && ft_move(&move))
		if ((cam->direction.u += 0.05) > M_PI)
			cam->direction.u = -M_PI;
	if (state[SDL_SCANCODE_K] && ft_move(&move))
		if ((cam->direction.u -= 0.05) < -M_PI)
			cam->direction.u = M_PI;
	move |= move_cam(cam);
	return (move);
}

int					sdl_events(t_sdl *sdl, t_cam *cam)
{
//	if (!(SDL_PollEvent(&sdl->event)))
//		errors(ERR_SDL, "SDL_WaitEvent failed --");
	if (SDL_PollEvent(&sdl->event))
	{
		if (sdl->event.window.type == SDL_WINDOWEVENT_CLOSE || \
			sdl->event.key.keysym.sym == SDLK_ESCAPE || \
			sdl->event.type == SDL_QUIT)
			return (0);
		if (sdl->event.type == SDL_WINDOWEVENT &&
			sdl->event.window.event == SDL_WINDOWEVENT_RESIZED)
		{
			sdl_init_window(sdl);
			cam->aspect = sdl->size.x / (float)sdl->size.y;
			return (EVENT_UPDATE);
		}
		if (sdl_keyboard(cam))
			return (EVENT_UPDATE);
	}
	return (EVENT_IDLE);
}

// SDL_GetMouseState(&x, &y);
// SDL_WarpMouseInWindow(env->win, env->ar.win_w >> 1, env->ar.win_h >> 1);
// SDL_ShowCursor(SDL_DISABLE);
// SDL_ShowCursor(SDL_ENABLE);
