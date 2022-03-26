/*
this sample is from:
https://www.ibm.com/docs/ja/zos/2.2.0?topic=functions-setjmp-preserve-stack-environment
*/

/* This example shows the effect of having set the stack environment.  */
#include <stdio.h>
#include <stdlib.h>
#include <setjmp.h>

jmp_buf mark;

void p(void);
void recover(void);

int main(void)
{
   if (setjmp(mark) != 0) {
      printf("longjmp has been called\n");
      recover();
      exit(0);
      }
   printf("setjmp has been called\n");

   p();

   return 0; /* never reached */
}

void p(void)
{
   int error = 0;

   error = 9;

   if (error != 0)
      longjmp(mark, -1);

}

void recover(void)
{

}
