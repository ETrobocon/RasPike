/* setjmp/longjmp for raspi(ARM).
   Copyright (C) 1997-2020 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library.  If not, see
   <https://www.gnu.org/licenses/>.  */


	
#define ENTRY(name) \
	.globl name; \
	.type name,%function; \
	.align 4; name: \
	.cfi_sections \
	.debug_frame; \
	.cfi_startproc;

#define END(name) \
	.cfi_endproc;\
	.size name,.-name

#define JMP_BUF_REGLIST {v1-v6, sl, fp}
	
ENTRY(_setjmp)	
	mov ip,r0
	str sp,[ip],#4
	str lr,[ip],#4
	stmia ip!, JMP_BUF_REGLIST
	stc p11, cr8, [ip], #64
	B __sigjmp_save
END(_setjmp)

ENTRY(longjmp)
	mov ip,r0
	ldr sp,[ip],#4
	ldr lr,[ip],#4
	ldmia   ip!, JMP_BUF_REGLIST
	/* Restore the VFP registers.  */
	/* Following instruction is vldmia ip!, {d8-d15}.  */
	ldc	p11, cr8, [r12], #64
	movs r0,r1
	moveq r0,#1
	bx lr
END(longjmp)
