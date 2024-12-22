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
#   $Id: celltypeModule.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

module CelltypePluginModule
  #=== Celltype# セルタイププラグイン (generate 指定子)
  def celltype_plugin
    plugin_name = @generate[0]
    option = @generate[1]
    @generate[2] = apply_plugin( plugin_name, option )
  end

  #=== Celltype# セルタイププラグインをこのセルタイプに適用
  def apply_plugin( plugin_name, option )

    # plClass = load_plugin( plugin_name, CelltypePlugin )
    if kind_of? Celltype then
      plugin_class = CelltypePlugin
    elsif kind_of? CompositeCelltype then
      plugin_class = CompositePlugin
    else
      raise "unknown class #{self.class.name}"
    end
    
    plClass = load_plugin( plugin_name, plugin_class )
    return if plClass == nil
    if $verbose then
      print "new celltype plugin: plugin_object = #{plClass.class.name}.new( #{@name}, #{option} )\n"
    end

    begin
      plugin_object = plClass.new( self, option )
      @generate_list << [ plugin_name, option, plugin_object ]
      plugin_object.set_locale @locale
      generate_and_parse plugin_object
    rescue Exception => evar
      cdl_error( "S1023 $1: fail to new" , plugin_name )
      print_exception( evar )
    end

    # 既に存在するセルに new_cell を適用
    @cell_list.each{ |cell|
      apply_plugin_cell plugin_object, cell
    }

    return plugin_object
  end

  def apply_plugin_cell plugin, cell
    begin
      plugin.new_cell cell
    rescue Exception => evar
      cdl_error( "S1037 $1: celltype plugin fail to new_cell" , plugin.class.name )
      print_exception( evar )
    end
  end

  def celltype_plugin_new_cell cell
    @generate_list.each{ |generate|
      celltype_plugin = generate[2]
      begin
        celltype_plugin.new_cell cell
      rescue Exception => evar
        cdl_error( "S1037 $1: celltype plugin fail to new_cell" , celltype_plugin.class.name )
        print_exception( evar )
      end
    }
  end
end #CelltypePluginModule
