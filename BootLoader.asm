org 0x7C00						;1)
jmp short Boot						;2)
nop								;3)
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=		;4)
bpbOEM				db "AAAAAAAA"	;5) OEM label for the disk (8 bytes)		
bpbBytesPerSector:  	DW 512		;6) The size of the sectors in bytes
bpbSectorsPerCluster: 	DB 1			;7) How many sectors make up a cluster
bpbReservedSectors: 	DW 1			;How many sectors are being reserved (only one: the boot sector)
bpbNumberOfFATs: 		DB 2			;How many FAT tables exist (The oringal and a backup)
bpbRootEntries: 		DW 224		;How many files can be stored in the root directory
bpbTotalSectors: 		DW 2880		;How many sectors exist on this disk
bpbMedia: 			DB 0xf0		;The type of media
bpbSectorsPerFAT: 		DW 9			;how many sectors the FAT table takes up on disk
bpbSectorsPerTrack: 	DW 18		;how many sectors fit on one track
bpbHeadsPerCylinder: 	DW 2			;how many physical heads 
bpbHiddenSectors: 		DD 0
bpbTotalSectorsBig: 	DD 0
bsDriveNumber: 		DB 0
bsUnused: 			DB 0
bsExtBootSignature: 	DB 0x29
bsSerialNumber:		DD 0xa0a1a2a3
bsVolumeLabel: 		DB "AAAAAAAAAAA"
bsFileSystem: 			DB "FAT12   "
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
BPrint:
	mov ah, 0x0E
	_BPrintLoop:
	lodsb
	cmp al, 0
	je _BDone
	int 0x10
	jmp _BPrintLoop
	_BDone:
	ret
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
ResetDisk:
	pusha
	mov ah, 0x00
	mov dl, 0x00
	int 0x13
	jc _ResetErr
	popa
	ret
	_ResetErr
	
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

LBAToCHS:							;AX = LBA
	div word [bpbSectorsPerTrack]		;AX = LBA/SPT, DX = AbsoluteSector - 1
	push dx						;Store sector on stack
	div word [bpbHeadsPerCylinder]	;AX = Cylinder, DX = head
	pop bx						;store the sector into BX from stack
	inc bx						;BX = Sector

	mov ch, bl					;Lower 8 bits [First 8 bits of the cylinder] into the upper 8 bits of CH
	mov cl, bh					;Upper 8 bits [Last 2 bits of the cylinder located here]
	shl cl, 6						;move the bits over by six so 00000011 would look like 11000000
	or cl, al						;CX should now be a proper 10 bit cylinder and 6 bit sector with dl as the head
	mov dh, 0x00
	xchg dh, dl
	call ReadDisk
	
	
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Boot:
	cli
	mov ax, 0x0000
	mov es, ax
	mov ds, ax
	mov ss, ax
	mov sp, 0x7C00
	mov bp, 0x0500
	sti

FindRootDir:
	mov ax, 0x0000
	mov ax, word [bpbSectorsPerFAT]
	mov bx, word [bpbNumberOfFATs]
	mul bx
	add ax, 1					;AX is now the starting sector of the root directory in LBA
	jmp LBAToCHS				;we now need to convert this into the CHS format 

ReadDisk:
	pusha
	mov si, READING
	call BPrint
	popa
	mov ah, 0x02
	mov bx, 0x7E00				;ES:BX 0x0000:0x7E00
	int 0x13
	jc _DiskReadError
	mov cx, 0x0008
	jmp ReadFAT

_DiskReadError:
	mov si, READERR
	call BPrint
	cli
	hlt

ReadFAT:
	mov di, [0x7E00]
	mov si, [KERNEL]
	cmp si, di
	jne _NotFound
	inc si
	inc di
	dec cx
	cmp cx, 0x0000
	je _LoadEntry
	jne ReadFAT

_LoadEntry:
	mov si, KERF
	call BPrint
	cli
	hlt

_NotFound:
	mov si, KERNF
	call BPrint
	cli	
	hlt
	
READING db 'Reading Disk...', 0x0A, 0x0D, 0
READERR db '!!ATTENTION!! - Disk Read Error. The system has been halted to prevent damage.', 0x0A, 0x0D, 0
KERNF db '!!ATTENTION!! - No Kernel [TerSysVI.bin] found. The system has been halted to prevent damage.', 0x0A, 0x0D, 0
KERNEL db 'TerSysVI BIN'
KERF db 'Kernel found. Loading Kernel from disk...', 0x0A, 0x0D, 0

times 510 - ($-$$) db 0
dw 0xAA55