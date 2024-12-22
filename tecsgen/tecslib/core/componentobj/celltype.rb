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
#   $Id: celltype.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

class Celltype < NSBDNode # < Nestable
# @name:: Symbol
# @global_name:: Symbol
# @name_list:: NamedList item: Decl (attribute, var), Port
# @port:: Port[]
# @attribute:: Decl[]
# @var:: Decl[]
# @require:: [[cp_name,Celltype|Cell,Port],...]
# @factory_list::   Factory[]
# @ct_factory_list::    Factory[] :    celltype factory
# @cell_list:: Cell[] : 定義のみ (V1.0.0.2 以降)
# @ordered_cell_list:: Cell[] : ID 順に順序付けされたセルリスト、最適化以降有効 (リンク単位ごとに生成されなおす)
# @b_reuse:: bool :  reuse 指定されて import された(template 不要)
# @singleton:: bool
# @idx_is_id:: bool
# @idx_is_id_act:: bool: actual value
# @b_need_ptab:: bool: true if having cells in multi-domain
# @active:: bool
# @pseudo_active:: bool  @pseudo_active が true の場合 @active も true
# @generate:: [ Symbol, String, Plugin ]  = [ PluginName, option, Plugin ] Plugin は生成後に追加される (generate指定子)
# @generate_list:: [ [ Symbol, String, Plugin ], ... ]   generate 指定と generate 文で追加された generate
#
# @n_attribute_ro:: int >= 0    none specified
# @n_attribute_rw:: int >= 0    # of [rw] specified attributes (obsolete)
# @n_attribute_omit : int >= 0  # of [omit] specified attributes
# @n_var:: int >= 0
# @n_var_size_is:: int >= 0     # of [size_is] specified vars # mikan count_is
# @n_var_omit:: int >= 0        # of [omit] specified vars # mikan var の omit は有？
# @n_var_init:: int >= 0        # of vars with initializer
# @n_call_port:: int >= 0       # dynamic ports are included
# @n_call_port_array:: int >= 0  # dynamic ports are included
# @n_call_port_omitted_in_CB:: int >= 0   最適化で省略される呼び口
# @n_call_port_dynamic:: int >= 0  #
# @n_call_port_array_dynamic:: int >= 0
# @n_call_port_ref_desc:: int >= 0  #
# @n_call_port_array_ref_desc:: int >= 0
# @n_entry_port:: int >= 0
# @n_entry_port_array:: int >= 0
# @n_entry_port_inline:: int >= 0
# @n_cell_gen:: int >= 0  生成するセルの数．コード生成の頭で算出する．意味解析段階では参照不可
# @id_base:: Integer : cell の ID の最小値(最大値は @id_base + @n_cell)
#
# @b_cp_optimized:: bool : 呼び口最適化実施
# @plugin:: PluginObject      このセルタイプがプラグインにより生成された CDL から生成された場合に有効。
#                              generate の指定は @generate にプラグインが保持される
#
# @included_header:: Hash :  include されたヘッダファイル
# @domain_roots::Hash { DomainTypeName(Symbol) => [ Region ] }  ドメインタイプ名と Region の配列 (optimize.rb で設定)
#                                               ルートリージョンはドメイン名が　nil
# @domain_class_roots::Hash { Region(domain_root) => { Region(class_root) => [ cell ] }
#                           @domain_class_roots[ domain_root ][ class_root ] = [ cell ]
# @domain_class_roots2::Hash { Region(sub_region:domain_or_class_root) => [ cell ] } 
#                            @domain_class_roots2[ sub_region(domain_or_class_root) ] = [ cell ]
#                            sub_region: クラスルートまたはドメインルートの、いずれか末端側のリージョン
# @@domain_class_roots::Hash { sub_region => [ celltype ] }   # { region => celltype }

  include PluginModule
  include CelltypePluginModule
  
  @@nest_stack_index = -1
  @@nest_stack = []
  @@current_object = nil
  @@celltype_list = []

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
    @@current_object = self
    @name = name
    if "#{Namespace.get_global_name}" != "" then
      @global_name = :"#{Namespace.get_global_name}_#{@name}"
    else
      @global_name = name
    end

    @name_list = NamedList.new( nil, "symbol in celltype #{name}" )
    @port = []
    @attribute = []
    @var = []
    @require = []
    @factory_list = []
    @ct_factory_list = []
    @cell_list = []
    @singleton = false
    @active = false
    @pseudo_active = false
    @generate = nil
    @generate_list = []

    @n_attribute_ro = 0
    @n_attribute_rw = 0
    @n_attribute_omit = 0
    @n_var = 0
    @n_var_omit = 0
    @n_var_size_is = 0
    @n_var_init = 0
    @n_call_port = 0
    @n_call_port_array = 0
    @n_call_port_omitted_in_CB = 0
    @n_call_port_dynamic = 0
    @n_call_port_array_dynamic = 0
    @n_call_port_ref_desc = 0
    @n_call_port_array_ref_desc = 0
    @n_entry_port = 0
    @n_entry_port_array = 0
    @n_entry_port_array_ns = 0
    @n_entry_port_inline = 0
    @n_cell_gen = 0

    @b_cp_optimized = false

    @plugin = Generator.get_plugin
      # plugin の場合 PluginObject が返される
    # 元の Generator から呼出された Generator の中でパースおよび意味チェックされている

    # if @plugin then
    #  # plugin 生成されるセルタイプは再利用ではない   #833 不具合修正
    #  @b_reuse = false
    # else
      @b_reuse = Generator.is_reuse?
    # end

    if $idx_is_id then
      @idx_is_id = true
      @idx_is_id_act = true
      @b_need_ptab = true
    else
      @idx_is_id = false
      @idx_is_id_act = false
      @b_need_ptab = false
    end

    Namespace.new_celltype( self )
    set_namespace_path # @NamespacePath の設定
    set_specifier_list( Generator.get_statement_specifier )

    @included_header = {}
    @domain_roots = {}
    @@celltype_list << self
  end

  def get_name
    @name
  end

  #== Celltype#ドメインルートを返す
  # @domain_roots はオプティマイズで設定される.
  # このためコード生成以降有効である.
  # 
  # @domain_roots の説明を参照
  def get_domain_roots
    @domain_roots
  end
  # @domain_class_roots の説明を参照
  # @domain_class_roots はオプティマイズで設定される.
  # このためコード生成以降有効である.
  def get_domain_class_roots
    @domain_class_roots
  end
  # @domain_class_roots2 の説明を参照
  # @domain_class_roots2 はオプティマイズで設定される.
  # このためコード生成以降有効である.
  def get_domain_class_roots2
    @domain_class_roots2
  end
  # @domain_class_roots_total はオプティマイズで設定される.
  # このためコード生成以降有効である.
  def self.get_domain_class_roots_total
    @@domain_class_roots
  end

  # Celltype# end_of_parse
  def end_of_parse
    # 属性・変数のチェック
    check_attribute

    # アロケータ呼び口を内部生成
    generate_allocator_port

    # リレーアロケータ、内部アロケータの設定
    @port.each { |p|
      p.set_allocator_instance
    }

    if @n_entry_port == 0 && @active == false && @factory_list.length == 0 &&
        ( @singleton && @ct_factory_list.length == 0 || ! @singleton )then
      cdl_warning( "W1002 $1: non-active celltype has no entry port & factory" , @name )
    end

    if @generate then
      celltype_plugin
    end

    # check_dynamic_join ##

    @@current_object = nil
  end

  def self.new_port( port )
    @@current_object.new_port( port )
  end

  def new_port( port )
    port.set_owner self
    @port << port
    @name_list.add_item( port )
    if port.get_port_type == :CALL then
      @n_call_port += 1
      @n_call_port_array += 1 if port.get_array_size != nil
      if port.is_dynamic? then
        @n_call_port_dynamic += 1
        @n_call_port_array_dynamic += 1 if port.get_array_size != nil
      end
      if port.is_ref_desc? then
        @n_call_port_ref_desc += 1
        @n_call_port_array_ref_desc += 1 if port.get_array_size != nil
      end
    else
      @n_entry_port += 1
      @n_entry_port_array += 1 if port.get_array_size != nil
      @n_entry_port_array_ns += 1 if port.get_array_size == "[]"
      @n_entry_port_inline += 1 if port.is_inline?
    end
    port.set_celltype self
  end

  def get_port_list
    @port
  end

  def self.new_attribute( attribute )
    @@current_object.new_attribute( attribute )
  end

  #=== Celltype# new_attribute for Celltype
  #attribute:: [Decl]
  def new_attribute( attribute )
    @attribute += attribute
    attribute.each { |a|
      a.set_owner self
      @name_list.add_item( a )
      if( a.is_omit? )then
        @n_attribute_omit += 1
      elsif( a.is_rw? )then
        @n_attribute_rw += 1
      else
        @n_attribute_ro += 1
      end
      if a.get_initializer then
        # 登録後にチェックしても問題ない（attr を参照できないので、自己参照しない）
        a.get_type.check_init( @locale, a.get_identifier, a.get_initializer, :ATTRIBUTE )
      end
    }
  end

  #=== Celltype# celltype の attribute/var のチェック
  # STAGE:  S
  #
  # このメソッドは celltype のパースが完了した時点で呼出される．
  def check_attribute
    # attribute の size_is 指定が妥当かチェック
    (@attribute+@var).each{ |a|
      if a.get_size_is then
        if ! a.get_type.kind_of?( PtrType ) then
          # size_is がポインタ型以外に指定された
          cdl_error( "S1011 $1: size_is specified for non-pointer type" , a.get_identifier )
        else

          # 参照する変数が存在し、計算可能な型かチェックする
          size = a.get_size_is.eval_const( @name_list )  # C_EXP の可能性あり
          init = a.get_initializer
          if init then
            if ! init.instance_of?( Array ) then
              # 初期化子が配列ではない
              cdl_error( "S1012 $1: unsuitable initializer, need array initializer" , a.get_identifier )
            elsif size.kind_of?( Integer ) && size < init.length then
              # size_is 指定された個数よりも初期化子の配列要素が多い
              cdl_error( "S1013 $1: too many initializer, $2 for $3" , a.get_identifier, init.length, size )
            # elsif a.get_size_is.eval_const( nil ) == nil  # C_EXP の可能性あり
            end

          end
        end
      else
        if a.get_type.kind_of?( PtrType ) then
          if a.get_initializer.instance_of?( Array ) ||
              ( a.get_initializer.instance_of?( Expression ) &&
                a.get_initializer.eval_const2(@name_list).instance_of?( Array ) ) then
            # size_is 指定されていないポインタが Array で初期化されていたら、エラー
            cdl_error( "S1159 $1: non-size_is pointer cannot be initialized with array initializer" , a.get_identifier )
          end
        end
      end
    }
  end

  def get_attribute_list
    @attribute
  end

  #=== Celltype# アロケータ呼び口を生成
  #    send, receive 引数のアロケータを呼出すための呼び口を生成
  def generate_allocator_port
    @port.each { |port|
      # ポートのすべてのパラメータを辿る
      port.each_param { |port, fd, par|
        case par.get_direction                        # 引数の方向指定子 (in, out, inout, send, receive )
        when :SEND, :RECEIVE
          if par.get_allocator then
            cp_name = :"#{port.get_name}_#{fd.get_name}_#{par.get_name}"     # アロケータ呼び口の名前
            #           ポート名          関数名         パラメータ名
            alloc_sig_path = par.get_allocator.get_namespace_path
            array_size = port.get_array_size            # 呼び口または受け口配列のサイズ
            created_port = Port.new( cp_name, alloc_sig_path, :CALL, array_size ) # 呼び口を生成
            created_port.set_allocator_port( port, fd, par )
            if port.is_optional? then
              created_port.set_optional
            end
            if port.is_omit? then
              created_port.set_omit
            end
            new_port( created_port )                    # セルタイプに新しい呼び口を追加
          # else
          #  already error "not found or not signature" in class ParamDecl
          end
        end
      }
    }
  end

  def get_name_list
    @name_list
  end

  def self.new_var( var )
    @@current_object.new_var( var )
  end

  #=== Celltype# 新しい内部変数
  #var:: [Decl]
  def new_var( var )
    @var += var
    var.each { |i|     # i: Decl
      i.set_owner self
      if i.is_omit? then
        @n_var_omit += 1
      else
        @n_var += 1
      end
      @name_list.add_item( i )

      # size_is 指定された配列? mikan  count_is
      if i.get_size_is then
        @n_var_size_is += 1
      end

      if i.get_initializer then
        i.get_type.check_init( @locale, i.get_identifier, i.get_initializer, :VAR, @name_list )
        @n_var_init += 1
      end
    }
  end

  def get_var_list
    @var
  end

  #=== Celltype# celltype の指定子を設定
  def set_specifier_list( spec_list )
    return if spec_list == nil

    spec_list.each { |s|
      case s[0]
      when :SINGLETON
        @singleton = true
      when :IDX_IS_ID
        @idx_is_id = true
        @idx_is_id_act = true
        @b_need_ptab = true
      when :ACTIVE
        @active = true
      when :PSEUDO_ACTIVE
        @active = true
        @pseudo_active = true
      when :GENERATE
        if @generate then
          cdl_error( "S1014 generate specifier duplicate"  )
        end
        @generate = [ s[1], s[2] ] # [ PluginName, "option" ]
      else
        cdl_error( "S1015 $1 cannot be specified for composite" , s[0] )
      end
    }
    if @singleton then
      @idx_is_id_act = false
      @b_need_ptab = false
    end
  end

  #
  def self.new_require( ct_or_cell_nsp, ep_name, cp_name = nil )
    @@current_object.new_require( ct_or_cell_nsp, ep_name.to_sym, cp_name )
  end

  def new_require( ct_or_cell_nsp, ep_name, cp_name )
    # Require: set_owner するものがない
    obj = Namespace.find( ct_or_cell_nsp )    #1
    if obj.instance_of? Celltype then
      # Celltype 名で指定
      ct = obj
    elsif obj.instance_of? Cell then
      # Cell 名で指定
      ct = obj.get_celltype
    elsif obj == nil then
      cdl_error( "S1016 $1 not found" , ct_or_cell_nsp.get_path_str )
      return
    else
      cdl_error( "S1017 $1 : neither celltype nor cell" , ct_or_cell_nsp.get_path_str )
      return
    end

    if( ! ct.is_singleton? ) then
      # シングルトンではない
      cdl_error( "S1018 $1 : not singleton cell" , obj.get_name )
    end

    # 受け口を探す
    obj2 = ct.find( ep_name )
    if( ( ! obj2.instance_of? Port ) || obj2.get_port_type != :ENTRY ) then
      cdl_error( "S1019 \'$1\' : not entry port" , ep_name )
      return
    elsif obj2.get_array_size then
      cdl_error( "S1020 \'$1\' : required port cannot be array" , ep_name )
      return
    end

    if obj2.get_signature == nil then
      # signature が未定義：既にエラー
      return
    end

    require_call_port_prefix = :_require_call_port
    if cp_name == nil then
      # 関数名重複チェック
      @require.each{ |req|
        unless req[0].to_s =~ /^#{require_call_port_prefix}/ then
          next     # 名前ありの require は関数名重複チェックしない
        end
        port = req[2]
        if port.get_signature == obj2.get_signature then
          # 同じ signature （すべて同じ関数名を持つ）個別に出すのではなく、まとめてエラーとする
          cdl_error( "S1021 $1 : require cannot have same signature with \'$2\'" , obj2.get_name, port.get_name )
          next
        end
        port.get_signature.get_function_head_array.each{ |f|
          # mikan ここは、namedList からの検索にならないの？（効率が悪い）
          obj2.get_signature.get_function_head_array.each{ |f2|
            if( f.get_name == f2.get_name ) then
              cdl_error( "S1022 $1.$2 : \'$3\' conflict function name in $4.$5" , obj.get_name, obj2.get_name, f.get_name, req[1].get_name, req[2].get_name )
            end
          }
        }
      }
    end

    if cp_name == nil then
      b_has_name = false
      cp_name = :"#{require_call_port_prefix}_#{ct.get_name}_#{obj2.get_name}"
    else
      b_has_name = true
    end
    # require を追加
    @require << [ cp_name, obj, obj2 ]  # [ lhs:cp_name, rhs:Celltype, rhs:Port ]

    # require port を追加 (呼び口として追加する。ただし require をセットしておく)
    port = Port.new( cp_name, obj2.get_signature.get_namespace_path, :CALL )
    port.set_require( b_has_name )
    self.new_port port
  end

  def self.new_factory( factory )
    @@current_object.new_factory( factory )
  end

  def new_factory( factory )
    factory.set_owner self
    if factory.get_f_celltype then
      @ct_factory_list << factory
    else
      @factory_list << factory
    end

    factory.check_arg( self )

  end

  @@dynamic_join_checked_list = {}
  def self.check_dynamic_join
    Namespace.get_root.travers_all_celltype{ |ct|
      if @@dynamic_join_checked_list[ ct ] == nil then
        @@dynamic_join_checked_list[ ct ] = true
        ct.check_dynamic_join
      end
    }
  end

  #=== Celltype#dynamic の適合性チェック
  def check_dynamic_join
    return if ! $verbose
    @port.each{ |port|
      signature = port.get_signature
      next if signature == nil   # すでにエラー
      if port.is_dynamic? then
        dbgPrint( "[DYNAMIC] checking dynamic port: #{@global_name}.#{port.get_name}\n" )
        # print( "[DYNAMIC] checking dynamic port: #{@global_name}.#{port.get_name}\n" )
        next if find_ref_desc_port signature
        next if find_descriptor_param signature, :DYNAMIC
        cdl_warning( 'W9999 $1 cannot get information for dynamic port $2', @name, port.get_name )
      elsif port.is_ref_desc? then
        dbgPrint( "[DYNAMIC] checking ref_desc port: #{@global_name}.#{port.get_name}\n" )
        # print( "[DYNAMIC] checking ref_desc port: #{@global_name}.#{port.get_name}\n" )
        next if find_dynamic_port signature
        next if find_descriptor_param signature, :REF_DESC
        cdl_warning( 'W9999 $1 cannot put information from ref_desc port $2', @name, port.get_name )
      elsif port.get_signature then
        if port.get_signature.has_descriptor? then
          port.get_signature.get_descriptor_list.each{ |signature, param|
            dbgPrint( "[DYNAMIC] checking Descriptor parameter: #{@global_name}.#{port.get_name} ... #{param.get_name}\n" )
            # print( "[DYNAMIC] checking Descriptor parameter: #{@global_name}.#{port.get_name} ... #{param.get_name}\n" )
            if port.get_port_type == :CALL then
              if param.get_direction == :IN
                next if find_ref_desc_port signature
                next if find_descriptor_param signature, :DYNAMIC
              elsif param.get_direction == :OUT
                next if find_dynamic_port signature
                next if find_descriptor_param signature, :REF_DESC
              end
            else  # :ENTRY
              if param.get_direction == :IN
                next if find_dynamic_port signature
                next if find_descriptor_param signature, :REF_DESC
              elsif param.get_direction == :OUT
                next if find_ref_desc_port signature
                next if find_descriptor_param signature, :DYNAMIC
              end
            end
            cdl_warning( 'W9999 "$1" cannot handle Descriptor "$2" information for port "$3"', @name, param.get_name, port.get_name )
          }
        end
      end
    }
  end

  def find_dynamic_port signature
    dbgPrint "[DYNAMIC] find_dynamic_port signature=#{signature.get_name}"
    @port.each{ |port|
      dbgPrint "[DYNAMIC] port=#{port.get_name} signature=#{port.get_signature.get_name} dynamic=#{port.is_dynamic?}"
      return port if port.is_dynamic? && port.get_signature == signature
    }
    return nil
  end
  def find_ref_desc_port signature
    if signature == nil then  # すでにエラー
      return nil
    end
    dbgPrint "[DYNAMIC] find_ref_desc_port signature=#{signature.get_name}"
    @port.each{ |port|
      dbgPrint "[DYNAMIC] port=#{port.get_name} signature=#{port.get_signature.get_name} ref_desc=#{port.is_ref_desc?}"
      return port if port.is_ref_desc? && port.get_signature == signature
    }
    return nil
  end
  #=== Celltype#ディスクリプタ型でシグニチャが一致し dyn_ref に対応づく引数を探す
  #dyn_ref::Symbol: :DYNAMIC=ディスクリプタを得る手段となる引数を探す．:REF_DESC=渡す手段となる引数を探す
  def find_descriptor_param signature, dyn_ref
    param_list = []
    @port.each{ |port|
      port.each_param{ |port, func, param|
        type = param.get_type
        while type.kind_of? PtrType
          type = type.get_type
        end
        dbgPrint( "[DYNAMIC] dyn_ref=#{dyn_ref} port_type=#{port.get_port_type} dir=#{param.get_direction} paramName=#{param.get_name} paramType=#{type.class}\n" )
        # print( "[DYNAMIC] dyn_ref=#{dyn_ref} port_type=#{port.get_port_type} dir=#{param.get_direction} paramName=#{param.get_name} paramType=#{type.class}\n" )
        if type.kind_of? DescriptorType then
          if type.get_signature == signature then
            dir = param.get_direction
            if dir == :INOUT then
              dbgPrint( "[DYNAMIC] found INOUT Descriptor parameter: #{@global_name}.#{port.get_name} ... #{param.get_name}\n" )
              # print( "[DYNAMIC] found INOUT Descriptor parameter: #{@global_name}.#{port.get_name} ... #{param.get_name}\n" )
              return param
            elsif dyn_ref == :DYNAMIC then
              if dir == :IN && port.get_port_type == :ENTRY ||
                 dir == :OUT && port.get_port_type == :CALL then
                dbgPrint( "[DYNAMIC] found INBOUND Descriptor parameter: #{@global_name}.#{port.get_name} ... #{param.get_name}\n" )
                # print( "[DYNAMIC] found INBOUND Descriptor parameter: #{@global_name}.#{port.get_name} ... #{param.get_name}\n" )
                return param
              end
            elsif dyn_ref == :REF_DESC
              if dir == :IN && port.get_port_type == :CALL ||
                 dir == :OUT && port.get_port_type == :ENTRY then
                dbgPrint( "[DYNAMIC] found OUTBOUND Descriptor parameter: #{@global_name}.#{port.get_name} ... #{param.get_name}\n" )
                # print( "[DYNAMIC] found OUTBOUND Descriptor parameter: #{@global_name}.#{port.get_name} ... #{param.get_name}\n" )
                return param
              end
            else
              raise "unknown ref_desc"
            end
          end
        end
      }
    }
    return nil
  end

  #=== Celltype# celltype に新しい cell を追加
  #cell:: Cell
  # 新しいセルをセルタイプに追加．
  # セルの構文解釈の最後でこのメソドを呼出される．
  # シングルトンセルが同じ linkunit に複数ないかチェック
  def new_cell( cell )
    dbgPrint "Celltype#new_cell( #{cell.get_name} )\n"
    # Celltype では Cell の set_owner しない
    # シングルトンで、プロトタイプ宣言でない場合、コード生成対象リージョンの場合
    if @singleton  then
      @cell_list.each{ |c|
        if c.get_region.get_link_root == cell.get_region.get_link_root then
          cdl_error( "S1024 $1: multiple cell for singleton celltype" , @name )
        end
      }
    end
    @cell_list << cell

    # プラグインにより生成されたセルタイプか ?
    if @plugin then
      @plugin.new_cell cell
    end

    # セルタイププラグインの適用
    celltype_plugin_new_cell cell
  end

  #=== Celltype# セルタイプは INIB を持つか？
  # セルタイプが INIB を持つかどうかを判定する
  # $rom == false のとき:  INIB を持たない． （すべては CB に置かれる）
  # $rom == true のとき、INIB に置かれるものが一つでも存在すれば INIB を持つ
  #   INIB に置かれるものは
  #     attribute (omit のものは除く．現仕様では rw のものはない)
  #     size_is を伴う var
  #     呼び口（ただし、最適化で不要となるものは除く）
  def has_INIB?

    result = $rom &&
             (@n_attribute_ro > 0 ||
              @n_var_size_is > 0 ||
              ( @n_call_port - @n_call_port_omitted_in_CB - (@n_call_port_dynamic-@n_call_port_array_dynamic) ) > 0 ||
              $ram_initializer && @n_call_port_dynamic > 0 ||
              @n_entry_port_array_ns > 0)
    # print "name=#{@name} n_attribute_ro=#{@n_attribute_ro}  n_var_size_is=#{@n_var_size_is} n_call_port=#{@n_call_port} n_call_port_omitted_in_CB=#{@n_call_port_omitted_in_CB} n_call_port_dynamic=#{@n_call_port_dynamic} n_call_port_array_dynamic=#{@n_call_port_array_dynamic} n_entry_port_array_ns=#{@n_entry_port_array_ns} has_INIB?=#{result}\n"

    return result
  end

  #=== Celltype# セルタイプは CB を持つか？
  # $rom == true のとき、いかのものが置かれる．それらの一つでも存在すれば CB を持つ
  #   size_is が指定されていない var
  #   rw 指定された attribute (現仕様では存在しない)
  # $rom == false のとき、いかのものが置かれる．それらの一つでも存在すれば CB を持つ
  #   attribute
  #   var
  #   呼び口（ただし、最適化で不要となるものは除く）
  def has_CB?
    if $rom then
      return @n_attribute_rw > 0 || (@n_var-@n_var_size_is) > 0 || (@n_call_port_dynamic - @n_call_port_array_dynamic) > 0
      # return @n_attribute_rw > 0 || @n_var > 0
    else
      return @n_attribute_rw > 0 || @n_attribute_ro > 0 || @n_var > 0 || (@n_call_port-@n_call_port_omitted_in_CB) > 0 || @n_entry_port_array_ns > 0
    end
  end

  #=== Celltype# SET_CB_INIB_POINTER, INITIALIZE_CB が必要か
  def need_CB_initializer?
    @n_var_init > 0 || has_CB? || ( @n_call_port_dynamic && $ram_initializer )
  end

  #=== Celltype# 逆require の結合を生成する
  def create_reverse_require_join cell
    @port.each{ |p|
      p.create_reverse_require_join cell
    }
  end

  #=== Celltype# singleton セルを得る
  #region:: Region   : singleton を探す Region
  # 距離が最も近いものを返す
  # mikan 本当は region の範囲の singleton を探す必要がある
  def get_singleton_cell region
    cell = nil
    dist = 999999999 # mikan 制限値（これは十分すぎるほどデカイが）
    # require: celltype で指定
    @cell_list.each{ |c|
      # 到達可能で最も近いセルを探す（複数の singleton があるかもしれない）
      d = region.distance( c.get_region )
      #debug
      dbgPrint "distance #{d} from #{region.get_name} to #{c.get_name} in #{c.get_region.get_name}\n"
      if d != nil then
        if d < dist then
          cell = c
          dist = d
        end
      end
    }
    if cell then
      dbgPrint "distance found:#{cell.get_name} in #{cell.get_region.get_name}\n"
    else
      dbgPrint "distance not found\n"
    end
    return cell
  end

  def find( name )
    @name_list.get_item( name )
  end

=begin
  @generate_list に @generate も入っているので、これは使わない方がよい
  #=== Celltype# セルタイププラグインを得る
  def get_celltype_plugin
    if @generate then
      return @generate[2]
    end
  end
=end

  def get_global_name
    @global_name
  end

  def is_singleton?
    @singleton
  end

  def is_active?
    @active
  end

  def idx_is_id_act?
    @idx_is_id_act
  end

  def multi_domain?
    @b_need_ptab
  end

  #=== Celltype# アクティブではないか
  # このメソッドでは active の他に factory (singleton においては FACTORYを含む)がなければ inactive とする
  def is_inactive?
    if @active == false && @factory_list.length == 0 &&
        ( @singleton && @ct_factory_list.length == 0 || ! @singleton )then
      return true
    end
    return false
  end

  def get_id_base
    @id_base
  end

  def get_plugin
    @plugin
  end

  def get_require
    @require
  end

  #=== Celltype# コード生成する必要があるか判定
  # セルの個数が 0 ならセルタイプコードは生成不要
  def need_generate?
    @n_cell_gen > 0
  end

  #=== Celltype# require 呼び口の結合を行う
  # STAGE: S
  # セルタイプの require 呼び口について、結合を行う
  # セルが生成されないかチェックを行う
  def set_require_join
    @require.each{ |req|
      cp_name = req[0]
      cell_or_ct = req[1]
      port = req[2]
      @cell_list.each{ |c|
        c.set_require_join( cp_name, cell_or_ct, port )
      }
    }
  end

  def get_cell_list
    @cell_list
  end

  #=== Celltype# inline 受け口しかないか？
  # 受け口が無い場合、すべての受け口が inline とはしない
  def is_all_entry_inline?
    @n_entry_port == @n_entry_port_inline && @n_entry_port > 0
  end

  #=== Celltype# セルタイプコード (celltype.c) を持つか
  #false の場合、celltype_inline.h しか持たない
  def has_celltype_code?
    ! (is_all_entry_inline? && ! is_active?)
  end

  #=== Celltype.get_celltype_list
  def self.get_celltype_list
    @@celltype_list
  end

  def show_tree( indent )
    indent.times { print "  " }
    puts "Celltype: name=#{@name} global_name=#{@global_name}"  
    (indent+1).times { print "  " }
    puts "active=#{@active}, singleton=#{@singleton}, idx_is_id=#{@idx_is_id} plugin=#{@plugin.class} reuse=#{@b_reuse}"
    (indent+1).times { print "  " }
    puts "namespace_path: #{@NamespacePath}"
    (indent+1).times { print "  " }
    puts "port:"
    @port.each { |i| i.show_tree( indent + 2 ) }
    (indent+1).times { print "  " }
    puts "attribute:"
    @attribute.each { |i| i.show_tree( indent + 2 ) }
    (indent+1).times { print "  " }
    puts "var:"
    @var.each { |i| i.show_tree( indent + 2 ) }
#    (indent+1).times { print "  " }
#    puts "require:"   mikan
#    @require.each { |i| i.show_tree( indent + 2 ) }
    (indent+1).times { print "  " }
    puts "factory:"
    @factory_list.each { |i| i.show_tree( indent + 2 ) }
    (indent+1).times { print "  " }
    puts "@n_attribute_ro #{@n_attribute_ro}"
    (indent+1).times { print "  " }
    puts "@n_attribute_rw #{@n_attribute_rw}"
# @n_attribute_omit : int >= 0  # of [omit] specified cells
# @n_var:: int >= 0
# @n_var_size_is:: int >= 0     # of [size_is] specified cells # mikan count_is
# @n_var_omit:: int >= 0        # of [omit] specified  cells # mikan var の omit は有？
# @n_call_port:: int >= 0
# @n_call_port_array:: int >= 0
# @n_call_port_omitted_in_CB:: int >= 0   最適化で省略される呼び口
# @n_entry_port:: int >= 0
# @n_entry_port_array:: int >= 0
    (indent+1).times { print "  " }
    puts "@n_entry_port_inline #{@n_entry_port_inline}"
# @n_cell:: int >= 0  コード生成の頭で算出する．意味解析段階では参照不可
# @id_base:: Integer : cell の ID の最小値(最大値は @id_base + @n_cell)

  end
end

