org 0x7C00
jmp near Boot
nop
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
bpbOEM			db "AAAAAAAA"			
bpbBytesPerSector:  	DW 512
bpbSectorsPerCluster: 	DB 1
bpbReservedSectors: 	DW 1
bpbNumberOfFATs: 	DB 2
bpbRootEntries: 	DW 224
bpbTotalSectors: 	DW 2880
bpbMedia: 		DB 0xf0
bpbSectorsPerFAT: 	DW 9
bpbSectorsPerTrack: 	DW 18
bpbHeadsPerCylinder: 	DW 2
bpbHiddenSectors: 	DD 0
bpbTotalSectorsBig: 	DD 0
bsDriveNumber: 		DB 0
bsUnused: 		DB 0
bsExtBootSignature: 	DB 0x29
bsSerialNumber:		DD 0xa0a1a2a3
bsVolumeLabel: 		DB "OUR FLOPPY "
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

ReadDisk:
	mov si, READING
	call BPrint
	mov ah, 0x02
	mov al, 13	;how many sectors to read
	mov cl, 1	;Starting sector
	mov ch, 1	;cylinder
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

times 510 - ($-$$) db 0
dw 0xAA55