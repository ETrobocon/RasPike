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
#   $Id: namespace.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

#== Namespace
#
# root namespace だけ、Region クラスのインスタンスとして生成される
# root namespace は、root region を兼ねるため
#
# @cell_list は Region の場合にのみ持つ (mikan @cell_list 関連は Region に移すべき)
#
class Namespace < NSBDNode
# @name::  Symbol     # root の場合 "::" (String)
# @global_name:: str
# @name_list:: NamedList   Signature,Celltype,CompositeCelltype,Cell,Typedef,Namespace
# @struct_tag_list:: NamedList : StructType
# @namespace_list:: Namespace[] : Region は Namespace の子クラスであり、含まれる
# @signature_list:: Sginature[]
# @celltype_list:: Celltype[]
# @compositecelltype_list:: CompositeCelltype[]
# @cell_list:: Cell[]
# @typedef_list:: Typedef[]
# @decl_list:: ( Typedef | StructType | EnumType )[]   依存関係がある場合に備えて、順番どおりに配列に格納 mikan enum
# @const_decl_list:: Decl[]
# @cache_n_cells:: Integer :  get_n_cells の結果をキャッシュする
# @cache_generating_region:: Region :  get_n_cells の結果をキャッシュするしているリージョン

  # mikan namespace の push, pop

  # namespace 階層用のスタック
  @@namespace_stack = []      # @@namespace_stack[0] = "::" (generator.rb)
  @@namespace_sp = -1

  # Generator ネスト用のスタック (namespace 階層用のスタックを対比する)
  @@nest_stack_index = -1
  @@nest_stack = []

  @@root_namespace = nil

  # Generator ネスト用スタックの push, pop (クラスメソッド)
  def self.push
    dbgPrint "push Namespace\n"
    @@nest_stack_index += 1
    @@nest_stack[ @@nest_stack_index ] = [ @@namespace_stack, @@namespace_sp ]
    if @@root_namespace then
      @@namespace_sp = 0
      @@namespace_stack[ @@namespace_sp ] = @@root_namespace
    end
  end

  def self.pop
    dbgPrint "pop Namespace\n"
    @@namespace_stack, @@namespace_sp = @@nest_stack[ @@nest_stack_index ]
    @@nest_stack_index -= 1
    if @@nest_stack_index < -1 then
      raise "TooManyRestore"
    end
  end

  # namespace 階層用スタックの push, pop (インスタンスメソッド)
  def push ns
    @@namespace_sp += 1
    @@namespace_stack[ @@namespace_sp ] = self
    dbgPrint "Namespace.PUSH #{@@namespace_sp} #{@name}\n"
  end

  def pop
    dbgPrint "Namespace.POP #{@@namespace_sp} #{@name}\n"
    @@namespace_sp -= 1
    if @@namespace_sp < 0 then
      raise "StackUnderflow"
    end
  end

  def initialize( name )

    dbgPrint "Namespace: initialize name=#{name} sp=#{@@namespace_sp} **\n"
    super()
    @name = name

    if( name == "::" )then
      if( @@root_namespace != nil )then
        # root は一回のみ生成できる
        raise "try to re-create root namespace"
      end
      @@root_namespace = self
      @NamespacePath = NamespacePath.new( name, true )
    else
      ns = @@namespace_stack[ @@namespace_sp ].find( name )
      if ns.kind_of? Namespace then
        dbgPrint "namespace: re-appear #{@name}\n"
        # 登録済み namespace の再登録
        set_owner @@namespace_stack[ @@namespace_sp ]
        ns.push ns
        return
      elsif ns then
        cdl_error( "S1151 $1: not namespace", @name )
        prev_locale = ns.get_locale
        puts "previous: #{prev_locale[0]}: line #{prev_locale[1]} \'#{name}\' defined here"
      end
      dbgPrint "namespace: 1st-appear #{@name}\n"
    end

    dbgPrint "Namespace: initialize name=#{name} sp=#{@@namespace_sp}\n"
    if @@namespace_sp >= 0 then   # root は除外
      dbgPrint "Namespace: initialize2 name=#{name} sp=#{@@namespace_sp}\n"
      @@namespace_stack[@@namespace_sp].new_namespace( self )
    end
    push self

    @global_name = Namespace.get_global_name    # stack 登録後取る
    @name_list = NamedList.new( nil, "symbol in namespace '#{@name}'" )
    @struct_tag_list = NamedList.new( nil, "struct tag" )

    @namespace_list = []
    @signature_list = []
    @celltype_list = []
    @compositecelltype_list = []
    @cell_list = []
    @typedef_list = []
    @decl_list = []
    @const_decl_list = []
    @cache_n_cells = nil
    @cache_generating_region = nil
    if @NamespacePath == nil then
      # root namespace の場合は設定済 (親 namespace が見つからず例外になる)
      set_namespace_path # @NamespacePath の設定
    end
  end

  def end_of_parse
    pop
  end

  def get_name
    @name
  end

  #=== Namespace:: global_name を得る
  # parse 中のみこのメソッドは使える
  # STAGE: P
  def self.get_global_name    # parse 中有効
    if @@namespace_sp <= 0 then
      return ""
    end

    path = @@namespace_stack[1].get_name.to_s
    i = 2
    while i <= @@namespace_sp
      path = path+"_"+@@namespace_stack[i].get_name.to_s
      i += 1
    end

    path
  end

  def get_global_name
    @global_name
  end

  #=== Namespace#セルの個数を得る
  # 子 region が linkunit, node 指定されていれば、含めない（別のリンク単位）
  # プロトタイプ宣言のもののみの個数を含めない
  # mikan namespace 下に cell を置けない仕様になると、このメソッドは Region のものでよい
  # mikan 上記の場合 instance_of? Namespace の条件判定は不要となる
  def get_n_cells
    if @cache_generating_region == $generating_region then
      # このメソッドは繰り返し呼び出されるため、結果をキャッシュする
      return @cache_n_cells
    end

    count = 0
    @cell_list.each{ |c|
      # 定義かプロトタイプ宣言だけかは、new_cell の段階で判断できないため、カウントしなおす
      if c.get_f_def == true then
        # print "get_n_cells: cell: #{c.get_name}\n"
        count += 1
      end
    }

    @namespace_list.each{ |ns|
      if ns.instance_of? Namespace then
        count += ns.get_n_cells
      else
        # ns は Region である
        rt = ns.get_region_type
        # print "get_n_cells: region: #{ns.get_name}: #{rt}\n"
        if rt == :NODE || rt == :LINKUNIT then
          # 別の linkunit なので加算しない
        else
          count += ns.get_n_cells
        end
      end
    }

    @cache_generating_region = $generating_region
    @cache_n_cells = count
    return count
  end

  #=== Namespace.find : in_path で示されるオブジェクトを探す
  #in_path:: NamespacePath
  #in_path:: Array : 古い形式
  #  path [ "::", "ns1", "ns2" ]   absolute
  #  path [ "ns1", "ns2" ]         relative
  def self.find( in_path )

    if in_path.instance_of? Array then
      # raise "Namespace.find: old fashion"

      path = in_path
      length = path.length
      return self.find_one( path[0] ) if length == 1

      name = path[0]
      if name == "::" then
        i = 1
        name = path[i]   # 構文的に必ず存在
        object = @@root_namespace.find( name )  # root
      else
        # 相対パス
        i = 0
        object = @@namespace_stack[@@namespace_sp].find_one( name ) # crrent
      end

    elsif in_path.instance_of? NamespacePath then
      path = in_path.get_path
      length = path.length

      if length == 0 then
        if in_path.is_absolute? then
          return @@root_namespace
        else
          raise "path length 0, not absolute"
        end
      end

      i = 0
      name = path[0]
      if in_path.is_absolute? then
        object = @@root_namespace.find( name )  # root
      else
        bns = in_path.get_base_namespace
        object = bns.find_one( name )           # crrent
      end
    else
      raise "unexpected path"
    end

    i += 1
    while i < length

      unless object.kind_of?( Namespace ) then
        # クラスメソッド内で cdl_error を呼び出すことはできない
        # また、前方参照対応後、正確な行番号が出ない問題も生じる
        # cdl_error( "S1092 \'$1\' not namespace" , name )
        # このメソッドから nil が帰った場合 "not found" が出るので、ここでは出さない
        return nil
      end

      object = object.find( path[i] )
      i += 1
    end

    return object
  end


  def find( name )
    @name_list.get_item(name)
  end

  #=== Namespace# namespace から探す。見つからなければ親 namespace から探す
  def self.find_one( name )
    return @@namespace_stack[@@namespace_sp].find_one( name )
  end

  def find_one( name )

    object = find( name )
    # これは出すぎ
    # dbgPrint "in '#{@name}' find '#{name}' object #{object ? object.class : "Not found"}\n"

    if object != nil then
      return object
    elsif @name != "::" then
      return @owner.find_one( name )
    else
      return nil
    end
  end

  def self.get_current
    @@namespace_stack[@@namespace_sp]
  end

  def self.find_tag( name )
    # mikan tag : namespace の path に対応しない
    # namespace の中にあっても、root namespace にあるものと見なされる
    # よって カレント namespace から根に向かって探す
    i = @@namespace_sp
    while i >= 0
      res = @@namespace_stack[i].find_tag( name )
      if res then
        return res
      end
      i -= 1
    end
  end

  def find_tag( name )
    @struct_tag_list.get_item( name )
  end

 ### namespace
  def self.new_namespace( namespace )
    @@namespace_stack[@@namespace_sp].new_namespace( namespace )
  end

  def new_namespace( namespace )
    dbgPrint "new_namespace: #{@name}:#{self} #{namespace.get_name}:#{namespace} \n"
    namespace.set_owner self   # Namespace (Namespace)

    @name_list.add_item( namespace )
    @namespace_list << namespace
  end

 ### signature
  def self.new_signature( signature )
    @@namespace_stack[@@namespace_sp].new_signature( signature )
  end

  def new_signature( signature )
    signature.set_owner self   # Signature (Namespace)
    @name_list.add_item( signature )
    @signature_list << signature
  end

 ### celltype
  def self.new_celltype( celltype )
    @@namespace_stack[@@namespace_sp].new_celltype( celltype )
  end

  def new_celltype( celltype )
    celltype.set_owner self   # Celltype (Namespace)
    @name_list.add_item( celltype )
    @celltype_list << celltype
  end

 ### compositecelltype
  def self.new_compositecelltype( compositecelltype )
    @@namespace_stack[@@namespace_sp].new_compositecelltype( compositecelltype )
  end

  def new_compositecelltype( compositecelltype )
    compositecelltype.set_owner self   # CompositeCelltype (Namespace)
    @name_list.add_item( compositecelltype )
    @compositecelltype_list << compositecelltype
  end

 ### cell (Namespace)
  def self.new_cell( cell )
    @@namespace_stack[@@namespace_sp].new_cell( cell )
  end

  def new_cell( cell )
    dbgPrint "Namespace.new_cell: #{@NamespacePath.get_path_str}::#{cell.get_name}\n"
    if ! is_root? && ! ( instance_of? Region ) then
      cdl_error( "S9999 '$1' cell cannot be placed under namespace", cell.get_name )
    end
    cell.set_owner self   # Cell (Namespace)
    @name_list.add_item( cell )
    @cell_list << cell
  end

  #=== Namespace# 参照されているが、未定義のセルを探す
  # プロトタイプ宣言だけで定義されていないケースをエラーとする
  # 受動の未結合セルについて警告する
  def check_ref_but_undef
    @cell_list.each { |c|
      if ! c.get_f_def then   # Namespace の @cell_list にはプロトタイプが含まれるケースあり
        if c.get_f_ref then
          c.cdl_error( "S1093 $1 : undefined cell" , c.get_namespace_path.get_path_str )
        elsif $verbose then
          c.cdl_warning( "W1006 $1 : only prototype, unused and undefined cell" , c.get_namespace_path.get_path_str )
        end
      else
        dbgPrint "check_ref_but_undef: #{c.get_global_name}\n"
        ct = c.get_celltype
        # if c.get_f_ref == false && c.is_generate? && ct && ct.is_inactive? then
        if c.get_f_ref == false && ct && ct.is_inactive? then
          c.cdl_warning( "W1007 $1 : non-active cell has no entry join and no factory" , c.get_namespace_path.get_path_str )
        end
        if c.has_ineffective_restrict_specifier then
          c.cdl_warning( "W9999: $1 has ineffective restrict specifier", c.get_namespace_path.get_path_str )
        end
      end
    }
    @namespace_list.each { |n|
      n.check_ref_but_undef
    }
  end

  #=== Namespace# セルの受け口の参照カウントを設定する
  def set_port_reference_count
    @cell_list.each { |c|
      c.set_port_reference_count
    }
    @namespace_list.each { |n|
      n.set_port_reference_count
    }
  end

 ### struct
  def self.new_structtype( struct )
    @@namespace_stack[@@namespace_sp].new_structtype( struct )
  end

  def new_structtype( struct )
    # struct.set_owner self   # StructType (Namespace) # StructType は BDNode ではない
    dup = @struct_tag_list.get_item(struct.get_name)
    if dup != nil then
      if struct.same? dup then
        # 同じものが typedef された
        # p "#{struct.get_name}"
        return
      end
    end

    @struct_tag_list.add_item( struct )
    @decl_list << struct
  end

 ### typedef
  def self.new_typedef( typedef )
    @@namespace_stack[@@namespace_sp].new_typedef( typedef )
  end

  def new_typedef( typedef )
    typedef.set_owner self   # TypeDef (Namespace)
    dup = @name_list.get_item(typedef.get_name)
    if dup != nil then
      typedef_type = typedef.get_declarator.get_type.get_original_type
      dup_type = dup.get_declarator.get_type.get_original_type
      # print "typedef: #{typedef.get_name} = #{typedef_type.get_type_str} #{typedef_type.get_type_str_post}\n"
      if typedef_type.get_type_str == dup_type.get_type_str &&
          typedef_type.get_type_str_post == dup_type.get_type_str_post then
        # 同じものが typedef された
        # ここへ来るのは C で関数ポインタを typedef しているケース
        # 以下のように二重に定義されている場合は type_specifier_qualifier_list として扱われる
        #    typedef long LONG; 
        #    typedef long LONG;
        # bnf.y.rb では declarator に TYPE_NAME を許さないので、ここへ来ることはない
        # p "#{typedef.get_declarator.get_type.get_type_str} #{typedef.get_name} #{typedef.get_declarator.get_type.get_type_str_post}"
        return
      end
      # p "prev: #{dup.get_declarator.get_type.get_type_str}#{dup.get_declarator.get_type.get_type_str_post} current:#{typedef.get_declarator.get_type.get_type_str} #{typedef.get_declarator.get_type.get_type_str_post}"
    end

    # p "typedef: #{typedef.get_name}  #{typedef.get_declarator.get_type.get_original_type.get_type_str}#{typedef.get_declarator.get_type.get_original_type.get_type_str_post}"
    # typedef.show_tree 0

    @name_list.add_item( typedef )
    @typedef_list << typedef
    @decl_list << typedef
  end

  def self.is_typename?( str )
    i = @@namespace_sp
    while i >= 0
      if @@namespace_stack[i].is_typename?( str ) then
        return true
      end
      i -= 1
    end
    false
  end

  def is_typename?( str )
    if @name_list.get_item( str ).instance_of?( Typedef ) then
      true
    else
      false
    end
  end

 ### const_decl
  def self.new_const_decl( decl )
    @@namespace_stack[@@namespace_sp].new_const_decl( decl )
  end

  def new_const_decl( decl )
    decl.set_owner self   # Decl (Namespace:const)
    if ! decl.is_const? then			# const 修飾さていること
      if decl.is_type?( PtrType ) then
        cdl_error( "S1094 $1: pointer is not constant. check \'const\'" , decl.get_name )
      else
        cdl_error( "S1095 $1: not constant" , decl.get_name )
      end
    elsif ! decl.is_type?( IntType ) && ! decl.is_type?( FloatType ) &&
        ! decl.is_type?( BoolType ) && ! decl.is_type?( PtrType ) then
                                            # IntType, FloatType であること
      cdl_error( "S1096 $1: should be int, float, bool or pointer type" , decl.get_name )
    elsif decl.get_initializer == nil then   # 初期値を持つこと
      cdl_error( "S1097 $1: has no initializer" , decl.get_name )
#    elsif decl.get_initializer.eval_const(nil) == nil then  #eval_const は check_init で呼出されるので二重チェック
#                                            # mikan 初期値が型に対し適切であること
#      cdl_error( "S1098 $1: has unsuitable initializer" , decl.get_name )
    else
      decl.get_type.check_init( @locale, decl.get_name, decl.get_initializer, :CONSTANT )
      @name_list.add_item( decl )
      @const_decl_list << decl
    end

  end

 ### region
  # def self.new_region( region )
  #   @@namespace_stack[@@namespace_sp].new_region( region )
  # end
# 
  # def new_region( region )
  #   region.set_owner self   # Rgion (Namespace)
  #   @name_list.add_item( region )
  # end

 ###

  #=== Namespace# すべてのセルの require ポートを設定
  # STAGE: S
  def set_require_join
    @celltype_list.each{ |ct|
      ct.set_require_join
    }
    # すべての namespace について require ポートをセット
    @namespace_list.each{ |ns|
      ns.set_require_join
    }
  end

  #=== Namespace# Join への definition の設定とチェック
  # セルタイプに属するすべてのセルに対して実施
  def set_definition_join
    # celltype のコードを生成
    @cell_list.each { |c|
      dbgPrint "set_definition_join #{c.get_name}\n"
      c.set_definition_join
    }
    @namespace_list.each{ |ns|
      ns.set_definition_join
    }
  end

  #=== Namespace# set_max_entry_port_inner_cell
  # セルタイプに属するすべてのセルに対して実施
  def set_max_entry_port_inner_cell
    # celltype のコードを生成
    @cell_list.each { |c|
      c.set_max_entry_port_inner_cell
    }
    @namespace_list.each{ |ns|
      ns.set_max_entry_port_inner_cell
    }
  end

  #=== Namespace# セルの結合をチェックする
  def check_join
    @cell_list.each { |c|
      dbgPrint "check_join #{c.get_name}\n"
      c.check_join
      c.check_reverse_require
    }
    @namespace_list.each{ |ns|
      ns.check_join
    }
  end

  #== Namespace# ルートか?
  # ルートネームスペース と ルートリージョンは同じ
  def is_root?
    @name == "::"
  end

  #== Namespace# ルートを得る
  # ルートリージョンとルートネームスペースは同じオブジェクト
  def self.get_root
    @@root_namespace
  end

  #== Namespace に属するシグニチャのリスト
  def get_signature_list
    @signature_list
  end

  #== Namespace# 子ネームスペースのリスト
  #
  def get_namespace_list
    @namespace_list
  end

  #== Namespace (Region) に属するセルのリスト
  def get_cell_list
    @cell_list
  end

  #== Namespace (Region)# 子リージョンのリスト
  #
  # リージョンは Namespace クラスで namespace として記憶されている
  def get_region_list
    @namespace_list
  end
  
  def show_tree( indent )
    indent.times { print "  " }
    puts "#{self.class}: name: #{@name} path: #{get_namespace_path.get_path_str}"
    @struct_tag_list.show_tree( indent + 1 )
    @name_list.show_tree( indent + 1 )
  end

end
