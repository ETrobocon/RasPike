# Raspi用 SPIKE制御開発環境「RasPike（ラスパイク）」

2024/6/30 RasPike-ARTバージョンを公開しました。
RasPike-ARTバージョンの説明以下を参照ください。

https://github.com/ETrobocon/RasPike/wiki/RasPike%E2%80%90ARTモード
RasPike-ARTモードを使う場合、RasPikeのドキュメントのほとんどが無効になりますので、上記のリンクの情報を使ってください。



## はじめに

この環境はETロボコン用にraspberryPiとLEGO(R)のSPIKE Prime(R)を接続して動作させるためのものです。raspberry側のEV3RT互換環境と、SPIKE側の制御ソフトからなり、これらを総称して「RasPike」と呼びます。

EV3RTのベースとなるraspberry-Pi用aspシミュレータはMac OS X用のシミュレータをraspi用に修正したものとなっています。
https://www.toppers.jp/asp3-e-download.html


また、linux用の変更やsetjmp/longjmpのmangleに関しては
https://qiita.com/morioka/items/a186fff4db1eabb7e7de
を参考にしています。

本SWはmaosxシミュレータの成果物および、TOPPERS様の「箱庭」プロジェクトでのathrillの成果物を多く使用しています。感謝いたします。

## RasPikeの概要

RasPikeはETロボコンでSPIKEを使用するためにETロボコン実行委員会で作成した環境です。
主なHW/SW構成は下図のようになります。

<img src="https://user-images.githubusercontent.com/790672/160266485-719d880a-64e5-475f-8683-81bd0073c6ac.jpg" width="80%"/>

SPIKEは単独ではCPUやメモリの制約が強く、EV3で行なっていたような複雑な処理ができません。また、今の所SPIKEにnativeで動作するリアルタイムOSはできていません。
そのため、基本的なプログラムはRasPi上で動作させ、そこからモーターなどの制御情報をSPIKEに伝え、SPIKEからはステータス情報を伝える構成としています。
RasPiではEV3RTとほぼ互換な開発環境で開発をできるようにしていますので、従来持っていたコードや技術教育のコードなどがほぼそのまま利用できるはずです。
こうすることで、シミュレータ、EV3、SPIKEでの開発を同じプログラム（ただし、パラメータや有効なAPIなどはそれぞれで異なります）で行うことができるようにしています。
SPIKE側にはmicro pythonで作成した受け用プログラム(raspike_etrobo_main.py)が受信用のプログラムとして動作します。

2022年度のETロボコンは実機大会で行う予定ですが、コロナの状況によりシミュレータ大会となる可能性もあります。その場合でも、RasPike環境で作ることで、プログラムの使い回しができるようになります。


## Raspberry側の環境構築

https://github.com/ETrobocon/RasPike/wiki
を参照ください
