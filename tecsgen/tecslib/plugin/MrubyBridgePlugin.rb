# -*- coding: utf-8 -*-
#
#  mruby => TECS bridge
#  
#   Copyright (C) 2008-2015 by TOPPERS Project
#
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
#   $Id: MrubyBridgePlugin.rb 2638 2017-05-29 14:05:52Z okuma-top $
#

#== MrubyBridgePlugin クラス
class MrubyBridgePlugin < MultiPlugin
  def self.get_plugin superClass
    # case when (つまりは ===) では、期待したように一致しない模様
    if superClass == SignaturePlugin then
      dbgPrint "MrubyBridgePlugin: SignaturePlugin"
      require_tecsgen_lib 'tecslib/plugin/MrubyBridgeSignaturePlugin.rb'
      return MrubyBridgeSignaturePlugin
    elsif superClass == CelltypePlugin
      dbgPrint "MrubyBridgePlugin: CelltypePlugin"
      require_tecsgen_lib 'tecslib/plugin/MrubyBridgeCelltypePlugin.rb'
      return MrubyBridgeCelltypePlugin
    elsif superClass == CompositePlugin
      dbgPrint "MrubyBridgePlugin: CompositePlugin"
      require_tecsgen_lib 'tecslib/plugin/MrubyBridgeCompositePlugin.rb'
      return MrubyBridgeCompositePlugin
    elsif superClass == CellPlugin
      dbgPrint "MrubyBridgePlugin: CellPlugin"
      require_tecsgen_lib 'tecslib/plugin/MrubyBridgeCellPlugin.rb'
      return MrubyBridgeCellPlugin
    #elsif superClass == ThroughPlugin
    #  return ThroughPlugin
    #elsif superClass == DomainPlugin
    #  return DomainPlugin
    else
      dbgPrint "MrubyBridgePlugin: unsupported"
      return nil
    end
  end
end
