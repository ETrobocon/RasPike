# -*- coding: utf-8 -*-
#
#  TECS Generator
#      Generator for TOPPERS Embedded Component System
#  
#   Copyright (C) 2008-2021 by TOPPERS Project
#--
#   上記著作権者は，以下の(1)〜(4)の条件を満たす場合に限り，本ソフトウェ
#   ア（本ソフトウェアを改変したものを含む．以下同じ）を使用・複製・改
#   変・再配布（以下，利用と呼ぶ）することを無償で許諾する．
#   (1) 本ソフトウェアをソースコードの形で利用する場合には，上記の著作
#       権表示，この利用条件および下記の無保証規定が，そのままの形でソー
#       スコード中に含まれていること．
#   (2) 本ソフトウェアを，ライブラリ形式など，他のソフトウェア開発に使
#       用できる形で再配布する場合には，再配布に伴うドキュメント（利用
#       者マニュアルなど）に，上記の著作権表示，この利用条件および下記
#       の無保証規定を掲載すること．
#   (3) 本ソフトウェアを，機器に組み込むなど，他のソフトウェア開発に使
#       用できない形で再配布する場合には，次のいずれかの条件を満たすこ
#       と．
#     (a) 再配布に伴うドキュメント（利用者マニュアルなど）に，上記の著
#         作権表示，この利用条件および下記の無保証規定を掲載すること．
#     (b) 再配布の形態を，別に定める方法によって，TOPPERSプロジェクトに
#         報告すること．
#   (4) 本ソフトウェアの利用により直接的または間接的に生じるいかなる損
#       害からも，上記著作権者およびTOPPERSプロジェクトを免責すること．
#       また，本ソフトウェアのユーザまたはエンドユーザからのいかなる理
#       由に基づく請求からも，上記著作権者およびTOPPERSプロジェクトを
#       免責すること．
#  
#   本ソフトウェアは，無保証で提供されているものである．上記著作権者お
#   よびTOPPERSプロジェクトは，本ソフトウェアに関して，特定の使用目的
#   に対する適合性も含めて，いかなる保証も行わない．また，本ソフトウェ
#   アの利用により直接的または間接的に生じたいかなる損害に関しても，そ
#   の責任を負わない．
#  
#   $Id: componentobj.rb 2846 2018-03-25 11:30:55Z okuma-top $
#++

# シグニチャ
require_tecsgen_lib 'tecslib/core/componentobj/signature.rb'

# セルタイプ
require_tecsgen_lib 'tecslib/core/componentobj/celltypeModule.rb'
require_tecsgen_lib 'tecslib/core/componentobj/celltype.rb'
require_tecsgen_lib 'tecslib/core/componentobj/port.rb'
require_tecsgen_lib 'tecslib/core/componentobj/factory.rb'

# セル
require_tecsgen_lib 'tecslib/core/componentobj/cell.rb'
require_tecsgen_lib 'tecslib/core/componentobj/join.rb'
require_tecsgen_lib 'tecslib/core/componentobj/reversejoin.rb'

# 複合セルタイプ
require_tecsgen_lib 'tecslib/core/componentobj/compositecelltype.rb'
require_tecsgen_lib 'tecslib/core/componentobj/compositecelltypejoin.rb'

# ネームスペース、リージョン
require_tecsgen_lib 'tecslib/core/componentobj/domaintype.rb'
require_tecsgen_lib 'tecslib/core/componentobj/classtype.rb'
require_tecsgen_lib 'tecslib/core/componentobj/namespace.rb'
require_tecsgen_lib 'tecslib/core/componentobj/region.rb'
require_tecsgen_lib 'tecslib/core/componentobj/namespacepath.rb'

# import, import_C
require_tecsgen_lib 'tecslib/core/componentobj/importable.rb'
require_tecsgen_lib 'tecslib/core/componentobj/import.rb'
require_tecsgen_lib 'tecslib/core/componentobj/import_c.rb'

# generate 文
require_tecsgen_lib 'tecslib/core/componentobj/generate.rb'

###
# 共通の設計メモ

# STAGE:
# このメンテナンス状況はよろしくない
#  B    bnf.y.rb から呼出される
#  P    parse 段階で呼出される（bnf.y.rb から直接呼出されるわけではないが、構文木生成を行う）
#  S    P の中から呼出されるが、構文木生成するわけではなく意味チェックする
#  G    コード生成（この段階で、構文木は完全である．不完全ならエラーで打ちきられている）
#                                                   factory の第一引数 "format" の後ろの引数

# mikan 以下は ruby の mix in で実現できるかもしれない
# Nestable を継承した場合、クラス変数は Nestable のものが共有される（別にしたかった）
# class Nestable
#   @@nest_stack_index = -1
#   @@nest_stack = []
#   @@current_object = nil
# 
#   def self.push
#     @@nest_stack_index += 1
#     @@nest_stack[ @nest_stack_index ] = @@current_object
#     @@current_object = nil
#   end
# 
#   def pop
#     @@current_object = @@nest_stack[ @@nest_stack_index ]
#     @nest_stack_index -= 1
#     if @@nest_stack_index < -1 then
#       raise TooManyRestore
#     end
#   end
# end
#
# 以下のクラスにおいて使用している
#   Signature
#   Cell
#   Celltype
#   CompositeCelltype
#   Import
#   Namespace
