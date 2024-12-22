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
#   $Id: generate.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

#== generate: signature, celltype, cell へのプラグインのロードと適用
class Generate < Node
#@plugin_name:: Symbol
#@object_nsp:: NamespacePath
#@option::         String '"', '"' で囲まれている
#@plugin_object:: Plugin

  include PluginModule

  def initialize( plugin_name, object_nsp, option )
    super()
    @plugin_name = plugin_name
    @object_nsp = object_nsp
    option = option.to_s    # option は Token
    @option = option
    @plugin_object = nil

    dbgPrint "generate: #{plugin_name} #{object_nsp.to_s} option=#{option}\n"

    object = Namespace.find( object_nsp )
    if object.kind_of?( Signature ) ||
       object.kind_of?( Celltype ) ||
       object.kind_of?( CompositeCelltype ) ||
       object.kind_of?( Cell )then
      @plugin_object = object.apply_plugin( @plugin_name, @option )
    elsif object then
      # V1.5.0 以前の仕様では、signature のみ可能だった
#      cdl_error( "S1149 $1 not signature" , signature_nsp )
      cdl_error( "S9999 generate: '$1' neither signature, celltype nor cell", object_nsp )
      return
    else
      cdl_error( "S9999 generate: signature '$1' not found", object_nsp )
    end
  end
end
