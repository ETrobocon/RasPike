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
#   $Id: compositecelltypejoin.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

# CLASS: CompositeCelltype 用の Join
# REM:   CompositeCelltype が export するもの
class CompositeCelltypeJoin < BDNode
# @export_name:: string     :  CompositeCelltype が export する名前（呼び口、受け口、属性）
# @internal_cell_name:: string : CompositeCelltype 内部のセルの名前
# @internal_cell_elem_name:: string : CompositeCelltype 内部のセルの呼び口、受け口、属性の名前
# @cell : Cell : Cell::  internal cell  : CompositeCelltyep 内部のセル（in_compositeセル）
# @port_decl:: Port | Decl
# @b_pseudo: bool : 

  def initialize( export_name, internal_cell_name,
		 internal_cell_elem_name, cell, port_decl )
    super()
    @export_name = export_name
    @internal_cell_name = internal_cell_name
    @internal_cell_elem_name = internal_cell_elem_name
    @cell = cell
    @port_decl = port_decl

  end

  #=== CompositeCelltypeJoin# CompositeCelltypeJoin の対象セルか？
  #cell::  Cell 対象かどうかチェックするセル
  #
  #     CompositeCelltypeJoin と cell の名前が一致するかチェックする
  #     port_decl が指定された場合は、現状使われていない
  def match?( cell, port_decl = nil )

    #debug
    if port_decl
      dbgPrint(  "match?"  )
      dbgPrintf( "  @cell:      %-20s      %08x\n", @cell.get_name, @cell.object_id )
      dbgPrintf( "  @port_decl: %-20s      %08x\n", @port_decl.get_name, @port_decl.object_id )
      dbgPrintf( "  cell:       %-20s      %08x\n", cell.get_name, cell.object_id )
      dbgPrintf( "  port_decl:  %-20s      %08x\n", port_decl.get_name, port_decl.object_id )
      dbgPrint(  "  cell_name: #{cell.get_name.class}=#{cell.get_name} cell_elem_name: #{port_decl.get_name.class}=#{port_decl.get_name}\n" )
      dbgPrint(  "  @cell_name: #{@cell.get_name.class}=#{@cell.get_name} cell_elem_name: #{@port_decl.get_name.class}=#{@port_decl.get_name}\n" )

    end

#    if @cell.equal?( cell ) && ( port_decl == nil || @port_decl.equal?( port_decl ) ) then
    # なぜ port_decl が一致しなければならなかったか忘れた。
    # recursive_composite で名前の一致に変更   060917
    if((@cell.get_name == cell.get_name) && (port_decl == nil || @port_decl.get_name == port_decl.get_name))then
      true
    else
      false
    end
  end

  def check_dup_init
    return if get_port_type != :CALL

    if @cell.get_join_list.get_item @internal_cell_elem_name then
      cdl_error( "S1131 \'$1.$2\' has duplicate initializer" , @internal_cell_name, @internal_cell_elem_name )
    end
  end

  def get_name
    @export_name
  end

  def get_cell_name
    @internal_cell_name
  end

  def get_cell
    @cell
  end

  def get_cell_elem_name
    @internal_cell_elem_name
  end

  # @port_decl が Port の場合のみ呼び出してよい
  def get_port_type
    if @port_decl then
      @port_decl.get_port_type
    end
  end

  def get_port_decl
    @port_decl
  end

  #=== CompositeCelltypeJoin#get_allocator_instance
  def get_allocator_instance
    if @port_decl.instance_of? Port then
      return @port_decl.get_allocator_instance
    elsif @port_decl
      raise "CompositeCelltypeJoin#get_allocator_instance: not port"
    else
      return nil
    end
  end

  # @port_decl が Port の場合のみ呼び出してよい
  def is_require?
    if @port_decl then
      @port_decl.is_require?
    end
  end

  # @port_decl が Port の場合のみ呼び出してよい
  def is_allocator_port?
    if @port_decl then
      @port_decl.is_allocator_port?
    end
  end

  # @port_decl が Port の場合のみ呼び出してよい
  def is_optional?
    if @port_decl then
      @port_decl.is_optional?
    end
  end

  #=== CompositeCelltypeJoin# 右辺が Decl ならば初期化子（式）を返す
  # このメソッドは Cell の check_join から初期値チェックのために呼び出される
  def get_initializer
    if @port_decl.instance_of? Decl then
      @port_decl.get_initializer
    end
  end

  def get_size_is
    if @port_decl.instance_of? Decl then
      @port_decl.get_size_is
    end
  end

  #=== CompositeCelltypeJoin# 配列サイズを得る
  #RETURN:: nil: not array, "[]": 大きさ指定なし, Integer: 大きさ指定あり
  def get_array_size
    @port_decl.get_array_size
  end

  #=== CompositeCelltypeJoin# signature を得る
  # @port_decl が Port の時のみ呼び出してもよい
  def get_signature
    @port_decl.get_signature
  end

  #=== CompositeCelltypeJoin# get_type
  def get_type
    if @port_decl.instance_of? Decl
      @port_decl.get_type
    end
  end

  #=== CompositeCelltypeJoin# get_initializer
  def get_initializer
    if @port_decl.instance_of? Decl
      @port_decl.get_initializer
    end
  end

  #=== CompositeCelltypeJoin# get_choice_list
  def get_choice_list
    if @port_decl.instance_of? Decl
      @port_decl.get_choice_list
    end
  end

  def show_tree( indent )
    indent.times { print "  " }
    puts "CompositeCelltypeJoin: export_name: #{@export_name} #{self}"
    (indent+1).times { print "  " }
    puts "internal_cell_name: #{@internal_cell_name}"
    (indent+1).times { print "  " }
    puts "internal_cell_elem_name: #{@internal_cell_elem_name}"
    if @port_decl then
      @port_decl.show_tree( indent + 1 )
    end
  end
end
