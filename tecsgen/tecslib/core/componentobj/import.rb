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
#   $Id: import.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

class Import < Node
# @b_reuse::bool:       再利用．セルタイプの template 生成不要
# @b_reuse_real::bool:  実際に再利用
# @cdl::      string:   import する CDL
# @cdl_path:: string:   CDL のパス
# @b_imported:: bool:   import された(コマンドライン指定されていない)

  include Importable

  # ヘッダの名前文字列のリスト  添字：expand したパス、値：Import
  @@import_list = {}

  @@nest_stack_index = -1
  @@nest_stack = []
  @@current_object = nil

  def self.push object
    @@nest_stack_index += 1
    @@nest_stack[ @@nest_stack_index ] = @@current_object
    @@current_object = object
  end

  def self.pop
    @@current_object = @@nest_stack[ @@nest_stack_index ]
    @@nest_stack_index -= 1
    if @@nest_stack_index < -1 then
      raise "TooManyRestore"
    end
  end

  #=== Import# import を行う
  #cdl::      string   cdl へのパス．"" で囲まれていることを仮定
  #b_reuse::  bool     true: template を生成しない
  def initialize( cdl, b_reuse = false, b_imported = true )
    Import.push self
    @b_imported = b_imported
    super()
    @@current_import = self
    # ヘッダファイル名文字列から前後の "", <> を取り除くn
    @cdl = cdl.to_s.gsub( /\A["<](.*)[">]\z/, '\1' )

    # サーチパスから探す
    found = false
    @cdl_path = ""

    @b_reuse = b_reuse
    @b_reuse_real = @b_reuse || Generator.is_reuse?

    if( Generator.get_plugin ) &&( File.exist? "#{$gen}/#{@cdl}" ) then
      @cdl_path = "#{$gen}/#{@cdl}"
      found = true
    else
      path = find_file @cdl
      if path then
        found = true
        @cdl_path = path
      end
    end

    if found == false then
      cdl_error( "S1148 $1 not found in search path" , @cdl )
      return
    end

    # 読込み済みなら、読込まない
    prev = @@import_list[ File.expand_path( @cdl_path ) ]
    if( prev ) then
      if prev.is_reuse_real? != @b_reuse_real then
        cdl_warning( "W1008 $1: reuse designation mismatch with previous import" , @cdl )
      end
      return
    end

    # import リストを記録
    @@import_list[ File.expand_path( @cdl_path ) ] = self

    # plugin から import されている場合
    plugin = Generator.get_plugin

    # パーサインスタンスを生成(別パーサで読み込む)
    parser = Generator.new

    # plugin から import されている場合の plugin 設定
    parser.set_plugin plugin

    # reuse フラグを設定
    parser.set_reuse @b_reuse_real

    # cdl をパース
    parser.parse( [@cdl_path] )

    # 終期化　パーサスタックを戻す
    parser.finalize
    Import.pop
  end

  def self.get_list
    @@import_list
  end

  def get_cdl_path
    @cdl_path
  end

  def is_reuse_real?
    @b_reuse_real
  end

  def self.get_current
    @@current_object
  end

  def is_imported?
    @b_imported
  end

  #=== cdl の名前を返す
  # 引数で指定されている cdl 名。一部パスを含む可能性がある
  def get_cdl_name
    @cdl
  end
end
