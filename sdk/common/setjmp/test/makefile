default:exec

exec:test
	env LD_PRELOAD=../$(ARC)/libssetjmp.so ./test

exec_static:test_static
	./test_static

test:test.c
	gcc -o $@ -g $^ 

test_static:test.c ../libssetjmp.a
	gcc -o $@ -g $^

clean:
	rm -f *.o *~ test test_static

