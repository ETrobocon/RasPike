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
#   $Id: namespacepath.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

#== 名前空間パス
class NamespacePath < Node
#@b_absolute::Bool
#@path::[ Symbol,... ]
#@namespace::Namespace:  @b_absolute == false のとき、基点となる namespace

  #=== NamespacePath# initialize
  #ident::Symbol           最初の名前, ただし "::" のみの場合は String
  #b_absolute:Bool         "::" で始まっている場合 true
  #namespace::Namespace    b_absolute = false かつ、構文解釈段階以外で呼び出す場合は、必ず指定すること 
  def initialize( ident, b_absolute, namespace = nil )
    super()

    if ident == "::" then   # RootNamespace
      @path = []
      @b_absolute = true
    else
      @path = [ ident ]
      @b_absolute = b_absolute
    end

    if namespace then
      @namespace = namespace
      if b_absolute == true then
        raise "NamespacePath#initialize: naamespace specified for absolute path"
      end
    else
      if b_absolute == false then
        @namespace = Namespace.get_current
      else
        @namespace = nil
      end
    end
  end

  #=== NamespacePath# append する
  #RETURN self
  # このメソッドは、元の NamespacePath オブジェクトを変形して返す
  def append!( ident )
    @path << ident
    return self
  end
  #=== NamespacePath# append する
  # このメソッドは、元の NamespacePath オブジェクトを変形しない
  #RETURN:: 複製した NamespacePath
  def append( ident )
    cl = self.clone
    cl.set_clone
    cl.append!( ident )
    return cl
  end

  def set_clone
    @path = @path.clone
  end

  def get_name
    @path[ @path.length - 1 ]
  end

  #=== NamespacePath#クローンを作成して名前を変更する
  def change_name name
    cl = self.clone
    cl.set_clone
    cl.change_name_no_clone name
    return cl
  end
  alias :change_name_clone :change_name

  #=== NamespacePath#名前を変更する
  # このインスタンスを参照するすべてに影響を与えることに注意
  def change_name_no_clone name
    @path[ @path.length - 1 ] = name
    nil
  end

  #=== NamespacePath:: path 文字列を得る
  # CDL 用の path 文字列を生成
  def to_s
    get_path_str
  end
  def get_path_str
    first = true
    if @b_absolute then
      path = "::"
    else
      path = ""
    end
    @path.each{ |n|
      if first then
        path = "#{path}#{n}"
        first = false
      else
        path += "::#{n}"
      end
    }
    return path
  end

  def is_absolute?
    @b_absolute
  end
  def is_name_only?
    @path.length == 1 && @b_absolute == false
  end

  #=== NamespacePath:: パスの配列を返す
  # is_absolute? true の場合、ルートからのパス
  #              false の場合、base_namespace からの相対
  # ルート namespace の場合、長さ０の配列を返す
  #
  def get_path
    @path
  end

  #=== NamespacePath#フルパスの配列を返す
  # 返された配列を書き換えてはならない
  def get_full_path
    if @b_absolute then
      return @path
    else
      return @namespace.get_namespace_path.get_full_path.clone + @path
    end
  end

  #=== NamespacePath:: 相対パスのベースとなる namespace
  # is_absolute? == false の時のみ有効な値を返す (true なら nil)
  def get_base_namespace
    @namespace
  end

  #=== NamespacePath:: C 言語グローバル名を得る
  def get_global_name
    if @b_absolute then
      global_name = ""
    else
      global_name = @namespace.get_global_name
    end

    @path.each{ |n|
      if global_name != "" then
        global_name = "#{global_name}_#{n}"
      else
        global_name = n.to_s
      end
    }
    global_name
  end

  #=== NamespacePath:: 分解して NamespacePath インスタンスを生成する
  #path_str:: String       : namespace または region のパス ex) "::path::A" , "::", "ident"
  #b_force_absolute:: Bool : "::" で始まっていない場合でも絶対パスに扱う
  #
  # NamespacePath は通常構文解析されて作成される
  # このメソッドは、オプションなどで指定される文字列を分解して NamespacePath を生成するのに用いる
  # チェックはゆるい。不適切なパス指定は、不適切な NamespacePath が生成される
  def self.analyze( path_str, b_force_absolute = false )

    if path_str == "::" then
      return self.new( "::", true )
    end

    pa = path_str.split( "::" )
    if pa[0] == "" then
      pa.shift
      b_absolute = true
    else
      if b_force_absolute then
        b_absolute = true
      else
        b_absolute = false
      end
    end

    if pa[0] then
      nsp = self.new( pa[0].to_sym, b_absolute )
    else
      nsp = self.new( "::", b_absolute )
    end
    pa.shift

    pa.each{ |a|
      if a then
        nsp.append! a.to_sym
      else
        nsp.append! "::"
      end
    }

    return nsp
  end

end

# 以下単体テストコード
if $unit_test then
  root_namespace = Namespace.new("::")

  puts( "===== Unit Test: NamespacePath ===== (componentobj.rb)")
  a = NamespacePath.new( :"ABC", true )
  printf( "Path: %-10s global_name: %s\n", a.get_path_str, a.get_global_name )

  a.append( :"DEF" )
  printf( "Path: %-10s global_name: %s\n", a.get_path_str, a.get_global_name )

  a = NamespacePath.new( :"abc", false )
  printf( "Path: %-10s global_name: %s\n", a.get_path_str, a.get_global_name )

  a.append( :"def" )
  printf( "Path: %-10s global_name: %s\n", a.get_path_str, a.get_global_name )

  puts ""
end
