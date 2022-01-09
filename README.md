Raspi用EV3 シミュレータ

使い方
このraspi用aspシミュレータはMac OS X用のシミュレータをraspi用に修正したものです。
https://www.toppers.jp/asp3-e-download.html
athrillのバージョンに合わせるため、3.2.0を使用しています。
また、linux用の変更やsetjmp/longjmpのmangleに関しては
https://qiita.com/morioka/items/a186fff4db1eabb7e7de
を参考にしています。

mac os x用のシミュレータはsetjmp/longjmpの仕組みを使ってコンテキストスイッチを行なっていますが、通常のsetjmp/longjmpで設定されるPC/SPはmangleされており、オリジナルのシミュレータのようにjmp_bufにポインタを簡単に設定することはできません。そのため、mangleを行わないsetjmp/longjmpを組み合わせることで実行できるようにしています。

mangleしないバージョンのsetjmp/longjmpは
https://github.com/ytoi/raspi_simple_setjmp.git
を使うことで対応します。
これをmakeしてできたlibssetjmp.soをLD_PRELOAD環境変数を使うことで、libcよりも早く読み込ませて置き換えをおこないます。

makeのやり方
```
cd sdk/workspace
make img=(アプリケーション名)
```

実行の仕方
```
env LD_PRELOAD=../../raspi_simple_setjmp/libssetjmp.so ./asp
```
で実行できます。

gdbを使う場合は
```
gdb asp
gdb) set environment LD_PRELOAD=../../../raspi_simple_setjmp/libssetjmp.so
gdb) handle SIGUSR2 noprint nostop pass
gdb) r
```
で実行できます。シミュレータではSIGUSR2をプライオリティ変更のとりがとして利用しているので、SIGUSR2をgdbがトラップせずにaspアプリ側に渡す必要があります。
libssetjmp.soの置いている場所に合わせて変更してください。

.gdbinitに書いておく方法もあります。
.gdbinit
```
set environment LD_PRELOAD=../../../raspi_simple_setjmp/libssetjmp.so
handle SIGUSR2 noprint nostop pass
```

ただし、これを行う場合には~/.gdbinitの方にも以下の記述が必要です。
```
add-auto-load-safe-path /home/pi/etrobo/asp/sdk/workspace/.gdbinit
```

workspaceがある実際の場所に変更してください。




