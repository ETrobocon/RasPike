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
#   $Id: decl.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

#=== 宣言
# @kind で示される各種の宣言
class Decl < BDNode

# @identifer:: String
# @global_name:: String | nil : String(@kind=TYPEDEF||:CONSTANT), nil(@kind=その他)
#                set_kind にて設定される
# @type:: ArrayType, FuncType, PtrType, IntType, StructType
#         VoidType, FloatType, DefinedType, BoolType
# @initializer:: constant_expression, mikan { initlist }
# @kind:: :VAR, :ATTRIBUTE, :PARAMETER, :TYPEDEF, :CONSTANT, :MEMBER, :FUNCHEAD(signatureの関数定義)
# @b_referenced:: bool
#
# 以下は、@kind が :VAR, :ATTRIBUTE のときに有効
# @rw:: bool     # 古い文法では attr に指定可能だった（消すには generate の修正も必要）
# @omit:: bool
# @choice_list:: [String]  attr 初期値の選択肢
# 以下は、@kind が :VAR, :ATTRIBUTE, :MEMBER のときに有効
# @size_is:: Expression or nil unless specified
# 以下は、@kind が :MEMBER のときに有効
# @count_is:: Expression or nil unless specified
#             attr, var の場合、count_is は指定できない
# @string:: Expression, -1 (length not specified) or nil (not specified)
#
# mikan  ParamDecl だけ別に設けたが、MemberDecl, AttrDecl なども分けるべきか(？)

  def initialize( identifier )
    super()
    @identifier = identifier
    @rw = false
    @omit = false
    @size_is = nil
    @count_is = nil
    @string  = nil
    @choice_list  = nil
    @b_referenced  = false
  end

  def set_initializer( initializer )
    @initializer = initializer
  end

  def get_initializer
    @initializer
  end

  def is_function?
    if @type.class == FuncType then
      return true
    else
      return false
    end
  end

  #== Decl の意味的誤りをチェックする
  def check
    # return nil if @type == nil

    # 構造体タグチェック（ポインタ型から構造体が参照されている場合は、タグの存在をチェックしない）
    @type.check_struct_tag @kind

    # 型のチェックを行う
    res = @type.check
    if res then
      cdl_error( "S2002 $1: $2" , @identifier, res )
    end

    # 不要の初期化子をチェックする
    if @initializer then
      case @kind
      when :PARAMETER, :TYPEDEF, :MEMBER, :FUNCHEAD
        cdl_error( "S2003 $1: $2 cannot have initializer" , @identifier, @kind.to_s.downcase )
      when :VAR, :ATTRIBUTE, :CONSTANT
        # p @initializer  ここでは代入可能かどうか、チェックしない
        # :VAR, :ATTRIBUTE, :CONSTANT はそれぞれでチェックする
        # return @type.check_init( @identifier, @initializer, @kind )
      else
        raise "unknown kind in Delc::check"
      end
    end

    if( @type.kind_of? ArrayType ) && ( @type.get_subscript == nil ) && ( @omit == false ) then
      if @kind == :ATTRIBUTE then
        cdl_error( "S2004 $1: array subscript must be specified or omit" , @identifier )
      elsif @kind == :VAR || @kind == :MEMBER then
        # p "Decl: #{@type.class.name}"
        if @type.instance_of?( CArrayType ) && @kind == :MEMBER then
          cdl_info( "I9999 $1: array without subscript might not be handled" , @identifier )
        else
          cdl_error( "S2005 $1: array subscript must be specified" , @identifier )
        end
      end
    end

    return nil
  end

  #== ポインタレベルを得る
  # 戻り値：
  #   非ポインタ変数   = 0
  #   ポインタ変数     = 1
  #   二重ポインタ変数 = 2
  def get_ptr_level
    level = 0
    type = @type
    while 1
      if type.kind_of?( PtrType ) then
        level += 1
        type = type.get_referto
#      elsif type.kind_of?( ArrayType ) then  # 添数なし配列はポインタとみなす
#        if type.get_subscript == nil then
#          level += 1
#          type = type.get_type
#        else
#          break
#        end
        # mikan ポインタの添数あり配列のポインタレベルは０でよい？
      elsif type.kind_of?( DefinedType ) then
        type = type.get_type
        # p "DefinedType: #{type} #{type.class}"
      else
        break
      end
    end
    return level
  end

  def get_name
    @identifier
  end

  def get_global_name
    @global_name
  end

  def set_type( type )
    unless @type then
      @type = type
    else
      @type.set_type( type )             # 葉に設定
    end
  end

  def get_type
    @type
  end

  def get_identifier
    @identifier
  end

  # STAGE: B
  def set_kind( kind )
    @kind = kind
    case kind
    when :TYPEDEF, :CONSTANT
      if Namespace.get_global_name.to_s == "" then
        @global_name = @identifier
      else
        @global_name = :"#{Namespace.get_global_name}_#{@identifier}"
      end
    else
      @global_name = nil
    end
  end

  def get_kind
    @kind
  end

  def set_specifier_list( spec_list )
    spec_list.each{  |spec|
      case spec[0]
      when :RW
        @rw = true
      when :OMIT
        @omit = true
      when :SIZE_IS
        @size_is = spec[1]
      when :COUNT_IS
        @count_is = spec[1]
      when :STRING
        @string = spec[1]
      when :CHOICE
        @choice_list = spec[1]
      else
        raise "Unknown specifier #{spec[0]}"
      end
    }

    if @size_is || @count_is || @string
        @type.set_scs( @size_is, @count_is, @string, nil, false )
    end
  end

  def is_rw?
    @rw
  end

  def is_omit?
    @omit
  end

  def get_size_is
    @size_is
  end

  def get_count_is
    @count_is
  end

  def get_string
    @string
  end

  def get_choice_list
    @choice_list
  end

  def referenced
    @b_referenced = true
  end

  def is_referenced?
    @b_referenced
  end

  def is_type?( type )
    t = @type
    while 1
      if t.kind_of?( type ) then
        return true
      elsif t.kind_of?( DefinedType ) then
        t = t.get_type
      else
        return false
      end
    end
  end

  def is_const?
    type = @type
    while 1
      if type.is_const? then
        return true
      elsif type.kind_of?( DefinedType ) then
        type = type.get_type
      else
        return false
      end
    end
  end

  #=== Decl# print_flowinfo
  def print_flowinfo file
    if @kind == :VAR then
      file.write "#{@identifier} "
    end
  end

  def show_tree( indent )
    indent.times { print "  " }
    puts "Declarator: name: #{@identifier} kind: #{@kind} global_name: #{@global_name} #{locale_str}"
    (indent+1).times { print "  " }
    puts "type:"
    @type.show_tree( indent + 2 )
    if @initializer then
      (indent+1).times { print "  " }
      puts "initializer:"
      @initializer.show_tree( indent + 2 )
    else
      (indent+1).times { print "  " }
      puts "initializer: no"
    end
    (indent+1).times { print "  " }
    puts "size_is: #{@size_is.to_s}, count_is: #{@count_is.to_s}, string: #{@string.to_s} referenced: #{@b_referenced} "
   
  end

end
