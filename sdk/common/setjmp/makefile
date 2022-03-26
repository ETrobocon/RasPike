default:all

setjmp.o:setjmp.S
	gcc -c $< -o $@

sigjmp.o:sigjmp.c
	gcc -c $< -o $@


all:libssetjmp.so libssetjmp.a

libssetjmp.so:setjmp.o sigjmp.o
	gcc -shared -fPIC -o $@ $^

libssetjmp.a:setjmp.o sigjmp.o
	ar rcs libssetjmp.a setjmp.o sigjmp.o

clean:
	rm -f *~ *.o *.so *.a
