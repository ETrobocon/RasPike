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
#   $Id: compositecelltype.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

class CompositeCelltype < NSBDNode # < Nestable
# @name:: str
# @global_name:: str
# @cell_list_in_composite:: NamedList   Cell
# @cell_list::Array :: [ Cell ] : cell of CompositeCelltype's cell
# @export_name_list:: NamedList : CompositeCelltypeJoin
# @port_list:: CompositeCelltypeJoin[]
# @attr_list:: CompositeCelltypeJoin[]
# @b_singleton:: bool : 'singleton' specified
# @b_active:: bool : 'active' specified
# @real_singleton:: bool : has singleton cell in this composite celltype
# @real_active:: bool : has active cell in this composite celltype
# @name_list:: NamedList item: Decl (attribute), Port エクスポート定義
# @internal_allocator_list:: [ [cell, internal_cp_name, port_name, func_name, param_name, ext_alloc_ent], ... ]
# @generate:: [ Symbol, String, Plugin ]  = [ PluginName, option, Plugin ] Plugin は生成後に追加される
# @generate_list:: [ [ Symbol, String, Plugin ], ... ]   generate 文で追加された generate

  @@nest_stack_index = -1
  @@nest_stack = []
  @@current_object = nil

  include CelltypePluginModule
  include PluginModule

  def self.push
    @@nest_stack_index += 1
    @@nest_stack[ @@nest_stack_index ] = @@current_object
    @@current_object = nil
  end

  def self.pop
    @@current_object = @@nest_stack[ @@nest_stack_index ]
    @@nest_stack_index -= 1
    if @@nest_stack_index < -1 then
      raise "TooManyRestore"
    end
  end

  def initialize( name )
    super()
    @name = name
    @cell_list_in_composite = NamedList.new( nil, "in composite celltype #{name}" )
    @cell_list = []
    @export_name_list = NamedList.new( nil, "export in composite celltype #{name}" )
    @name_list = NamedList.new( nil, "in composite celltype #{name}" )
    @@current_object = self

    @b_singleton = false
    @real_singleton = nil
    @b_active = false
    @real_active = nil
    if "#{Namespace.get_global_name}" == "" then
      @global_name = @name
    else
      @global_name = :"#{Namespace.get_global_name}_#{@name}"
    end

    Namespace.new_compositecelltype( self )
    set_namespace_path # @NamespacePath の設定

    @port_list = []
    @attr_list = []
    @internal_allocator_list = []
    @generate_list = []
    set_specifier_list( Generator.get_statement_specifier )
  end

  def self.end_of_parse
    @@current_object.end_of_parse
    @@current_object = nil
  end

  # CompositeCelltype#end_of_parse
  def end_of_parse
    # singleton に関するチェック
    if @b_singleton && @real_singleton == nil then
      cdl_warning( "W1004 $1 : specified singleton but has no singleton in this celltype" , @name )
    elsif ! @b_singleton && @real_singleton != nil then
      if ! @b_singleton then
        cdl_error( "S1053 $1 must be singleton. inner cell \'$2\' is singleton" , @name, @real_singleton.get_name )
      end
    end

    # active に関するチェック
    if @b_active && @real_active == nil then
      cdl_error( "S1054 $1 : specified active but has no active in this celltype" , @name )
    elsif ! @b_active && @real_active != nil then
      cdl_error( "S1055 $1 must be active. inner cell \'$2\' is active" , @name, @real_active.get_name )
    end

    # @allocator_instance を設定する
    @name_list.get_items.each{ |n|
      if n.instance_of? Port then
        n.set_allocator_instance
      end
    }

    # リレーアロケータの entry 側
    @port_list.each{ |p|
      if p.get_port_type == :ENTRY then
        if p.get_allocator_instance == nil then
          next
        end

        p.get_allocator_instance.each{ |name,ai|
          if ai[0] == :RELAY_ALLOC then
            self.new_join( :"#{p.get_name}_#{ai[4]}_#{ai[5]}", p.get_cell_name, :"#{p.get_cell_elem_name}_#{ai[4]}_#{ai[5]}", :CALL )
          end
        }
      end
    }
    # mikan relay が正しく抜けているかチェックされていない

    # callback 結合
    @cell_list_in_composite.get_items.each{ |c|
      ct = c.get_celltype
      if ct then
        c.create_reverse_join
      end
    }

    # 意味解析
    @cell_list_in_composite.get_items.each{ |c|
      c.set_definition_join
    }

    # cell の未結合の呼び口がないかチェック
    @cell_list_in_composite.get_items.each{ |c|
      c.check_join
      c.check_reverse_require
    }

    # 呼び口の結合について、export と内部結合の両方がないかチェック
    # リレーアロケータ、内部アロケータの設定
    @port_list.each{ |p|
      p.check_dup_init
    }

    # すべてのエクスポート定義に対応した呼び口、受け口、属性が存在するかチェック
    @name_list.get_items.each{ |n|
      if( @export_name_list.get_item( n.get_name ) == nil )then
        cdl_error( "S1056 $1 : cannot export, nothing designated" , n.get_name )
      end
    }

    # 内部アロケータを設定する
    @internal_allocator_list.each{ |cell, cp_internal_name, port_name, fd_name, par_name, ext_alloc_ent|
      res = ext_alloc_ent.get_allocator_rhs_elements( :INTERNAL_ALLOC )
      ep_name = res[0]
      cj = @export_name_list.get_item( ep_name )
      internal_alloc_name_from_port_def = cj.get_cell_name
      internal_alloc_ep_name_from_port_def = cj.get_cell_elem_name

      # puts "internal_allocator #{cell.get_name} #{cp_internal_name} #{port_name}.#{fd_name}.#{par_name}"
      cell.get_allocator_list.each{ |a|
        # puts "allocator_list of #{cell.get_name} #{a[0]} #{a[1]}.#{a[2]}.#{a[3]}.#{a[4]} #{a[5].to_s}"
        if cp_internal_name == :"#{a[1]}_#{a[3]}_#{a[4]}" then
          dbgPrint "internal_allocator {cp_internal_name} #{a[1]}_#{a[3]}_#{a[4]}\n"
          dbgPrint "internal_allocator: #{a[5]}, #{internal_alloc_name_from_port_def}.#{internal_alloc_ep_name_from_port_def}\n"
          if a[5].to_s != "#{internal_alloc_name_from_port_def}.#{internal_alloc_ep_name_from_port_def}" then
            cdl_error( "S1173 $1: allocator mismatch from $2's allocator", "#{port_name}.#{fd_name}.#{par_name}", cell.get_name  )
          end
        end
      }
    }

    # composite プラグイン
    if @generate then
      celltype_plugin
    end
  end

 ### CompositeCelltype#new_cell_in_composite
  def self.new_cell_in_composite( cell )
    @@current_object.new_cell_in_composite( cell )

  end

  def new_cell_in_composite( cell )
    cell.set_owner self  # Cell (in_omposite)
    @cell_list_in_composite.add_item( cell )
    if cell.get_celltype then    # nil ならば、すでにセルタイプなしエラー
      if cell.get_celltype.is_singleton? then
        @real_singleton = cell
      end
      if cell.get_celltype.is_active? then
        @real_active = cell
      end
    end
  end

 ### join
  def self.new_join( export_name, internal_cell_name,
			 internal_cell_elem_name, type )
    @@current_object.new_join( export_name, internal_cell_name,
					 internal_cell_elem_name, type )
    
  end

 ### CompositeCelltype#new_cell
  def new_cell cell
    @cell_list << cell

    # セルタイププラグインの適用
    celltype_plugin_new_cell cell
  end

  #=== CompositeCelltype# CompositeCelltypeJoin を作成
  # STAGE: B
  #export_name:: Symbol : 外部に公開する名前
  #internal_cell_name:: Symbol : 内部セル名
  #internal_cell_elem_name:: Symbol : 内部セルの要素名（呼び口名、受け口名、属性名のいずれか）
  #type::  :CALL, :ENTRY, :ATTRIBUTE のいずれか（構文要素としてあるべきもの）
  #RETURN:: Decl | Port : エクスポート定義
  # new_join は
  #   cCall => composite.cCall;     (セル内)
  #   attr = composite.attr;        (セル内)
  #   composite.eEnt => cell2.eEnt; (セル外)
  # の構文要素の出現に対して呼び出される
  def new_join( export_name, internal_cell_name,
		            internal_cell_elem_name, type )

    dbgPrint "new_join: #{export_name} #{internal_cell_name} #{internal_cell_elem_name}\n"

    cell = @cell_list_in_composite.get_item( internal_cell_name )
    if cell == nil then
      cdl_error( "S1057 $1 not found in $2" , internal_cell_name, @name )
      return
    end

    celltype = cell.get_celltype
    return if celltype == nil	# celltype == nil ならすでにエラー

    # 内部セルのセルタイプから対応要素を探す
    # このメソッドは、構文上、呼び口、受け口、属性が記述できる箇所から呼出される
    # 構文上の呼出し位置（記述位置）と、要素が対応したものかチェック
    obj = celltype.find( internal_cell_elem_name )
    if obj.instance_of?( Decl ) then
      if obj.get_kind == :VAR then
        cdl_error( "S1058 \'$1\' : cannot export var" , internal_cell_elem_name )
        return
      elsif type != :ATTRIBUTE then
        cdl_error( "S1059 \'$1\' : exporting attribute. write in cell or use \'=\' to export attribute" , export_name )
        # return 次のエラーを避けるために処理続行し、付け加えてみる
      end
    elsif obj.instance_of?( Port ) then
      if obj.get_port_type != type then
        cdl_error( "S1060 \'$1\' : port type mismatch. $2 type is allowed here." , export_name, type )
        # return 次のエラーを避けるために処理続行し、付け加えてみる
      end
    else
      cdl_error( "S1061 \'$1\' : not defined" , internal_cell_elem_name )
      dbgPrint "S1061 CompositeCelltypeJoin#new_join: #{export_name} => #{internal_cell_name}.#{internal_cell_elem_name} #{type}\n"
      return
    end

    # エクスポート定義と一致するかどうかチェック
    obj2 = @name_list.get_item( export_name )
    if( obj2 == nil )then
      cdl_error( "S1062 $1 has no export definition" , export_name )
    elsif obj2.instance_of?( Decl ) then
      if( ! obj.instance_of? Decl )then
        cdl_error( "S1063 $1 is port but previously defined as an attribute" , export_name )
      elsif ! obj.get_type.equal? obj2.get_type then
        cdl_error( "S1064 $1 : type \'$2$3\' mismatch with pprevious definition\'$4$5\'" , export_name, obj.get_type.get_type_str, obj.get_type.get_type_str_post, obj2.get_type.get_type_str, obj2.get_type.get_type_str_post )
      end
    elsif obj2.instance_of?( Port ) then
      if( obj.instance_of? Port )then
        if( obj.get_port_type != obj2.get_port_type )then
          cdl_error( "S1065 $1 : port type $2 mismatch with previous definition $3" , export_name, obj.get_port_type, obj2.get_port_type )
        elsif obj.get_signature != obj2.get_signature then
          if obj.get_signature != nil && obj2.get_signature != nil then
            # nil ならば既にエラーなので報告しない
            cdl_error( "S1066 $1 : signature \'$2\' mismatch with previous definition \'$3\'" , export_name, obj.get_signature.get_name, obj2.get_signature.get_name )
          end
        elsif obj.get_array_size != obj2.get_array_size then
          cdl_error( "S1067 $1 : array size mismatch with previous definition" , export_name )
        elsif obj.is_optional? != obj2.is_optional? then
          cdl_error( "S1068 $1 : optional specifier mismatch with previous definition" , export_name )
        elsif obj.is_omit? != obj2.is_omit? then
          cdl_error( "S9999 $1 : omit specifier mismatch with previous definition" , export_name )
        elsif obj.is_dynamic? != obj2.is_dynamic? then
          cdl_error( "S9999 $1 : dynamic specifier mismatch with previous definition" , export_name )
        elsif obj.is_ref_desc? != obj2.is_ref_desc? then
          cdl_error( "S9999 $1 : ref_desc specifier mismatch with previous definition" , export_name )
        end
      else
        cdl_error( "S1069 $1 is an attribute but previously defined as a port" , export_name )
      end
    end

    join = CompositeCelltypeJoin.new( export_name, internal_cell_name,
				 internal_cell_elem_name, cell, obj2 )
    join.set_owner self   # CompositeCelltypeJoin
    cell.add_compositecelltypejoin join

    # debug
    dbgPrint "compositecelltype join: add #{cell.get_name} #{export_name} = #{internal_cell_name}.#{internal_cell_elem_name}\n"

    if obj.instance_of?( Decl ) then
      # attribute
#      # 内部から外部へ複数の結合がないかチェック
#      found = false
#      @attr_list.each{ |a|
#        if a.get_name == join.get_name then
#          found = true
#          break
#        end
#      }
#      if found == false then
        @attr_list << join
#      end
    else
      # call/entry port
#      # 内部から外部へ複数の結合がないかチェック
#      found = false
#      @port_list.each{ |port|
#        if port.get_name == join.get_name then
#          found = true
#          break
#        end
#      }
#      if found == false then
        @port_list << join
#      end
    end

    # join を @export_name_list に登録（重複チェックとともに，後で行われる CompositeCelltypeJoin の clone に備える）
    if obj.instance_of?( Decl ) && @export_name_list.get_item( export_name ) then
      # 既に存在する。追加しない。新仕様では、@export_name_list に同じ名前が含まれることがある。
    elsif obj.instance_of?( Port ) && obj.get_port_type == :CALL && @export_name_list.get_item( export_name ) then
      # 既に存在する。追加しない。新仕様では、@export_name_list に同じ名前が含まれることがある。
    else
      # print "Composite:new_join: #{join.get_name} len=#{@export_name_list.get_items.length}\n"
      @export_name_list.add_item( join )
    end

    # export するポートに含まれる send/receive パラメータのアロケータ(allocator)呼び口をセルと結合
    if obj2.instance_of? Port then
      obj2.each_param{ |port, fd, par|
        case par.get_direction                        # 引数の方向指定子 (in, out, inout, send, receive )
        when :SEND, :RECEIVE
          cp_name = :"#{port.get_name}_#{fd.get_name}_#{par.get_name}"     # アロケータ呼び口の名前
          #            ポート名         関数名         パラメータ名
          cp_internal_name = :"#{internal_cell_elem_name}_#{fd.get_name}_#{par.get_name}"

          # リレーアロケータ or 内部アロケータ指定がなされている場合、アロケータ呼び口を追加しない
          # この時点では get_allocator_instance では得られないため tmp を得る
          if port.get_allocator_instance_tmp then
            found = false
            port.get_allocator_instance_tmp.each { |s|
              if s[1] == fd.get_name && s[2] == par.get_name then
                found = true

                if s[0] == :INTERNAL_ALLOC then
                  # 内部アロケータの場合    # mikan これは内部のセルに直結する。外部のポートに改めるべき
                  @internal_allocator_list << [ cell, cp_internal_name, port.get_name, fd.get_name, par.get_name, s[3] ]
                end
              end
            }
            if found == true
              next
            end
          end

          # 外部アロケータの場合
          new_join( cp_name, internal_cell_name, cp_internal_name, :CALL )
        end
      }
    end

    # エクスポート定義を返す
    return obj2
  end

  def self.has_attribute? attr
    @@current_object.has_attribute? attr
  end

  def has_attribute? attr
    @name_list.get_item( attr ) != nil
  end

  def self.new_port port
    @@current_object.new_port port
  end

  #=== CompositeCelltype# new_port
  def new_port port
    port.set_owner self   # Port (CompositeCelltype)
    dbgPrint "new_port: #{@owner.get_name}.#{port.get_name}\n"
    @name_list.add_item port

    # export するポートに含まれる send/receive パラメータのアロケータ呼び口の export を生成してポートに追加
    # この時点では内部アロケータかどうか判断できないので、とりあえず生成しておく
    port.each_param { |port, fd, par|
      case par.get_direction                        # 引数の方向指定子 (in, out, inout, send, receive )
      when :SEND, :RECEIVE
        #### リレーアロケータ or 内部アロケータ指定がなされている場合、アロケータ呼び口を追加しない
        # 内部アロケータ指定がなされている場合、アロケータ呼び口を追加しない
        # この時点では get_allocator_instance では得られないため tmp を得る
        if port.get_allocator_instance_tmp then
          found = false
          port.get_allocator_instance_tmp.each { |s|
            if s[0] == :INTERNAL_ALLOC && s[1] == fd.get_name && s[2] == par.get_name then
              found = true
              break
            end
          }
          if found == true
            next
          end
        end

        if par.get_allocator then
          cp_name = :"#{port.get_name}_#{fd.get_name}_#{par.get_name}"     # アロケータ呼び口の名前
          #           ポート名          関数名         パラメータ名
          alloc_sig_path = [ par.get_allocator.get_name ]  # mikan Namespace アロケータ呼び口のシグニチャ
          array_size = port.get_array_size            # 呼び口または受け口配列のサイズ
          created_port = Port.new( cp_name, alloc_sig_path, :CALL, array_size ) # 呼び口を生成
          created_port.set_allocator_port( port, fd, par )
          if port.is_omit? then
            created_port.set_omit
          end
          new_port( created_port )           # セルタイプに新しい呼び口を追加
        # else
        #   already error
        end
      end
    }
  end

  def self.new_attribute attr
    @@current_object.new_attribute attr
  end

  #=== CompositeCelltype# new_attribute for CompositeCelltype
  #attribute:: [Decl]
  def new_attribute( attribute )
    attribute.each { |a|
      a.set_owner self   # Decl (CompositeCelltype)
      # V1.1.0.10 composite の attr の size_is は可となった
      # if a.get_size_is then
      #  cdl_error( "S1070 $1: size_is pointer cannot be exposed for composite attribute" , a.get_name )
      # end
      @name_list.add_item( a )
      if a.get_initializer then
        a.get_type.check_init( @locale, a.get_identifier, a.get_initializer, :ATTRIBUTE )
      end
    }
  end

  #=== CompositeCelltype# 逆require の結合を生成する
  def create_reverse_require_join cell
    @name_list.get_items.each{ |n|
      if n.instance_of? Port then
        n.create_reverse_require_join cell
      end
    }
  end

  # false : if not in celltype definition, nil : if not found in celltype
  def self.find( name )
    if @@current_object == nil then
      return false
    end
    @@current_object.find name
  end

  def find name
    dbgPrint "CompositeCelltype: find in composite: #{name}\n"
    cell = @cell_list_in_composite.get_item( name )
    return cell if cell

    dbgPrint "CompositeCelltype: #{name}, #{@name_list.get_item( name )}\n"
    return @name_list.get_item( name )

    # 従来仕様
#    cj = @export_name_list.get_item( name )
#p "#{name}, #{cj.get_port_decl}"
#    if cj then
#      return cj.get_port_decl
#    else
#      return nil
#    end
  end

  #=== CompositeCelltype# export する CompositeCelltypeJoin を得る
  #name:: string:
  # attribute の場合、同じ名前に対し複数存在する可能性があるが、最初のものしか返さない
  def find_export name
    return @export_name_list.get_item( name )
  end

  #=== CompositeCelltype# composite celltype の cell を展開
  #name:: string: Composite cell の名前
  #global_name:: string: Composite cell の global name (C 言語名)
  #join_list:: NamedList : Composite cell に対する Join の NamedList
  #RETURN:
  # [ { name => cell }, [ cell, ... ] ]
  #  戻り値 前は 名前⇒cloneされた内部セル、後ろは composite の出現順のリスト
  def expand( name, global_name, namespacePath, join_list, region, plugin, locale )

    # debug
    dbgPrint "expand composite: #{@name} name: #{name}  global_name: #{global_name}\njoin_list:\n"
    join_list.get_items.each{ |j|
      dbgPrint "   #{j.get_name} #{j}\n"
    }
  
    # 展開で clone されたセルのリスト、右辺は Cell (composite の場合 composite な cell の clone)
    clone_cell_list = {}
    clone_cell_list2 = []
    clone_cell_list3 = {}

    #  composite 内部のすべての cell について
    @cell_list_in_composite.get_items.each { |c|

      # debug
      dbgPrint "expand : cell #{c.get_name}\n"

      # Join の配列
      ja = []

      # CompositeCelltype が export する呼び口、受け口、属性のリストについて
      # @export_name_list.get_items.each{ |cj|	# cj: CompositeCelltypeJoin
      # 新仕様では、@export_name_list に入っていない attr がありうる
      (@port_list+@attr_list).each{ |cj|	# cj: CompositeCelltypeJoin

        # debug
        dbgPrint "        cj : #{cj.get_name}\n"

        # CompositeCelltypeJoin (export) の対象セルか？
        if cj.match?( c ) then

          # 対象セル内の CompositeCelltype の export する Join (attribute または call port)
          j = join_list.get_item( cj.get_name )

          # debug
          if j then
            dbgPrint "  REWRITE_EX parent cell: #{name} child cell: #{c.get_name}:  parent's export port: #{cj.get_name}  join: #{j.get_name}=>#{j.get_rhs.to_s}\n"
          else
            dbgPrint "expand : parent cell: #{name} child cell: #{c.get_name}:  parent's export port: #{cj.get_name}  join: nil\n"
          end

          if j then
            # 呼び口、属性の場合
            #  ComositeCell 用のもの(j) を対象セル用に clone (@through_list もコピーされる)
            # p "expand: cloning Join #{j.get_name} #{@name} #{name}"
            jc = j.clone_for_composite( @name, name, locale )
                                        # celltype_name, cell_name

            # debug
            # p "cn #{jc.get_name} #{cj.get_cell_elem_name}"

            # 対象セルの呼び口または属性の名前に変更
            jc.change_name( cj.get_cell_elem_name )

            # 対象セルに対する Join の配列
            ja << jc
          end

          # debug
          dbgPrint "\n"
        end
      }

      # debug
      dbgPrint "expand : clone #{name}_#{c.get_name}\n"

      # セルの clone を生成
#      clone_cell_list[ "#{name}_#{c.get_name}" ] =  c.clone_for_composite( name, global_name, ja )
      c2 =  c.clone_for_composite( name, global_name, namespacePath, ja, @name, region, plugin, locale )
      clone_cell_list[ "#{c.get_local_name}" ] = c2
      clone_cell_list2 << c2
      clone_cell_list3[ c ] = c2

    }

    clone_cell_list.each { |nm,c|
      dbgPrint "  cloned: #{nm} = #{c.get_global_name}\n"
      # join の owner を clone されたセルに変更する V1.1.0.25
      c.get_join_list.get_items.each{ |j|
        j.set_cloned( clone_cell_list[ "#{c.get_local_name}" ] )
      }
      dbgPrint "change_rhs_port: inner cell #{c.get_name}\n"
      c.change_rhs_port clone_cell_list3
    }
    clone_cell_list2.each { |c|
      c.expand_inner
    }
    return [ clone_cell_list, clone_cell_list2 ]
  end

  #=== CompositeCelltype 指定子リストの設定
  def set_specifier_list( spec_list )
    return if spec_list == nil

    spec_list.each { |s|
      case s[0]
      when :SINGLETON
        @b_singleton = true
      when :IDX_IS_ID
        cdl_warning( "W1005 $1 : idx_is_id is ineffective for composite celltype" , @name )
      when :ACTIVE
        @b_active = true
      when :GENERATE
        if @generate then
          cdl_error( "S9999 generate specifier duplicate"  )
        end
        @generate = [ s[1], s[2] ] # [ PluginName, "option" ]
      else
        cdl_error( "S1071 $1 cannot be specified for composite" , s[0] )
      end
    }
  end

  def get_name
    @name
  end

  def get_global_name
    @global_name
  end

  def get_port_list
    @port_list
  end

  def get_attribute_list
    @attr_list
  end

  def get_var_list
    []   # 空の配列を返す
  end

  def get_internal_allocator_list
    @internal_allocator_list
  end

  #== CompositeCelltype#get_real_celltype
  # port_name に接続されている内部のセルタイプを得る
  def get_real_celltype( port_name )
    cj = find_export port_name
    inner_celltype = cj.get_cell.get_celltype
    if inner_celltype.instance_of? CompositeCelltype then
      return inner_celltype.get_real_celltype
    else
      return inner_celltype
    end
  end

=begin
  @generate_list に @generate も入っているので、これは使わない方がよい
  #== CompositeCelltype# generate 指定子の情報
  # CompositeCelltype には generate が指定できないので nil を返す
  # Celltype::@generate を参照のこと
  def get_celltype_plugin
    nil
  end
=end

  def is_singleton?
    @b_singleton
  end

  def is_active?
    @b_active
  end

  #=== CompositeCelltype# アクティブではない
  # active ではないに加え、全ての内部セルのセルタイプが inactive の場合に inactive
  # （内部のセルが active または factory を持っている）
  def is_inactive?
    if @b_active == false then
      @cell_list_in_composite.get_items.each{ |c|
        if c.get_celltype && c.get_celltype.is_inactive? == false then
          # c.get_celltype == nil の場合はセルタイプ未定義ですでにエラー
          return false
        end
      }
      return true
    else
      return false
    end
  end

  def get_id_base
    raise "get_id_base"
  end

  def show_tree( indent )
    indent.times { print "  " }
    puts "CompositeCelltype: name: #{@name}"
    (indent+1).times { print "  " }
    puts "active: #{@b_active}, singleton: #{@b_singleton}"
    @cell_list_in_composite.show_tree( indent + 1 )
    (indent+1).times { print "  " }
    puts "name_list"
    @name_list.show_tree( indent + 2 )
    (indent+1).times { print "  " }
    puts "export_name_list"
    @export_name_list.show_tree( indent + 2 )
    if @internal_allocator_list.length > 0 then
      (indent+1).times { print "  " }
      puts "internal_allocator_list:"
      @internal_allocator_list.each{  |a|
        (indent+1).times { print "  " }
        puts "  #{a[0].get_name} #{a[1]} #{a[2]} #{a[3]} #{a[4]}"
      }
    end
  end

end
