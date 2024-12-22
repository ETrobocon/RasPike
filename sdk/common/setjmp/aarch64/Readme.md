libsetjmp.so.aarch64の作り方

glibcをコンパイルする。やり方はhttps://tech-blog.s-yoshiki.com/entry/301を参照しています。

任意のディレクトリで以下を実行
apt install -y gawk bison 
wget https://ftp.gnu.org/gnu/glibc/glibc-2.36.tar.gz
tar -xf glibc-2.36.tar.gz
cd glibc-2.36

展開したら、ここのディレクトリのsrcに入っているいかの２つのファイルをコピーする
cp (RasPikeディレクトリ)/sdk/common/setjmp/aarch64/src/*.S sysdeps/aarch64/

あとは通常通りにglibcをコンパイルする。

mkdir -p ./glibc-build
cd ./glibc-build
../glibc-2.36/configure --prefix=$PWD/local
make

これでmakeが終わったら
cd setjmp
gcc -shared -fPIC -o libsetjmp.so.aarch64 setjmp.o __longjmp.o sigjmp.o  ../signal/sigprocmask.o ../nptl/pthread_sigmask.o ../csu/errno.o -lc



objcopy     --redefine-sym __sigprocmask=sigprocmask sigjmp.o sigjmp.o.mod
gcc -shared -fPIC -o libsetjmp.so.aarch64 setjmp.os __longjmp.os sigjmp.os
gcc -shared -fPIC -o libsetjmp.so.aarch64 setjmp.o __longjmp.o sigjmp.o  ../signal/sigprocmask.o ../nptl/pthread_sigmask.o -lc


これでできたlibsetjmp.so.aarch64
を使う


