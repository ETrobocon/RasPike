default:all

IFLAGS=-I./src
VPATH=src

setjmp.o:setjmp.S
	gcc -g $(IFLAGS) -c $< -o $@

longjmp.o:__longjmp.S
	gcc -g $(IFLAGS) -c $< -o $@

sigjmp.o:sigjmp.c
	gcc -g $(IFLAGS) -c $< -o $@



all:libssetjmp.so libssetjmp.a

libssetjmp.so:setjmp.o sigjmp.o longjmp.o
	gcc -g -shared -fPIC -o $@ $^

libssetjmp.a:setjmp.o sigjmp.o longjmp.o
	ar rcs libssetjmp.a setjmp.o sigjmp.o

clean:
	rm -f *~ *.o *.so *.a
