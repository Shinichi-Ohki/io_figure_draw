#!/usr/bin/ruby
#==============================================================================
#	JSON to I/O Figure script
#
#		-i 入力ファイル名(省略された場合は標準入力からJSONを読む)
#		-o 出力ファイル名(省略された場合は"iofig_genarator"を設定)
#==============================================================================

require "rubygems"
require "cairo"			#グラフィックスライブラリ
require "json/pure"		#JSONパーサ
require "optparse"		#コマンドラインオプションパーサ

#==============================================================================
#	矢印を引くメソッド(1bit信号)
#
#	context		:描画するコンテキスト名
#	startx		:開始X座標
#	starty		:開始Y座標
#	allowlength	:長さ
#	allowtype	:向き(1:右向き 2:左向き 3:両方)
#	style		:水平線部分のスタイル(0:実線 1:点線)
#==============================================================================
def drawallow(context,startx,starty,allowlength,allowtype,style)
	wing = 10										# 矢印の羽の長さ
	context.set_line_width(4)						# 線幅を4pixelに
	x = startx
	y = starty
	#---------------------draw horizontal line
	context.set_dash([5,5],2.5) if (style == 1)		# styleが1だったら点線に
	context.move_to(x,y)
	x += allowlength
	context.line_to(x,y)
	context.stroke
	context.set_dash([1,0])

	#---------------------draw left arrow
	if (allowtype >= 2)
		x = startx + wing
		y = starty - wing
		context.move_to(x,y)
		x -= wing
		y += wing
		context.line_to(x,y)
		x += wing
		y += wing
		context.line_to(x,y)
		context.stroke
	end
	
	#---------------------draw right arrow
	if ((allowtype == 1) || (allowtype == 3)) 
		x = startx + allowlength - wing
		y = starty - wing
		context.move_to(x,y)
		x += wing
		y += wing
		context.line_to(x,y)
		x -= wing
		y += wing
		context.line_to(x,y)
		context.stroke
	end
end
#==============================================================================

#==============================================================================
#	矢印を引くメソッド(多bit信号:バス)
#
#	context		:描画するコンテキスト名
#	startx		:開始X座標
#	starty		:開始Y座標
#	allowlength	:長さ
#	allowtype	:向き(1:右向き 2:左向き 3:両方)
#==============================================================================
def drawallow_bus(context,startx,starty,allowlength,allowtype)
	wing = 13
	context.set_line_width(10)
	x = startx
	y = starty
	x += 2 if (allowtype >= 2)
	#---------------------draw horizontal line
	context.move_to(x,y)
	x += allowlength
	x -= 4 if ((allowtype == 1) || (allowtype == 3))
	context.line_to(x,y)
	context.stroke

	context.set_line_width(1)
	#---------------------draw right arrow
	if (allowtype >= 2)
		x = startx + wing - 3
		y = starty - wing
		context.move_to(x,y)
		x -= wing
		y += wing
		context.line_to(x,y)
		x += wing
		y += wing
		context.line_to(x,y)
		context.fill
	end
	
	#---------------------draw left arrow
	if ((allowtype == 1) || (allowtype == 3))
		x = startx + allowlength - wing + 3
		y = starty - wing
		context.move_to(x,y)
		x += wing
		y += wing
		context.line_to(x,y)
		x -= wing
		y += wing
		context.line_to(x,y)
		context.fill
	end
end
#==============================================================================


#==============================================================================
#	オプション解析と入出力ファイル名設定
#
#	-i 入力ファイル名(省略された場合は標準入力からJSONを読む)
#	-o 出力ファイル名(省略された場合は"iofig_genarator"を設定)
#==============================================================================
Stringarray = Array.new
Typearray = Array.new	# 0:null line, 1:input, 2:output, 3: inout, 4:func_in, 5:func_out
Widtharray = Array.new
infilename = String.new
outfilename = String.new

#---------------------Parse commandline option
OptionParser.new {|opt|
	opt.on('-i VAL') {|v| infilename = v }
	opt.on('-o VAL') {|v| outfilename = v }
	opt.parse!(ARGV)
}

#---------------------No input filename
if (infilename=="") then
	jsonfile = String.new
	while( a = gets )
		jsonfile << a
	end
else
	pathname = File::dirname(infilename)
	filename = File::basename(infilename,'.*')
	extname = File::extname(infilename)
	targetfilename = String.new(filename+'.json')

	in_json = open(targetfilename)
		jsonfile = in_json.read
	in_json.close
end

#---------------------No output filename
if (outfilename=="") then
	outfilename = "iofig_genarator"
end

jsondata = JSON.parse(jsonfile)
jsondata.each do |jdata|
	Stringarray << jdata["name"]
	Typearray << jdata["type"]
	Widtharray << jdata["width"]
end
#==============================================================================


#==============================================================================
# Main
#==============================================================================
#----------------Graphics init
fontsize = 30
format = Cairo::FORMAT_RGB24
width = 500
height = Stringarray.size * fontsize + 30
radius = height / 3
maxstrlen = 0
linelen = 100										# 矢印の長さ

Stringarray.each { |str|
	maxstrlen = str.length if (maxstrlen < str.length)
}
maxstrlen *= fontsize*0.6
width = maxstrlen + linelen + 100
surface = Cairo::ImageSurface.new(format, width, height)
context = Cairo::Context.new(surface)
context.font_size = fontsize

#----------------Fill White
context.set_source_rgba(1,1,1,1)
context.rectangle(0, 0, width, height)
context.fill

#----------------Draw allow
#context.set_source_rgba(1, 0, 1, 1)
context.set_source_rgba(0, 0, 0, 1)
y = fontsize*0.7								# Set start Y

(0..Stringarray.size-1).each do |i|
	if (Widtharray[i] == 1 )					# single bit signal
		if (Typearray[i] <=3)					# input,output,inout
			drawallow(context,10,y,linelen,Typearray[i],0)
		else									# func_in,func_out
			drawallow(context,10,y,linelen,Typearray[i]-3,1)
		end
	elsif (Widtharray[i] > 1 )					# Bus
		drawallow_bus(context,10,y,linelen,Typearray[i])
	end
	y += fontsize
end

#----------------Write Text
startx=4+linelen+20
starty=fontsize+2

x = startx
y = starty
context.set_source_rgba(0, 0, 0, 1)
context.set_line_width(1)

Stringarray.each { |str|
	context.move_to(x,y)
	context.show_text(str) if (str.length != 0)
	y+=fontsize
}
context.stroke

#----------------Draw Box
context.rectangle(linelen+20, 1, maxstrlen+50, fontsize*Stringarray.size+20 )
context.stroke

#----------------Output PNG
surface.write_to_png(outfilename+".png")

#----------------Output CSV
Typelegend = ["","input","output","inout","func_in","func_out"]
out_csv = open(outfilename+'.csv', "w")
out_csv.print "\"Signal Name\",\"Signal Type\",\"Signal Width\"\n"
for i in 0..Typearray.size-1
	out_csv.print "\"",Stringarray[i],"\",\"",Typelegend[Typearray[i]],"\",",Widtharray[i],"\n"  if (Stringarray[i].length != 0)
end
out_csv.close()

