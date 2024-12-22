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
#   $Id: importable.rb 3266 2023-01-03 07:32:40Z okuma-top $
#++

#== Importable class
# this module is included by Import_C and Import
module Importable
#@last_base_dir::String

  #=== Importable#find_file
  #file::String : file name to find
  #return::String | Nil: path to file or nil if not found
  #find file in 
  def find_file file
    $import_path.each{ |path|
      if path == "."
        pt = file
      else
        pt = "#{path}/#{file}"
      end
      if File.exist?( pt )
        if ! $base_dir[ Dir.pwd ]
          $base_dir[ Dir.pwd ] = true
        end
        if $verbose then
          print "#{file} is found in #{path}\n"
        end
        @last_base_dir = nil
        dbgPrint "base_dir=. while searching #{file}\n"
        return pt
      end
    }

    $base_dir.each_key{ |bd|
      $import_path.each{ |path|
#        if path =~ /\A\// || path =~ /\A[a-zA-Z]:/
          pt = "#{path}/#{file}"
#        else
#          pt = "#{bd}/#{path}/#{file}"
#        end
        begin
          Dir.chdir $run_dir
          Dir.chdir bd
          if File.exist?( pt )
            if $verbose then
              print "#{file} is found in #{bd}/#{path}\n"
            end
            @last_base_dir = bd
            dbgPrint "base_dir=#{bd} while searching #{file}\n"
            $base_dir[ bd ] = true
            return pt
          end
        rescue
        end
      }
    }
    @last_base_dir = nil
    dbgPrint "base_dir=. while searching #{file}\n"
    return nil
  end

  def get_base_dir
    return @last_base_dir
    $base_dir.each{ |bd, flag|
      if flag == true
        return bd
      end
    }
    return nil
  end
end
