#include <stdio.h>
#include <stdlib.h>

int c;
int d=0;
int count=0;
int was_found=0;
int temp_found=0;
int ansi_found=0;

int treatfile(int c,FILE *out)
{
if (c==254)
	{
	was_found=1;
	return 0;
	}
else
	if (was_found==1)
		{
		c=c-100;
		while (c!=0)
		{
		putc('*',out);
		count++;
		c--;
		}
		count=0;
		was_found=0;
		return 0;
		}
	else
		{
		putc(c,out);
		return 0;
		}
}

int transfile(int c, FILE *out)
{
if (ansi_found==1)
	{
	ansi_found=0;
	goto continue_lab;
	}

if (temp_found==1)
	{
	temp_found=0;
	goto continue_lab;
	}

if (d==1)
	{
	if (c==253)
		{
		c=253;
		ansi_found=1;
		goto continue_lab;
		}
	if (c==254)
		{
		c=254;
		temp_found=1;
		goto continue_lab;
		}
	if (c==39)
		{
		d=0;
		goto continue_lab;
		}

	if (c==255)
		{
		c=255;
		goto continue_lab;
		}
	if (c>30)
		c=c-10;

	}

if (d==0)
	{
	if (c==39)
		{
		d=1;
	}
	}

continue_lab:
putc(c, out);
return 0;
}

void main(int argc, char *argv[])
{
if (argc<2)
	{
	printf("\nError in parameters...\n");
	exit (1);
	}
char *file_to_open;
char *file_to_write;
	file_to_open=argv[1];
	file_to_write=argv[2];
FILE *in;
FILE *out;

in = fopen(file_to_open, "rb");
out= fopen("AUTOCONF.TMP", "wb");
printf("\tTranslating %s into %s.\n",file_to_open,file_to_write);
while((c=getc(in))!=EOF)
	{
	treatfile(c, out);
	}
fclose (in);
fclose (out);

in = fopen("AUTOCONF.TMP", "rb");
out= fopen(file_to_write, "wb");

printf("\tTreating spaces...\n");

while((c=getc(in))!=EOF)
	{
	transfile(c, out);
	}

fclose (in);
fclose (out);
exit;
}

