#include <stdio.h>
#include <string.h>
#include <dos.h>
#include <stdlib.h>
 #include <time.h>

void main(void)
{
   printf("\nAUTOCONF internal date and time compile, another version.");
   printf("\nDoubrovkine Daniel - All Rights Reserved - 1995");
   printf("\nWARNING! Please DO delete this undistributable software to avoid any DAMAGE!");
   printf("\nTHIS IS AN INTERNAL DEVELOPMENT AID DESIGNED FOR INTERNAL USAGE ONLY!\n");

   FILE *in, *out;
   if ((in = fopen("AUTOCONF.ASM", "rb"))==NULL)
     {fprintf(stderr, "Cannot open input file.\n"); return;}

   if ((out = fopen("AUTOCONF.GOD", "wb+"))==NULL)
     {fprintf(stderr, "Cannot open output file.\n");return;}

   while (!feof(in))
	{
	fputc(fgetc(in), out);
	}

   fclose(in);
   fclose(out);

   if ((in = fopen("AUTOCONF.GOD", "rb"))==NULL)
     {fprintf(stderr, "Cannot open input file.\n"); return;}

   if ((out = fopen("AUTOCONF.ASM", "wb+"))==NULL)
     {fprintf(stderr, "Cannot open output file.\n");return;}

   char string[255];
   int ch=0;
   int n;
   int line=0;

   while (!feof(in))
   {
      line++;
      for(n=0,ch=0;ch!=10;n++)
	{
	ch=fgetc(in);
	if (feof(in)) break;
	string[n]=ch;
	}
	if (strstr(string,"compiled_date           db")!=NULL)
		{
		struct date d;
		getdate(&d);
		int dec, sign;


		strcpy(string,"compiled_date           db      '");
		strcat(string,"assembl.: ");
		int ndig = 2;
		if (d.da_day<10) {ndig=1;strcat(string,"0");}
		int value = d.da_day;
		strcat(string,ecvt(value, ndig, &dec, &sign));
		strcat(string,"/");

		ndig = 2;
		if (d.da_mon<10) {ndig=1;strcat(string,"0");}
		value = d.da_mon;
		strcat(string,ecvt(value, ndig, &dec, &sign));
		strcat(string,"/");

		ndig = 4;
		if (d.da_year<10) {ndig=1;strcat(string,"0");}
		value = d.da_year;
		char *year_string=ecvt(value, ndig, &dec, &sign);
		year_string[0]=year_string[2];
		year_string[1]=year_string[3];
		year_string[2]='\0';

		strcat(string,year_string);

		struct dostime_t t;
		_dos_gettime(&t);

		strcat(string," (");
		ndig = 2;
		if (t.hour<10) {ndig=1;strcat(string,"0");}
		value = t.hour;
		strcat(string,ecvt(value, ndig, &dec, &sign));
		strcat(string,":");
		ndig = 2;
		if (t.minute<10) {ndig=1;strcat(string,"0");}
		value = t.minute;
		strcat(string,ecvt(value, ndig, &dec, &sign));
		strcat(string,")'");

		strcat(string,"\n");
		n=strlen(string);
		}
	fwrite(string, n, 1, out); /* write struct s to file */
   if (line==300){printf(".");line=0;}
   }
   printf("\n");
   fclose(in);
   fclose(out);

   return;
}

