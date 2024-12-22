/*
  Copyright (C) 2012-2022 Free Software Foundation, Inc.
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
   License along with the GNU C Library; if not, see
   <https://www.gnu.org/licenses/>.  */


#ifndef __MINIMUMHEADER_H_
#define __MINIMUMHEADER_H_

// from sysdeps/generic/sysdep.h
//# define cfi_def_cfa(reg, off)		.cfi_def_cfa reg, off
# define cfi_def_cfa(reg, off)	       
# define cfi_offset(reg, off)		.cfi_offset reg, off
# define cfi_same_value(reg)		.cfi_same_value reg
# define cfi_startproc			.cfi_startproc
# define cfi_endproc			.cfi_endproc
/* Define a macro we can use to construct the asm name for a C symbol.  */
# define C_LABEL(name)	name##:


//from include/libc-symbols.h
#ifndef C_SYMBOL_NAME
# define C_SYMBOL_NAME(name) name
#endif
#ifndef ASM_LINE_SEP
# define ASM_LINE_SEP ;
#endif


# define strong_alias(original, alias) \
  .globl C_SYMBOL_NAME (alias) ASM_LINE_SEP \
  .set C_SYMBOL_NAME (alias),C_SYMBOL_NAME (original)

//# define hidden_def(name) strong_alias (name, __GI_##name)
# define hidden_def(name) strong_alias (name, _##name)
# define libc_hidden_def(name) hidden_def(name)

//from include/stap-probe.h
#  define LIBC_PROBE(name, n, ...)		/* Nothing.  */


// from sysdeps/aarch64/sysdep.h
/* Define an entry point visible from C.  */
#define ASM_SIZE_DIRECTIVE(name) .size name,.-name

#define ENTRY(name)						\
  .globl C_SYMBOL_NAME(name);					\
  .type C_SYMBOL_NAME(name),%function;				\
  .p2align 6;							\
  C_LABEL(name)							\
  cfi_startproc;						\
  BTI_C;							\

//CALL_MCOUNT

#define END(name)						\
  cfi_endproc;							\
  ASM_SIZE_DIRECTIVE(name)

# define PTR_ARG(n)	

#if 0
# define BTI_C		hint	34
# define BTI_J		hint	36
#else
# define BTI_C		nop
# define BTI_J		nop
#endif


// Fixed Macro
#define IS_IN(sym) 0
# define CALL_MCOUNT		/* Do nothing.  */


// from sysdeps/aarch64/setjmp/jmpbuf-offsets.h

#define JB_X19            0
#define JB_X20            1
#define JB_X21            2
#define JB_X22            3
#define JB_X23            4
#define JB_X24            5
#define JB_X25            6
#define JB_X26            7
#define JB_X27            8
#define JB_X28            9
#define JB_X29           10
#define JB_LR            11
#define JB_SP		 13

#define JB_D8		 14
#define JB_D9		 15
#define JB_D10		 16
#define JB_D11		 17
#define JB_D12		 18
#define JB_D13		 19
#define JB_D14		 20
#define JB_D15		 21

#endif
