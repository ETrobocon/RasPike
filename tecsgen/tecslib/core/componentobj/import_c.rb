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
#   $Id: import_c.rb 3269 2023-07-26 00:02:52Z okuma-top $
#++

class Import_C < Node

  # ヘッダの名前文字列のリスト
  @@header_list = {}
  @@header_list2 = []
  @@define_list = {}

  include Importable

  #=== Import_C# import_C の生成（ヘッダファイルを取込む）
  #header:: Token : import_C の第一引数文字列リテラルトークン
  #define:: Token : import_C の第二引数文字列リテラルトークン
  def initialize( header, define = nil )
    super()
    # ヘッダファイル名文字列から前後の "" を取り除く
    # header = header.to_s.gsub( /\A"(.*)"\z/, '\1' )
    header = CDLString.remove_dquote header.to_s

    if define then
      # 前後の "" を取り除く
      # def_opt = define.to_s.gsub( /\A"(.*)/, '\1' )
      # def_opt.sub!( /(.*)"\z/, '\1' )
      def_opt = CDLString.remove_dquote define.to_s

      # "," を -D に置き換え
      def_opt = def_opt.gsub( /,/, " -D " )

      # 先頭に -D を挿入 # mikan 不適切な define 入力があった場合、CPP 時にエラー
      def_opt = def_opt.gsub( /^/, "-D " )

    end

    # コマンドライン指定された DEFINE 
    $define.each{ |define|
      if $IN_EXERB then
        q = ""
      else
        if define =~ /'/ then
          q = '"'
        else
          q = "'"
        end
      end
      def_opt = "#{def_opt} -D #{q}#{define}#{q}"
    }

    header_path = find_file header

=begin
    include_opt = ""
    found = false
    header_path = ""
    $import_path.each{ |path|
      include_opt = "#{include_opt} -I #{path}"
      if found == false then
        begin
          # ファイルの stat を取ってみる(なければ例外発生)
          File.stat( "#{path}/#{header}" )

          # cdl を見つかったファイルパスに再設定
          header_path = "#{path}/#{header}"
          found = true
        rescue => evar
          found = false
          # print_exception( evar )
        end
      end
    }

    if found == false then
=end
    if header_path == nil then
      cdl_error( "S1142 $1 not found in search path" , header )
      return
    end

    include_opt = ""
    if get_base_dir then
      base = get_base_dir + "/"
    else
      base = ""
    end
    $import_path.each{ |path|
      include_opt = "#{include_opt} -I #{base}#{path}"
    }

    # 読込み済み？
    if( @@header_list[ header ] ) then
      # 第二引数 define が以前と異なる
      if @@define_list[ header ].to_s != define.to_s then
        cdl_error( "S1143 import_C: arg2: mismatch with previous one"  )
      end
      # いずれにせよ読み込まない
      return
    end

    # ヘッダのリストを記録
    @@header_list[ header ] = header_path
    @@header_list2 << header
    @@define_list[ header ] = define

    if $verbose then
      print "import_C header=#{header_path}, define=#{define}\n"
    end

    begin
      tmp_C = "#{$gen}/tmp_C_src.c"
      file = File.open( tmp_C, "w" )
    rescue => evar
      cdl_error( "S1144 $1: temporary C source: open error" , tmp_C )
      print_exception( evar )
    end

    begin
      print_defines file

      file.print( "#include \"#{header}\"\n" )
    rescue => evar
      cdl_error( "S1145 $1: temporary C source: writing error" , tmp_C )
      print_exception( evar )
    ensure
      file.close
    end

    # CPP 出力用 tmp ファイル名
    tmp_header = header.gsub( /\//, "_" )
    tmp_header = "#{$gen}/tmp_#{tmp_header}"

    # CPP コマンドラインを作成
    cmd = "#{$cpp} #{def_opt} #{include_opt} #{tmp_C}"

    begin
      if( $verbose )then
        puts "CPP: #{cmd}"
      end

      # プリプロセッサコマンドを pipe として開く
          # cmd は cygwin/Linux では bash(sh) 経由で実行される
          # Exerb 版では cmd.exe 経由で実行される
          # この差は引き数の (), $, % などシェルの特別な文字の評価に現れるので注意
          cpp = IO.popen( cmd, "r:ASCII-8BIT" )
      begin
        tmp_file = nil
        tmp_file = File.open( tmp_header, "w:ASCII-8BIT" )
        cpp.each { |line|
          line = line.gsub( /^#(.*)$/, '/* \1 */' )
          tmp_file.puts( line )
        }
      rescue => evar
        cdl_error( "S1146 $1: error occured while CPP （C-PreProcessor）, check C-compiler path or command line ooptions" , header )
        print_exception( evar )
      ensure
        tmp_file.close if tmp_file    # mikan File.open に失敗した時 tmp_file == nil は保証されている ?
        cpp.close
      end
    rescue => evar
      cdl_error( "S1147 $1: popen for CPP（C-PreProcessor） failed, check C-compiler path or command line ooptions" , header )
      print_exception( evar )
    end

    # C 言語のパーサインスタンスを生成
    c_parser = C_parser.new

    # tmp_header をパース
    c_parser.parse( [tmp_header] )

    # 終期化　パーサスタックを戻す
    c_parser.finalize

  end

  def print_defines file
    if ! $b_no_gcc_extension_support then
      
    file.print <<EOT

#ifndef TECS_NO_GCC_EXTENSION_SUPPORT

/*
 * these extension can be eliminated also by spefcifying option
 * --no-gcc-extension-support for tecsgen.
 */
#ifdef __GNUC__

#ifndef __attribute__
#define __attribute__(x)
#endif

#ifndef __extension__
#define __extension__
#endif

#ifndef __builtin_va_list
#define __builtin_va_list va_list
#endif

#if 0
#ifndef __asm__
#define __asm__(x)
#endif
#endif /* 0 */

#ifndef restrict
#define restrict
#endif

#endif /* ifdef __GNUC__ */
#endif /* TECS_NO_GCC_EXTENSION_SUPPORT */
EOT
    end

    file.print <<EOT
#ifndef NO_TECSGEN_VA_LIST
/* va_list is not supported in C_parser.y.rb */
typedef struct { int dummy; } va_list;
#endif /* NO_TECSGEN_VA_LIST */

EOT
  end

  def self.get_header_list
    @@header_list
  end
  def self.get_header_list2
    @@header_list2
  end

end
