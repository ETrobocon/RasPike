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
#   $Id: region.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

#== Region クラス
# 
# Region は Namespace を継承している
# root region は特殊で、root namespace と同じである
#
# cell は region に属する
# region に属する cell のリストは Namespace クラスのインスタンス変数として記憶される
#
class Region < Namespace
# @name:: string
# @in_through_list:: [ [ plugin_name, plugin_arg ], ... ] : plungin_name = nil の時 in 禁止
# @out_through_list:: [ [ plugin_name, plugin_arg ], ... ] : plungin_name = nil の時 out 禁止
# @to_through_list:: [ [ dst_region, plugin_name, plugin_arg ], ... ]
# @from_through_list:: [ [ src_region, plugin_name, plugin_arg ], ... ]
# @cell_port_throug_plugin_list:: { "#{cell_name}.#{port_name}" => through_generated_list の要素 }
#    この region から cell_name.port_name への through プラグインで生成されたオブジェクト
# @region_type::Symbol|Nil : :NODE, :LINKUNIT, :DOMAIN, :CLASS
# @region_type_param::Symbol|Nil : domain, class の名前. node, linkunit では nil
# @link_root:: Region : linkUnit の根っことなる region (node, linkunit が指定された region)
# @node_root:: Region : node の根っことなる region (node が指定された region)
# @family_line:: [ @region_root, ...,@region_me ]  家系
# @in_through_count:: Integer :  n 番目の in_through 結合 (n>=0)
# @out_through_count:: Integer : n 番目の out_through 結合 (n>=0)
# @to_through_count:: { :RegionName => Integer }: RegionName への n 番目の to_through 結合 (n>=0)
# @from_through_count:: { :RegionName => Integer }: RegionName への n 番目の from_through 結合 (n>=0)
# @domain_type::DomainType : domain 指定されていない場合、nil
# @domain_root::Region : domain 指定されていなる Region (root の場合 nil)
# @class_type::ClassType : class 指定されていない場合、nil
# @class_root::Region : class 指定されていなる Region (root の場合 nil)

  @@in_through_list  = []
  @@out_through_list = []
  @@to_through_list  = []
  @@from_through_list  = []
  @@region_type = nil
  @@region_type_param = nil
  @@domain_name = nil
  @@domain_option = nil    # Token が入る
  @@class_name = nil
  @@class_option = nil    # Token が入る

  @@link_roots = []
  @@node_roots = []

  def initialize( name )
    if name != "::" then
      object = Namespace.get_current.find( name )    #1
    else
      # root リージョン
      object = nil
      @@region_type = :NODE
    end

    @in_through_list    = @@in_through_list
    @out_through_list   = @@out_through_list
    @to_through_list    = @@to_through_list
    @from_through_list  = @@from_through_list
    @region_type        = @@region_type
    @region_type_param  = @@region_type_param

    @@in_through_list   = []
    @@out_through_list  = []
    @@to_through_list   = []
    @@from_through_list   = []
    @@region_type       = nil
    @@region_type_param = nil

    @in_through_count = -1
    @out_through_count = -1
    @to_through_count = {}
    @from_through_count = {}

    super( name )
    set_region_roots

    if @@domain_name then
      dbgPrint "Region=#{name} domain_type=#{@@domain_name} option=#{@@domain_option}\n"
      domain_option = CDLString.remove_dquote @@domain_option.to_s
      @domain_type = DomainType.new( self, @@domain_name, domain_option, @node_root )
      @@domain_name       = nil
      @@domain_option     = nil
    else
      @domain_type = nil
    end

    if @@class_name then
      dbgPrint "Region=#{name} class_type=#{@@class_name} option=#{@@class_option}\n"
      if @@class_option.kind_of? Token then
        class_option = CDLString.remove_dquote @@class_option.to_s
      else
        class_option = @@class_option  # :global
      end
      @class_type = ClassType.new( self, @@class_name, class_option, @node_root )
      @@class_name       = nil
      @@class_option     = nil
    else
      @class_type = nil
    end
  
    if object then

      if object.instance_of?( Region ) then
        dbgPrint "Region.new: re-appear #{@name}\n"

        # # Region path が前回出現と一致するか？
        # if @@region_stack[ @@region_stack_sp - 1 ] then
        #   my_path = @@region_stack[ @@region_stack_sp - 1 ].get_path_string.to_s + "." + @name.to_s
        # else
        #   my_path = @name.to_s
        # end
        # if my_path != object.get_path_string then
        #   cdl_error( "S1139 $1: region path mismatch. previous path: $2" , my_path, object.get_path_string )
        # end

        # 再出現
        # @@region_stack[@@region_stack_sp] = object

        # 再出現時に specifier が指定されているか？
        if( @in_through_list.length != 0 || @out_through_list.length != 0 || @to_through_list.length != 0 ||
          @from_through_list.length != 0 || @region_type != nil || @domain_type != nil || @class_type != nil )then
          cdl_error( "S1140 $1: region specifier must place at first appearence" , name )
        end
        return

      else
        # エラー用ダミー定義

        # 異なる同名のオブジェクトが定義済み
        cdl_error( "S1141 $1 duplication, previous one : $2" , name, object.class )
        # @@region_stack[@@region_stack_sp] = self    # エラー時暫定 region
      end
    else
      # 初出現
      dbgPrint "Region.new: #{@name}\n"
      set_region_family_line

      if @region_type == :NODE then
        dbgPrint "new Node: #{@name}\n"
        @@node_roots << self
      end
      if @region_type == :NODE || @region_type == :LINKUNIT then
        dbgPrint "new LinkRoot: #{@name}\n"
        @@link_roots << self
      end
    end

    @cell_port_throug_plugin_list = {}

# p @name
# p @in_through_list
# p @out_through_list
# p @to_through_list

  end

  def self.end_of_parse
    Namespace.get_current.create_domain_plugin
    Namespace.get_current.create_class_plugin
    Namespace.get_current.end_of_parse
  end

  def self.new_in_through( plugin_name = nil, plugin_arg = nil )
    @@in_through_list << [ plugin_name, plugin_arg ]
  end

  def self.new_out_through( plugin_name = nil, plugin_arg = nil )
    @@out_through_list << [ plugin_name, plugin_arg ]
  end

  def self.new_to_through( dst_region, plugin_name, plugin_arg )
    # p "New to_through #{dst_region}"
    @@to_through_list  << [ dst_region, plugin_name, plugin_arg ]
  end

  def self.new_from_through( src_region, plugin_name, plugin_arg )
    # p "New to_through #{dst_region}"
    @@from_through_list  << [ src_region, plugin_name, plugin_arg ]
  end

  def self.set_type( type, param = nil )
    if @@region_type then
      Generator.error( "S1178 $1 region type specifier duplicate, previous $2", type, @@region_type )
    end
    @@region_type = type
    @@region_type_param = param
  end

  def self.set_domain( name, option )
    if @@domain_name then
      Generator.error( "S9999 $1 domain specifier duplicate, previous $2", name, @@domain_name )
    elsif @@class_name then
      Generator.error( "S9999 $1 domain & class specifier are incompatible $2", name, @@class_name )
    end
    @@domain_name = name
    @@domain_option = option
  end

  def self.set_class( name, option )
    if @@class_name then
      Generator.error( "S9999 $1 class specifier duplicate, previous $2", name, @@class_name )
    elsif @@domain_name then
      Generator.error( "S9999 $1 class & domain specifier are incompatible $2", name, @@domain_name )
    end
    @@class_name = name
    @@class_option = option
  end

  #== Region ルートリージョンを得る
  # ルートリージョンは、ルートネームスペースと同じである
  def self.get_root
    Namespace.get_root
  end

  def set_region_roots
    # root namespace (root region) の region type は :NODE
    # if @name == "::" then
    #   @region_type = :NODE
    # end
    dbgPrint "Region#set_region_roots name=#{@name}\n"
    if @region_type == :NODE then
      @node_root = self
    else
      @node_root = @owner.get_node_root
    end
    if @region_type == :NODE || @region_type == :LINKUNIT then
      @link_root = self
    else
      @link_root = @owner.get_link_root
    end
  end

  def set_region_family_line
    dbgPrint  "set_region_family_line: Region: #{@name}  \n"
      #---- Domain ----
    if @domain_type != nil || @owner == nil || @region_type == :NODE then
      @domain_root = self
    else
      @domain_root = @owner.get_domain_root
    end

    if @domain_type then
      # ルートリージョンが最初から @domain_type 設定されることはないの
      # で @owner == nil を調べる必要はない
      @owner.set_domain_type @domain_type
    end

    #---- Class ----
    if @class_type != nil || @owner == nil || @region_type == :NODE then
      @class_root = self
    else
      @class_root = @owner.get_class_root
    end

    if @class_type then
      # ルートリージョンが最初から @class_type 設定されることはないの
      # で @owner == nil を調べる必要はない
      @owner.set_class_type @class_type
    end
    
    #---- Faily Line ----
    if @owner then
      @family_line = ( @owner.get_family_line.dup ) << self
    else
      @family_line = [ self ]    # root region
    end
  end

  #== Region#ドメインを設定する
  #ドメインタイプが指定されたリージョンの親リージョンにドメインタイプを設定する
  # 親リージョンは、既にドメインタイプが指定されていなければ、OutOfDomain とする
  def set_domain_type domain_type
    if @region_type == :NODE then
      if @domain_type then
        if @domain_type.get_name != domain_type.get_name then
          cdl_error( "S9999 '$1' node root cannot belong to both $2 and $3", @name, @domain_type.get_name, domain_type.get_name )
        end
      else
        @domain_type = DomainType.new( self, domain_type.get_name, "OutOfDomain", @node_root )
        @domain_type.create_domain_plugin
      end
    elsif @domain_type == nil then
      @owner.set_domain_type domain_type
    end
  end

  #== Region#クラスを設定する
  #クラスが指定されたリージョンの親リージョンにクラスを設定する
  # 親リージョンは、既にクラスが指定されていなければ、OutOfClass とする
  def set_class_type class_type
    if @region_type == :NODE then
      if @class_type then
        if @class_type.get_name != class_type.get_name then
          cdl_error( "S9999 '$1' node root cannot belong to both $2 and $3",
                      @name, @class_type.get_name, class_type.get_name )
        end
      else
        @class_type = ClassType.new( self, class_type.get_name, :root, @node_root )
        @class_type.create_class_plugin
      end
    elsif @class_type == nil then
      @owner.set_class_type class_type
    end
  end

  def self.get_node_roots
    @@node_roots
  end

  def self.get_link_roots
    @@link_roots
  end

  def get_family_line
    @family_line
  end

  def get_in_through_list
    @in_through_list
  end

  def get_out_through_list
    @out_through_list
  end

  def get_to_through_list
    @to_through_list
  end

  def get_from_through_list
    @from_through_list
  end

  def get_node_root
    @node_root
  end

  def get_link_root
    @link_root
  end

  #== REgion# DomainType を返す
  # Region がドメインルートでない場合 nil を返す
  def get_domain_type
    @domain_type
  end

  #== Region# domain の根っことなる region を得る
  # Region のインスタンスを返す
  # domain 指定子があれば、そのリージョンがドメインルートである
  # なければ、親リージョンのドメインルートとする
  def get_domain_root
    @domain_root
  end

  #== REgion# ClassType を返す
  # Region がクラスルートでない場合 nil を返す
  def get_class_type
    @class_type
  end

  def get_class_root
    @class_root
  end
  
  def get_path_string
    pstring = ""
    delim = ""
    @family_line.each{ |p|
      pstring = "#{pstring}#{delim}#{p.get_name}"
      delim = "."
    }
    dbgPrint "get_path_string: #{pstring}\n"
    pstring
  end

  def get_region_type
    @region_type
  end

  def get_name
    @name
  end

  #== Region.ルートリージョン
  # ルートリージョンは、namespace のルートと同じインスタンス
  def self.get_root
    Namespace.get_root
  end

  def next_in_through_count
    @in_through_count += 1
  end

  def next_out_through_count
    @out_through_count += 1
  end

  def next_to_through_count( symRegionName )
    if @to_through_count[ symRegionName ] == nil then
      @to_through_count[ symRegionName ] = 0
    else
      @to_through_count[ symRegionName ] += 1
    end
  end

  def next_from_through_count( symRegionName )
    if @from_through_count[ symRegionName ] == nil then
      @from_through_count[ symRegionName ] = 0
    else
      @from_through_count[ symRegionName ] += 1
    end
  end

  #=== Region# 構文解析中の region を得る
  # 構文解析中 Namespace (あるいは子クラスの Region) の上位をたどって Region を見つける
  # cell が namespace 下におくことができなければ、ループをまわす必要はない
  def self.get_current
    # @@region_stack[@@region_stack_sp]
    region = Namespace.get_current
    while 1
      if region.instance_of? Region
        break
      end
      region = region.get_owner
    end
    return region
  end

  #=== Region# through プラグインで、この region から cell_name.port_name へのプラグインオブジェクトを登録
  # mikan namesppace 対応 (cell_name)
  def add_cell_port_through_plugin( cell_name, port_name, subscript, through_plugin_object )
    if subscript then
      subscript = '[' + subscript.to_s + ']'
    end
    @cell_port_throug_plugin_list[ "#{cell_name}.#{port_name}#{subscript}" ] = through_plugin_object
  end

  def find_cell_port_through_plugin( cell_name, port_name, subscript )
    if subscript then
      subscript = '[' + subscript.to_s + ']'
    end
    return @cell_port_throug_plugin_list[ "#{cell_name}.#{port_name}#{subscript}" ]
  end

  def create_domain_plugin
    if @domain_type then
      @domain_type.create_domain_plugin
    end
  end

  def create_class_plugin
    if @class_type then
      @class_type.create_class_plugin
    end
  end

  #=== Region# to_region への距離（unreachable な場合 nil)
  # mikan Cell#check_region とRegion へたどり着くまでの処理に共通性が高い
  # region#distance は require で用いられる
  def distance( to_region )

    r1 = self                   # 出発 region
    r2 = to_region              # 目的 region
    dist = 0

    if ! r1.equal? r2 then      # 同一 region なら呼出し可能

      # mikan namespace 対応
      f1 = r1.get_family_line
      len1 = f1.length
      f2 = r2.get_family_line
      len2 = f2.length

      # 不一致になるところ（兄弟）を探す
      i = 1  # i = 0 は :RootRegion なので必ず一致
      while( i < len1 && i < len2 )
        if( f1[i] != f2[i] )then
          break
        end
        i += 1
      end

      sibling_level = i     # 兄弟となるレベル、もしくはどちらか一方が終わったレベル

      # p "sibling_level: #{i}"
      # p "from: #{f1[i].get_name}" if f1[i]
      # p "to: #{f2[i].get_name}" if f2[i]

      # 呼び側について呼び元のレベルから兄弟レベルまで（out_through をチェックおよび挿入）
      i = len1 -1
      while i >= sibling_level
        dbgPrint "going out from #{f1[i].get_name} level=#{i}\n"
        # print "DOMAIN: going out from #{f1[i].get_name} level=#{i}\n"
        domain_type = f1[i].get_domain_type
        class_type = f1[i].get_class_type
        dbgPrint "distance: region=#{f1[i].get_name} domain_type=#{domain_type} class_type=#{class_type}"
        join_ok = false
        if domain_type then
          if ! domain_type.joinable?( f1[i], f1[i-1], :OUT_THROUGH ) then
            return nil
          end
          join_ok = true
        elsif class_type then
          if ! class_type.joinable?( f1[i], f1[i-1], :OUT_THROUGH ) then
            return nil
          end
          join_ok = true
        end
        if ! join_ok then
          out_through_list = f1[i].get_out_through_list   # [ plugin_name, plugin_arg ]
          if out_through_list.length == 0 then
            return nil
          end
        end
        i -= 1
        dist += 1
      end

      # 兄弟レベルにおいて（to_through をチェックおよび挿入）
      if f1[sibling_level] && f2[sibling_level] then
        dbgPrint "going from #{f1[sibling_level].get_name} to #{f2[sibling_level].get_name}\n"
        # print "DOMAIN: going from #{f1[sibling_level].get_name} to #{f2[sibling_level].get_name}\n"
        domain_type = f1[sibling_level].get_domain_type
        class_type = f1[sibling_level].get_class_type
        join_ok = false
        if domain_type then
          if ! domain_type.joinable?( f1[i], f1[i-1], :TO_THROUGH ) then
            return nil
          end
          join_ok = true
        elsif class_type then
          if ! class_type.joinable?( f1[i], f1[i-1], :TO_THROUGH ) then
            return nil
          end
          join_ok = true
        end
        if ! join_ok then
          found = 0
          f1[sibling_level].get_to_through_list.each { |t|
            if t[0][0] == f2[sibling_level].get_name then   # region 名が一致するか ?
              found = 1
            end
          }
          f2[sibling_level].get_from_through_list.each { |t|
            if t[0][0] == f1[sibling_level].get_name then   # region 名が一致するか ?
              found = 1
            end
          }
          if found == 0 then
            return nil
          end
        end
        dist += 1
      end

      # 受け側について兄弟レベルから受け側のレベルまで（in_through をチェックおよび挿入）
      i = sibling_level
      while i < len2
        dbgPrint "going in to #{f2[i].get_name} level=#{i}\n"
        # print "DOMAIN: going in to #{f2[i].get_name} level=#{i}\n"
        domain_type = f2[i].get_domain_type
        class_type = f2[i].get_class_type
        join_ok = false
        if domain_type then
          if ! domain_type.joinable?( f2[i-1], f2[i], :IN_THROUGH ) then
            return nil
          end
          join_ok = true
        elsif class_type then
          if ! class_type.joinable?( f2[i-1], f2[i], :IN_THROUGH ) then
            return nil
          end
          join_ok = true
        end
        if ! join_ok then
          in_through_list = f2[i].get_in_through_list   # [ plugin_name, plugin_arg ]
          if in_through_list.length == 0 then
            return nil
          end
        end
        i += 1
        dist += 1
      end
    end

    dbgPrint "dsitance=#{dist} from #{r1.get_name} to #{r2.get_name}\n"
    # print "dsitance=#{dist} from #{r1.get_name} to #{r2.get_name}\n"

    return dist
  end

  # Regin# self は、region の子リージョンか？
  def is_sub_region_of? region
    while region != self
      if region.is_root? then
        return true
      end
      region = region.get_owner
    end
    return false
  end

  def is_node_root?
    @@node_roots.include? self
  end

  def is_link_root?
    @@link_roots.include? self
  end

  def is_class_root?
    @region_type == :NODE
  end

  def is_domain_root?
    @region_type == :NODE
  end

  def show_tree( indent )
    super
    (indent+1).times { print( "  " ) }
    puts "path: #{get_path_string}"
    (indent+1).times { print( "  " ) }
    puts "namespace: #{@namespace ? @namespace.get_name : "nil"}  owner: #{@owner.class}.#{@owner ? @owner.get_name : "nil"}"
    if @domain_type
      @domain_type.show_tree( indent+1 )
    end
    (indent+1).times { print( "  " ) }
    puts "domain_root=#{@domain_root.get_name} class_root=#{@class_root.get_name}"
  end
end
