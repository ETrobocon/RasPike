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
#   $Id: cdlinitializer.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

#== CDL の初期化子を扱うためのクラス
# CDL の初期化子そのものではない
class CDLInitializer
  #=== 初期化子のクローン
  # 初期化子は Expression, C_EXP, Array のいずれか
  def self.clone_for_composite( rhs, ct_name, cell_name, locale )
    if rhs.instance_of? C_EXP then
      # C_EXP の clone を作るとともに置換
      rhs = rhs.clone_for_composite( ct_name, cell_name, locale )
    elsif rhs.instance_of? Expression then
      rhs = rhs.clone_for_composite
    elsif rhs.instance_of? Array then
      rhs = clone_for_compoiste_array( rhs, ct_name, cell_name, locale )
    else
      raise "unknown rhs for join"
    end
    return rhs
  end

  #=== 初期化子（配列）のクローン
  # 要素は clone_for_composite を持つものだけ
  def self.clone_for_compoiste_array( array, ct_name, cell_name, locale )
    # "compoiste.identifier" の場合 (CDL としては誤り)
    if array[0] == :COMPOSITE then
      return array.clone
    end

    new_array = array.map{ |m|
      clone_for_composite( m, ct_name, cell_name, locale )
    }
    return new_array
  end
end
