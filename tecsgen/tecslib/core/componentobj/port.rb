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
#   $Id: port.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

#== 構文要素：口を表すクラス（セルタイプの呼び口、受け口）
class Port < BDNode
# @name::  str
# @signature:: Signature
# @port_type::  :CALL, :ENTRY
# @array_size:: nil: not array, "[]": sizeless, Integer: sized array
# @reverse_require_cell_path:: NamespacePath :     逆require呼び元セル  mikan namespace (呼び口のみ指定可能)
# @reverse_require_callport_name:: Symbol:  逆require呼び元セルの呼び口名
#
# set_allocator_port によって設定される．設定された場合、このポートはアロケータポートである。
# @allocator_port:: Port : この呼び口ができる元となった呼び口または受け口
# @allocator_func_decl:: Decl : この呼び口ができる元となった呼び口または受け口の関数
# @allocator_param_decl:: ParamDecl : この呼び口ができる元となった呼び口または受け口のパラメータ
#
# set_specifier によって設定される(
# @allocator_instance:: Hash : {"func_param" => [ :RELAY_ALLOC, func_name, param_name, rhs_cp_name, rhs_func_name, rhs_param_name ]}
#                                               [:INTERNAL_ALLOC, func_name, param_name, rhs_ep_name ]
# @allocator_instance_tmp:: Hash : {"func_param" => [:INTERNAL_ALLOC|:RELAY_ALLOC,  IDENTIFIER, IDENTIFIER, expression ],..}
#                                                                                    function    parameter   rhs
#
# @b_require:: bool : require により生成された call port の場合 true
# @b_has_name:: bool : require : 名前ありのリクワイア呼び口
# @b_inline:: bool : entry port のみ
# @b_omit:: bool : omit 指定子が指定された (call port のみ)
# @b_optional:: bool : call port のみ
# @b_ref_desc:: bool :  ref_desc キーワードが指定された
# @b_dynamic:: bool :  dynamic キーワードが指定された (呼び口のみ)
#
# optimize::
# @celltype:: 属するセルタイプ
#
# :CALL の場合の最適化
# @b_VMT_useless:: bool                     # VMT 関数テーブルを使用しない
# @b_skelton_useless:: bool                 # スケルトン関数不要   (true の時、受け口関数を呼出す)
# @b_cell_unique:: bool                     # 呼び先は唯一のセル
# @only_callee_port:: Port                  # 唯一の呼び先ポート
# @only_callee_cell:: Cell                  # 唯一の呼び先セル (@b_PEPDES_in_CB_useless = true の時有効)
#
# :ENTRY の場合の最適化（呼び口最適化と同じ変数名を使用）
# @b_VMT_useless:: bool                     # VMT 関数テーブルが不要
# @b_skelton_useless:: bool                 # スケルトン関数不要

  def initialize( name, sig_path, port_type, array_size = nil, reverse_require_cell_path = nil, reverse_require_entry_port_name = nil )
    super()
    @name = name
    @port_type = port_type

    if array_size == "[]" then
#      if port_type == :ENTRY then
#        cdl_error( "S1072 $1: entry port: sizeless array not supported in current version" , name )
#      end
      @array_size = array_size
    elsif array_size then
      if array_size.kind_of? Expression then
        @array_size = array_size.eval_const(nil)
      else
        @array_size = array_size   # これはアロケータ呼び口の場合（元の呼び口で既に評価済み）
      end
      if @array_size == nil then
        cdl_error( "S1073 Not constant expression $1" , array_size.to_s )
      end

      #if Integer( @array_size ) != @array_size || @array_size <= 0 then
      if ! @array_size.kind_of? Integer then
        cdl_error( "S1074 Not Integer $1" , array_size.to_s )
      end

    end

    object = Namespace.find( sig_path )    #1
    if object == nil then
      # mikan signature の名前が不完全
      cdl_error( "S1075 \'$1\' signature not found" , sig_path )
    elsif ! object.instance_of?( Signature ) then
      # mikan signature の名前が不完全
      cdl_error( "S1076 \'$1\' not signature" , sig_path )
    else
      @signature = object

    end

    # 逆require
    @reverse_require_cell_path       = nil
    @reverse_require_entry_port_name = nil
    if reverse_require_cell_path then
      if port_type == :CALL then
        cdl_error( "S1152 $1 call port cannot have fixed join", @name )
      else
        @reverse_require_cell_path       = reverse_require_cell_path
        @reverse_require_entry_port_name = reverse_require_entry_port_name

        # 受け口配列か？
        if array_size then
          cdl_error( "S1153 $1: cannot be entry port array for fixed join port", @name )
        end

        # 呼び口のセルタイプを探す
        ct_or_cell = Namespace.find( @reverse_require_cell_path )  #1
        if ct_or_cell.instance_of? Cell then
          ct = ct_or_cell.get_celltype
        elsif ct_or_cell.instance_of? Celltype then
          ct = ct_or_cell
          if ! ct.is_singleton? then
            cdl_error( "S1154 $1: must be singleton celltype for fixed join", @reverse_require_cell_path.to_s )
          end
        else
          ct = nil
          cdl_error( "S1155 $1: not celltype or not found", @reverse_require_cell_path.get_path_str)
        end

        if ct == nil then
          return    # 既にエラー
        end

        # 添え字なしの呼び口配列か？
        port = ct.find( @reverse_require_entry_port_name )
        if port == nil || port.get_port_type != :CALL
          cdl_error( "S1156 $1: not call port or not found", @reverse_require_entry_port_name )
        else
          if port.get_array_size != "[]" then
            cdl_error( "S1157 $1: sized array or not array", @reverse_require_entry_port_name )
          end
        end

      end
    end

    @b_require = false
    @b_has_name = false
    @b_inline = false
    @b_optional = false
    @b_omit = false
    @b_ref_desc = false
    @b_dynamic = false
    reset_optimize
  end

  #=== Port#最適化に関する変数をリセットする
  # Region ごとに最適化のやりなおしをするため、リセットする
  def reset_optimize
    if @port_type == :CALL then
      # call port optimize
      @b_VMT_useless = false                     # VMT 不要 (true の時 VMT を介することなく呼出す)
      @b_skelton_useless = false                 # スケルトン関数不要   (true の時、受け口関数を呼出す)
      @b_cell_unique = false                     # 唯一の呼び先セル
      @only_callee_port = nil                    # 唯一の呼び先ポート
      @only_callee_cell = nil                    # 唯一の呼び先セル
    else
      # entry port optimize
      if $unopt || $unopt_entry then
        # 最適化なし
        @b_VMT_useless = false                     # VMT 不要 (true の時 VMT を介することなく呼出す)
        @b_skelton_useless = false                 # スケルトン関数不要   (true の時、受け口関数を呼出す)
      else
        # 最適化あり
        @b_VMT_useless = true                      # VMT 不要 (true の時 VMT を介することなく呼出す)
        @b_skelton_useless = true                  # スケルトン関数不要   (true の時、受け口関数を呼出す)
      end
    end
  end

  def set_celltype celltype
    @celltype = celltype
  end

  def get_name
    @name
  end

  def get_port_type
    @port_type
  end

  def get_signature
    @signature
  end

  def get_array_size
    @array_size
  end

  def get_celltype
    @celltype
  end

  #=== Port# アロケータポートの設定
  #port:: Port : send/receive のあった呼び口または受け口
  #fd:: Decl : 関数の declarator
  #par:: ParamDecl : send/receive のあった引数
  # この呼び口が生成されるもとになった呼び口または受け口の情報を設定
  def set_allocator_port( port, fd, par )
    @allocator_port = port
    @allocator_func_decl = fd
    @allocator_param_decl = par
  end

  def is_allocator_port?
    @allocator_port != nil
  end

  def get_allocator_port
    @allocator_port
  end

  def get_allocator_func_decl
    @allocator_func_decl
  end

  def get_allocator_param_decl
    @allocator_param_decl
  end

  def set_require( b_has_name )
    @b_require = true
    @b_has_name = b_has_name
  end

  def is_require?
    @b_require
  end

  #=== Port# require 呼び口が名前を持つ？
  # require 限定
  def has_name?
    @b_has_name
  end

  def is_optional?
    @b_optional
  end

  def set_optional
    @b_optional = true
  end

  #=== Port# omit 指定されている?
  def is_omit?
    @b_omit || ( @signature && @signature.is_empty? )
  end

  def set_omit
    @b_omit = true
  end

  def set_VMT_useless                     # VMT 関数テーブルを使用しない
   @b_VMT_useless = true
  end

  def set_skelton_useless                 # スケルトン関数不要   (true の時、受け口関数を呼出す)
    @b_skelton_useless = true
  end

  def set_cell_unique                     # 呼び先セルは一つだけ
    @b_cell_unique = true
  end

  #=== Port# 呼び口/受け口の指定子の設定
  # inline, allocator の指定
  def set_specifier spec_list
    spec_list.each { |s|
      case s[0]
      when :INLINE
        if @port_type == :CALL then
          cdl_error( "S1077 inline: cannot be specified for call port"  )
          next
        end
        @b_inline = true
      when :OMIT
        if @port_type == :ENTRY then
          cdl_error( "S9999 omit: cannot be specified for entry port"  )
          next
        end
        @b_omit = true
      when :OPTIONAL
        if @port_type == :ENTRY then
          cdl_error( "S1078 optional: cannot be specified for entry port"  )
          next
        end
        @b_optional = true
      when :REF_DESC
        if @port_type == :ENTRY then
          cdl_error( "S9999 ref_desc: cannnot be specified for entry port" )
          next
        end
        @b_ref_desc = true
      when :DYNAMIC
        if @port_type == :ENTRY then
          cdl_error( "S9999 dynamic: cannnot be specified for entry port" )
          next
        end
        @b_dynamic = true
      when :ALLOCATOR
        if @port_type == :CALL then
          cdl_error( "S1079 allocator: cannot be specified for call port"  )
        end
        if @allocator_instance_tmp then
          cdl_error( "S1080 duplicate allocator specifier"  )
          next
        end
        @allocator_instance_tmp = s[1]
      else
        raise "unknown specifier #{s[0]}"
      end
    }
    if ( @b_dynamic || @b_ref_desc ) then
      if @b_dynamic then
        dyn_ref = "dynamic"
      else
        dyn_ref = "ref_desc"
      end
      if @b_omit then     # is_omit? は is_empty? も含んでいるので使えない
        cdl_error( "S9999 omit cannot be specified with $1", dyn_ref  )
      elsif @signature && @signature.is_empty? then
        cdl_error( "S9999 $1 cannot be specified for empty signature", dyn_ref  )
      elsif @signature && @signature.has_descriptor? then
        # cdl_error( "S9999 $1 port '$2' cannot have Descriptor in its signature", dyn_ref, @name )
      end

    elsif @b_dynamic && @b_ref_desc then
      cdl_error( "S9999 both dynamic & ref_desc cannot be specified simultaneously"  )
    end
  end

  #=== Port# リレーアロケータ、内部アロケータのインスタンスを設定
  # 呼び口の前方参照可能なように、セルタイプの解釈の最後で行う
  def set_allocator_instance
    if @allocator_instance_tmp == nil then
      return
    end

    @allocator_instance = {}
    @allocator_instance_tmp.each { |ai|
      direction = nil
      alloc_type = ai[0]
      # ai = [ :INTERNAL_ALLOC|:RELAY_ALLOC, func_name, param_name, rhs ]
      case alloc_type
      when :INTERNAL_ALLOC
        if ! @owner.instance_of? CompositeCelltype then # ミスを防ぐために composite でなければとした
          cdl_error( "S1081 self allocator not supported yet"  )   # mikan これはサポートされているはず。要調査 12/1/15
          next
        end
        # OK
      when :RELAY_ALLOC
        # OK
      when :NORMAL_ALLOC
        # ここへ来るのは composite の受け口で右辺が "eEnt.func.param" 形式で指定されていた場合
        cdl_error( "S1174 $1 not suitable for lhs, suitable lhs: 'func.param'", "#{ai[1]}.#{ai[3]}.#{ai[4]}" )
        next
      else
        raise "Unknown allocator type #{ai[1]}"
      end

      # '=' 左辺(func_name,param_name)は実在するか?
      if @signature then       # signature = nil なら既にエラー
        fh = @signature.get_function_head( ai[1] )
        if fh == nil then
          cdl_error( "S1082 function \'$1\' not found in signature" , ai[1] )
          next
        end
        decl = fh.get_declarator
        if ! decl.is_function? then
          next   # 既にエラー
        end
        paramdecl = decl.get_type.get_paramlist.find( ai[2] )
        if paramdecl == nil then
          cdl_error( "S1083 \'$1\' not found in function \'$2\'" , ai[2], ai[1] )
          next
        end
        case paramdecl.get_direction
        when :SEND, :RECEIVE
          # OK
          direction = paramdecl.get_direction
        else
          cdl_error( "S1084 \'$1\' in function \'$2\' is not send or receive" , ai[2], ai[1] )
          next
        end
      end

      # 重複指定がないか?
      if @allocator_instance[ "#{@name}_#{ai[1]}_#{ai[2]}" ] then
        cdl_error( "S1085 duplicate allocator specifier for \'$1_$2\'" , ai[1], ai[2] )
      end

      # 右辺のチェック
      case alloc_type
      when :INTERNAL_ALLOC

        ele = ai[3].get_elements
        if( ele[0] != :IDENTIFIER )then
          cdl_error( "S1086 $1: rhs not in 'allocator_entry_port' form", ai[3].to_s )
          next
        end

        ep_name = ele[1]   # アロケータ受け口名
        ep = @owner.find ep_name.get_path[0]  # mikan "a::b"
        if ep == nil || ! ep.instance_of?( Port ) || ep.get_port_type != :ENTRY || ! ep.get_signature.is_allocator? then
          cdl_error( "S1175 $1 not found or not allocator entry port for $2" , ep_name, ai[1] )
        end
        # 右辺チェック終わり
        # ai2 = [ :INTERNAL_ALLOC, func_name, param_name, rhs_ep_name ]
        ai2 = [ ai[0], ai[1], ai[2], ep_name ]

      when :RELAY_ALLOC
        ele = ai[3].get_elements
        if( ele[0] != :OP_DOT ||
            ele[1][0] != :OP_DOT || ele[1][1][0] != :IDENTIFIER || ! ele[1][1][1].is_name_only? ||
            ! ele[1][2].instance_of?( Token ) || ! ele[2].instance_of?( Token ) )then   #1
          # [ :OP_DOT, [ :OP_DOT, [ :IDENTIFIER,  name_space_path ],  Token(1) ],  Token(2) ]
          #    ele[0]    ele[1][0]  ele[1][1][0]  ele[1][1][1]        ele[1][2]    ele[2]
          #      name_space_path.Token(1).Token(2) === call_port.func.param
          #  mikan Expression#analyze_cell_join_expression の変種を作成して置き換えるべき

          cdl_error( "S1176 rhs not in 'call_port.func.param' form for for $1_$2" , ai[1], ai[2] )   # S1086
          next
        end
        func_name = ele[1][2]; cp_name = ele[1][1][1].get_name; param_name = ele[2].to_sym
        cp = @owner.find cp_name    # リレーする先の呼び口
        if cp then
# mikan cp が呼び口であることのチェック（属性の場合もある）
# mikan 受け口から受け口へのリレーへの対応 (呼び口から呼び口へのリレーはありえない)  <=== 文法にかかわる事項（呼び口側でアロケータが決定される）
          sig = cp.get_signature
          if sig && @signature then
            fh = @signature.get_function_head( func_name )
            if fh == nil then
              cdl_error( "S1087 function \'$1\' not found in signature \'$2\'" , func_name, sig.get_name )
              next
            end
            decl = fh.get_declarator
            if ! decl.is_function? then
              next   # 既にエラー
            end
            paramdecl = decl.get_type.get_paramlist.find( param_name )
            if paramdecl == nil then
              cdl_error( "S1088 \'$1\' not found in function \'$2\'" , param_name, func_name )
              next
            end
            case paramdecl.get_direction
            when :SEND, :RECEIVE
              # OK
              if alloc_type == :RELAY_ALLOC && direction != paramdecl.get_direction then
                cdl_error( "S1089 relay allocator send/receive mismatch between $1.$2 and $3_$4.$5" , ai[1], ai[2], cp_name, func_name, param_name )
              end
            else
              cdl_error( "S1090 \'$1\' in function \'$2\' is not send or receive" , param_name, func_name )
              next
            end

            # else
            # sig == nil ならば既にエラー
          end
        else
          if @celltype then
            ct_name = @celltype.get_name
          else
            ct_name = "(None)"
          end
          cdl_error( "S1091 call port \'$1\' not found in celltype $2" , cp_name, ct_name )
          next
        end
        # 右辺チェック終わり
        # ai2 = [ :RELAY_ALLOC, func_name, param_name, rhs_cp_name, rhs_func_name, rhs_param_name ]
        ai2 = [ ai[0], ai[1], ai[2], cp_name, func_name, param_name ]
      end # case alloc_type

      @allocator_instance[ "#{@name}_#{ai[1]}_#{ai[2]}" ] = ai2
    }
  end

  def is_inline?
    @b_inline
  end

  def is_VMT_useless?                     # VMT 関数テーブルを使用しない
    if @port_type == :ENTRY && $unopt_entry == true then
      # プラグインから $unopt_entry を設定するケースのため
      # ここで読み出すときに、false を返す (reset_optimize での設定変更は速すぎる)
      return false
    else
      return @b_VMT_useless
    end
  end

  def is_skelton_useless?                 # スケルトン関数不要   (true の時、受け口関数を呼出す)
    if @port_type == :ENTRY && $unopt_entry == true then
      # プラグインから $unopt_entry を設定するケースのため
      # ここで読み出すときに、false を返す (reset_optimize での設定変更は速すぎる)
      return false
    else
      return @b_skelton_useless
    end
  end

  def is_cell_unique?                     # 呼び先のセルは一つ？
    @b_cell_unique
  end

  #=== Port# 受け口最適化の設定
  # この受け口を参照する呼び口が VMT, skelton を必要としているかどうかを設定
  # 一つでも呼び口が必要としている（すなわち b_*_useless が false）場合は、
  # この受け口の最適化を false とする
  def set_entry_VMT_skelton_useless( b_VMT_useless, b_skelton_useless )
    if ! b_VMT_useless then
      @b_VMT_useless = false
    end
    if ! b_skelton_useless then
      @b_skelton_useless = false
    end
  end

  #=== Port# 唯一の結合先を設定
  # 最適化で使用
  #  b_VMT_useless == true || b_skelton_useless == true の時に設定される
  #  optional の場合 callee_cell, callee_port が nil となる
  def set_only_callee( callee_port, callee_cell )
    @only_callee_port = callee_port
    @only_callee_cell = callee_cell
  end

  #=== Port# 唯一の結合先ポートを返す(compositeの場合実セル)
  # optional 呼び口で未結合の場合 nil を返す
  def get_real_callee_port
    if @only_callee_cell then
      return @only_callee_cell.get_real_port( @only_callee_port.get_name )
    end
  end

  #=== Port# 唯一の結合先セルを返す(compositeの場合実セル)
  # optional 呼び口で未結合の場合 nil を返す
  def get_real_callee_cell
    if @only_callee_cell then
      return @only_callee_cell.get_real_cell( @only_callee_port.get_name )
    end
  end

  def get_allocator_instance
    return @allocator_instance
  end

  def get_allocator_instance_tmp
    return @allocator_instance_tmp
  end

  #=== Port# 逆require の結合を生成する
  # STAGE: S
  def create_reverse_require_join cell
    if @reverse_require_cell_path == nil then
      return
    end

    # 呼び元セルを探す
    ct_or_cell = Namespace.find( @reverse_require_cell_path )   # mikan namespace    #1
    if ct_or_cell.instance_of? Cell then
      cell2 = ct_or_cell
      ct = cell2.get_celltype
      if ct == nil then
        return    # 既にエラー
      end
    elsif ct_or_cell.instance_of? Celltype then
      cell2 = ct_or_cell.get_singleton_cell( cell.get_region )
      if cell2 == nil then
        cdl_error( "S1158 $1: singleton cell not found for fixed join", ct_or_cell.get_name )
        return
      end
      ct = ct_or_cell
    else
      # 既にエラー：無視
      return
    end

    # 結合を生成する
    dbgPrint "create_reverse_require_join #{cell2.get_name}.#{@reverse_require_entry_port_name}[] = #{cell.get_name}.#{@name}"
    nsp = NamespacePath.new( cell.get_name, false, cell.get_namespace )
#    rhs = Expression.new( [ :OP_DOT, [ :IDENTIFIER, Token.new( cell.get_name, nil, nil, nil ) ],
    rhs = Expression.new( [ :OP_DOT, [ :IDENTIFIER, nsp ],
                            Token.new( @name, nil, nil, nil ) ], cell.get_locale )   #1
    join = Join.new( @reverse_require_entry_port_name, -1, rhs, cell.get_locale )
    cell2.new_join( join )
    join.set_definition( ct.find(join.get_name) )

  end

  #=== Port# signature のすべての関数のすべてのパラメータをたどる
  #block:: ブロックを引数として取る(ruby の文法で書かない)
  #  ブロックは3つの引数を受け取る(Port, Decl,      ParamDecl)    Decl: 関数ヘッダ
  # Signature クラスにも each_param がある（同じ働き）
  def each_param &pr # ブロック引数{  |port, func_decl, param_decl| }
    return if @signature == nil                         # signature 未定義（既にエラー）
    fha = @signature.get_function_head_array            # 呼び口または受け口のシグニチャの関数配列
    return if fha == nil                                # nil なら文法エラーで有効値が設定されなかった

    # obsolete Ruby 3.0 では使用できない
    # pr = Proc.new   # このメソッドのブロック引数を pr に代入
    port = self
    fha.each{ |fh|  # fh: FuncHead                      # 関数配列中の各関数頭部
      fd = fh.get_declarator                            # fd: Decl  (関数頭部からDeclarotorを得る)
      if fd.is_function? then                           # fd が関数でなければ、すでにエラー
        fd.get_type.get_paramlist.get_items.each{ |par| # すべてのパラメータについて
          pr.call( port, fd, par )
        }
      end
    }
  end

  #=== Port# 逆require指定されている？
  def is_reverse_required?
    @reverse_require_cell_path != nil
  end

  #=== Port# is_dynamic?
  def is_dynamic?
    @b_dynamic
  end

  #=== Port# is_ref_desc?
  def is_ref_desc?
    @b_ref_desc
  end

  def show_tree( indent )
    indent.times { print "  " }
    puts "Port: name:#{@name} port_type:#{@port_type} require:#{@b_require} inline:#{@b_inline} omit:#{@b_omit} optional:#{@b_optional} ref_desc:#{@b_ref_desc} dynamic:#{@b_dynamic}"
    (indent+1).times { print "  " }
    if @signature then
      puts "signature: #{@signature.get_name} #{@signature}"
    else
      puts "signature: NOT defined"
    end
    if @array_size == "[]" then
      (indent+1).times { print "  " }
      puts "array_size: not specified"
    elsif @array_size then
      (indent+1).times { print "  " }
      puts "array_size: #{@array_size}"
    end
    if @allocator_instance then
      (indent+1).times { print "  " }
      puts "allocator instance:"
      @allocator_instance.each { |b,a|
        (indent+2).times { print "  " }
        puts "#{a[0]} #{a[1]} #{b} "
        # a[3].show_tree( indent+3 )
      }
    end
    (indent+1).times { print "  " }
    if @port_type == :CALL then
      puts "VMT_useless : #{@b_VMT_useless}  skelton_useless : #{@b_skelton_useless}  cell_unique : #{@b_cell_unique}"
    else
      puts "VMT_useless : #{@b_VMT_useless}  skelton_useless : #{@b_skelton_useless}"
    end
  end

end
