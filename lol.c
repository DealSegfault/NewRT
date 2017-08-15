 include <stdio.h>
s# include <string.h>

int		main(int argc, char **argv)
{
	char	**grille;

	grille = &argv[1];
	for (int i = 0; i < 9; i++)
	{
		if (strlen(grille[i]) != 9)
		{
			printf("Invalid map\n");
			return (0);
		}
	}
	printf("Valid map\n");
}
