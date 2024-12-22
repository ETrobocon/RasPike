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
#   $Id: factory.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

class Factory < BDNode
# @name:: string
# @file_name:: string
# @format:: string
# @arg_list:: Expression の elements と同じ形式 [ [:IDENTIFIER, String], ... ]
# @f_celltype:: bool : true: celltype factory, false: cell factory

  @@f_celltype = false

  def initialize( name, file_name, format, arg_list )
    super()
    @f_celltype = @@f_celltype

    case name
    when :write
      # write 関数
      @name = name

      # write 関数の第一引数：出力先ファイル名
        # 式を評価する（通常単一の文字列であるから、単一の文字列が返される）
      @file_name = file_name.eval_const(nil).val  # file_name : Expression
      if ! @file_name.instance_of?( String ) then
        # 文字列定数ではなかった
        cdl_error( "S1132 $1: 1st parameter is not string(file name)" , @name )
        @file_name = nil
      end

      # write 関数の第二引数：フォーマット文字列
      @format    = format.eval_const(nil).val     # format : Expression
        # 式を評価する（通常単一の文字列であるから、単一の文字列が返される）
      if ! @format.instance_of?( String ) then
        # 文字列定数ではなかった
        cdl_error( "S1133 $1: 2nd parameter is not string(fromat)" , @name )
        @format = nil
      end

      # 第三引数以降を引数リストとする mikan 引数のチェック
      @arg_list = arg_list

    else
      cdl_error( "S1134 $1: unknown factory function" , name )
    end
    Celltype.new_factory( self )
  end

  def check_arg( celltype )
    if ! @arg_list then
      return
    end

    if @f_celltype then
      cdl_error( "S1135 celltype factory can\'t have parameter(s)"  )
      return
    end

    @arg_list.each{ |elements|

      case elements[0]
      when :IDENTIFIER  #1
        obj = celltype.find( elements[1] )
        if obj == nil then
          cdl_error( "S1136 \'$1\': not found" , elements[1] )
        elsif ! obj.instance_of?( Decl ) || obj.get_kind != :ATTRIBUTE then
          cdl_error( "S1137 \'$1\': not attribute" , elements[1] )
        end
      when :STRING_LITERAL
      else
        cdl_error( "S1138 internal error Factory.check_arg()"  )
      end

    }
  end

  def self.set_f_celltype( f_celltype )
    @@f_celltype = f_celltype
  end

  def get_f_celltype
    @f_celltype
  end

  def get_name
    @name
  end

  def get_file_name
    @file_name
  end

  def get_format
    @format
  end

  def get_arg_list
    @arg_list
  end

  def show_tree( indent )
    indent.times { print "  " }
    puts "Factory: name: #{@name}"
    if @arg_list then
      (indent+1).times { print "  " }
      puts "argument(s):"
      @arg_list.each { |l|
        (indent+2).times { print "  " }
        print "\"#{l}\"\n"
      }
    end
  end
end
