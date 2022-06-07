TITLE Matrix Multiply(matrix_mutiply.asm)

INCLUDE Irvine32.inc

ExitProcess PROTO,
dwExitCode:DWORD

ReadTheFile PROTO,
Ptrf : PTR DWORD,
fH : DWORD

ParseTable PROTO,
table : DWORD,
RowSize : DWORD,
ColSize : DWORD

ReadCommand PROTO
Calculate PROTO
Display PROTO
SaveToFile PROTO
BToA PROTO
CheckMatrixSize PROTO

.data
MATRIX_SIZE_ERROR BYTE "矩阵尺寸错误"
REAFILE_ERROR BYTE "读取文件发生错误", 0
OUTPUT_ERROR BYTE "导出文件发出错误", 0

tableBuffer BYTE 50 DUP(0)
buffer BYTE 50 DUP(? )
CommandBuffer BYTE 50 DUP(? )

filename1 BYTE 20 DUP(? )
filename2 BYTE 20 DUP(? )
filename3 BYTE 20 DUP(? )
Ptrf1 DWORD OFFSET filename1
Ptrf2 DWORD OFFSET filename2
Ptrf3 DWORD OFFSET filename3
filehandle1 DWORD ?
filehandle2 DWORD ?
filehandle3 DWORD ?

;//最大支持50个值
BinaryResult DWORD 50 DUP(0)
BufferSize DWORD 50
table1 DWORD 50 DUP(0)
table2 DWORD 50 DUP(0)
table3 BYTE 50 DUP(0)
Ptrt1 DWORD OFFSET table1
Ptrt2 DWORD OFFSET table2
Ptrt3 DWORD OFFSET table3

RowSize1 DWORD 0
RowSize2 DWORD 0
ColSize1 DWORD 0
ColSize2 DWORD 0
LEN_OF_T3 DWORD 0

.code
main PROC
	invoke ReadCommand				;//读取命令行，读取到filename1，2，3
	invoke ReadTheFile, Ptrf1, filehandle1;//读文件，读出ascii
	invoke ParseTable, Ptrt1, OFFSET RowSize1, OFFSET ColSize1;//将ascii转二进制，分析行数列数
	invoke ReadTheFile,Ptrf2,filehandle2
	invoke ParseTable, Ptrt2, OFFSET RowSize2, OFFSET ColSize2
	invoke CheckMatrixSize			;//检查矩阵尺寸
	invoke Calculate				;//矩阵乘法
	invoke Display					;//命令行显示
	invoke SaveToFile				;//保存到文件
	invoke ExitProcess,0
main ENDP

;//------------------------------------------------------------
CheckMatrixSize PROC
;//检查矩阵尺寸是否可乘，不可乘退出程序
;//------------------------------------------------------------
	mov edx,ColSize1
	.IF edx != RowSize2
		mov edx, OFFSET Matrix_Size_Error
		call WriteString
		invoke ExitProcess, 0
	.ENDIF
	ret
CheckMatrixSize ENDP

;//------------------------------------------------------------
SaveToFile PROC
;//保存到文件
;//------------------------------------------------------------
	mov edx, Ptrf3
	call CreateOutputFile
	cmp eax, INVALID_HANDLE_VALUE
	je error
	mov filehandle3,eax
	invoke BToA
	mov eax, filehandle3
	mov edx,Ptrt3
	mov ecx,BufferSize
	call WriteToFile
	ret
error:
	mov edx, OFFSET OUTPUT_ERROR
	call WriteString
	invoke ExitProcess, 0
SaveToFile ENDP

;//------------------------------------------------------------
BToA PROC USES esi ebx edx edi
	LOCAL index: DWORD,		;//table3索引
		  temp: DWORD;//带转换的二进制数
;//------------------------------------------------------------
	mov esi,0
	mov index,0
	mov BufferSize,0
	.WHILE esi < LEN_OF_T3
		mov eax, BinaryResult[esi*4]
		mov temp,eax
		mov edi,0	;//压栈次数
		jmp L2
L1:
		mov ebx,10
		mov edx,0
		div ebx	
		add edx,30h
		push edx
		inc edi
L2:
		cmp eax,0h
		jne L1

		.WHILE edi > 0
			pop edx
			mov eax,index
			mov table3[eax],dl
			add BufferSize,1
			add index,1
			dec edi
		.ENDW
		mov eax,index
		mov table3[eax],20h
		add BufferSize,1
		add index,1
		mov edx,0
		mov eax,esi
		inc eax
		mov ebx,ColSize2
		div ebx
		.IF edx == 0h && esi != 0h
			mov eax,index
			mov table3[eax],0Dh
			inc eax
			mov table3[eax],0Ah
			inc eax
			mov index,eax
			add BufferSize,2
		.ENDIF
		inc esi
	.ENDW
	mov eax,index
	mov table3[eax],0h
	ret
BToA ENDP

;//------------------------------------------------------------
Display PROC USES esi eax ebx edx
;//将二进制结果通过WriteDec输出到控制台
;//并且顺便计算结果规模
;//------------------------------------------------------------
	mov esi,0
	mov eax,RowSize1
	mov ebx,ColSize2
	mul ebx
	mov LEN_OF_T3,eax ;//计算结果矩阵的规模
	.WHILE (esi < LEN_OF_T3)
		mov edx,0
		mov eax,esi
		mov ebx,ColSize2
		div ebx
		.IF edx == 0h && esi != 0h
			call CRLF
		.ENDIF
		mov eax, BinaryResult[esi*4]
		call WriteDec
		mov eax,20h
		call WriteChar
		inc esi
	.ENDW
	ret
Display ENDP

;//------------------------------------------------------------
Calculate PROC USES eax ebx edx ecx esi
	LOCAL i: DWORD,j: DWORD,k: DWORD,
		  index: DWORD,sum: DWORD,
		  p1: DWORD,p2: DWORD
;//矩阵乘法
;//------------------------------------------------------------
	mov i, 0
	mov j, 0
	mov k, 0
	mov index, 0
	mov sum, 0
	mov p1, 0
	mov p2, 0
	mov esi,index
@@while:
	mov eax,i
	cmp eax,RowSize1
	jae quit
L1: mov eax,j		
	cmp eax,ColSize2
	mov sum,0
	jae clsJ
L2: mov eax,k;//最里层循环
	cmp eax,ColSize1
	jae clsK
	mov eax,i
	mov ebx,ColSize1
	mul ebx
	add eax, k
	mov eax,table1[eax*4]
	mov p1,eax		;//p1=a[i][k]
	mov eax,k
	mov ebx,ColSize2
	mul ebx
	add eax,j
	mov eax,table2[eax*4]
	mov p2,eax		;//p2=b[k][j]
	mov eax,p1
	mov ebx,p2
	mul ebx
	add sum,eax     ;//sum+=p1*p2
	add k,1
	jmp L2
clsK:
	mov k,0
	add j,1
	mov eax,sum
	mov BinaryResult[esi*4],eax
	inc esi
	jmp L1
clsJ:
	mov j,0
	add i,1
	jmp @@while
quit:
	ret
Calculate ENDP
	
;//------------------------------------------------------------
ParseTable PROC USES eax esi edx ebx ecx,
	table: DWORD,		;//矩阵指针
	RowSize: DWORD,		;//矩阵行数
	ColSize: DWORD		;//矩阵列数
	LOCAL index: DWORD, tmpRow: DWORD, tmpCol: DWORD,
	      digit: DWORD,sum: DWORD
;//将从文件中读取的ASCII码转换为二进制数
;//------------------------------------------------------------
	mov index,0
	mov tmpRow,1;//最后没有CRLF，从1开始记
	mov tmpCol,1;//最后一个后面没空格，从1开始记
	mov esi,0
	.WHILE tableBuffer[esi] != 0
		.IF tableBuffer[esi] == 20h		
			.IF tmpRow < 2
				add tmpCol,1
			.ENDIF
			inc esi
		.ELSEIF tableBuffer[esi] == 0dh
			add tmpRow,1
			add esi,2
		.ELSE				;//ASCII码除以30h余数是对应的数字值
			mov sum,0
			mov digit,0
			.WHILE tableBuffer[esi] >= 30h &&tableBuffer[esi] <= 39h
				mov edx, 0h
				movzx eax, tableBuffer[esi]
				mov ecx, 30h
				div ecx;//结果在EDX
				mov digit, edx
				mov eax, sum;//此时数字自乘10
				mov ebx,10
				mul ebx
				mov sum,eax
				mov edx,digit
				add sum,edx
				inc esi
			.ENDW
			mov eax,table
			add eax,index
			mov ecx,sum
			mov [eax],ecx
			add index,4
		.ENDIF
	.ENDW
	mov eax, tmpCol
	mov esi, ColSize
	mov[esi], eax;//确定列数
	mov eax, tmpRow
	mov esi, RowSize
	mov[esi], eax;//确定行数
	ret
ParseTable ENDP
	
;//------------------------------------------------------------
ReadTheFile PROC USES edx eax ecx,
	Ptrf: PTR DWORD,	;//文件名指针
	fH: DWORD			;//句柄
;//读文件内容，将文件的ASCII码写入缓冲区
;//------------------------------------------------------------
	mov edx,Ptrf
	call OpenInputFile
	cmp eax,INVALID_HANDLE_VALUE
	je error
	mov fH,eax
	mov edx, OFFSET tableBuffer
	mov ecx, DWORD PTR BufferSize
	call ReadFromFile
	mov eax,fH
	call closeFile
	ret
error :
	mov edx, OFFSET REAFILE_ERROR
	call WriteString
	invoke ExitProcess, 0
ReadTheFile ENDP

;//------------------------------------------------------------
ReadCommand PROC USES edx esi ebx
;//读取命令行参数
;//------------------------------------------------------------
	mov edx, OFFSET CommandBuffer
	call GetCommandTail
	mov esi,1
	mov ebx,0
	.while CommandBuffer[esi] != 20h;
		mov al, CommandBuffer[esi]
		mov	filename1[ebx],al
		inc esi
		inc ebx
	.ENDW
	inc esi
	mov filename1[ebx],0
	mov ebx,0
	.while CommandBuffer[esi] != 20h;
		mov al, CommandBuffer[esi]
		mov	filename2[ebx], al
		inc esi
		inc ebx
	.ENDW
	inc esi
	mov filename2[ebx], 0
	mov ebx, 0
	.while CommandBuffer[esi] != 00h;
		mov al, CommandBuffer[esi]
		mov	filename3[ebx], al
		inc esi
		inc ebx
	.ENDW
	mov filename3[ebx], 0
quit:
	ret
ReadCommand ENDP

END main