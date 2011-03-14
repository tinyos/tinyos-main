/****************************************************************
  KPIT Cummins Infosystems Ltd, Pune, India. 1-April-2006.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 *****************************************************************/

/*
   Written By:
   Shrirang Khishti <shrirangk@kpitcummins.com>.

   This is a smaller version of printf
   Positive points about this function
   1. Reduces code size considerably ,very useful in embedded applications
   2. No malloc calls are used
   3. Supports almost all the functionalities of GNU std printf routine.
   4. If user dont want float_support in this customized printf
   just undef macro float_support
 */

#ifndef  __M16C60_PRINTF_H__
#define __M16C60_PRINTF_H__
#include <stdarg.h>
#include <string.h>

#define printf _printf

int left_val,right_val;

#define condition *format!='f'&&*format!='d'&&*format!='c'&&*format!='s'&&*format!='l'&&*format!='u'&&*format!='\0'&&*format!=' '&&*format!='i'&&*format!='x'&&*format!='X'&&*format!='o'&&*format!='%'&&*format!='p'

#define float_support

long temp_arr[]={100000,10,100,1000,10000,100000,1000000,10000000,100000000,1000000000};


/**
 * @fn
 * @brief 
 *
 * @param c
 */
int
_putchar(int c)
{     
  /* Convert CR to CR/LF */
  if (c == '\n')
    lowlevel_putc('\r');
  lowlevel_putc(c);

  return c;
}


/**
 * @fn void _puts(const char *tempStr)
 * @brief Prints a NULL-erminated string on UART 1
 *
 * @param s The string to output
 *
 */
int
_puts(const char *s)
{
  while( *s != '\0' )
    _putchar(*s++);

  return 0;
}


/**
 * @fn void strrev(char *str)
 * @brief Reverses a string
 *
 * @param str The string to reverse
 */
void
strrev(char *str)
{
  char *temp, c;
  int len=strlen(str) ;
  temp = str + len -1;

  while(str < temp ) {

    c = *str;
    *str = *temp;

    *temp = c;
    str++;
    temp--;
  }
}


static void print_hex_oct( long int temp_var,int _div,int corr_factor,int ret_val,int sign,int *cntr_val)
{
  unsigned long int i=1,i1,temp=temp_var;
  int cntr=0,neg_flag=0;
  char s1[40];

  if(sign==1&&temp_var<0)
  {
    temp=-temp_var;
    neg_flag=1;
  }
  if(temp==0)
    s1[cntr++]='0';
  while(temp>0)
  {
    i1=temp%_div;
    temp=temp/_div;
    if(i1<=9)
      s1[cntr]=i1+'0';
    else
      s1[cntr]=i1+corr_factor-9;
    cntr++;
  }

  while((left_val-(right_val>cntr?right_val:cntr+neg_flag))>0)
  {
    _putchar(' ');
    left_val--;
		(*cntr_val)++;
	}

	while(right_val-cntr>0)
	{
		s1[cntr++]='0';
	}

	if(neg_flag==1)
	s1[cntr++]='-';

	s1[cntr]='\0';
	strrev(s1);
	_puts(s1);
	(*cntr_val)+=strlen(s1);
}


#ifdef float_support
static void float_print(long double f1,long double f2,int multi,int *cntr_val)
{
	int i=1,temp,cntr=0,i1,neg_flag=0;
	char s1[10];

	 if(f1<0)
	 {
		 f1=f1*-1;
		 neg_flag=1;
		 f2=f1;
	 }
	 temp=(int)f1;

	 f1=f1-temp;
     f1=f1*multi;

     temp=f1;

     if(temp==0)
    	s1[cntr++]='0';
     while(temp>0)
     {
         i1=temp%10;
         temp=temp/10;
         s1[cntr]=i1+0x30;
         cntr++;
     }

     while(right_val<9&&(right_val -cntr)>0)
	   s1[cntr++]='0';
	   s1[cntr]='.';
	   cntr++;

	   temp=(int)f2;
	 if(temp==0)
		s1[cntr++]='0';
	 while(temp>0)
	 {
	      i1=temp%10;
	      temp=temp/10;
	      s1[cntr]=i1+0x30;
	      cntr++;
	 }

	 while(left_val-- -cntr>0)
		{
			_putchar(' ');
			(*cntr_val)++;
		}
			if(neg_flag==1)
	    s1[cntr++]='-';
	    s1[cntr]='\0';
	    cntr--;
	 	strrev(s1);
    	_puts(s1);
		(*cntr_val)+=strlen(s1);
   		neg_flag=0;
}

#endif // float_support

static int format_val(char *temp,long float_flag,int *cntr_val,int flag)
{
left_val=0;
right_val=0;
	if(*temp=='\0'&&flag==1)
	{
		right_val=3;
		return 0;
	}
	while(*temp!='.'&&*temp!='\0')
	{
		if(*temp<'0'||*temp>'9')
		{
			while(*temp)
			{
				_putchar(*temp++);
				(*cntr_val)++;
			}
			return -1;
		}
		else
		left_val=left_val*10+*temp-'0';
    	 temp++;
	}
    if(*temp)
		temp++;
		else
		return left_val;
	while(*temp)
	{
	if(*temp<'0'||*temp>'9')
	{
	while(*temp)
		{
			_putchar(*temp++);
			(*cntr_val)++;
		}
	return -1;
	}
	else
	right_val=right_val*10+*temp-'0';
     temp++;
	}

return 0;
}


/**
 * @fn int _printf(const char *format, ...)
 * @brief Prints a formatted string on UART1
 *
 * @param format The string
 */
int _printf(const char *format, ...)
{
   int format_cntr=0;
   char temp_str[20];
   int return_flag=0,cntr_val;
   long double f1,f2;
   char *str_temp;
   int *cntr=&cntr_val;

   va_list ap;
   va_start(ap, format);
   *cntr=0;
   while(*format) {
     temp_str[format_cntr]='\0';
     if(*format=='%')
     {
       *format++;
       while(*format==' ')
       {
	 format++;
	 _putchar(' ');
       }
       while(condition)

       {
	 temp_str[format_cntr++]=*format++;
       }
       temp_str[format_cntr]='\0';
       if(*format=='%')
       {
	 _putchar('%');
	 (*cntr)++;
	 format_cntr=0;
	 format++;
	 continue;
       }

       /************** print unsigned ****************/
       else if(*format=='u')
       {
	 return_flag=format_val(temp_str,0,cntr,0);
	 if(return_flag!=-1)

	   print_hex_oct(va_arg(ap,unsigned int),10,0,return_flag,0,cntr);

	 else
	 {
	   _putchar(*format);
	   (*cntr)++;
	 }
	 format++;
	 format_cntr=0;
	 continue;
       }
       /*********** Print Integer Values **************/
       else if(*format=='d'||*format=='i')
       {
	 return_flag=format_val(temp_str,0,cntr,0);

	 if(return_flag!=-1)

	   print_hex_oct(va_arg(ap,int),10,0,return_flag,1,cntr);

	 else
	 {
	   _putchar(*format);
	   (*cntr)++;
	 }
	 format++;
	 format_cntr=0;
	 continue;

       }

       /*********** Print hex,Octal values ******************/
       else if(*format=='x'||*format=='X'||*format=='o'||*format=='p')
       {
	 return_flag=format_val(temp_str,0,cntr,0);
	 if(return_flag!=-1) {

	   if(*format=='x'||*format=='p')
	     print_hex_oct(va_arg(ap,unsigned int),16,0x60,return_flag,0,cntr);
	   else if(*format=='X')
	     print_hex_oct(va_arg(ap,unsigned int),16,0x40,return_flag,0,cntr);
	   else
	     print_hex_oct(va_arg(ap,unsigned int),8,0,return_flag,0,cntr);
	 }
	 else
	 {
	   _putchar(*format);
	   (*cntr)++;
	 }
	 format++;
	 format_cntr=0;
	 continue;
       }

       /************ Character printing ****************88*/
       else if(*format=='c')
       {
	 return_flag=format_val(temp_str,0,cntr,0);
	 if(return_flag!=-1)
	 {
	   while(return_flag-->1)
	   {
	     _putchar(' ');
	     (*cntr)++;
	   }
	   _putchar(va_arg(ap,int));
	   (*cntr)+=2;
	 }
	 else
	 {
	   _putchar(*format);
	   (*cntr)++;
	 }
	 format++;
	 format_cntr=0;
	 continue;
       }

       /*************** Print String *****************/
       else if(*format=='s')
       {
	 return_flag=format_val(temp_str,0,cntr,0);
	 if(return_flag!=-1)
	 {
	   str_temp=va_arg(ap,char*);

	   while((return_flag--  -(int) strlen(str_temp))>0)
	   {
	     _putchar(' ');
	     (*cntr)++;

	   }
	   _puts(str_temp);
	   (*cntr)+=strlen(str_temp);
	 }
	 else
	 {
	   _putchar(*format);
	   (*cntr)++;
	 }
	 format++;
	 format_cntr=0;
	 continue;

       }
       /*************** Print floating point number *****************/
       else if(*format=='f'||(*format=='l'&&*(format+1)=='f'))
       {

	 return_flag=format_val(temp_str,1,cntr,1);
	 if(return_flag!=-1)
	 {
	   if(*format=='l')
	   {
	     f1=va_arg(ap,long double);
	     format+=2;
	   }
	   else
	   {
	     f1=va_arg(ap,double);
	     format++;
	   }
	   f2=f1;
#ifdef float_support
	   right_val++;
	   float_print(f1,f2,temp_arr[right_val%10],cntr);
#endif
	 }
	 else
	 {
	   _putchar(*format++);
	   (*cntr)++;
	 }
	 format_cntr=0;
	 continue;
       }
       else if(*format=='l'&&((*(format+1)=='d')||(*(format+1)=='u')))
       {
	 return_flag=format_val(temp_str,0,cntr,0);

	 if((return_flag=-1)&&(*(format+1)=='d'))
	 {
	   print_hex_oct(va_arg(ap,long int),10,0x00,return_flag,1,cntr);
	 }

	 else if((return_flag=-1)&&(*(format+1)=='u'))
	 {
	   print_hex_oct(va_arg(ap,unsigned long int),10,0x00,return_flag,0,cntr);
	 }

	 else
	 {
	   _putchar(*format);
	   _putchar(*(format+1));
	   (*cntr)+=2;
	 }
	 format+=2;
	 format_cntr=0;
	 continue;
       }
       else
       {
	 _puts(temp_str);
	 format_cntr=0;
	 continue;
       }
     }
     _putchar(*format++);

     (*cntr)++;
   }
   va_end(ap);
   return cntr_val;
}


#endif // __M16C60_PRINTF_H__

