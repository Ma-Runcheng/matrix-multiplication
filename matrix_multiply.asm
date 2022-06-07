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
MATRIX_SIZE_ERROR BYTE "����ߴ����"
REAFILE_ERROR BYTE "��ȡ�ļ���������", 0
OUTPUT_ERROR BYTE "�����ļ���������", 0

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

;//���֧��50��ֵ
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
	invoke ReadCommand				;//��ȡ�����У���ȡ��filename1��2��3
	invoke ReadTheFile, Ptrf1, filehandle1;//���ļ�������ascii
	invoke ParseTable, Ptrt1, OFFSET RowSize1, OFFSET ColSize1;//��asciiת�����ƣ�������������
	invoke ReadTheFile,Ptrf2,filehandle2
	invoke ParseTable, Ptrt2, OFFSET RowSize2, OFFSET ColSize2
	invoke CheckMatrixSize			;//������ߴ�
	invoke Calculate				;//����˷�
	invoke Display					;//��������ʾ
	invoke SaveToFile				;//���浽�ļ�
	invoke ExitProcess,0
main ENDP

;//------------------------------------------------------------
CheckMatrixSize PROC
;//������ߴ��Ƿ�ɳˣ����ɳ��˳�����
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
;//���浽�ļ�
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
	LOCAL index: DWORD,		;//table3����
		  temp: DWORD;//��ת���Ķ�������
;//------------------------------------------------------------
	mov esi,0
	mov index,0
	mov BufferSize,0
	.WHILE esi < LEN_OF_T3
		mov eax, BinaryResult[esi*4]
		mov temp,eax
		mov edi,0	;//ѹջ����
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
;//�������ƽ��ͨ��WriteDec���������̨
;//����˳���������ģ
;//------------------------------------------------------------
	mov esi,0
	mov eax,RowSize1
	mov ebx,ColSize2
	mul ebx
	mov LEN_OF_T3,eax ;//����������Ĺ�ģ
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
;//����˷�
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
L2: mov eax,k;//�����ѭ��
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
	table: DWORD,		;//����ָ��
	RowSize: DWORD,		;//��������
	ColSize: DWORD		;//��������
	LOCAL index: DWORD, tmpRow: DWORD, tmpCol: DWORD,
	      digit: DWORD,sum: DWORD
;//�����ļ��ж�ȡ��ASCII��ת��Ϊ��������
;//------------------------------------------------------------
	mov index,0
	mov tmpRow,1;//���û��CRLF����1��ʼ��
	mov tmpCol,1;//���һ������û�ո񣬴�1��ʼ��
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
		.ELSE				;//ASCII�����30h�����Ƕ�Ӧ������ֵ
			mov sum,0
			mov digit,0
			.WHILE tableBuffer[esi] >= 30h &&tableBuffer[esi] <= 39h
				mov edx, 0h
				movzx eax, tableBuffer[esi]
				mov ecx, 30h
				div ecx;//�����EDX
				mov digit, edx
				mov eax, sum;//��ʱ�����Գ�10
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
	mov[esi], eax;//ȷ������
	mov eax, tmpRow
	mov esi, RowSize
	mov[esi], eax;//ȷ������
	ret
ParseTable ENDP
	
;//------------------------------------------------------------
ReadTheFile PROC USES edx eax ecx,
	Ptrf: PTR DWORD,	;//�ļ���ָ��
	fH: DWORD			;//���
;//���ļ����ݣ����ļ���ASCII��д�뻺����
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
;//��ȡ�����в���
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