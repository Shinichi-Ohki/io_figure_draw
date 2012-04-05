#!/usr/bin/ruby
#==============================================================================
#	NSL declare to JSON script
#
# 2011/09/05 ����
# 2011/09/27 �G���A�R�����g�̍폜�ɑΉ�
#==============================================================================

declare_flag = false

Stringarray = Array.new
Typearray = Array.new	# 0:null line, 1:input, 2:output, 3: inout, 4:func_in, 5:func_out
Widtharray = Array.new

exit if (ARGV.size==0)

pathname = File::dirname(ARGV[0])
filename = File::basename(ARGV[0],'.*')
extname = File::extname(ARGV[0])
targetfilename = File.join(pathname,filename+extname)	# �p�X���ƃt�@�C�������Ȃ�
f = open(targetfilename)
targetfile = f.read										# �t�@�C���ꊇ�ǂݏo��
f.close
targetfile.gsub!(/\/\*\/?(\n|[^\/]|[^*]\/)*\*\//,"")	# �G���A�R�����g�̍폜

targetfile.each_line do |s|
	if (/\}/ =~ s) && (declare_flag) then
		declare_flag = false
	end
	if declare_flag
		s.gsub!(/[ \t]+,/,",")						# �J���}�̑O�̋󔒂ƃ^�u���폜
		s.gsub!(/,[ \t]+/,",")						# �J���}�̌�̋󔒂ƃ^�u���폜
		s.gsub!(/\r\n/,"\n")						# CR+LF��LF�݂̂ɕϊ�
		s.gsub!(/[ \t]+\/\/.*/,"")					# ���������Ă�����1�s�R�����g���폜
		linearray = s.sub(/;$/,"").split(/;/)		# �s����;���폜������A;�ŕ���
#		puts linearray
		linecount = 0
		linearray.each do |port|
#			/\((.*?),(.*?)\)/ =~ port
			if (/^[ \t]*\/\/.*/ =~ port) then		# �R�����g��//�݂̂̍s�͖�������
			elsif (/^[ \t]*\n/ =~ port) then		# ��s(�������̓X�y�[�X���^�u�݂̂̍s)�̏ꍇ
				Stringarray << ""					# �M����:null
				Typearray << 0						# �M����:0
				Widtharray << 0						# �r�b�g��:0
			else
				sig = port.strip.split(/[ \t]+/)
#				puts sig[0]
#				puts sig[1]
				case sig[0].downcase				# �M����̔���
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
						# ���input/output/inout�ŕ����̐M����錾���Ă���ꍇ�ɁA������𕪊�����
						signame = sig[1].sub(/[ \t]/,"").split(/[,]/)

#						puts signame.size
						signame.each do |s|						# �M�����ɔz��ɐM���������Z�b�g
							sigitem = s.split(/[\[\]]/)
#							puts s
							Stringarray << s					# �M����
							Typearray << sigtype				# �M����(input:1/output:2/inout:3)
							if (sigitem.size == 1) then			# �r�b�g��
								Widtharray << 1					# 1�̂Ƃ�1
							else
								Widtharray << sigitem[1].to_i	# ����ȊO�̎����̕�
							end
						end
					when 4..5 									# (func_in/func_out)
						# ���func_in/out�ŕ����̐M����錾���Ă���ꍇ�ɁA������𕪊�����
						signame = sig[1].sub(/[ \t],/,"").split(/\),/)	# "),"�ŕ�����𕪊�����(func�ɂ͈���������̂�","�����ŕ����ł��Ȃ�)

						signame.each do |s|						# �M�����ɔz��ɐM���������Z�b�g
							s.concat(")") if ((/[^\)]$/ =~ s) && (/\(/ =~ s)) # ����������")"��������̂ŁA�⊮����B������"("������Ƃ��̂�
							Stringarray << s					# �M����
							Typearray << sigtype				# �M����(func_in:4,func_out:5)
							Widtharray << 1						# �r�b�g��(�K��1)
#							puts s
						end
				end
			end
			linecount += 1
		end
	end

	if /declare/ =~ s.downcase		# declare���o�Ă��邩�ǂ���
		declare_flag = true			# �o�Ă�����true
	end

end

#==============================================================================
# JSON Output section
# JSON�쐬
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
