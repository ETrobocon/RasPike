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
#   $Id: classtype.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

#== ClassType
#
# region の class を記憶するクラス
class ClassType < Node
#@name::Symbol : クラスタイプの名前 ex) FMP, HRMP
#@region::Region
#@plugin_name::Symbol : ex) FMPPlugin
#@option::String : クラス名 | :global (OutOfClass)
#@plugin::ClassPlugin の子クラス
#@node_root::Region : node_root となるリージョン

  include PluginModule

  # ドメインに属する region の Hash
  # class 指定が一度も行われない場合、このリストは空である
  # ルートリージョンは option = "OutOfClass" で登録される (class 指定が無ければ登録されない)
  @@class_regions = { }  # {:node_root => { :class_type => [ region, ... ] } }

  def initialize( region, name, option, node_root )
    super()
    dbgPrint "ClassType.new: region=#{region.get_name} class_name=#{name} option=#{option} node_root=#{node_root.get_name}\n"
    @name = name
    @plugin_name = (name.to_s + "Plugin").to_sym
    @pluginClass = load_plugin( @plugin_name, ClassPlugin )
    @region = region
    @option = option
    @node_root = node_root

    if @@class_regions[ node_root ] == nil then
      @@class_regions[ node_root ] = {}
    end

    if @@class_regions[ node_root ][ name ] then
      if ! @@class_regions[ node_root ][ name ].include?( region ) then
        @@class_regions[ node_root ][ name ] << region
      end
    else
      @@class_regions[ node_root ][ name ] = [ region ]
    end
  end

  def create_class_plugin
    if ! @plugin then
      dbgPrint "create_class_plugin region=#{@region.get_name} name=#{@name} option=#{@option}\n"
      # pluginClass = Object.const_get @plugin_name  # not incompatible with MultiPlugin
      return if @pluginClass == nil
      @plugin = @pluginClass.new( @region, @name, @option )
      @plugin.set_locale @locale
    end
  end

  def add_through_plugin( join, from_region, to_region, through_type )
    # print( "CLASS: add_through_plugin: from=#{from_region.get_name}#{join.get_owner.get_name}.#{join.get_name} to=#{to_region}#{join.get_cell.get_name}.#{join.get_port_name} through_type=#{through_type}\n" )
    return @plugin.add_through_plugin( join, from_region, to_region, through_type )
  end

  def joinable?( from_region, to_region, through_type )
    dbgPrint( "ClassType.joinable?: from_region=#{from_region.get_name} to_region=#{to_region} through_type=#{through_type}\n" )
    return @plugin.joinable?( from_region, to_region, through_type )
  end

  def check_class( class_name )
    dbgPrint "ClassType#check_class class_name=#{class_name}\n"
    if @plugin == nil || @plugin.check_class( class_name )== false then
      cdl_error( "S9999 '$1': invalide class name", class_name)
    end
  end

  def get_name
    @name
  end

  def get_plugin
    @plugin
  end

  #== ClassType リージョンの Hash を得る
  # @@class_regions の説明参照
  def self.get_class_regions node_root
    if @@class_regions[node_root] then
      return @@class_regions[node_root]
    else
      return {}
    end
  end

  def get_regions node_root
    return @@class_regions[ node_root ][ @name ]
  end

  def get_option
    dbgPrint "ClassType: get_option: #{@option}\n"
    return @option
  end

  #== ClassType#ドメイン種別を得る
  def get_kind
    dbgPrint "ClassType#get_kind plugin_name=#{@plugin_name} plugin=#{@plugin} DomainType=#{self}\n"
    @plugin.get_kind
  end

  def show_tree( indent )
    (indent+1).times { print( "  " ) }
    puts "class: name=#{@name} plugin=#{@plugin_name} option=#{@option}"
  end
end

