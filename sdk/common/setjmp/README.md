# raspi_simple_setjmp
Provide not mangling setjmp/longjmp for RasPi OS 32bit. 

glibcのsetjmp/longjmpはセキュリティのためポインタがmangling(難読化)されており、簡単に置き換えることはできません。
このままだとCでコンテキストを切り替える仕組みとしてsetjmp/longjmpを使用しようとしてもできないため、mangligしないsetjmp/longjmpを提供します。
これは32bitのFPUを使わないモードに特化して作成しているため、それ以外の環境では動かないでしょう。

使い方
1. cloneしてmakeする
2. 作成されたlibssetjmp.soをアプリケーションに使わせるため、LD_PRELOADで先行してライブラリをリンクさせます
	env LD_PRELOAD=libssetjmp.so a.out

注意事項
このソースコードはglibc-2.31のコードをベースに、不要なところを除いたものです。そのため、ライセンスがLGPLとなっています
