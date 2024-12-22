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
#   $Id: namedlist.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

class NamedList
#  @names:: {} of items
#  @items:: [] of items : item の CLASS は get_name メソッドを持つこと get_name の戻り値は Symbol でなくてはならない
#                         NamedList を clone_for_composite する場合は、item にもメソッドが必要
#  @type:: string	エラーメッセージ

  def initialize( item, type )
    @names = {}
    @items = []
    @type = type
    add_item( item )
  end

  #=== 要素を加える
  # parse した時点で加えること(場所を記憶する)
  def add_item( item )

    if item then
      dbgPrint "add_item: name=#{item.get_name}   #{item.locale_str}\n"
      assert_name item
      name = item.get_name
      prev = @names[name]
      if prev then
=begin
        print "add_item: length=#{@names.length} length2=#{@items.length}\n"
        @names.each{|nm,obj|
          print "  name=#{nm}\n"
        }
        @items.each{|item|
          print "  item=#{item.get_name}   #{item.locale_str}\n"
        }
=end
        Generator.error( "S2001 \'$1\' duplicate $2" , name, @type )
        prev_locale = prev.get_locale
        puts "previous: #{prev_locale[0]}: line #{prev_locale[1]} \'#{name}\' defined here"
        return self
      end

      @names[name]=item
      @items << item
    end

    return self
  end

  def change_item( item )
    assert_name item
    name = item.get_name

    prev_one = @names[name]
    @names[name]=item

    @items = @items - [ prev_one ]
    @items << item
  end

  def del_item( item )
    assert_name item
    name = item.get_name
    @names.delete name

    @items = @items - [ item ]
  end

  def get_item( name )
    if ! name.kind_of? Symbol
      print "get_item: '#{name}', items are below\n"
      @names.each{ |nm,item|
        p nm
      }
      raise "get_item: #{name}: not Symbol"
    end
    if name then
      return @names[name.to_sym]
    else
      return nil
    end
  end

  def get_items
    return @items
  end

  #=== composite cell を clone した時に要素(JOIN) の clone する
  #
  # mikan このメソッドは Join に特化されているので NamedList から分離すべき
  def clone_for_composite( ct_name, cell_name, locale )
    cl = self.clone
    cl.set_cloned( ct_name, cell_name, locale )
    return cl
  end

  #=== clone された NamedList インスタンスの参照するもの(item)を clone
  #
  # mikan このメソッドは Join に特化されているので NamedList から分離すべき
  def set_cloned( ct_name, cell_name, locale )
    items = []
    names = {}
    @items.each { |i|
      dbgPrint "NamedList clone #{ct_name}, #{cell_name}, #{i.get_name}\n"

      cl = i.clone_for_composite( ct_name, cell_name, locale )
      names[cl.get_name] = cl
      items << cl
    }
    @items = items
    @names = names
  end

  def assert_name item
    if ! item.get_name.kind_of? Symbol
      raise "Not symbol for NamedList item"
    end
  end

  def show_tree( indent )
    @items.each { |i|
      i.show_tree( indent )
    }
  end

end
