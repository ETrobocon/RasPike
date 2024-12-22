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
#   $Id: signature.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

class Signature < NSBDNode  # < Nestable
#  @name:: Symbol
#  @global_name:: Symbol
#  @function_head_list:: NamedList : FuncHead のインスタンスが要素
#  @func_name_to_id::  {String}  :  関数名を添字とする配列で id を記憶する．id は signature の出現順番 (1から始まる)
#  @context:: string : コンテキスト名
#  @b_callback:: bool: callback : コールバック用のシグニチャ
#  @b_deviate:: bool: deviate : 逸脱（pointer level mismatch を出さない）
#  @b_checked_as_allocator_signature:: bool:  アロケータシグニチャとしてチェック済み
#  @b_empty:: Bool: 空(関数が一つもない状態)
#  @descriptor_list:: nil | { Signature => ParamDecl }  最後の ParamDecl しか記憶しないことに注意
#  @generate:: [ Symbol, String, Plugin ]  = [ PluginName, option, Plugin ] Plugin は生成後に追加される

  include PluginModule

  @@nest_stack_index = -1
  @@nest_stack = []
  @@current_object = nil

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

  # STAGE: P
  # このメソッドは parse 中のみ呼び出される
  def self.get_current
    @@current_object
  end

  #
  # STAGE: B
  def initialize( name )
    super()
    @name = name
    Namespace.new_signature( self )
    set_namespace_path # @NamespacePath の設定
    if "#{Namespace.get_global_name}" == "" then
      @global_name = @name
    else
      @global_name = :"#{Namespace.get_global_name}_#{@name}"
    end

    @func_name_to_id = {}
    @context = nil
    @b_callback = false
    @b_deviate = false
    @b_empty = false
    @b_checked_as_allocator_signature = false
    @descriptor_list = nil
    @generate = nil
    @@current_object = self
    set_specifier_list( Generator.get_statement_specifier )
  end

  #
  # STAGE: B
  def end_of_parse( function_head_list )
    @function_head_list = function_head_list

    # id を割付ける
    id = 1
    function_head_list.get_items.each{ |f|
      @func_name_to_id[ f.get_name ] = id
      f.set_owner self
      id += 1
    }
    if id == 1 then
      @b_empty = true
    end

    # set_descriptor_list ##

    if @generate then
      signature_plugin
    end

    @@current_object = nil

    return self
  end

  #=== Signature# signature の指定子を設定
  # STAGE: B
  #spec_list::      [ [ :CONTEXT,  String ], ... ]
  #                     s[0]        s[1]
  def set_specifier_list( spec_list )
    return if spec_list == nil  # 空ならば何もしない

    spec_list.each { |s|
      case s[0]     # statement_specifier
      when :CALLBACK
        @b_callback = true
      when :CONTEXT         # [context("non-task")] etc
        if @context then
          cdl_error( "S1001 context specifier duplicate"  )
        end
        # @context = s[1].gsub( /\A\"(.*)\"$/, "\\1" )
        @context = CDLString.remove_dquote s[1]
        case @context
        when "non-task", "task", "any"
        else
          cdl_warning( "W1001 \'$1\': unknown context type. usually specifiy task, non-task or any" , @context )
        end
      when :DEVIATE
        @b_deviate = true
      when :GENERATE
        if @generate then
          cdl_error( "S9999 generate specifier duplicate"  )
        end
        @generate = [ s[1], s[2] ] # [ PluginName, "option" ]
      else
        cdl_error( "S1002 \'$1\': unknown specifier for signature" , s[0] )
      end
    }
  end

  def get_name
    @name
  end

  def get_global_name
    @global_name
  end

  def get_function_head_array
    if @function_head_list then
      return @function_head_list.get_items
    else
      return nil
    end
  end

  def get_function_head( func_name )
    return @function_head_list.get_item( func_name.to_sym )
  end

  #=== Signature# 関数名から signature 内の id を得る
  def get_id_from_func_name func_name
    @func_name_to_id[ func_name ]
  end

  #=== Signature# context を得る
  # context 文字列を返す "task", "non-task", "any"
  # 未指定時のデフォルトとして task を返す
  def get_context
    if @context then
      return @context
    else
      return "task"
    end
  end

  #=== Signature# signaure のすべての関数のすべてのパラメータをたどる
  #block:: ブロックを引数に取る
  # ブロックは2つの引数を受け取る  Decl, ParamDecl     ( Decl: 関数ヘッダ )
  # Port クラスにも each_param がある（同じ働き）
  def each_param &pr # ブロック引数 { |func_decl, param_decl| }
    fha = get_function_head_array                       # 呼び口または受け口のシグニチャの関数配列
    return if fha == nil                                # nil なら文法エラーで有効値が設定されなかった

    # obsolete Ruby 3.0 では使えなくなった
    # pr = Proc.new   # このメソッドのブロック引数を pr に代入
    fha.each{ |fh|  # fh: FuncHead                      # 関数配列中の各関数頭部
      fd = fh.get_declarator                            # fd: Decl  (関数頭部からDeclarotorを得る)
      if fd.is_function? then                           # fd が関数でなければ、すでにエラー
        fd.get_type.get_paramlist.get_items.each{ |par| # すべてのパラメータについて
          pr.call( fd, par )
        }
      end
    }
  end

  #=== Signature# 正当なアロケータ シグニチャかテストする
  # alloc, dealloc 関数を持つかどうか、第一引き数がそれぞれ、整数、ポインタ、第二引き数が、ポインタへのポインタ、なし
  def is_allocator?

    # 一回だけチェックする
    if @b_checked_as_allocator_signature == true then
      return true
    end
    @b_checked_as_allocator_signature = true

    fha = get_function_head_array                       # 呼び口または受け口のシグニチャの関数配列
    if fha == nil then                                  # nil なら文法エラーで有効値が設定されなかった
      return false
    end

    found_alloc = false; found_dealloc = false
    fha.each{ |fh|  # fh: FuncHead                      # 関数配列中の各関数頭部
      fd = fh.get_declarator                            # fd: Decl  (関数頭部からDeclarotorを得る)
      if fd.is_function? then                           # fd が関数でなければ、すでにエラー
        func_name = fd.get_name.to_sym 
        if func_name == :alloc then
          found_alloc = true
          params = fd.get_type.get_paramlist.get_items
          if params then
            if ! params[0].instance_of?( ParamDecl ) ||
                ! params[0].get_type.get_original_type.kind_of?( IntType ) ||
                params[0].get_direction != :IN then
              # 第一引数が int 型でない
              if ! params[0].instance_of?( ParamDecl ) ||
                  ! params[0].get_type.kind_of?( PtrType ) ||
                  ! params[0].get_type.get_type.kind_of?( PtrType ) ||
                  params[0].get_type.get_type.get_type.kind_of?( PtrType ) ||
                  params[0].get_direction != :OUT then
                # 第一引数がポインタ型でもない
                cdl_error3( @locale, "S1003 $1: \'alloc\' 1st parameter neither [in] integer type nor [out] double pointer type", @name )
              end
            elsif ! params[1].instance_of?( ParamDecl ) ||
                ! params[1].get_type.kind_of?( PtrType ) ||
                ! params[1].get_type.get_type.kind_of?( PtrType ) ||
                params[1].get_type.get_type.get_type.kind_of?( PtrType ) ||
                params[0].get_direction != :IN then
              # (第一引数が整数で) 第二引数がポインタでない
              cdl_error3( @locale, "S1004 $1: \'alloc\' 2nd parameter not [in] double pointer" , @name )
            end
          else
            cdl_error3( @locale, "S1005 $1: \'alloc\' has no parameter, unsuitable for allocator signature" , @name )
          end
        elsif func_name == :dealloc then
          found_dealloc = true
          params = fd.get_type.get_paramlist.get_items
          if params then
            if ! params[0].instance_of?( ParamDecl ) ||
                ! params[0].get_type.kind_of?( PtrType ) ||
                params[0].get_type.get_type.kind_of?( PtrType ) ||
                params[0].get_direction != :IN then
              cdl_error3( @locale, "S1006 $1: \'dealloc\' 1st parameter not [in] pointer type" , @name )
#            elsif params[1] != nil then    # 第二引き数はチェックしない
#              cdl_error3( @locale, "S1007 Error message is changed to empty" )
#                 cdl_error3( @locale, "S1007 $1: \'dealloc\' cannot has 2nd parameter" , @name )
            end
          else
            cdl_error3( @locale, "S1008 $1: \'dealloc\' has no parameter, unsuitable for allocator signature" , @name )
          end
        end
        if found_alloc && found_dealloc then
          return true
        end
      end
    }
    if ! found_alloc then
      cdl_error3( @locale, "S1009 $1: \'alloc\' function not found, unsuitable for allocator signature" , @name )
    end
    if ! found_dealloc then
      cdl_error3( @locale, "S1010 $1: \'dealloc\' function not found, unsuitable for allocator signature" , @name )
    end
    return false
  end

  #=== Signature# シグニチャプラグイン (generate 指定子)
  def signature_plugin
    plugin_name = @generate[0]
    option = @generate[1]
    apply_plugin( plugin_name, option )
  end

  #== Signature#apply_plugin
  def apply_plugin plugin_name, option
    if is_empty? then
      cdl_warning( "S9999 $1 is empty. cannot apply signature plugin. ignored" , @name )
      return
    end

    plClass = load_plugin( plugin_name, SignaturePlugin )
    return if plClass == nil
    if $verbose then
      print "new through: plugin_object = #{plClass.class.name}.new( #{@name}, #{option} )\n"
    end

    begin
      plugin_object = plClass.new( self, option )
      plugin_object.set_locale @locale
    rescue Exception => evar
      cdl_error( "S1150 $1: fail to new" , plugin_name )
      print_exception( evar )
    end
    generate_and_parse plugin_object
end

  #== Signature# 引数で参照されている Descriptor 型のリストを
  #RETURN:: Hash { Signature => ParamDecl }:  複数の ParamDecl から参照されている場合、最後のものしか返さない
  def get_descriptor_list
    # print "Signature#get_descriptor_list #{@name}\n"
    # 本来 Signature.set_descriptor_list の呼出しで @descriptor_list が設定されるのだが、
    # post_code.cdl (ジェネレータ生成) で生成、または import されたシグニチャには設定されない。
    # 読み出し時に、オンデマンドで設定する。
    if @descriptor_list == nil then
      set_descriptor_list
    end
    @descriptor_list
  end

  @@set_descriptor_list = {}
  def self.set_descriptor_list
    Namespace.get_root.travers_all_signature{ |sig|
      if @@set_descriptor_list[ sig ] == nil then
        @@set_descriptor_list[ sig ] = true
        sig.set_descriptor_list
      end
    }
  end

  #== Signature# 引数で参照されている Descriptor 型のリストを作成する
  def set_descriptor_list
    desc_list = { }
    # p "has_desc #{@name}"
    fha = get_function_head_array                       # 呼び口または受け口のシグニチャの関数配列
    if fha == nil then                                  # nil の場合、自己参照によるケースと仮定
      @descriptor_list = desc_list
      return desc_list
    end
    fha.each{ |fh|
      fd = fh.get_declarator                            # fd: Decl  (関数頭部からDeclarotorを得る)
      if fd.is_function? then                           # fd が関数でなければ、すでにエラー
        params = fd.get_type.get_paramlist.get_items
        if params then
          params.each{ |param|
            t = param.get_type.get_original_type
            while( t.kind_of? PtrType )
              t = t.get_referto
            end
            # p "has_desc #{param.get_name} #{t}"
            if t.kind_of? DescriptorType then
              desc_list[ t.get_signature ] = param
              # p self.get_name, t.get_signature.get_name
              if t.get_signature == self then
               # cdl_error( "S9999 Descriptor argument '$1' is the same signature as this parameter '$2' included", @name, param.get_name )
              end
              dir = param.get_direction
              if dir != :IN && dir != :OUT && dir != :INOUT then
                cdl_error( "S9999 Descriptor argument '$1' cannot be specified for $2 parameter", param.get_name, dir.to_s.downcase )
              end
            end
          }
        end
      end
    }
    @descriptor_list = desc_list
  end

  #=== Signature# 引数に Descriptor があるか？
  def has_descriptor?
    if get_descriptor_list == nil then
      # end_of_parse が呼び出される前に has_descriptor? が呼び出された
      # 呼び出し元は DescriptorType#initialize
      # この場合、同じシグニチャ内の引数が Descriptor 型である
      return true
    elsif get_descriptor_list.length > 0 then
      return true
    else
      return false
    end
  end

  #=== Signature# コールバックか？
  # 指定子 callback が指定されていれば true 
  def is_callback?
    @b_callback
  end

  #=== Signature# 逸脱か？
  # 指定子 deviate が指定されていれば true 
  def is_deviate?
    @b_deviate
  end

  #=== Signature# 空か？
  def is_empty?
    @b_empty
  end

  #=== Signature# Push Pop Allocator が必要か？
  # Transparent RPC の場合 oneway かつ in の配列(size_is, count_is, string のいずれかで修飾）がある
  def need_PPAllocator?( b_opaque = false )
    fha = get_function_head_array                       # 呼び口または受け口のシグニチャの関数配列
    fha.each{ |fh|
      fd = fh.get_declarator
      if fd.get_type.need_PPAllocator?( b_opaque ) then
        # p "#{fd.get_name} need_PPAllocator: true"
        @b_need_PPAllocator = true
        return true
      end
      # p "#{fd.get_name} need_PPAllocator: false"
    }
    return false
  end

  def show_tree( indent )
    indent.times { print "  " }
    puts "Signature: name: #{@name} context: #{@context} deviate : #{@b_deviate} PPAllocator: #{@b_PPAllocator} #{self}"
    (indent+1).times { print "  " }
    puts "namespace_path: #{@NamespacePath}"
    (indent+1).times { print "  " }
    puts "function head list:"
    @function_head_list.show_tree( indent + 2 )
  end

end
