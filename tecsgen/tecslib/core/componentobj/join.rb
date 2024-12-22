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
#   $Id: join.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

class Join < BDNode
# 結合の左辺
# @name:: string : 属性名 or 呼び口名
# @subscript:: nil: not array, -1: subscript not specified, >=0: array_subscript
# @definition:: Port, Decl(attribute or var)
#
# 結合の右辺
# @rhs:: Expression | initializer ( array of Expression | initializer (Expression | C_EXP) )
# available if definition is Port
# @cell_name:: string : 右辺のセルの名前
# @cell:: Cell  : 右辺のセル
# @celltype:: Celltype : 右辺のセルタイプ
# @port_name:: string : 右辺の受け口名
# @port:: Port : 右辺の受け口
# @array_member:: rhs array : available only for first appear in the same name
# @array_member2:: Join array : available only for first appear in the same name
# @rhs_subscript:: nil : not array, >=0: 右辺の添数
#

# @through_list::  @cp_through_list + @region_through_list + @ep_through_list
#  以下の構造を持つ（@cp_through_list の構造は共通）
# @cp_through_list::  呼び口に指定された through
#   [ [plugin_name, cell_name, plugin_arg], [plugin_name2, cell_name2, plugin_arg], ... ]
# @ep_through_list::  受け口に指定された through
#   [ [plugin_name, cell_name, plugin_arg], [plugin_name2, cell_name2, plugin_arg], ... ]
# @region_through_list::  region に指定された through
#   [ [plugin_name, cell_name, plugin_arg, region], [plugin_name2, cell_name2, plugin_arg, region2], ... ]
#
# @through_generated_list:: [Plugin_class object, ...]: @through_list に対応
# @region_through_generated_list:: [Plugin_class object, ...]: @region_through_list に対応
#

  include PluginModule

  #=== Join# 初期化
  #name:: string: 名前（属性名、呼び口名）
  #subscript:: Nil=非配列, -1="[]", N="[N]"
  #rhs:: Expression: 右辺の式
  def initialize( name, subscript, rhs, locale = nil )
    # dbgPrint "Join#new: #{name}, #{subscript} #{rhs.eval_const(nil)}\n"
    dbgPrint "Join#new: #{name}, #{subscript}\n"

    super()
    if locale then
      @locale = locale
    end

    @name = name
    if subscript.instance_of?( Expression ) then
       #mikan 配列添数が整数であることを未チェック
       @subscript = subscript.eval_const(nil)
       if @subscript == nil then
         cdl_error( "S1099 array subscript not constant"  )
       end
    else
       @subscript = subscript
    end

    @rhs = rhs
    @definition = nil

    # 配列要素を設定
    # 本当は、初出の要素のみ設定するのが適当
    # new_join で add_array_member の中で初出要素の array_member に対し設定する
    if @subscript == -1 then
      @array_member  = [self]
      @array_member2 = [self]
    elsif @subscript != nil then
      @array_member = []
      @array_member2 = []
      @array_member[@subscript]  = self
      @array_member2[@subscript] = self
    end

    @through_list = []
    @cp_through_list = []
    @ep_through_list = []
    @region_through_list = []
    @through_generated_list = []
    @region_through_generated_list = []
  end

  #===  Join# 左辺に対応する celltype の定義を設定するとともにチェックする
  # STAGE:   S
  #
  #     代入可能かチェックする
  #definition:: Decl (attribute,varの時) または Port (callの時) または nil (definition が見つからなかった時)

  def set_definition( definition )

    dbgPrint "set_definition: #{@owner.get_name}.#{@name} = #{definition.class}\n"

    # 二重チェックの防止
    if @definition then
      # set_definition を個別に行うケースで、二重に行われる可能性がある（異常ではない）
      # 二重に set_definition が実行されると through が二重に適用されてしまう
      # cdl_warning( "W9999 $1, internal error: set_definition duplicate", @name )
      return
    end

    @definition = definition

    # mikan 左辺値、右辺値の型チェックなど
    if @definition.instance_of?( Decl ) then
      check_var_init
    elsif @definition.instance_of?( Port ) then
      check_call_port_init
      if @definition.get_port_type == :CALL then   # :ENTRY ならエラー。無視しない
        check_and_gen_through
        create_allocator_join  # through プラグイン生成した後でないと、挿入前のセルのアロケータを結合してしまう
      end
    elsif @definition == nil then
      cdl_error( "S1117 \'$1\' not in celltype", @name )
    else
      raise "UnknownToken"
    end
  end

  #=== Join# 変数の初期化チェック
  def check_var_init
    # attribute, var の場合
    if @definition.get_kind == :ATTRIBUTE then
#        check_cell_cb_init( definition.get_type, @rhs )
      # 右辺で初期化可能かチェック
      @definition.get_type.check_init( @locale, @definition.get_identifier, @rhs, :ATTRIBUTE )
    elsif @definition.get_kind == :VAR then
      # var は初期化できない
      cdl_error( "S1100 $1: cannot initialize var" , @name )
    else
      # Bug trap
      raise "UnknownDeclKind"
    end
  end

  #=== Join# 呼び口の初期化チェック
  def check_call_port_init
    ### Port
    dbgPrint( "Join#check_call_port_init:cell.call=#{@owner.get_name}.#{@name}\n")

    # 左辺は受け口か（受け口を初期化しようとしている）？
    if @definition.get_port_type == :ENTRY then
      cdl_error( "S1101 \'$1\' cannot initialize entry port" , @name )
      return
    end

#      # 配列添数の整合性チェック
#      # 呼び口の定義で、非配列なら添数なし、添数なし配列なら添数なし、添数あり配列なら添数あり
    as = @definition.get_array_size
    if ( @subscript == nil && as != nil ) then
      cdl_error( "S1102 $1: must specify array subscript here" , @name )
    elsif ( @subscript != nil && as == nil ) then
      cdl_error( "S1103 $1: cannot specify array subscript here" , @name )
    end
#    if @subscript == nil then
#      if as != nil then
#        cdl_error( "S1103 $1: need array subscript" , @name )
#      end
#    elsif @subscript == -1 then
#      if as != "[]" then
#        cdl_error( "S1104 $1: need array subscript number. ex. \'[0]\'" , @name )
#      end
#    else # @subscript >0
#      if as == nil then
#        cdl_error( "S1105 $1: cannot specify array subscript here" , @name )
#      elsif as == "[]" then
#        cdl_error( "S1106 $1: cannot specify array subscript number. use \'[]\'" , @name )
#      end
#    end

    # mikan Expression の get_type で型導出させる方がスマート
    #(1) '=' の右辺は "Cell.ePort" の形式か？
    #     演算子は "."  かつ "." の左辺が :IDENTIFIER
    #     "." の右辺はチェック不要 (synatax 的に :IDENTIFIER)
    #(2) "Cell" は存在するか？（名前が一致するものはあるか）
    #(3) "Cell" は cell か？
    #(4) "Cell" の celltype は有効か？ (無効なら既にエラー）
    #(5) "ePort" は "Cell" の celltype 内に存在するか？
    #(6) "ePort" は entry port か？
    #(7) signature は一致するか
    #(8) 右辺の配列(受け口配列)

    # 右辺がない（以前の段階でエラー）
    return unless @rhs

    # cCall = composite.cCall; のチェック．この形式は属性用
    # 呼び口を export するには cCall => composite.cCall; の形式を用いる
    if @rhs.instance_of?( Array ) == true && @rhs[0] == :COMPOSITE then
      cdl_error( "S1107 to export port '$1', use \'cCall => composite.cCall\'", @name  )
      return
    elsif ! @rhs.instance_of?( Expression ) then
      raise "Unknown bug. specify -t to find problem in source"
    end

    # 右辺の Expression の要素を取り出す
    ret = @rhs.analyze_cell_join_expression
    if ret == nil then   #1
      cdl_error( "S1108 $1: rhs not \'Cell.ePort\' form" , @name )
      return
    end

    nsp, @rhs_subscript, @port_name = ret[0], ret[1], ret[2]
    @cell_name = nsp.get_name     # mikan ns::cellname の形式の考慮

    # composite の定義の中なら object は結合先 cell か、見つからなければ nil が返る
    # composite の定義外なら false が返る
    object = CompositeCelltype.find( @cell_name )
    if object == false then
      # p nsp.get_path_str, nsp.get_path
      object = Namespace.find( nsp )    #1
      in_composite = false
    else
      if nsp.get_path.length != 1 then
        cdl_error( "$1 cannot have path", nsp.get_path_str )
      end
      in_composite = true
    end

    if object == nil then                                             # (2)
      cdl_error( "S1109 \'$1\' not found" , nsp.to_s )
    elsif ! object.instance_of?( Cell ) then                          # (3)
      cdl_error( "S1110 \'$1\' not cell" , nsp.to_s )
    else
      dbgPrint "set_definition: set_f_ref #{@owner.get_name}.#{@name} => #{object.get_name}\n"
      object.set_f_ref

      # 右辺のセルのセルタイプ
      celltype = object.get_celltype

      if celltype then                                                # (4)
        object2 = celltype.find( @port_name )
        if object2 == nil then                                        # (5)
          cdl_error( "S1111 \'$1\' not found" , @port_name )
        elsif ! object2.instance_of? Port \
             || object2.get_port_type != :ENTRY then                  # (6)
          cdl_error( "S1112 \'$1\' not entry port" , @port_name )
        elsif @definition.get_signature != object2.get_signature then # (7)
          cdl_error( "S1113 \'$1\' signature mismatch" , @port_name )
        elsif object2.get_array_size then                             # (8)
          # 受け口配列

          unless @rhs_subscript then
            # 右辺に添数指定がなかった
            cdl_error( "S1114 \'$1\' should be array" , @port_name )
          else

            as = object2.get_array_size
            if( as.kind_of?( Integer ) && as <= @rhs_subscript )then
              # 受け口配列の大きさに対し、右辺の添数が同じか大きい
              cdl_error( "S1115 $1[$2]: subscript out of range (< $3)" , @port_name, @rhs_subscript, as )
            else
              dbgPrint "Join OK #{@owner.get_name}.#{@name}[#{@rhs_subscript}] = #{object.get_name}.#{@port_name} #{self}\n"
              @cell = object
              @celltype = celltype
              @port = object2
              # 右辺のセルの受け口 object2 を参照済みにする
              # object2: Port, @definition: Port
              @cell.set_entry_port_max_subscript( @port, @rhs_subscript )
            end

            # debug
            dbgPrint "Join set_definition: rhs: #{@cell}  #{@cell.get_name if @cell}\n"

          end
        elsif @rhs_subscript then
          # 受け口配列でないのに右辺で添数指定されている
          cdl_error( "S1116 \'$1\' entry port is not array" , @port_name )
        else
          dbgPrint "Join OK #{@owner.get_name}.#{@name} = #{object.get_name}.#{@port_name} #{self}\n"
          @cell = object
          @port = object2
          @celltype = celltype

          # 右辺のセル object の受け口 object2 を参照済みにする
          # object2: Port, @definition: Port

          # debug
          # p "rhs:  #{@cell}  #{@cell.get_name}"
        end  # end of port (object2) チェック

        #else
        #  celltype == nil (すでにエラー)
      end  # end of celltyep チェック

      if ! @owner.get_plugin.kind_of?( ThroughPlugin ) then
        # 受け口の through を設定
        dbgPrint( "ep_through_list: cell=#{object.get_name} len=#{object.get_ep_through_list.length}\n")
        object.get_ep_through_list.each{ |ent|
          dbgPrint( "Join name=#{@name} port_name=#{@port.get_name} ep_through=#{ent[0]}\n")
          if ent[0] == @port.get_name then
            plugin_name = ent[1].to_s
            cell_name = :"#{ent[1].to_s}_"
            plugin_arg = ent[2]
            print( "ep_through: plugin_name=#{plugin_name}\n")
            @ep_through_list << [ plugin_name, cell_name, plugin_arg ]
          end
        }
      end
      check_region( object )

    end  # end of cell (object) チェック

  end

  #=== Join# アロケータの結合を生成
  # STAGE: S
  #cell::  呼び口の結合先のセル
  #
  # ここでは呼び口側に生成されるアロケータ呼び口の結合を生成
  # 受け口側は Cell の set_specifier_list で生成
  #  a[*] の内容は Cell の set_specifier_list を参照
  def create_allocator_join

    cell = get_rhs_cell2   # 右辺のセルを得る
    port = get_rhs_port2

    if( cell && cell.get_allocator_list ) then      # cell == nil なら既にエラー

      dbgPrint "create_allocator_join: #{@owner.get_name}.#{@name}=>#{cell ? cell.get_name : "nil"}\n"

      cell.get_allocator_list.each { |a|

        if( a[0+1] == port && a[1+1] == @rhs_subscript )then
          # 名前の一致するものの結合を生成する
          # 過不足は、別途チェックされる
          cp_name = :"#{@name}_#{a[2+1]}_#{a[3+1]}"
          # p "creating allocator join #{cp_name} #{@subscript} #{a[1+1]}"
          join = Join.new( cp_name, @subscript, a[4+1], @locale )

          #debug
          dbgPrint "create_allocator_join: #{@owner.get_name}.#{cp_name} [#{@subscript}] #{@name}\n"
          @owner.new_join join
        else
          dbgPrint "create_allocator_join:3 not #{@owner.get_name}.#{a[0+1]} #{@name}\n"
        end
      }
    end
  end

  #=== Join# リージョン間の結合をチェック
  # リージョン間の through による @region_through_list の作成
  # 実際の生成は check_and_gen_through で行う
  # mikan Cell#distance とRegion へたどり着くまでための処理に共通部分が多い
  def check_region( object )

    #debug
    dbgPrint "check_region #{@owner.get_name}.#{@name} => #{object.get_name}\n"
    # print "DOMAIN: check_region #{@owner.get_name}.#{@name} => #{object.get_name}\n"

    # プラグインで生成されたなかでは生成しない
    # さもないとプラグイン生成されたものとの間で、無限に生成される
##    if Generator.get_nest >= 1 then
##    if Generator.get_plugin then     # mikan これは必要？ (意味解析段階での実行になるので不適切)
    if @owner.get_plugin.kind_of?( ThroughPlugin ) then
      # プラグイン生成されたセルの場合、結合チェックのみ
      return
    end

    # region のチェック
    r1 = @owner.get_region      # 呼び口セルの region
    r2 = object.get_region      # 受け口セルの region

    if ! r1.equal? r2 then      # 同一 region なら呼出し可能

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

      dbgPrint "sibling_level: #{i}\n"
      dbgPrint "from: #{f1[i].get_name}\n" if f1[i]
      dbgPrint "to: #{f2[i].get_name}\n" if f2[i]

      if f1[sibling_level] && f2[sibling_level] then
        b_to_through = true
      else
        b_to_through = false
      end

      # 呼び側について呼び元のレベルから兄弟レベルまで（out_through をチェックおよび挿入）
      i = len1 -1
      if b_to_through then
        end_level = sibling_level
      else
        end_level = sibling_level - 1
      end
      while i > end_level
      # while i > sibling_level
      # while i >= sibling_level
        dbgPrint "going out from #{f1[i].get_name} level=#{i}\n"
        region_count = f1[i].next_out_through_count
        out_through_list = f1[i].get_out_through_list   # [ plugin_name, plugin_arg ]
        domain_type = f1[i].get_domain_type
        class_type = f1[i].get_class_type
        if domain_type then
          domain_through = domain_type.add_through_plugin( self, f1[i], f1[i-1], :OUT_THROUGH )
          if domain_through == nil then
            cdl_error( "S9999 $1: going out from regin '$2' not permitted by domain '$3'" , @name, f1[i].get_name, domain_type.get_name )
          end
        elsif class_type then
          class_through = class_type.add_through_plugin( self, f1[i], f1[i-1], :OUT_THROUGH )
          if class_through == nil then
            cdl_error( "S9999 $1: going out from regin '$2' not permitted by class '$3'" , @name, f1[i].get_name, class_type.get_name )
          end
        elsif out_through_list.length == 0 then
          cdl_error( "S1118 $1: going out from region \'$2\' not permitted" , @name, f1[i].get_name )
        end

        out_through_list.each { |ol|
          if ol[0] then    # plugin_name が指定されていなければ登録しない
            plugin_arg = CDLString.remove_dquote ol[1]
            through = [ ol[0], :"Join_out_through_", plugin_arg, f1[i], f1[i-1], :OUT_THROUGH, region_count]
            @region_through_list << through
          end
        }
        if domain_through && domain_through.length > 0 then
          through = [ domain_through[0], :"Join_domain_out_through_", domain_through[1], f1[i], f1[i-1], :OUT_THROUGH, region_count ]
          @region_through_list << through
        end
        if class_through && class_through.length > 0 then
          through = [ class_through[0], :"Join_class_out_through_", class_through[1], f1[i], f1[i-1], :OUT_THROUGH, region_count ]
          @region_through_list << through
        end
        i -= 1
      end

      # 兄弟レベルにおいて（to_through をチェックおよび挿入）
      if f1[sibling_level] && f2[sibling_level] then
        dbgPrint "going from #{f1[sibling_level].get_name} to #{f2[sibling_level].get_name}\n"
        found = 0
        region_count = f1[i].next_to_through_count( f2[sibling_level].get_name )   # to_through の region カウント
        f1[sibling_level].get_to_through_list.each { |t|
          if t[0][0] == f2[sibling_level].get_name then   # region 名が一致するか ?
            if t[1] then    # plugin_name が指定されていなければ登録しない
              plugin_arg = CDLString.remove_dquote t[2]
              through = [ t[1], :"Join_to_through__", plugin_arg, f1[sibling_level], f2[sibling_level], :TO_THROUGH, region_count ]
              @region_through_list << through
            end
            found = 1
          end
        }
        domain_type = f1[sibling_level].get_domain_type
        class_type = f1[sibling_level].get_class_type
        if domain_type then
          domain_through = domain_type.add_through_plugin( self, f1[sibling_level], f2[sibling_level], :TO_THROUGH )
          if domain_through == nil then
            cdl_error( "S9999 $1: going from regin '$2' not permitted by domain'$3'" , @name, f1[sibling_level].get_name, f2[sibling_level].get_domain_type.get_name )
          end
          if domain_through && domain_through.length > 0 then
            through = [ domain_through[0], :"Join_domain_to_through_", domain_through[1], f1[sibling_level], f2[sibling_level], :TO_THROUGH, region_count ]
            @region_through_list << through
          end
          found = 1     # ２重エラー抑制のため、いずれにせよ found とする
        elsif class_type then
          class_through = class_type.add_through_plugin( self, f1[sibling_level], f2[sibling_level], :TO_THROUGH )
          if class_through == nil then
            cdl_error( "S9999 $1: going from regin '$2' not permitted by class'$3'" , @name, f1[sibling_level].get_name, f2[sibling_level].get_class_type.get_name )
          end
          if class_through && class_through.length > 0 then
            through = [ class_through[0], :"Join_class_to_through_", class_through[1], f1[sibling_level], f2[sibling_level], :TO_THROUGH, region_count ]
            @region_through_list << through
          end
          found = 1     # ２重エラー抑制のため、いずれにせよ found とする
        end
        region_count = f2[i].next_from_through_count( f1[sibling_level].get_name )   # form_through の region カウント
        f2[sibling_level].get_from_through_list.each { |t|
          if t[0][0] == f1[sibling_level].get_name then   # region 名が一致するか ?
            if t[1] then    # plugin_name が指定されていなければ登録しない
              plugin_arg = CDLString.remove_dquote t[2]
              through = [ t[1], :"Join_from_through__", plugin_arg, f1[sibling_level], f2[sibling_level], :FROM_THROUGH, region_count ]
              @region_through_list << through
            end
          found = 1
          end
        }
        
        if found == 0 then
          cdl_error( "S1119 $1: going from region \'$2\' to \'$3\' not permitted" , @name, f1[sibling_level].get_name, f2[sibling_level].get_name )
        end
      end

      # 受け側について兄弟レベルから受け側のレベルまで（in_through をチェックおよび挿入）
      if b_to_through then
        i = sibling_level + 1      # to_through を経た場合、最初の in_through は適用しない
      else
        i = sibling_level
      end
      while i < len2
        dbgPrint "going in to #{f2[i].get_name} level=#{i}\n"
        region_count = f2[i].next_in_through_count
        in_through_list = f2[i].get_in_through_list   # [ plugin_name, plugin_arg ]
        domain_type = f2[i].get_domain_type
        class_type = f2[i].get_class_type
        if domain_type then
          domain_through = domain_type.add_through_plugin( self, f2[i-1], f2[i], :IN_THROUGH )
          if domain_through == nil then
            cdl_error( "S9999 $1: going in from regin '$2' to '$3' not permitted by domain '$4'",
                        @name, f2[i-1].get_name, f2[i].get_name, domain_type.get_name )
          end
          if domain_through && domain_through.length > 0 then
            through = [ domain_through[0], :"Join_domain_in_through_", domain_through[1], f2[i-1], f2[i], :IN_THROUGH, region_count ]
            @region_through_list << through
          end
        elsif class_type then
          class_through = class_type.add_through_plugin( self, f2[i-1], f2[i], :IN_THROUGH )
          if class_through == nil then
            cdl_error( "S9999 $1: going in from regin '$2' to '$3' not permitted by class '$4'",
                        @name, f2[i-1].get_name, f2[i].get_name, class_type.get_name )
          end
          if class_through && class_through.length > 0 then
            through = [ class_through[0], :"Join_class_in_through_", class_through[1], f2[i-1], f2[i], :IN_THROUGH, region_count ]
            @region_through_list << through
          end
        elsif in_through_list.length == 0 then
          cdl_error( "S1120 $1: going in to region \'$2\' not permitted" , @name, f2[i].get_name )
        end
        in_through_list.each { |il|
          if il[0] then    # plugin_name が指定されていなければ登録しない
            plugin_arg = CDLString.remove_dquote il[1]
            through = [ il[0], :"Join_in_through_", plugin_arg, f2[i-1], f2[i],:IN_THROUGH, region_count ]
            @region_through_list << through
          end
        }
        i += 1
      end
    end
  end


  #=== Join# 生成しないリージョンへの結合かチェック
  # 右辺のセルが、生成されないリージョンにあればエラー
  # 右辺は、プラグイン生成されたセルがあれば、それを対象とする
  def check_region2
    lhs_cell = @owner

    # 生成しないリージョンのセルへの結合か？
    # if join.get_cell && ! join.get_cell.is_generate? then
    # if get_rhs_cell && ! get_rhs_cell.is_generate? then # composite セルがプロタイプ宣言の場合例外
    # print "Link root: (caller #{@owner.get_name}) '#{@owner.get_region.get_link_root.get_name}'"
    # print " #{@owner.get_region.get_link_root == get_rhs_region.get_link_root ? "==" : "!="} "
    # print "'#{get_rhs_region.get_link_root.get_name}'  (callee #{@cell_name})\n"

    if get_rhs_region then
      dbgPrint "check_region2 #{lhs_cell.get_name} => #{get_rhs_region.get_path_string}#{@rhs.to_s}\n"

      # if get_rhs_region.is_generate? != true then  #3
      if @owner.get_region.get_link_root != get_rhs_region.get_link_root then
        cdl_error( "S1121 \'$1\' in region \'$2\' cannot be directly joined $3 in  $4" , lhs_cell.get_name, lhs_cell.get_region.get_namespace_path.get_path_str, @rhs.to_s, get_rhs_region.get_namespace_path.get_path_str )
      end
    else
      # rhs のセルが存在しなかった (既にエラー)
    end
  end

  def get_definition
    @definition
  end

  #=== Join# specifier を設定
  # STAGE: B
  # set_specifier_list は、join の解析の最後で呼び出される
  # through 指定子を設定
  #  check_and_gen_through を呼出して、through 生成
  def set_specifier_list( specifier_list )

    specifier_list.each { |s|
      case s[0]
      when :THROUGH
        # set plugin_name
        plugin_name = s[1].to_s
        plugin_name[0] = "#{plugin_name[/^./].upcase}"     # 先頭文字を大文字に : ruby のクラス名の制約

        # set cell_name
        cell_name = :"#{s[1].to_s}_"

        # set plugin_arg
        plugin_arg = CDLString.remove_dquote s[2].to_s
        # plugin_arg = s[2].to_s.gsub( /\A"(.*)/, '\1' )   # 前後の "" を取り除く
        # plugin_arg.sub!( /(.*)"\z/, '\1' )

        @cp_through_list << [ plugin_name, cell_name, plugin_arg ]
      end
    }

  end

  #=== Join# through のチェックと生成
  # new_join の中の check_region で region 間の through が @region_through に設定される
  # set_specifier で呼び口の結合で指定された through が @cp_through 設定される
  # その後、このメソッドが呼ばれる
  def check_and_gen_through

    dbgPrint "check_and_gen_through #{@owner.get_name}.#{@name}\n"

    if ! @definition.instance_of? Port then
      cdl_error( "S1123 $1 : not port: \'through\' can be specified only for port" , @name )
      return
    end
    if @cp_through_list.length > 0 then
      # is_empty? must check before is_omit?
      if @definition.get_signature && @definition.get_signature.is_empty? then
        cdl_warning( "W9999 'through' is specified for empty signature, ignored"  )
        return
      elsif @definition.is_omit? then
        cdl_warning( "W9999 'through' is specified for omitted port, ignored"  )
        return
      end
    end

    @through_list = @cp_through_list + @region_through_list + @ep_through_list
      # 後から @cp_through_list と @region_through_list に分けたため、このような実装になった

    if @through_list then           # nil when the join is not Port
      len = @through_list.length    # through が連接している数
    else
      len = 0
    end
    cp_len = @cp_through_list.length
    rgn_len = @region_through_list.length
    # ep_len = @ep_through_list.length       # 使わない

    if @owner.is_in_composite? && len > 0 then
      cdl_error( "S1177 cannot specify 'through' in composite in current version" )
      return
    end

    # 連続した through について、受け口側から順にセルを生成し解釈する
    i = len - 1
    while i >= 0

      through = @through_list[ i ]
      plugin_name           = through[ 0 ]
      generating_cell_name  = through[ 1 ]
      plugin_arg            = through[ 2 ]

      if i != len - 1 then

        begin
          next_cell_nsp       = @through_generated_list[ i + 1 ].get_cell_namespace_path
          next_port_name      = @through_generated_list[ i + 1 ].get_through_entry_port_name
          next_port_subscript = @through_generated_list[ i + 1 ].get_through_entry_port_subscript
        rescue Exception => evar
          cdl_error( "S1124 $1: plugin function failed: \'get_through_entry_port_name\'" , plugin_name )
          print_exception( evar )
          i -= 1
          next
        end

        next_cell = Namespace.find( next_cell_nsp )    #1
        if next_cell == nil then
          # p "next_cell_path: #{next_cell_nsp.get_path_str}"
          cdl_error( "S1125 $1: not generated cell \'$2\'" , @through_generated_list[ i + 1 ].class, next_cell_nsp.get_path_str )
          return
        end

      else
        # 最後のセルの場合、次のセルの名前、ポート名
        next_cell      = @cell
        next_port_name = @port_name
        next_port_subscript = @rhs_subscript

        if next_cell == nil then
          # 結合先がない
          return
        end
      end

      if i < cp_len then
        prev_region = @owner.get_region     # 呼び元セルのリージョン
      elsif i < (cp_len+rgn_len) then
        prev_region = @through_list[i][3]   # region 間プラグイン
      else
        if rgn_len > 0 then
          prev_region = @through_list[cp_len+rgn_len-1][3]   # reion 間のプラグインの一番後ろ
        else
          prev_region = @owner.get_region
        end
      end

      if cp_len <= i && i < (cp_len+rgn_len) then
        # region_through_list 部分
        # region から @cell_name.@port_name への through がないか探す
        # rp = @through_list[i][3].find_cell_port_through_plugin( @cell_name, @port_name ) #762
        rp = @through_list[i][3].find_cell_port_through_plugin( @cell.get_global_name, @port_name, @rhs_subscript )
           # @through_list[i] と @region_through_list[i-cp_len] は同じ
        # 共用しないようにするには、見つからなかったことにすればよい
        # rp = nil
      else
        # region 以外のものは共有しない
        # 呼び口側に指定されているし、plugin_arg が異なるかもしれない
        rp = nil
      end

      if rp == nil then
        plClass = load_plugin( plugin_name, ThroughPlugin )
        if( plClass ) then
          gen_through_cell_code_and_parse( plugin_name, i, prev_region, next_cell, next_port_name, next_port_subscript, plClass )
        end
      else
        # 見つかったものを共用する
        @through_generated_list[ i ] = rp
      end

      if cp_len <= i && i < (cp_len+rgn_len) then
          # @through_generated_list のうち @region_through_listに対応する部分
        @region_through_generated_list[ i - cp_len ] = @through_generated_list[ i ]
        if rp == nil then
          # 生成したものを region(@through_list[i][3]) のリストに追加
          # @through_list[i][3].add_cell_port_through_plugin( @cell_name, @port_name, @through_generated_list[i] ) #762
          @through_list[i][3].add_cell_port_through_plugin( @cell.get_global_name, @port_name, @rhs_subscript, @through_generated_list[i] )
        end
      end

      if i == 0 then
        # 最も呼び口側のセルは、CDL 上の結合がないため、参照されたことにならない
        if @through_generated_list[0] == nil then
          return  # plugin_object の生成に失敗している
        end
        cell = Namespace.find( @through_generated_list[0].get_cell_namespace_path )    #1
        if cell.instance_of? Cell then
          cell.set_f_ref
        end
      end

      i -= 1
    end
  end

  @@through_count = { }
  def get_through_count name
    sym = name.to_sym
    if @@through_count[ sym ] then
      @@through_count[ sym ] += 1
    else
      @@through_count[ sym ] = 0
    end
    return @@through_count[ sym ]
  end

  #=== Join# through プラグインを呼び出して CDL 生成させるとともに、import する
  def gen_through_cell_code_and_parse( plugin_name, i, prev_region, next_cell, next_port_name, next_port_subscript, plClass )

    through = @through_list[ i ]
    plugin_name           = through[ 0 ]
    generating_cell_name  = :"#{through[ 1 ]}_#{get_through_count through[ 1 ]}"
    plugin_arg            = through[ 2 ]
    @@start_region        = prev_region
    if through[ 3 ] then
      # region 間の through の場合
      # @@start_region      = through[ 3 ]
      if next_cell.get_region.equal? @@start_region then
        @@end_region      = @@start_region
      else
        @@end_region      = through[ 4 ]
      end
      @@through_type      = through[ 5 ]
      @@region_count      = through[ 6 ]
    else
      # 呼び口の through の場合
      # @@start_region      = @owner.get_region    # 呼び口側セルの region
      @@end_region        = next_cell.get_region # 次のセルの region
      @@through_type      = :THROUGH             # 呼び口の through 指定
      @@region_count      = 0
    end
    @@plugin_creating_join = self
    caller_cell = @owner

    begin
      plugin_object = plClass.new( generating_cell_name.to_sym, plugin_arg.to_s,
                                   next_cell, next_port_name.to_sym, next_port_subscript,
                                   @definition.get_signature, @celltype, caller_cell )
      plugin_object.set_locale @locale
    rescue Exception => evar
      cdl_error( "S1126 $1: fail to new" , plugin_name )
      if @celltype && @definition.get_signature && caller_cell && next_cell then
        print "signature: #{@definition.get_signature.get_name} from: #{caller_cell.get_name} to: #{next_cell.get_name} of celltype: #{@celltype.get_name}\n"
      end
      print_exception( evar )
      return 
    end

    @through_generated_list[ i ] = plugin_object

    # Region に関する情報を設定
    # 後から追加したので、new の引数外で設定
    # plugin_object.set_through_info( start_region, end_region, through_type )

    generate_and_parse plugin_object
  end

  #プラグインへの引数で渡さないものを、一時的に記憶しておく
  # プラグインの initialize の中でコールバックして設定する
  @@plugin_creating_join = nil
  @@start_region = nil
  @@end_region = nil
  @@through_type = nil
  @@region_count = nil

  #=== Join# ThroughPlugin の追加情報を設定する
  # このメソッドは ThroughPlugin#initialize から呼び出される
  # plugin_object を生成する際の引数では不足する情報を追加する
  def self.set_through_info plugin_object
    plugin_object.set_through_info( @@start_region, @@end_region, @@through_type,
                                    @@plugin_creating_join,
                                    @@plugin_creating_join.get_cell,
                                    @@region_count )
  end

  def get_name
    @name
  end

  #=== Join#配列添数を得る
  # @subscript の説明を参照のこと
  def get_subscript
    @subscript
  end

  def get_cell_name         # 受け口セル名
    @cell_name
  end

  def get_celltype
    @celltype
  end

  def get_cell
    @cell
  end

  #=== Join# 右辺の実セルを得る
  #    実セルとは through で挿入されたもの、composite の内部など実際に結合される先
  #    このメソッドは　get_rhs_port と対になっている
  #    このメソッドは、意味解析段階では呼び出してはならない (対象セルの意味解析が済む前には正しい結果を返さない)
  def get_rhs_cell
    # through 指定あり？
    if @through_list[0] then
      if @through_generated_list[0] then
        cell = Namespace.find( @through_generated_list[0].get_cell_namespace_path )    #1
        # cell が nil になるのはプラグインの get_cell_namespace_path が正しくないか、
        # プラグイン生成コードがエラーになっている。
        # できの悪いプラグインが多ければ、cell == nil をはじいた方がよい。
        return cell.get_real_cell( @through_generated_list[0].get_through_entry_port_name )
      else
        return nil            # generate に失敗している
      end
    elsif @cell then
      return @cell.get_real_cell( @port_name )
    else
      # 右辺が未定義の場合 @cell は nil (既にエラー)
      return nil
    end
  end

  #=== Join# 右辺のセルを得る
  # 右辺のセルを得る。ただし、composite 展開されていない
  # composite 展開されたものを得るには get_rhs_cell を使う
  # プロトタイプ宣言しかされていない場合には、こちらしか使えない
  # このメソッドは get_rhs_port2 と対になっている
  def get_rhs_cell2
    # through 指定あり？
    if @through_list[0] then
      if @through_generated_list[0] then
        cell = Namespace.find( @through_generated_list[0].get_cell_namespace_path )    #1
      else
        cell = @cell            # generate に失敗している
      end
    else
      cell = @cell
    end

    return cell
  end

  #=== Join# 右辺のセルを得る
  # through は適用しないが、composite は展開した後のセル
  # (意味解析が終わっていないと、composite 展開が終わっていない)
  # このメソッドは get_rhs_port3 と対になっている
  def get_rhs_cell3
    if @cell then
      return @cell.get_real_cell( @port_name )
    end
  end

  #=== Join# 右辺のセルのリージョンを得る
  # 右辺が未定義の場合、nil を返す
  # composite の場合、実セルではなく composite cell の region を返す(composite はすべて同じ region に属する)
  # composite の cell がプロトタイプ宣言されているとき get_rhs_cell/get_real_cell は ruby の例外となる
  def get_rhs_region
    # through 指定あり？
    if @through_list[0] then
      if @through_generated_list[0] then
        cell = Namespace.find( @through_generated_list[0].get_cell_namespace_path )    #1
        if cell then
          return cell.get_region
        end
      else
        return nil       # generate に失敗している
      end
    elsif @cell then
      return @cell.get_region
    end
    # 右辺が未定義の場合 @cell は nil (既にエラー)
    return nil
  end

  def get_cell_global_name  # 受け口セル名（コンポジットなら展開した内側のセル）

    # debug
    dbgPrint "cell get_cell_global_name:  #{@cell_name}\n"
    # @cell.show_tree( 1 )

    if @cell then
      return @cell.get_real_global_name( @port_name )
    else
      return "NonDefinedCell?"
    end

  end

  #===  Join# 結合の右辺の受け口の名前
  #     namespace 名 + '_' + セル名 + '_' + 受け口名   （このセルが composite ならば展開後のセル名、受け口名）
  #subscript:: Integer  呼び口配列の時添数 または nil 呼び口配列でない時
  def get_port_global_name( subscript = nil )  # 受け口名（コンポジットなら展開した内側のセル）

    # debug
    dbgPrint "Cell get_port_global_name:  #{@cell_name}\n"

    # through 指定あり？
    if @through_list[0] then
      cell = Namespace.find( @through_generated_list[0].get_cell_namespace_path )    #1

      # through で挿入されたセルで、実際に接続されるセル（compositeの場合内部の)の受け口の C 言語名前
      return cell.get_real_global_port_name( @through_generated_list[0].get_through_entry_port_name )
    else

      # 実際に接続されるセルの受け口の C 言語名前
      if @cell then
        return @cell.get_real_global_port_name( @port_name )
      else
        return "UndefinedCellsPort?"
      end

    end

  end

  def get_port_name
    @port_name
  end

  def get_rhs
    @rhs
  end

  # 末尾数字1 : CDL で指定された、右辺のセルを返す
  def get_rhs_cell1   # get_cell と同じ
    @cell
  end
  def get_rhs_port1   # get_port_name 同じ
    @port_name
  end
  def get_rhs_subscript1
    @rhs_subscript
  end

  #=== Join# 右辺のポートを得る
  #    右辺が composite の場合は、内部の繋がるセルのポート, through の場合は挿入されたセルのポート
  #    このメソッドは get_rhs_cell と対になっている
  def get_rhs_port
    # through 指定あり？
    if @through_list[0] then
      # through で生成されたセルを探す
      cell = Namespace.find( @through_generated_list[0].get_cell_namespace_path )    #1
      # cell のプラグインで生成されたポート名のポートを探す (composite なら内部の繋がるポート)
      return cell.get_real_port( @through_generated_list[0].get_through_entry_port_name )
    else
      # ポートを返す(composite なら内部の繋がるポートを返す)
      return @cell.get_real_port( @port_name )
    end
  end

  #=== Join# 右辺の配列添数を得る
  #    右辺が through の場合は挿入されたセルの添数
  #    右辺が composite の場合は、内部の繋がるセルのポートの添数 (composite では変わらない)
  #    このメソッドは get_rhs_cell,  と対になっている
  def get_rhs_subscript
    if @through_list[0] then
      return @through_generated_list[0].get_through_entry_port_subscript
    else
      return @rhs_subscript
    end
  end

  #=== Join# 右辺のポートを得る
  # 右辺のポートを得る。
  # これはプロトタイプ宣言しかされていない場合には、こちらしか使えない
  def get_rhs_port2
    # through 指定あり？
    if @through_list[0] then
      if @through_generated_list[0] then
        port = @through_generated_list[0].get_through_entry_port_name.to_sym
      else
        port = @port_name    # generate に失敗している
      end
    else
      port = @port_name
    end

    return port
  end

  #=== Join# 右辺のポートを得る
  # through は適用しないが、composite は展開した後のセルの対応するポート
  def get_rhs_port3
    if @cell then
      return @cell.get_real_port( @port_name )
    end
  end

  #=== Join# 呼び口配列の2番目以降の要素を追加する
  #     一番最初に定義された配列要素が全要素の初期値の配列を持つ
  #     このメソッドは非配列の場合も呼出される（join 重複エラーの場合）
  #join2:: Join  呼び口配列要素の Join
  def add_array_member join2

    # subscript2: join2 の左辺添数
    subscript2 = join2.get_subscript

    if @subscript == nil then		# not array : initialize duplicate
      # 非配列の場合、join が重複している
      cdl_error( "S1127 \'$1\' duplicate", @name )
      # print "add_array_member2: #{@owner.get_name}\n"

    elsif @subscript >= 0 then
      # 添数指定ありの場合
      if( subscript2 == nil || subscript2 < 0 ) then
        # join2 左辺は非配列または添数なし
        # 配列が不一致
        cdl_error( "S1128 \'$1\' inconsistent array definition", @name )
      elsif @array_member[subscript2] != nil then
        # 同じ添数が既に定義済み
        cdl_error( "S1129 \'$1\' redefinition of subscript $2" ,@name, subscript2 )
      else
        # 添数の位置に要素を追加
        @array_member[subscript2] = join2.get_rhs
        @array_member2[subscript2] = join2
#        p "0:#{join2.get_rhs}"
      end

    else
      # 添数指定なしの場合
      if( subscript2 == nil || subscript2 >= 0 ) then
        # join2 左辺は非配列または添数有
        # 配列が不一致
        cdl_error( "S1130 \'R1\' inconsistent array definition", @name )
      end

      # 添数なし配列の場合、配列要素を追加
      @array_member  << join2.get_rhs
      @array_member2 << join2
    end
  end

  def get_array_member
    @array_member
  end

  def get_array_member2
    @array_member2
  end

  def change_name name
    # debug
    dbgPrint "change_name: #{@name} to #{name}\n"

    @name = name

    if @array_member2 then
      i = 0
      while i < @array_member2.length
        if @array_member2[i] != self && @array_member[i] != nil then
          # @array_member2[i] が nil になるのは optional の時と、
          # Join の initialize で無駄に @array_member2 が設定されている場合
          # 無駄に設定されているものについては、再帰的に呼び出す必要はない（clone_for_composite では対策している）
          @array_member2[i].change_name( name )
        end
        i += 1
      end
    end
  end

  # composite cell を展開したセルの結合を clone したセルの名前に変更
  def change_rhs_port( clone_cell_list, celltype )
    dbgPrint "change_rhs_port: name=#{@name}\n"

    # debug
    if $debug then
#    if @name == :cCallB then
      # dbgPrint "change_rhs name: #{@name}  cell_name: #{@cell_name} #{@cell} #{self}\n"
      print "============\n"
      print "CHANGE_RHS change_rhs name: #{@owner.get_name}.#{@name}  rhs cell_name: #{@cell_name} #{@cell} #{self}\n"

      clone_cell_list.each{ |cell, ce|
        # dbgPrint "=== change_rhs:  #{cell.get_name}=#{cell} : #{ce.get_name}\n"
        print "   CHANGE_RHS  change_rhs:  #{cell.get_name}=#{cell} : #{ce.get_name}\n"
      }
      print "============\n"
    end

    c = clone_cell_list[@cell]
    return if c == nil

    # debug
    dbgPrint "  REWRITE cell_name:  #{@owner.get_name}   #{@cell_name} => #{c.get_global_name}, #{c.get_name}\n"

    # @rhs の内容を調整しておく（この内容は、subscript を除いて、後から使われていない）
    elements = @rhs.get_elements
    if elements[0] == :OP_SUBSC then  # 右辺：受け口配列？
      elements  = elements[1]
    end

    # 右辺が　cell.ePort の形式でない
    if elements[0] != :OP_DOT || elements[1][0] != :IDENTIFIER then   #1
      return
    else
      # セル名を composite 内部の名前から、外部の名前に入れ替える
      # elements[1][1] = Token.new( c.get_name, nil, nil, nil )
      elements[1][1] = NamespacePath.new( c.get_name, false, c.get_namespace )
    end

    @cell_name = c.get_name
    @cell = c
    # @definition = nil          # @definition が有効： チェック済み（とは、しない）

    if @array_member2 then

      # debug
      dbgPrint "array_member2.len : #{@array_member.length}\n"

      i = 0
      while i < @array_member2.length
        # @array_member2[i] が nil になるのは optional の時と、
        # Join の initialize で無駄に @array_member2 が設定されている場合
        # 無駄に設定されているものについては、再帰的に呼び出す必要はない（clone_for_composite では対策している）
        if @array_member2[i] != self && @array_member[i] != nil then
          dbgPrint "change_rhs array_member #{i}: #{@name}  #{@cell_name}\n"
          @array_member2[i].change_rhs_port( clone_cell_list, celltype )
        end
        i += 1
      end
    end

  end

  #=== Join# composite セル用にクローン
  #cell_global_name:: string : 親セルのグローバル名
  # 右辺の C_EXP に含まれる $id$, $cell$, $ct$ を置換
  # ここで置換するのは composite の attribute の C_EXP を composite セルタイプおよびセル名に置換するため
  # （内部セルの C_EXP もここで置換される）
  # @through_list などもコピーされるので、これが呼び出される前に確定する必要がある
  def clone_for_composite( ct_name, cell_name, locale, b_need_recursive = true )
    # debug
    dbgPrint "=====  clone_for_composite: #{@name} #{@cell_name} #{self}   =====\n"
    cl = self.clone

    if @array_member2 && b_need_recursive then
      cl.clone_array_member( ct_name, cell_name, self, locale )
    end

    rhs = CDLInitializer.clone_for_composite( @rhs, ct_name, cell_name, locale )
    cl.change_rhs rhs

    # debug
    dbgPrint "join cloned : #{cl}\n"
    return cl
  end

  def clone_array_member( ct_name, cell_name, prev, locale )
    # 配列のコピーを作る
    am  = @array_member.clone
    am2 = @array_member2.clone

    # 配列要素のコピーを作る
    i = 0
    while i < am2.length
      if @array_member2[i] == prev then
        # 自分自身である（ので、呼出すと無限再帰呼出しとなる）
        am2[i] = self
        am[i] = am2[i].get_rhs
      elsif @array_member2[i] then
#        am2[i] = @array_member2[i].clone_for_composite( ct_name, cell_name, locale, false )
        am2[i] = @array_member2[i].clone_for_composite( ct_name, cell_name, locale, true )
        am[i] = am2[i].get_rhs
      else
        # 以前のエラーで array_member2[i] は nil になっている
      end

      # debug
      dbgPrint "clone_array_member: #{@name} subsript=#{i} #{am2[i]} #{@array_member2[i]}\n"

      i += 1
    end

    # i = 0 は、ここで自分自身を設定
    # am2[0] = self

    @array_member  = am
    @array_member2 = am2

  end

  #=== Join# rhs を入れ換える
  #rhs:: Expression | initializer
  # 右辺を入れ換える．
  # このメソッドは、composite で cell の属性の初期値を attribute の値で置き換えるのに使われる
  # このメソッドは composite 内の cell の属性の初期値が定数ではなく式になった場合、不要になる
  def change_rhs rhs
    @rhs = rhs
  end

  #=== Join# clone された join の owner を変更
  def set_cloned( owner )
    dbgPrint "Join#set_cloned: #{@name}  prev owner: #{@owner.get_name} new owner: #{owner.get_name}\n"
    @owner = owner
    if @array_member2 then
      @array_member2.each{ |join|
        dbgPrint "Joinarray#set_cloned: #{@name}  prev owner: #{join.get_owner.get_name} new owner: #{owner.get_name}\n"
        join.set_owner owner
      }
    end
  end

  def show_tree( indent )
    indent.times { print "  " }
    puts "Join: name: #{@name} owner: #{@owner.get_name} id: #{self}"
    if @subscript == nil then
    elsif @subscript >= 0 then
      (indent+1).times { print "  " }
      puts "subscript: #{@subscript}"
    else
      (indent+1).times { print "  " }
      puts "subscript: not specified"
    end
    (indent+1).times { print "  " }
    puts "rhs: "
    if @rhs.instance_of?( Array )then
      @rhs.each{ |i|
        if i.instance_of?( Array )then
          i.each{ |j|
            j.show_tree( indent + 3 )
          }
        elsif i.instance_of? Symbol then
          (indent+2).times { print "  " }
          print i
          print "\n"
        else
          i.show_tree( indent + 2 )
        end
      }
    else
      @rhs.show_tree( indent + 2 )
      (indent+1).times { print "  " }
      if @definition then
        puts "definition:"
        @definition.show_tree( indent + 2 )
      else
        puts "definition: not found"
      end
    end
    if @definition.instance_of?( Port ) then
      (indent+2).times { print "  " }
      if @cell then
        puts "cell: #{@cell_name} #{@cell}  port: #{@port_name}  cell_global_name: #{@cell.get_global_name}"
      else
        puts "cell: #{@cell_name} port: #{@port_name}  (cell not found)"
      end
    end
    if @through_list then
      i = 0
      @through_list.each { |t|
        (indent+2).times { print "  " }
        puts "through: plugin name :  '#{t[0]}' arg : '#{t[2]}'"
        if @through_generated_list[i] then
          @through_generated_list[i].show_tree( indent+3 )
        end
        i += 1
      }
    end
    if @array_member2 then
      (indent+1).times { print "  " }
      puts "array member:"
      i = 0
      @array_member2.each { |j|
        if j then
          (indent+2).times { print "  " }
          puts "[#{i}]: #{j.get_name}  id: #{j} owner=#{j.get_owner.get_name}"
          j.get_rhs.show_tree(indent+3)
#          (indent+3).times { print "  " }
#          puts "cell global name: #{j.get_cell_global_name}"
#          puts "cell global name: #{j.get_rhs_cell.get_global_name}"
#          (indent+3).times { print "  " }
#          puts "port global name: #{j.get_port_global_name}"
#          puts "port global name: #{j.get_rhs_port.get_name}"
        else
          (indent+2).times { print "  " }
          puts "[#{i}]: [optional]  id: #{j}"
        end
        i += 1
      }
    end
  end

end
