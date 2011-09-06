#include <stdio.h>
#include <stdlib.h>

int c;
int d=0;
int count=1;
int was_found=0;
int c_found=0;
int c2=0;
int a;
int toggle=0;

int treatfile(int c, FILE *out)
{
if (toggle==1)
	{
	if (c==39) toggle=0;
	if (c==c2)
		{
		count++;
		return 0;
		}
	else
	{
	if (count<=4)
		{
		for (a=count;a>=1;a--) putc(c2, out); count=1;
		}
	else
		{
		putc(254,out);
		count+=100;
		putc(c2,out);
		putc(count,out);
		}
	}
	c2=c;
	count=1;
	return 0;
	}

if (toggle==0)
	{
	if (c==39)
	{
	toggle=1;
	putc(c2,out);
	}
	else
	putc(c2,out);
	c2=c;
	return 0;
	}

return 0;
}

int transfile(int c, FILE *out)
{
if (c_found==1) {
		if (c==253)
		{
		c_found=0; c=253; goto continue_lab;
		}
		else
		{
		c_found=0; goto continue_lab;
		}
		}
if (d==1){if (c==253){c=253;c_found=1;goto continue_lab;}
if (c==39){d=0;goto continue_lab;}
if (c==255){c=255;goto continue_lab;}
if (c==252){c=252;goto continue_lab;}
if (c>=32)
	{
	asm{
	mov al,byte ptr c
	add al,0
	xor al,11101000b
	mov byte ptr c,al
	}
	goto continue_lab;
	}

}
if (d==0){if (c==39){d=1;}}
continue_lab:
putc(c, out);
return 0;
}

void main (int argc,char **argv)
{
printf("\nCODE another version... AUTOCONF text compression utility.");
printf("\nDoubrovkine Daniel - All Rights Reserved - 1993.");
printf("\nWARNING! Please DO delete this undistributable software to avoid any DAMAGE!");
printf("\nTHIS IS AN INTERNAL DEVELOPMENT AID DESIGNED FOR INTERNAL USAGE ONLY!");
printf("\nfile: %s\n",argv[1]);
char *file_to_open;
file_to_open=argv[1];
FILE *in;
FILE *out;
count=0;
in = fopen(file_to_open, "rb");
out= fopen("AUTOCONF.TM2", "wb");
printf("\tCoding file...");
while((c=getc(in))!=EOF)
	{transfile(c, out);}
fclose (in);
fclose (out);
printf("\tDone.");
in = fopen("AUTOCONF.TM2", "rb");
if (argc!=2) out=fopen("AUTOCON2.INC","wb");
else out= fopen("AUTOCONF.INC", "wb");
count=1;
printf("\n\tCompacting repeats...");

c2=getc(in);
while((c=getc(in))!=EOF)
        {treatfile(c, out);}
fclose (in);
fclose (out);
printf("\tDone.\n");

exit;
}
