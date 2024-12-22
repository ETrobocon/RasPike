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
#   $Id: funchead.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

#== 関数頭部
# signature に登録される関数
class FuncHead <BDNode
#  @declarator:: Decl

  def initialize( declarator, type, b_oneway )
    super()
    declarator.set_type( type )
    @declarator = declarator
    @declarator.set_owner self  # Decl (FuncHead)

    if @declarator.get_type.kind_of?( FuncType ) then
      if b_oneway then
        @declarator.get_type.set_oneway( b_oneway )
      end
    end
    @declarator.get_type.check_struct_tag :FUNCHEAD

    # check if return type is pointer
    if declarator.get_type.kind_of? FuncType then
      if declarator.get_type.get_type.get_original_type.kind_of?( PtrType ) &&
          Signature.get_current.is_deviate? == false then
        cdl_warning( "W3004 $1 pointer type has returned. specify deviate or stop return pointer" , @declarator.get_identifier )
      end
    end
  end

  def get_name
    @declarator.get_name
  end

  def get_declarator
    @declarator
  end

  def is_oneway?
    if @declarator.is_function? then
      return @declarator.get_type.is_oneway?
    end
    return false
  end

  def is_function?
    @declarator.is_function?
  end

  #=== FuncHead# 関数の名前を返す
  def get_name
    return @declarator.get_name
  end

  #=== FuncHead# 関数型を返す
  def get_type
    return @declarator.get_type
  end

  #=== FuncHead# 関数の戻り値の型を返す
  # types.rb に定義されている型
  # 関数ヘッダの定義として不完全な場合 nil を返す
  def get_return_type
    if is_function? then
      return @declarator.get_type.get_type
    end
  end

  #=== FuncHead# 関数の引数のリストを返す
  # ParamList を返す
  # 関数ヘッダの定義として不完全な場合 nil を返す
  def get_paramlist
    if is_function? then
      return @declarator.get_type.get_paramlist
    end
  end

  def show_tree( indent )
    indent.times { print "  " }
    puts "FuncHead: #{locale_str}"
    @declarator.show_tree( indent + 1 )
  end
end
