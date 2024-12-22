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
#   $Id: paramdecl.rb 3268 2023-01-03 11:39:43Z okuma-top $
#++

# 関数パラメータの宣言
class ParamDecl < BDNode

# @declarator:: Decl:  Token, ArrayType, FuncType, PtrType
# @direction:: :IN, :OUT, :INOUT, :SEND, :RECEIVE
# @size:: Expr   (size_is 引数)
# @count:: Expr   (count_is 引数)
# @max:: Expr (size_is の第二引数)
# @b_nullable:: Bool : nullable 
# @string:: Expr or -1(if size not specified) （string 引数）
# @allocator:: Signature of allocator
# @b_ref:: bool : size_is, count_is, string_is 引数として参照されている
#
# 1. 関数型でないこと
# 2. ２次元以上の配列であって最も内側以外の添数があること
# 3. in, out, ..., size_is, count_is, ... の重複指定がないこと
# 4. ポインタレベルが適切なこと

  def initialize( declarator, specifier, param_specifier )
    super()
    @declarator = declarator
    @declarator.set_owner self  # Decl (ParamDecl)
    @declarator.set_type( specifier )
    @param_specifier = param_specifier
    @b_ref = false
    @b_nullable = false

    if @declarator.is_function? then		# (1)
      cdl_error( "S2006 \'$1\' function" , get_name )
      return
    end

    res = @declarator.check
    if res then					# (2)
      cdl_error( "S2007 \'$1\' $2" , get_name, res )
      return
    end

    @param_specifier.each { |i|
      case i[0]                                     # (3)
      when :IN, :OUT, :INOUT, :SEND, :RECEIVE
        if @direction == nil then
          @direction = i[0]
        elsif i[0] == @direction then
          cdl_warning( "W3001 $1: duplicate" , i[0] )
          next
        else
          cdl_error( "S2008 $1: inconsitent with previous one" , i[0] )
          next
        end

        case i[0]
        when :SEND, :RECEIVE
          @allocator = Namespace.find( i[1] )   #1
          if ! @allocator.instance_of?( Signature ) then
            cdl_error( "S2009 $1: not found or not signature" , i[1] )
            next
          elsif ! @allocator.is_allocator? then
            # cdl_error( "S2010 $1: not allocator signature" , i[1] )
          end
        end

      when :SIZE_IS
        if @size then
          cdl_error( "S2011 size_is duplicate"  )
        else
          @size = i[1]
        end
      when :COUNT_IS
        if @count then
          cdl_error( "S2012 count_is duplicate"  )
        else
          @count = i[1]
        end
      when :STRING
        if @string then
          cdl_error( "S2013 string duplicate"  )
        elsif i[1] then
          @string = i[1]
        else
          @string = -1
        end
      when :MAX_IS
        # max_is は、内部的なもの bnf.y.rb 参照
        # size_is で重複チェックされる
        @max = i[1]
      when :NULLABLE
        # if ! @declarator.get_type.kind_of?( PtrType ) then
        #  cdl_error( "S2026 '$1' nullable specified for non-pointer type", @declarator.get_name )
        # else
          @b_nullable = true
        # end
      end

    }

    if @direction == nil then
      cdl_error( "S2014 No direction specified. [in/out/inout/send/receive]"  )
    end

    if ( @direction == :OUT || @direction == :INOUT ) && @string == -1 then
      cdl_warning( "W3002 $1: this string might cause buffer over run" , get_name )
    end

    # mikan ポインタの配列（添数有）のレベルが０
    ptr_level = @declarator.get_ptr_level

    # p "ptr_level: #{@declarator.get_identifier} #{ptr_level}"
    # p @declarator

    #----  set req_level, min_level & max_level  ----#
    if !(@size||@count||@string) then	    # (4)
      req_level = 1
    elsif (@size||@count)&&@string then
      req_level = 2
    else
      req_level = 1
    end

    if @direction == :RECEIVE then
      req_level += 1
    end
    min_level = req_level
    max_level = req_level

    # IN without pointer specifier can be non-pointer type
    if @direction == :IN && !(@size||@count||@string) then
      min_level = 0
    end

    # if size_is specified and pointer refer to struct, max_level increase
    if @size then
      type = @declarator.get_type.get_original_type
      while type.kind_of? PtrType
        type = type.get_referto.get_original_type
      end
      if type.kind_of? StructType then
        max_level += 1
      end
    end
    #----  end req_level & max_level    ----#

    # p "req_level: #{req_level} ptr_level: #{ptr_level}"
    #if ptr_level < req_level && ! ( @direction == :IN && req_level == 1 && ptr_level == 0) then
    if ptr_level < min_level then
      cdl_error( "S2014 $1 need pointer or more pointer" , @declarator.get_identifier )
    elsif ptr_level > max_level then
      # note: 構文解析段階で実行のため get_current 可
      if Signature.get_current == nil || Signature.get_current.is_deviate? == false then
        cdl_warning( "W3003 $1 pointer level mismatch" , @declarator.get_identifier )
      end
    end

    type = @declarator.get_type
    while type.kind_of?( DefinedType )
      type = type.get_original_type
    end

    if ptr_level > 0 then
      # size_is, count_is, string をセット
      if @direction == :RECEIVE && ptr_level > 1 then
        type.get_type.set_scs( @size, @count, @string, @max, @b_nullable )
      else
        type.set_scs( @size, @count, @string, @max, @b_nullable )
      end

#p ptr_level
#type.show_tree 1

      # ポインタが指している先のデータ型を得る
      i = 0
      t2 = type
      while i < ptr_level
        t2 = t2.get_referto
        while t2.kind_of?( DefinedType )
          t2 = t2.get_original_type
        end
        i += 1
      end

# p @declarator.get_name
# t2.show_tree 1
# p t2.is_const?

      # const 修飾が適切かチェック
      if @direction == :IN then
        if ! t2.is_const? then
          cdl_error( "S2015 '$1' must be const for \'in\' parameter $2" , get_name, type.class )
        end
      else
        if t2.is_const? && Signature.get_current.is_deviate? == false then
          cdl_error( "S2016 '$1' can not be const for $2 parameter" , get_name, @direction )
        end
      end
    else
      # 非ポインタタイプ
      if @size != nil || @count != nil || @string != nil || @max != nil || @b_nullable then
        type.set_scs( @size, @count, @string, @max, @b_nullable )
      end
    end

#    if ptr_level > 0 && @direction == :IN then
#      if type.is_const != :CONST
#    end

    # p self

  end

  def check_struct_tag kind
    @declarator.get_type.check_struct_tag :PARAMETER
  end

  def get_name
    @declarator.get_name
  end

  def get_size
    @size
  end

  def get_count
    @count
  end

  def get_string
    @string
  end

  def get_max
    @max
  end

  def clear_max
    # p "clear_max: #{@declarator.get_name} #{@max.to_s}"
    @max = nil
    @declarator.get_type.clear_max
  end

  def is_nullable?
    @b_nullable
  end

  def get_type
    @declarator.get_type
  end

  def get_direction
    @direction
  end

  def get_declarator
    @declarator
  end

  def get_allocator
    @allocator
  end

  def referenced
    @b_ref = true
  end

  def is_referenced?
    @b_ref
  end

  #=== PPAllocator が必要か
  # Transparent RPC の場合 in で size_is, count_is, string のいずれかが指定されている場合 oneway では PPAllocator が必要
  # Transparent PC で oneway かどうかは、ここでは判断しないので別途判断が必要
  # Opaque RPC の場合 size_is, count_is, string のいずれかが指定されている場合、PPAllocator が必要
  def need_PPAllocator?( b_opaque = false )
    if ! b_opaque then
#      if @direction == :IN && ( @size || @count || @string ) then
      if @direction == :IN && @declarator.get_type.get_original_type.kind_of?( PtrType ) then
        return true
      end
    else
      if (@direction == :IN || @direction == :OUT || @direction == :INOUT ) &&
          @declarator.get_type.get_original_type.kind_of?( PtrType ) then
        return true
      end
    end
    return false
  end

  def show_tree( indent )
    indent.times { print "  " }
    puts "ParamDecl: direction: #{@direction} #{locale_str}"
    @declarator.show_tree( indent + 1 )
    if @size then
      (indent+1).times { print "  " }
      puts "size:"
      @size.show_tree( indent + 2 )
    end
    if @count then
      (indent+1).times { print "  " }
      puts "count:"
      @count.show_tree( indent + 2 )
    end
    if @string then
      (indent+1).times { print "  " }
      puts "string:"
      if @string == -1 then
       (indent+2).times { print "  " }
        puts "size is not specified"
      else
        @string.show_tree( indent + 2 )
      end
    end
    if @allocator then
      (indent+1).times { print "  " }
      puts "allocator: signature: #{@allocator.get_name}"
    end    
  end
end
