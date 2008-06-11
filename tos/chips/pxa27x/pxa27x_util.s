
.macro CPWAIT  Rd
        MRC     P15, 0, \Rd, C2, C0, 0       @ arbitrary read of CP15 into register Rd
        MOV     \Rd, \Rd                     @ wait for it (foward dependency)
        SUB     PC, PC, #4                   @ branch to next instruction
.endm

	
.macro ALLOCATE Rd
        MCR	P15, 0, \Rd, C7, C2, 5       @ perform line allocation based on Rd
.endm
@@@@@@@@@@@@@@@@@@@@@@@@@
@ to create an assembly function that confirms to AAPCS (or so I think ;o)
@ .func function name
@	STMFD R13!, {R4 - R12, LR}..alternatively STMFD R13!, {registers used, LR}
@	{function body}
@	LDMFD R13!, {R4 - R12, PC}...must match above with LR replaced by PC
@ .endfunc
@@@@@@@@@@@@@@@@@@@@@@@@@@

@whether WT or WB is used is determined in mmu_table.s	
  .extern MMUTable 
		
	.equ	MEMORY_CONFIG_BASE,(0x48000000)      
         .equ	FLASH_SYNC_value, (0x25C3<<1) @ Value to set flash into burst 16 sync mode
	@.equ	FLASH_SYNC_value, (0x25C2<<1) @ Value to set flash into burst 8 sync mode
        .equ	FLASH_WRITE,(0x0060)        @ Code for writing to flash
	.equ	FLASH_READSTATUS,(0x0070)        @ Code for reading status
        .equ	FLASH_WCONF,(0x0003)        @ Code to confirm write to flash	
        .equ	FLASH_READ,(0x00FF)	      @ Code to place flash in read mode	
        .equ	SXCNFG_sync_value,(0x7011)    @ SXCNFG value for burst16 sync flash operation
	@ .equ	SXCNFG_sync_value,(0x6011)    @ SXCNFG value for burst8  sync flash operation	
	.equ    SXCNFG_offset,(0x1c)     

	.global initMMU
	.global initSyncFlash
	.global enableICache	
	.global enableDCache
	.global disableDCache		
	.global invalidateDCache
	.global cleanDCache
	.global globalCleanAndInvalidateDCache
		
initSyncFlash:
	@this function MUST be called after the ICACHE is initialized to work correctly!!!
	@also, the DCache being on in WB mode will possibly cause this to randomly FAIL!
.func initSyncFlash
	STMFD R13!, {R4 - R7, LR}
	ldr     r1,     =MEMORY_CONFIG_BASE     @ Memory config register base
        ldr     r2,     =FLASH_SYNC_value	@ Value to set into flash RCR register
        ldr     r3,     =FLASH_WRITE		@ Write to flash instruction
        ldr     r4,     =FLASH_WCONF		@ Write to flash confirm instruction
        ldr     r5,     =FLASH_READ		@ Load "read array" mode command
        ldr     r6,     =0x0			@ Boot ROM Flash Base address
        ldr     r7,     =SXCNFG_sync_value	@ SXCNFG Magic number for now
	b goSyncFlash

@align on cache line so that we fetch the next 8 instructions...	
.align 5
goSyncFlash:	
	@ Now program everything into the Flash and SXCNFG registers
        str     r7,     [r1, #SXCNFG_offset]		@ Update PXA27x SXCNFG register
        strh    r3,     [r2]                            @ Yes, the data is on the address bus!
        strh    r4,     [r2]                            @ Confirm the write to the RCR
        strh    r5,     [r6]                            @ Place flash back in read mode
        ldrh    r5,     [r6]                            @ Create a data dependency stall to guarantee write
        nop                                             @ go to the end of the cache line
	nop
        nop
	LDMFD R13!, {R4 - R7, PC}
.endfunc

	@assembly routine to init our MMU
initMMU:
.func initMMU
	MRC P15,0,R0,C3,C0,0		@read the domain register into R0
	ORR R0, R0, #0xFF		@make sure that we completely enable domain 0
	MCR P15,0,R0,C3,C0,0		@write the domain register
	CPWAIT R0			@be anal and make sure it completes

	@time to setup the page table base register
	@LDR R0, =MMUTable		@move the table we want into R0
	MCR P15, 0, R0, C2, C0		@save it     
        CPWAIT	R0			@wait it

	@time to enable the MMU!
        MRC P15,0,R0,C1,C0,0		@get CP15 register 1
        ORR R0, R0, #0x1		@set the MMU enable bit
        MCR P15,0,R0,C1,C0,0		@save it
	CPWAIT	R0			@wait it
	MOV PC, LR
.endfunc

enableICache:	
.func enableICache
	@icache section
	@globally unlock the icache
	MCR P15, 0, R0, C9, C1, 1
	CPWAIT R0

	@globally unlock the itlb
	MCR P15, 0, R0, C10, C4, 1
	CPWAIT R0
		
	@invalidate just the icache and BTB....write to P15 C7, C5, 0
	MCR P15, 0, R0, C7, C5, 0
	CPWAIT R0
    
	@invalidate the iTLB...write to P15 C8, C5, 0
	MCR P15, 0, R0, c8, c5,	0	@save it
	CPWAIT R0			@wait it
    
	@Enable instruction cache 
	MRC P15, 0, R0, C1, C0, 0	@get CP15 register 1
	ORR R0, R0, #0x1000		@set the icache bit
	MCR P15, 0, R0, C1, C0, 0	@wait it
	CPWAIT R0
	
	@enable the BTB
	MRC P15, 0, R0, C1, C0, 0	@get CP15 register 1
	ORR R0, R0, #0x800		@set the btb enable bit
	MCR P15, 0, R0, C1, C0, 0	@save it	
	CPWAIT R0			@wait it	
	MOV PC, LR
.endfunc


enableDCache:
.func enableDCache
	@globally unlock the dtlb
	MCR P15, 0, R0, c10, c8, 1
	CPWAIT R0
	
	@globally unlock the dcache
	MCR P15, 0, R0, C9, c2, 1
	CPWAIT R0
	
	@first invalidate dcache and mini-dcache
	MCR P15, 0, R0, C7, C6, 0
	CPWAIT R0

	@invalidate the dTLB...write to P15 C8, C6, 0
	MCR P15, 0, R0, C8, C6,	0	@save it
	CPWAIT R0			@wait it

	
	@ now, enable data cache	
	MCR P15, 0, R0, C7, C10, 4	@drain write buffer
	MRC P15, 0, R0, C1, C0, 0	@get CP15 register 1
	ORR R0, R0, #0x4		@set the dcache enable bit
	MCR P15, 0, R0, C1, C0, 0	@save it
	CPWAIT R0			@wait it
	MOV PC, LR
.endfunc

disableDCache:
.func disableDCache
@since caching might be WB or WT for a given line, need to invalidate/flush dcache to ensure coherency
	@globally unlock the dcache
	STMFD R13!, {R0, LR}
	MCR P15, 0, R0, C9, c2, 1
	CPWAIT R0

	@globally clean and invalidate the cache
	bl globalCleanAndInvalidateDCache
		
	@ now, disable data cache	
	MCR P15, 0, R0, C7, C10, 4	@drain write buffer
	MRC P15, 0, R0, C1, C0, 0	@get CP15 register 1
	BIC R0, R0, #0x4		@clear the dcache enable bit
	MCR P15, 0, R0, C1, C0, 0	@save it
	CPWAIT R0			@wait it
	LDMFD R13!, {R0, LR}
.endfunc

@function to invalidate the DCCache for a given Buffer
@funtion take 2 parameters
@R0 = base virtual address to evict
@R1 = number of bytes to evict...cache line is 32 bytes
invalidateDCache:	
.func invalidateDCache
	CMPS R1,#0			@check that we're greater than 0
	MOVLE PC, LR			@return if not
invalidateDCacheLoop:	
	MCR P15, 0, R0, C7, C6, 1	@invalidate this line
	SUBS R1, R1, #32		@subtract out 32 w/CPSR update
	ADD  R0, R0, #32		@add 32 to the address w/o CPSR update
	BGT invalidateDCacheLoop	@rerun if subtract is greater than
	MOV PC, LR
.endfunc

@function to clean the DCCache for a given Buffer
@if a line is dirty, it will be cleaned...i.e. written back to memory in WB mode
@funtion take 2 parameters
@R0 = base virtual address to evict
@R1 = number of bytes to evict...cache line is 32 bytes
cleanDCache:	
.func cleanDCache
	CMPS R1,#0			@check that we're greater than 0
	MOVLE PC, LR			@return if not
cleanDCacheLoop:	
	MCR P15, 0, R0, C7, C10, 1	@clean this line
	SUBS R1, R1, #32		@subtract out 32 w/CPSR update
	ADD  R0, R0, #32		@add 32 to the address w/o CPSR update
	BGT cleanDCacheLoop		@rerun if subtract is greater than
	MCR P15, 0, R0, C7, C10, 4	@drain write buffer
	CPWAIT R0			@wait it
	MOV PC, LR
.endfunc


@Global Clean/Invalidate THE DATA CACHE
@R1 contains the virtual address of a region of cacheable memory reserved for
@this clean operation
@R0 is the loop count; Iterate 1024 times which is the number of lines in the
@data cache
	
globalCleanAndInvalidateDCache:
.func globalCleanAndInvalidateDCache
	@note, this function assumes that we will NEVER have anything physical at
	@address 0x04000000 corresponds to static chip select 1
	STMFD R13!, {R0 - R3, LR}
	LDR R1, =0x04000000	
	MOV R0, #1024
LOOP1:
	
	ALLOCATE R1 @ Allocate a line at the virtual address
	@ specified by R1.
	SUBS R0, R0, #1 @ Decrement loop count
	ADD R1, R1, #32 @ Increment the address in R1 to the next cache line
	BNE LOOP1
	
	@Clean the Mini-data Cache
	@ CanÆt use line-allocate command, so cycle 2KB of unused data through.
	@ R2 contains the virtual address of a region of cacheable memory reserved for
	@ cleaning the Mini-data Cache
	@ R0 is the loop count; Iterate 64 times which is the number of lines in the
	@ Mini-data Cache.

	@note, this function assumes that we will NEVER have anything physical at
	@address 0x05000000 corresponds to static chip select 1
	LDR R2, =0x05000000	
	MOV R0, #64
LOOP2:
	SUBS R0, R0, #1 @ Decrement loop count
	LDR R3,[R2],#32 @ Load and increment to next cache line
	BNE LOOP2
	
	@ Invalidate the data cache and mini-data cache
	MCR P15, 0, R0, C7, C6, 0
	LDMFD R13!, {R0 - R3, PC}
.endfunc
	
.end
	