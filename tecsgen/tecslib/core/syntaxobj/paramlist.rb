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
#   $Id: paramlist.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

# 関数パラメータリスト
class ParamList < BDNode
# @param_list:: NamedList : item: ParamDecl

  def initialize( paramdecl )
    super()
    @param_list = NamedList.new( paramdecl, "parameter" )
    @param_list.get_items.each { |paramdecl|
      paramdecl.set_owner self   # ParamDecl
    }
  end

  def add_param( paramdecl )
    return if paramdecl == nil    # 既にエラー

    @param_list.add_item( paramdecl )
    paramdecl.set_owner self   # ParamDecl
  end

  def get_items
    @param_list.get_items
  end

  #=== size_is, count_is, string の引数の式をチェック
  # 変数は前方参照可能なため、関数頭部の構文解釈が終わった後にチェックする
  def check_param
    @param_list.get_items.each { |i|
      next if i == nil                      # i == nil : エラー時

      if i.get_type.class == VoidType then
        # 単一の void 型はここにはこない
        cdl_error( "S2027 '$1' parameter cannot be void type", i.get_name )
      end

      size = i.get_size			# Expression
      if size then
        val = size.eval_const( @param_list )
        if val == nil then			# 定数式でないか？
          # mikan 変数を含む式：単一の変数のみ OK
          type = size.get_type( @param_list )
          unless type.kind_of?( IntType ) then
            cdl_error( "S2017 size_is argument is not integer type"  )
          else
            size.check_dir_for_param( @param_list, i.get_direction, "size_is" )
          end
        else
          if val != Integer( val ) then
            cdl_error( "S2018 \'$1\' size_is parameter not integer" , i.get_declarator.get_identifier )
          elsif val <= 0 then
            cdl_error( "S2019 \'$1\' size_is parameter negative or zero" , i.get_declarator.get_identifier )
          end
        end
      end

      max = i.get_max
      if max then
        val2 = max.eval_const( @param_list )
        if val2 == nil then
          cdl_error( "S2028 '$1' max (size_is 2nd parameter) not constant", i.get_name )
        elsif val2 != Integer( val2 ) || val2 <= 0 then
          cdl_error( "S2029 '$1' max (size_is 2nd parameter) negative or zero, or not integer", i.get_name )
        end
      end

      if val != nil && val2 != nil then
        if val < val2 then
          cdl_warning( "W3005 '$1' size_is always lower than max. max is ignored", i.get_name )
          i.clear_max
        else
          cdl_error( "S2030 '$1' both size_is and max are const. size_is larger than max", i.get_name )
        end
      end

      count = i.get_count			# Expression
      if count then
        val = count.eval_const( @param_list )
        if val == nil then			# 定数式でないか？
          # mikan 変数を含む式：単一の変数のみ OK
          type = count.get_type( @param_list )
          unless type.kind_of?( IntType ) then
            cdl_error( "S2020 count_is argument is not integer type"  )
          else
            count.check_dir_for_param( @param_list, i.get_direction, "count_is" )
          end
        else
          if val != Integer( val ) then
            cdl_error( "S2021 \'$1\' count_is parameter not integer" , i.get_declarator.get_identifier )
          elsif val <= 0 then
            cdl_error( "S2022 \'$1\' count_is parameter negative or zero" , i.get_declarator.get_identifier )
          end
        end
      end

      string = i.get_string			# Expression
      if string != -1 && string then
        val = string.eval_const( @param_list )
        if val == nil then			# 定数式でないか？
          # mikan 変数を含む式：単一の変数のみ OK
          type = string.get_type( @param_list )
          unless type.kind_of?( IntType ) then
            cdl_error( "S2023 string argument is not integer type"  )
          else
            string.check_dir_for_param( @param_list, i.get_direction, "string" )
          end
        else
          if val != Integer( val ) then
            cdl_error( "S2024 \'$1\' string parameter not integer" , i.get_declarator.get_identifier )
          elsif val <= 0 then
            cdl_error( "S2025 \'$1\' string parameter negative or zero" , i.get_declarator.get_identifier )
          end
        end
      end
    }
  end

  def check_struct_tag kind
    @param_list.get_items.each{ |p|
      p.check_struct_tag kind
    }
  end

  #=== Push Pop Allocator が必要か？
  # Transparent RPC の場合 (oneway かつ) in の配列(size_is, count_is, string のいずれかで修飾）がある
  def need_PPAllocator?( b_opaque = false )
    @param_list.get_items.each { |i|
      if i.need_PPAllocator?( b_opaque ) then
        return true
      end
    }
    false
  end

  def find( name )
    @param_list.get_item( name )
  end

  #== ParamList# 文字列化
  #b_name:: Bool: パラメータ名を含める
  def to_str( b_name )
    str = "("
    delim = ""
    @param_list.get_items.each{ |paramdecl|
      decl = paramdecl.get_declarator
      str += delim + decl.get_type
      if b_name then
        str += " " + decl.get_name
      end
      str += decl.get_type_post
      delim = ", "
    }
    str += ")"
  end

  def show_tree( indent )
    indent.times { print "  " }
    puts "ParamList: #{locale_str}"
    @param_list.show_tree( indent + 1 )
  end
end
