# Raspi用 SPIKE制御開発環境「RasPike（ラスパイク）」



## はじめに

この環境はETロボコン用にraspberryPiとLEGO(R)のSPIKE Prime(R)を接続して動作させるためのものです。raspberry側のEV3RT互換環境と、SPIKE側の制御ソフトからなり、これらを総称して「RasPike」と呼びます。

EV3RTのベースとなるraspberry-Pi用aspシミュレータはMac OS X用のシミュレータをraspi用に修正したものとなっています。
https://www.toppers.jp/asp3-e-download.html

athrillのバージョンに合わせるため、3.2.0を使用しています。

また、linux用の変更やsetjmp/longjmpのmangleに関しては
https://qiita.com/morioka/items/a186fff4db1eabb7e7de
を参考にしています。

本SWはmaosxシミュレータの成果物および、athrillの成果物を多く使用しています。

## Raspberry側の環境構築

### 0. HWの準備

Raspberry-PiとSPIKEの接続にはアフレルから販売されているSPIKE ETロボコンキットのSPIKE用ケーブルを使用します。
https://afrel.co.jp/product/et-set

接続の方法などはETロボコンの組み立て図を参照ください。SPIKEケーブルはSPIKEのDポートを利用します。また、Raspberry側でGPIOを使うための設定が必要になります。

### 1. OSのインストール

対応しているRasPiのOSはRasBerry Pi OS(Bullseye)の32bit版になります。
https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-32-bit
からwith Desktopバージョンを持ってきて、カードに焼いて立ち上げてください。

その後、必要なソフトとしてrubyなどがありますので、
```
sudo apt install ruby
sudo gem install shell
```

でインストールをしておいてください。

### 2. setjmp/longjmp特殊版のmake

mac os x用のシミュレータはsetjmp/longjmpの仕組みを使ってコンテキストスイッチを行なっていますが、通常のsetjmp/longjmpで設定されるPC/SPはmangleされており、オリジナルのシミュレータのようにjmp_bufにポインタを簡単に設定することはできません。そのため、mangleを行わないsetjmp/longjmpを組み合わせることで実行できるようにしています。

mangleしないバージョンのsetjmp/longjmpは以下にあります。

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

### 3. ev3rt simのコンパイル 


```
(workに移動)
git clone https://github.com/ytoi/ev3rt_aspsim_raspi_linux.git ev3rtsim
cd ev3rtsim/sdk/workspace
make img=(アプリ名)
```

## SPIKE側の環境構築

### 0. SPIKEのつなぎ方

以下で接続してください。
```
アームモータ : A
右モータ : B
左モータ : E
カラーセンサー  : C
超音波センサー : F
serial通信:D
```

上記接続に対し、EV3RTからは以下のようにマップされます。アプリ側はこれに合わせてコードを書いてください。

```
EV3RTでの見え方
ポートA:アームモータ
ポートB:右モータ
ポートC:左モータ
ポート1:タッチセンサ（実際はSPIKEの左ボタンが対応します)
ポート2:カラーセンサー
ポート3:超音波センサー
ポート4:ジャイロセンサ（これはまだ開発中)
```

### 1. SPIKEプログラムのインストール

SPIKEのプログラムはspikeディレクトリ以下にあります。
raspike_etrobo.py - ETロボコン用に最適化した制御プログラムです。
raspike_main.py - 汎用的なSPIKE制御用プログラムです

ETロボコン用にはraspike_etrobo.pyを利用してください。

SPIKEへの転送には以下の２つの方法があります。

(1) PCから直接SPIKEに入れる

(1-1) Visual Studio CodeのSPIKE用拡張を使うやり方

https://marketplace.visualstudio.com/items?itemName=PeterStaev.lego-spikeprime-mindstorms-vscode

raspike_etrobo.pyの先頭行に

``# LEGO type:standard slot:2 autostart``

とあるのは、この拡張機能のリロードボタンを押した時にSlot２に自動的にアップされ、実行されるための記述です。slot番号は2としていますが、自由に変えてください。

(1-2) PCのMu-Editorを使っていれる入れ方
　PCにMu-Editorを入れます。この場合、SPIKEに指しているUSBをPC側に挿してください。
 ファイル転送を選択して、raspike_etrobo.pyを右クリックして、「write as main.py」でSPIKEのmain.pyとして書き込みます。こうすることで、SPIKEは立ち上げるとRasPike用にRasPiからの信号待ちになります（一応ディスプレイに「ET」と表示しているので、きちんと動いているかはわかります）
 このやり方が一番パフォーマンス良いかと思います。RasPiのプログラムを動かす前にはSPIKEの再起動もするようにしましょう（メモリが使われて、GCが働くとパフォーマンスが悪くなるため）。

(2) Raspberry-PiからMu-Editorを使って入れる

アフレルさんの教材にあるのがこの方式ですが、作者はやったことがないので後で試したら記載します。

(3) PCから教材用SPIKEアプリを使って入れる

これはお勧めしません。SPIKEアプリはかなりパフォーマンスが悪いので、簡単な動作確認には良いですが、ETロボコンでは使わない方が良いでしょう。
（ただし、プログラムを入れるだけなら大丈夫かもしれません）

一度インストールしたら、そのあとはSPIKE側のUIからプログラムを選択して実行すれば良いです。再度のインストールは不要です。


## 実行方法

注意として、SPIKEの電源を入れたまま何度もSPIKEのプログラムを実行しているとSPIKE側のpythonがどんどん重くなり、性能が悪くなることです。走行させるたびにSPIKEの電源を切るようにしてください。性能が10倍くらい違います。

(1) SPIKEのプログラムを先に実行させます

(2) Raspberry-Piのシェルからプログラムを実行します

`` make start``



## ETロボコンシミュレータ実行の仕方

Raspberry-Pi上のプログラムでETロボコンシミュレータを動作させることができます。
ETロボコンシミュレータと繋ぐには、raspi側の設定と、ETロボコン側の設定が必要です。
raspi側はsdk/common/device_config_athrill.txtに相手側のIPアドレスを書く必要があります(TX)。

sdk/common/device_config.txtの以下を環境に合わせて変更してください

```
DEBUG_FUNC_VDEV_TX_IPADDR	192.168.11.4   --> PC側のIPアドレス
DEBUG_FUNC_VDEV_RX_IPADDR	192.168.11.12  --> RaspiのIPアドレス
```


また、ETロボコンシミュレータ側は「設定」からraspi側のIPアドレスを指定します（設定後は「リセット」ボタンを押して、ロボットが初期状態になるようにしてください）


```
make startsim
```

で実行できます。

gdbを使う場合は
```
gdb asp
gdb) set environment LD_PRELOAD=../../../raspi_simple_setjmp/libssetjmp.so
gdb) handle SIGUSR2 noprint nostop pass
gdb) r -d ../common/device_config.txt
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


