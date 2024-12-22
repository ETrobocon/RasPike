# -*- coding: utf-8 -*-
#
#  TECS Generator
#      Generator for TOPPERS Embedded Component System
#  
#   Copyright (C) 2008-2023 by TOPPERS Project
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
class CppIfGenCelltypePlugin < CelltypePlugin
    CLASS_NAME_SUFFIX = ""
    @@b_signature_header_generated = false

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
        if ! @celltype.is_singleton? then
            idx_def = "CPP_#{@celltype.get_global_name}_IDX idx_"
            idx_ini = ":cpp_idx( idx_ )"
            cpp_idx = "cpp_idx"
            idx2 = "cpp_idx.idx"
            idx_ = "idx_"
            delim_ini = ", "
        else
            idx_def = ""
            idx_ini = ""
            cpp_idx = ""
            idx2 = ""
            idx_ = ""
            delim_ini = ""
        end
        # シグニチャヘッダを生成する
        # これは、最初に呼び出されたときに、一度だけ、すべて生成する
        if @@b_signature_header_generated != true then
            @@b_signature_header_generated = true
            ns = Namespace.get_root
            gen_namespace_signature_header ns
        end

        file = CFile.open( "#{$gen}/#{@celltype.get_global_name}_cppif.hpp", "w" )
        file.print <<EOT
#ifndef #{@celltype.get_global_name.upcase}_CPPIF_HPP
#define #{@celltype.get_global_name.upcase}_CPPIF_HPP

/*
 * This file is intended to be included in non-TECS celltype code and in C++ code.
 */
EOT

dummy = <<EOT

#if 0   ///////// MACROs are undef later /////////
#ifndef TOPPERS_CB_TYPE_ONLY
#define TOPPERS_CB_TYPE_ONLY
#define TOPPERS_CB_TYPE_ONLY_defined_#{@celltype.get_global_name}_CIF_H
#endif
#endif /* 0 */
EOT

    file.print <<EOT
#include "#{@celltype.get_global_name}_tecsgen.h"
EOT

dummy = <<EOT
#ifdef TOPPERS_CB_TYPE_ONLY_defined_#{@celltype.get_global_name}_CIF_H
#undef TOPPERS_CB_TYPE_ONLY
#undef TOPPERS_CB_TYPE_ONLY_defined_#{@celltype.get_global_name}_CIF_H
#endif

EOT

        # signature ヘッダをインクルード
        b_gen = false
        @celltype.get_port_list.each{ |port|
            if port.get_port_type == :ENTRY then
                file.print "#include \"#{port.get_signature.get_global_name}_cppif.hpp\"\n"
                b_gen = true
            end
        }
        if b_gen then
            file.print "\n"
        end        

        if ! @celltype.is_singleton? then
            # シングルトンの場合 IDX は不要
            file.print <<EOT
/*
 * Cell IDX type for Cpp
 */
typedef struct  {
    #{@celltype.get_global_name}_IDX idx;
} CPP_#{@celltype.get_global_name}_IDX;

/*
 * Cell IDX macros in celltype '#{@celltype.get_name}'
 *   type of the macro value is #{@celltype.get_name}_IDX.
 *   macro name is (cell name) + "_IDX"
 */
EOT
            @celltype.get_cell_list.each{ |cell|
                if cell.is_generate? then
                    name_array = @celltype.get_name_array cell
                    if ! @celltype.is_singleton? then
                        idx_real = name_array[7]
                    else
                        idx_real = ""
                    end
                    file.print <<EOT
inline CPP_#{@celltype.get_global_name}_IDX CPP_#{cell.get_global_name}_IDX__()
{
    CPP_#{@celltype.get_global_name}_IDX cpp_idx = { #{idx_real} };
    return cpp_idx;
}
#define #{cell.get_global_name}_IDX  CPP_#{cell.get_global_name}_IDX__()
EOT
                end
            }
        end

        cell_sample = nil
        @celltype.get_cell_list.each{ |cell|
            if cell.is_generate? then
                cell_sample = cell
                break
            end
        }

        if cell_sample then
            cell_sample_name = cell_sample.get_name
        else
            cell_sample_name = :Cell
        end
        @celltype.get_port_list.each{ |port|
            if port.get_port_type == :ENTRY then
                if port.get_signature.get_function_head_array.length > 0 then
                    func_1st = port.get_signature.get_function_head_array[0]
                    if ! @celltype.is_singleton? then
                        cell_idx = "( Cell_IDX );"
                        cell_idx2 = "(#{@celltype.get_cell_list[0].get_global_name}_IDX);"
                    else
                        cell_idx = ";     // don't put empty parenthesis for singleton"
                        cell_idx2 = ";"
                    end
                    file.print <<EOT

/*-------------- begin: use sample ------------
 * Define variable for Cell with Cnstructor
 *   tCelltypeName    CellNameInCpp#{cell_idx}
 *   ex) #{@celltype.get_global_name}     #{cell_sample_name}#{cell_idx2}
 *
 * Call member function
 *   CellNameInCpp.eEntryName.FunctionName( parameters... );
 *   ex) #{cell_sample_name}.#{port.get_name}.#{func_1st.get_name}( parameters... );
 *-------------- end:   use sample ------------*/

EOT
                    break
                end
            end
        }

        file.print <<EOT
/*
 * C++ interface code
 *   This class comes from celltype '#{@celltype.get_name}'.
 */
class #{@celltype.get_global_name} {
EOT

        @celltype.get_port_list.each{ |port|
            if port.get_port_type == :ENTRY then
                sig = port.get_signature
                if port.get_array_size then
                    subsc_def = "int_t subscript_"
                    subsc_ini = "subscript(subscript_)"
                    delim = delim_ini
                else
                    subsc_def = ""
                    subsc_ini = ""
                    delim = ""
                end
                file.print <<EOT
    /* class for entry #{sig.get_global_name} #{port.get_name} */
    class #{port.get_name}_ : public #{sig.get_global_name}{
        public : 
        /* constructor: internal use only */
        #{port.get_name}_(#{idx_def}#{delim}#{subsc_def});
        /* destructor */
        // ~#{port.get_name}_();   unnecessary
    
        /* #{sig.get_name} functions */
EOT
                sig.get_function_head_array.each{ |fh|
                    file.print "        #{fh.get_return_type.get_type_str} #{fh.get_name}( "
                    delim =""
                    fh.get_paramlist.get_items.each{ |param|
                    file.print "#{delim}#{param.get_type.get_type_str} #{param.get_name}#{param.get_type.get_type_str_post}"
                        delim = ", "
                    }
                    file.print " );\n"
                }
                file.print <<EOT

EOT
                if ! @celltype.is_singleton? then
                    file.print <<EOT
        private:
        CPP_#{@celltype.get_global_name}_IDX cpp_idx;
EOT
                end
                # entry port array 
                if port.get_array_size then
                    file.print <<EOT
        private:
        int_t  subscript;
EOT
                end
                file.print "    };\n"
            end
            # entry port array 
            if port.get_array_size then
                file.print <<EOT
    class #{port.get_name}_EA{
        public : 
        /* constructor: internal use only */
        #{port.get_name}_EA(#{idx_def});
        /* destructor */
        // ~#{port.get_name}_();   unnecessary

        #{port.get_name}_ operator[]( int_t subscript ) const; 
EOT
                if ! @celltype.is_singleton? then
                    file.print <<EOT
        private:
        CPP_#{@celltype.get_global_name}_IDX cpp_idx;
EOT
                end
                file.print "    };\n"
            end
        }

        file.print <<EOT

    /*--------  begin public ----------*/
    public:
    /* constructor */
    #{@celltype.get_name}( #{idx_def} );
    /* destructor */
    // ~#{@celltype.get_name}();   unnecessary

EOT
        @celltype.get_port_list.each{ |port|
            if port.get_array_size then
                entry_array = "EA"
            else
                entry_array = ""
            end
            file.print <<EOT
    /* entry #{port.get_signature.get_global_name} #{port.get_name} */
    #{port.get_name}_#{entry_array} #{port.get_name}; 
EOT
        }
        file.print <<EOT
    /*--------  end public ----------*/
};
EOT

        file.print <<EOT

/*-------------- begin: implementation (I/F code only) ----------------*/
/* constructor  */
EOT
        file.print "inline    #{@celltype.get_global_name}::#{@celltype.get_global_name}(#{idx_def}) : "
        delim = ""
        @celltype.get_port_list.each{ |port|
            if port.get_port_type == :ENTRY then
                file.print "#{delim}#{port.get_name}(#{idx_})"
                delim = ", "
            end
        }
        file.print "{}\n\n"

        @celltype.get_port_list.each{ |port|
            if port.get_array_size then
                subsc_def = "int_t subscript_"
                subsc_ini = "subscript(subscript_)"
                if idx_ini == "" then
                    subsc_ini = ":" + subsc_ini
                end
                delim = delim_ini
            else
                subsc_def = ""
                subsc_ini = ""
                delim = ""
            end
            file.print <<EOT
/* ------------- entry port: #{port.get_name} ------------------*/
/* constructor: internal use only */
inline    #{@celltype.get_global_name}::#{port.get_name}_::#{port.get_name}_( #{idx_def}#{delim}#{subsc_def} ) #{idx_ini}#{delim}#{subsc_ini}{}

/* entry #{port.get_name} functions */
EOT
            port.get_signature.get_function_head_array.each{ |fh|
                if "#{@celltype.get_global_name}::#{port.get_name}_::#{fh.get_name}".length >= 32 then
                    cr ="\n"
                else
                    cr = ""
                end
                file.print "inline #{fh.get_return_type.get_type_str} #{@celltype.get_global_name}::#{port.get_name}_::#{fh.get_name}( "
                delim = ""
                fh.get_paramlist.get_items.each{ |param|
                    file.print "#{delim}#{param.get_type.get_type_str} #{param.get_name}#{param.get_type.get_type_str_post}"
                    delim = ", "
                }
                file.print " )#{cr}{ "
                if ! fh.get_return_type.kind_of?( VoidType ) then
                    file.print "return "
                end
                delim = delim_ini
                file.print "#{@celltype.get_global_name}_#{port.get_name}_#{fh.get_name}( #{idx2}"
                if port.get_array_size then
                    file.print "#{delim}subscript"
                    delim = ", "
                end
                fh.get_paramlist.get_items.each{ |param|
                    file.print "#{delim}#{param.get_name}"
                    delim = ", "
                }
                file.print " ); }\n#{cr}"
            }
            if port.get_array_size then
                file.print <<EOT
/* constructor for entry array (internal use only)*/
inline  #{@celltype.get_global_name}::#{port.get_name}_EA::#{port.get_name}_EA( #{idx_def} )#{idx_ini}{}
/* operator[] */
inline  #{@celltype.get_global_name}::#{port.get_name}_ #{@celltype.get_global_name}::#{port.get_name}_EA::operator[]( int_t subscript ) const
{
    /*
     * subscript is not checked here. No way to return error.
     */
    return #{@celltype.get_global_name}::#{port.get_name}_(#{cpp_idx}#{delim_ini}subscript);
};

EOT
            end
        }
        # undef macros
        @celltype.gen_ph_undef file
        file.print <<EOT
/*-------------- end: implementation (I/F code only) ----------------*/

#endif /* #{@celltype.get_global_name.upcase}_CPPIF_HPP */
EOT

        file.close
    end

    def gen_namespace_signature_header ns
        ns.get_signature_list.each{ |sig|
            file = CFile.open( "#{$gen}/#{sig.get_global_name}_cppif.hpp", "w" )
            file.print <<EOT
#ifndef #{sig.get_global_name.upcase}_CPPIF_HPP
#define #{sig.get_global_name.upcase}_CPPIF_HPP
/*
 * C++ interface code
 *   This class comes from signature '#{sig.get_name}#{CLASS_NAME_SUFFIX}'.
 *   All functions are pure virtual. These are defined in celltype class.
 */
 
 /* */
 class #{sig.get_global_name}#{CLASS_NAME_SUFFIX} {
    public:
EOT

            sig.get_function_head_array.each{ |fh|
                file.print "    virtual #{fh.get_return_type.get_type_str} #{fh.get_name}( "
                delim = ""
                fh.get_paramlist.get_items.each{ |param|
                    file.print "#{delim}#{param.get_type.get_type_str} #{param.get_name}#{param.get_type.get_type_str_post}"
                    delim = ", "
                }
                file.print " ) = 0;\n"
            }

            file.print <<EOT
};

#endif /* #{sig.get_global_name.upcase}_CPPIF_HPP */
EOT
            file.close
        }

        # 子ネームスペース
        ns.get_namespace_list.each{ |subns|
            gen_namespace_signature_header subns
        }
    end
end

