org 0x7C00
jmp short Boot
nop
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
bpbOEM			db "AAAAAAAA"		;OEM label for the disk (8 bytes)		
bpbBytesPerSector:  	DW 512			;The size of the sectors in bytes
bpbSectorsPerCluster: 	DB 1			;How many sectors make up a cluster
bpbReservedSectors: 	DW 1			;How many sectors are being reserved (only one: the boot sector)
bpbNumberOfFATs: 	DB 2			;How many FAT tables exist (The oringal and a backup)
bpbRootEntries: 	DW 224			;How many files can be stored in the root directory
bpbTotalSectors: 	DW 2880			;How many sectors exist on this disk
bpbMedia: 		DB 0xf0			;The type of media
bpbSectorsPerFAT: 	DW 9			;how many sectors the FAT table takes up on disk
bpbSectorsPerTrack: 	DW 18			;how many sectors fit on one track
bpbHeadsPerCylinder: 	DW 2			;how many physical heads 
bpbHiddenSectors: 	DD 0
bpbTotalSectorsBig: 	DD 0
bsDriveNumber: 		DB 0
bsUnused: 		DB 0
bsExtBootSignature: 	DB 0x29
bsSerialNumber:		DD 0xa0a1a2a3
bsVolumeLabel: 		DB "AAAAAAAAAAA"
bsFileSystem: 		DB "FAT12   "
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

LBAToCHS:
	div [bpbSectorsPerTrack]	;When dividing, the answer is stored in AX but the reaminder is stored in the DX register
	add dx, 0x01				;dx should now be the sector in CHS format
	mov [ABSOLUTESECTOR], dx		;Store the value in mem address pointed to by label
	mov ax, [LBA]
	mul [bpbHeadsPerCylinder]			;multiply the ax register by the number of heads on the medium
	div [bpbSectorsPerTrack]		;divide the ax register by the number of sectors per track
	mov [ABSOLUTECYLINDER], ax		;move what should be the Cylinder into the mem location at the label
	mov ax, [LBA]
	div [bpbSectorsPerTrack]
	div [bpbHeadsPerCylinder]
	mov [ABSOLUTEHEAD], dx			;the remainder, which was stored into dx should be the absolute head
	
	
	
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
	mul 2
	add ax, 1				;AX is now the starting sector of the root directory in LBA
	mov [LBA], ax
	call LBAToCHS				;we now need to convert this into the CHS format 

ReadDisk:
	pusha
	mov si, READING
	popa
	call BPrint
	mov ah, 0x02
	mov al, 	;how many sectors to read
	mov dh, 0	;head
	mov dl, 0x00	;Floppy Drive
	mov bx, 0x7E00	;ES:BX 0x0000:0x7E00
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
ABSOLUTESECTOR times 2 db 0
ABSOLUTEHEAD times 2 db 0
ABSOLUTECYLINDER times 2 db 0
LBA times 2 db 0

times 510 - ($-$$) db 0
dw 0xAA55