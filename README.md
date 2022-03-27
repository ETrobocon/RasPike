# Raspi用 SPIKE制御開発環境「RasPike（ラスパイク）」

3/27 現在ベータ版として公開しています。4/endに正式版となる予定ですが、その後も不具合対応が行われる予定です。

## はじめに

この環境はETロボコン用にraspberryPiとLEGO(R)のSPIKE Prime(R)を接続して動作させるためのものです。raspberry側のEV3RT互換環境と、SPIKE側の制御ソフトからなり、これらを総称して「RasPike」と呼びます。

EV3RTのベースとなるraspberry-Pi用aspシミュレータはMac OS X用のシミュレータをraspi用に修正したものとなっています。
https://www.toppers.jp/asp3-e-download.html



また、linux用の変更やsetjmp/longjmpのmangleに関しては
https://qiita.com/morioka/items/a186fff4db1eabb7e7de
を参考にしています。

本SWはmaosxシミュレータの成果物および、TOPPERS様の「箱庭」プロジェクトでのathrillの成果物を多く使用しています。感謝いたします。

## Raspberry側の環境構築

https://github.com/ETrobocon/RasPike/wiki
を参照ください
