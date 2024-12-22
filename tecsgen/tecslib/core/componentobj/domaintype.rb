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
#   $Id: domaintype.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

#== DomainType
#
# region の domain を記憶するクラス
class DomainType < Node
#@name::Symbol : ドメインタイプの名前 ex) HRP2, HRP
#@region::Region
#@plugin_name::Symbol : ex) HRP2Plugin
#@option::String : ex) (HRP2) "trusted", "nontrusted", (HRP3) :kernel, :user, :OutOfDomain
#@plugin::DomainPlugin の子クラス
#@node_root::Region : node_root となるリージョン

  include PluginModule

  # ドメインに属する region の Hash
  # domain 指定が一度も行われない場合、このリストは空である
  # ルートリージョンは option = "OutOfDomain" で登録される (domain 指定が無ければ登録されない)
  @@domain_regions = { }  # { node_root => { :domain_type => [ region, ... ] } }

  def initialize( region, name, option, node_root )
    super()
    @name = name
    @plugin_name = (name.to_s + "Plugin").to_sym
    @pluginClass = load_plugin( @plugin_name, DomainPlugin )
    @region = region
    @option = option
    @plugin = nil
    @node_root = node_root

    if ! @@domain_regions[ node_root ] then
      @@domain_regions[ node_root ] = {}
    end
    if @@domain_regions[ node_root ][ name ] then
      if ! @@domain_regions[ node_root ][ name ].include?( region ) then
        @@domain_regions[ node_root ][ name ] << region
      end
    else
      @@domain_regions[ node_root ][ name ] = [ region ]
    end
  end

  def create_domain_plugin
    if ! @plugin then
      # pluginClass = Object.const_get @plugin_name  # not incompatible with MultiPlugin
      dbgPrint "create_domain_plugin: plugin_name=#{@plugin_name} class=#{@pluginClass.name} region=#{@region.get_name} option=#{@option}\n"
      return if @pluginClass == nil
      @plugin = @pluginClass.new( @region, @name, @option )
      @plugin.set_locale @locale
      # p "*** plugin_name=#{@plugin_name} plugin=#{@plugin} DomainType=#{self}"
    end
  end

  def add_through_plugin( join, from_region, to_region, through_type )
    # print( "DOMAIN: add_through_plugin: from=#{from_region.get_name}#{join.get_owner.get_name}.#{join.get_name} to=#{to_region}#{join.get_cell.get_name}.#{join.get_port_name} through_type=#{through_type}\n" )
    return @plugin.add_through_plugin( join, from_region, to_region, through_type )
  end

  def joinable?( from_region, to_region, through_type )
    # print( "DOMAIN: joinable? from_region=#{from_region.get_name} to_region=#{to_region} through_type=#{through_type}\n" )
    return @plugin.joinable?( from_region, to_region, through_type )
  end

  def get_name
    @name
  end

  #== DomainType リージョンの Hash を得る
  # @@domain_regions の説明参照
  def self.get_domain_regions node_root
    if ! @@domain_regions[ node_root ] then
      return {}
    else
      return @@domain_regions[ node_root ]
    end
  end

  def get_regions node_root
    return @@domain_regions[ node_root ][ @name ]
  end

  def get_option
    @option
  end

  #== DomainType#ドメイン種別を得る
  #return::Symbol :kernel, :user, :OutOfDomain
  def get_kind
    dbgPrint "DomainType#get_kind plugin_name=#{@plugin_name} plugin=#{@plugin} DomainType=#{self}\n"
    if @plugin then
      @plugin.get_kind
    else
      # domain 指定されていないケース
      :OutOfDomain
    end
  end

  def show_tree( indent )
    (indent+1).times { print( "  " ) }
    puts "domain: name=#{@name} plugin=#{@plugin_name} option=#{@option}"
  end
end
