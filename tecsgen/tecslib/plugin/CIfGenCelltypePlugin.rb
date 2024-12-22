# -*- coding: utf-8 -*-
#
#  TECS Generator
#      Generator for TOPPERS Embedded Component System
#  
#   Copyright (C) 2008-2014 by TOPPERS Project
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
#   $Id: CelltypePlugin.rb 2952 2018-05-07 10:19:07Z okuma-top $
#++

#== celltype プラグインの共通の親クラス
class CIfGenCelltypePlugin < CelltypePlugin

    #celltype::     Celltype        セルタイプ（インスタンス）
    def initialize( celltype, option )
      super
      @celltype = celltype
      # @plugin_arg_str = option.gsub( /\A"(.*)/, '\1' )    # 前後の "" を取り除く
      # @plugin_arg_str.sub!( /(.*)"\z/, '\1' )
      @plugin_arg_str = CDLString.remove_dquote option
      @plugin_arg_list = {}
      @cell_list =[]
    end
  
    #=== 新しいセル
    #cell::        Cell            セル
    #
    # celltype プラグインを指定されたセルタイプのセルが生成された
    # セルタイププラグインに対する新しいセルの報告
    def new_cell( cell )
        @cell_list << cell
    end
    
    #=== 後ろの CDL コードを生成
    #プラグインの後ろの CDL コードを生成
    #file:: File: 
    def self.gen_post_code( file )
      # 複数のプラグインの post_code が一つのファイルに含まれるため、以下のような見出しをつけること
      # file.print "/* '#{self.class.name}' post code */\n"
    end

    #=== tCelltype_factory.h に挿入するコードを生成する
    # file 以外の他のファイルにファクトリコードを生成してもよい
    # セルタイププラグインが指定されたセルタイプのみ呼び出される
    def gen_factory file
        file = CFile.open( "#{$gen}/#{@celltype.get_global_name}_cif.h", "w" )

        file.print <<EOT
#ifndef #{@celltype.get_global_name.to_s.upcase}_H
#define #{@celltype.get_global_name.to_s.upcase}_H

/*
 * This header file is intedned to be included in non-TECS celltype code.
 * Don not include in celltype code.
 * Mutiple *_cif.h files can be included non-TECS celltype code.
 */

/* include celltype definition header */
#ifndef TOPPERS_CB_TYPE_ONLY
#define TOPPERS_CB_TYPE_ONLY
#define TOPPERS_CB_TYPE_ONLY_defined_#{@celltype.get_global_name}_CIF_H
#endif

#include "#{@celltype.get_global_name}_tecsgen.h"

#ifdef TOPPERS_CB_TYPE_ONLY_defined_#{@celltype.get_global_name}_CIF_H
#undef TOPPERS_CB_TYPE_ONLY
#undef TOPPERS_CB_TYPE_ONLY_defined_#{@celltype.get_global_name}_CIF_H
#endif

/**/
EOT

        @celltype.get_cell_list.each{ |cell|
            if cell.is_generate? then
                file.print "\n/*** cell: #{cell.get_name} ***/\n"
                name_array = @celltype.get_name_array cell
                cell_idx = name_array[7]
                @celltype.get_port_list.each{ |port|
                    if port.get_port_type == :ENTRY then
                        sz = port.get_array_size
                        if sz != nil then
                            subsc = "subscript"
                            delim_subsc = ", "
                        else
                            subsc = ""
                            delim_subsc = ""
                        end
                        file.print "/** port: #{port.get_name} **/\n"
                        sig = port.get_signature
                        sig.get_function_head_array.each{ |fh|
                            file.print "/* funcition: #{fh.get_name} */\n"
                            file.print "#define #{cell.get_global_name}_#{port.get_name}_#{fh.get_name}( #{subsc}"
                            delim = delim_subsc
                            fh.get_paramlist.get_items.each{ |param|
                                file.print "#{delim}#{param.get_name}"
                                    delim = ", "
                            }
                            file.print " ) \\\n        "
                            file.print "#{@celltype.get_global_name}_#{port.get_name}_#{fh.get_name}( "
                            if @celltype.is_singleton? then
                                delim = ""
                            else
                                file.print "#{name_array[7]}"   # cell_IDX
                                delim = ", "
                            end
                            file.print "#{delim}#{subsc}"
                            delim = delim_subsc
                            fh.get_paramlist.get_items.each{ |param|
                                file.print "#{delim}#{param.get_name}"
                                delim = ", "
                            }
                            file.print " )\n"
                        }
                    end
                    file.print "\n"
                }
            end
        }
        file.print "#endif /* #{@celltype.get_global_name.to_s.upcase}_H */\n"
        file.close
    end
end
