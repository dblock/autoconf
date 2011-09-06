#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void main(void)
{
  FILE *stream;
  int i;
  char *name;

    if ((name = tempnam("c:\\temp","acn")) == NULL)
      perror("tempnam couldn't create name");

  char str[255];
  strcpy(str,"COPY AUTOCONF.ASM ");
  strcat(str,name);
  printf("%s\n",str);
  system(str);
}
