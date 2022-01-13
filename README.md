Raspi用EV3 シミュレータ

初めに
このraspi用aspシミュレータはMac OS X用のシミュレータをraspi用に修正したものです。
https://www.toppers.jp/asp3-e-download.html
athrillのバージョンに合わせるため、3.2.0を使用しています。
また、linux用の変更やsetjmp/longjmpのmangleに関しては
https://qiita.com/morioka/items/a186fff4db1eabb7e7de
を参考にしています。
2022/1/14リリースバージョンでは、ETロボコンシミュレータと接続して動作するようになっています。
本SWはmaosxシミュレータの成果物および、athrillの成果物を多く使用しています。

1. OSのインストール

対応しているRasPiのOSはRasBerry Pi OS(Bullseye)の32bit版になります。
https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-32-bit
からwith Desktopバージョンを持ってきて、カードに焼いて立ち上げてください。

その後、必要なソフトとしてrubyなどがありますので、
```
sudo apt install ruby
sudo gem install shell
```

でインストールをしておいてください。

2. setjmp/longjmp特殊版のmake

mac os x用のシミュレータはsetjmp/longjmpの仕組みを使ってコンテキストスイッチを行なっていますが、通常のsetjmp/longjmpで設定されるPC/SPはmangleされており、オリジナルのシミュレータのようにjmp_bufにポインタを簡単に設定することはできません。そのため、mangleを行わないsetjmp/longjmpを組み合わせることで実行できるようにしています。

mangleしないバージョンのsetjmp/longjmpは
https://github.com/ytoi/raspi_simple_setjmp.git

```
mkdir work
cd work
git clone https://github.com/ytoi/raspi_simple_setjmp.git
cd raspi_simple_setjmp
make
```
でlibssetjmp.soができます。
これをLD_PRELOAD環境変数を使うことで、libcよりも早く読み込ませて置き換えをおこないます。

3. ev3rt simのコンパイル 


```
(workに移動)
git clone https://github.com/ytoi/ev3rt_aspsim_raspi_linux.git ev3rtsim
cd ev3rtsim/sdk/workspace
make img=(
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


注意点


2022/1/14現在、app.cに__dso_handle=0の定義があると、多重定義になってしまうので、アプリでは定義せず、コメントアウトしてください。
Bluetooth/EV3のファイルシステム関数は未サポートとなっています。


