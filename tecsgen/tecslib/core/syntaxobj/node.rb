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
#   $Id: node.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

#== Node
#
# Node の直接の子クラス： C_EXP, Type, BaseVal, BDNode(ほとんどのものは BDNode の子クラス)
# Node に (BDNodeにも) 入らないもの: Token, Import, Import_C, Generate
#
# owner を持たないものが Node となる
# エラーは、cdl_error を通じて報告する (意味解析が構文解析後に行われる場合には、行番号が正しく出力できる
# 

class Node
#@locale::    [@file, @lineno, @col]

  def initialize
    @locale = Generator.current_locale
  end

  #=== エラーを出力する
  def cdl_error( message, *arg )
    Generator.error2( @locale, message, *arg )
  end

  #=== エラーを出力する
  #locale:: Array(locale info) : 構文解析中は無視される
  def cdl_error2( locale, message, *arg )
    Generator.error2( locale, message, *arg )
  end

  #=== エラーを出力する
  #locale:: Array(locale info)
  # 構文解析中 cdl_error2 では locale が無視されるため、別に locale を出力する
  def cdl_error3( locale, message, *arg )
    Generator.error(  message, *arg )
    Console.puts "check: #{locale[0]}: line #{locale[1]} for above error"
  end

  #=== ウォーニング出力する
  def cdl_warning( message, *arg )
    Generator.warning2( @locale, message, *arg )
  end

  #=== ウォーニング出力する
  def cdl_warning2( locale, message, *arg )
    Generator.warning2( locale, message, *arg )
  end

  #=== 情報を表示する
  def cdl_info( message, *arg )
    Generator.info2( @locale, message, *arg )
  end

  #=== 情報を表示する
  def cdl_info2( locale, message, *arg )
    Generator.info2( locale, message, *arg )
  end

  def get_locale
    @locale
  end

  def set_locale locale
    @locale = locale
  end

  def locale_str
    if @locale then
      "locale=(#{@locale[0]}, #{@locale[1]})"
    else
      "locale=(?)"
    end
  end
end

#== 双方向 Node (Bi Direction Node)
#
#  Node の子クラス
#  owner Node から参照されているもの (owner へのリンクも取り出せる)
#
#  get_owner で得られるもの
#    FuncHead => Signature
#    Decl => Namespace(const), Typedef(typedef),
#            Celltype, CompositeCelltype(attr,var)
#            Struct(member), ParamDecl(parameter), FuncHead(funchead)
#    Signature, Celltype, CompositeCelltype, Typedef => Namespace
#,   Namespace => Namespace, Generator.class (root Namespace の場合)
#    Cell => Region, CompositeCelltype(in_composite)
#    Port => Celltype, Composite
#    Factory => Celltype
#    Join => Cell
#    CompositeCelltypeJoin => CompositeCelltype
#    Region => Region, 
#    ParamDecl => ParamList
#    ParamList => FuncHead
#    Expression => Namespace
#    大半のものは new_* メソッドで owner Node に伝達される
#    そのメソッドが呼び出されたときに owner Node が記録される
#    new_* がないもの：
#            Decl(parameter), ParamDecl, ParamList, FuncHead, Expression 
#
#    Expression は、owner Node となるものが多くあるが、改造が困難であるため
#    Expression が定義されたときの Namespace を owner Node とする
#    StructType は Type の一種なので owner を持たない
#
class BDNode < Node
#@owner::Node
#@NamespacePath:: NamespacePath
#@Generator::
#@import::Import :  

  def initialize
    super
    @owner = nil
    @NamespacePath = nil
    @import = Import.get_current

  end

  #=== owner を設定する
  def set_owner owner
    dbgPrint "set_owner: #{owner.class.name}\n"
    @owner = owner
  end

  #=== owner を得る
  # class の説明を参照
  def get_owner
    if @owner == nil
      raise "Node have no owner #{self.class.name} #{get_name}"
    end
    @owner
  end
end

#== Namespace 名を持つ BDNode
# Namespace(Region), Signature, Celltype, CompositeCelltype, Cell
class NSBDNode < BDNode

  def initialize
    super
  end

  #=== 属する namespace を得る
  # owner を namespace にたどり着くまで上にたどる
  def get_namespace
    if @owner.kind_of? Namespace
      return @owner
    elsif @owner != nil then
      return @owner.get_namespace
    else
      # @owner == nil なら "::"
      if @name != "::" then
        raise "non-root namespace has no owner #{self.class.name}##{@name} #{self}"
      end
      return nil
    end
  end

  def set_namespace_path
    ns = get_namespace
    if ns then
      @NamespacePath = ns.get_namespace_path.append( get_name )
    else
      raise "get_namespace_path: no namespace found"
    end
  end

  #=== NamespacePath を得る
  def get_namespace_path
    return @NamespacePath
  end

  def is_imported?
    if @import then
      return @import.is_imported?
    else
      return false    # mikan: 仮 @import が nil になるケースが追求できていない
    end
  end
end
