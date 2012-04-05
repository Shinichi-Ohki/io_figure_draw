#!/usr/bin/ruby
#==============================================================================
#	NSL declare to JSON script
#
# 2011/09/05 完成
# 2011/09/27 エリアコメントの削除に対応
#==============================================================================

declare_flag = false

Stringarray = Array.new
Typearray = Array.new	# 0:null line, 1:input, 2:output, 3: inout, 4:func_in, 5:func_out
Widtharray = Array.new

exit if (ARGV.size==0)

pathname = File::dirname(ARGV[0])
filename = File::basename(ARGV[0],'.*')
extname = File::extname(ARGV[0])
targetfilename = File.join(pathname,filename+extname)	# パス名とファイル名をつなぐ
f = open(targetfilename)
targetfile = f.read										# ファイル一括読み出し
f.close
targetfile.gsub!(/\/\*\/?(\n|[^\/]|[^*]\/)*\*\//,"")	# エリアコメントの削除

targetfile.each_line do |s|
	if (/\}/ =~ s) && (declare_flag) then
		declare_flag = false
	end
	if declare_flag
		s.gsub!(/[ \t]+,/,",")						# カンマの前の空白とタブを削除
		s.gsub!(/,[ \t]+/,",")						# カンマの後の空白とタブを削除
		s.gsub!(/\r\n/,"\n")						# CR+LFをLFのみに変換
		s.gsub!(/[ \t]+\/\/.*/,"")					# 何か書いてある後の1行コメントを削除
		linearray = s.sub(/;$/,"").split(/;/)		# 行末の;を削除した後、;で分割
#		puts linearray
		linecount = 0
		linearray.each do |port|
#			/\((.*?),(.*?)\)/ =~ port
			if (/^[ \t]*\/\/.*/ =~ port) then		# コメントの//のみの行は無視する
			elsif (/^[ \t]*\n/ =~ port) then		# 空行(もしくはスペースかタブのみの行)の場合
				Stringarray << ""					# 信号名:null
				Typearray << 0						# 信号種:0
				Widtharray << 0						# ビット幅:0
			else
				sig = port.strip.split(/[ \t]+/)
#				puts sig[0]
#				puts sig[1]
				case sig[0].downcase				# 信号種の判定
					when 'input'
						sigtype = 1
					when 'output'
						sigtype = 2
					when 'inout'
						sigtype = 3
					when 'func_in'
						sigtype = 4
					when 'func_out'
						sigtype = 5
				end
				case sigtype
					when 1..3 									# (input/output/inout)
						# 一つのinput/output/inoutで複数の信号を宣言している場合に、文字列を分割する
						signame = sig[1].sub(/[ \t]/,"").split(/[,]/)

#						puts signame.size
						signame.each do |s|						# 信号毎に配列に信号名等をセット
							sigitem = s.split(/[\[\]]/)
#							puts s
							Stringarray << s					# 信号名
							Typearray << sigtype				# 信号種(input:1/output:2/inout:3)
							if (sigitem.size == 1) then			# ビット幅
								Widtharray << 1					# 1のとき1
							else
								Widtharray << sigitem[1].to_i	# それ以外の時その幅
							end
						end
					when 4..5 									# (func_in/func_out)
						# 一つのfunc_in/outで複数の信号を宣言している場合に、文字列を分割する
						signame = sig[1].sub(/[ \t],/,"").split(/\),/)	# "),"で文字列を分割する(funcには引数があるので","だけで分割できない)

						signame.each do |s|						# 信号毎に配列に信号名等をセット
							s.concat(")") if ((/[^\)]$/ =~ s) && (/\(/ =~ s)) # 分割した時")"が消えるので、補完する。ただし"("があるときのみ
							Stringarray << s					# 信号名
							Typearray << sigtype				# 信号種(func_in:4,func_out:5)
							Widtharray << 1						# ビット幅(必ず1)
#							puts s
						end
				end
			end
			linecount += 1
		end
	end

	if /declare/ =~ s.downcase		# declareが出てくるかどうか
		declare_flag = true			# 出てきたらtrue
	end

end

#==============================================================================
# JSON Output section
# JSON作成
#==============================================================================
out_json = open(filename+'.json', "w")
out_json.print "[\n"
print "[\n"
for i in 0..Typearray.size-1
	out_json.print "{\"name\":\"",Stringarray[i],"\",\"type\":",Typearray[i],",\"width\":",Widtharray[i],"}"
	print "{\"name\":\"",Stringarray[i],"\",\"type\":",Typearray[i],",\"width\":",Widtharray[i],"}"
	if (i<Typearray.size-1) then
		out_json.print ",\n"
		print ",\n"
	else
		out_json.print "]\n"
		print "]\n"
	end
end
out_json.close()
