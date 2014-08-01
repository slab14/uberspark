/*
 * @XMHF_LICENSE_HEADER_START@
 *
 * eXtensible, Modular Hypervisor Framework (XMHF)
 * Copyright (c) 2009-2012 Carnegie Mellon University
 * Copyright (c) 2010-2012 VDG Inc.
 * All Rights Reserved.
 *
 * Developed by: XMHF Team
 *               Carnegie Mellon University / CyLab
 *               VDG Inc.
 *               http://xmhf.org
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in
 * the documentation and/or other materials provided with the
 * distribution.
 *
 * Neither the names of Carnegie Mellon or VDG Inc, nor the names of
 * its contributors may be used to endorse or promote products derived
 * from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * @XMHF_LICENSE_HEADER_END@
 */

#include <xmhf.h>
#include <xmhf-core.h>
#include <xmhf-debug.h>

#include <xcprimeon.h>

#define __XMHF_SLAB_CALLER_INDEX__	XMHF_SLAB_XCPRIMEON_INDEX
#include <xc-initbs.h>
#undef __XMHF_SLAB_CALLER_INDEX__

/*//this is the SL parameter block and is placed in a seperate (untrusted)
//section. It is populated by the XMHF bootloader.
XMHF_BOOTINFO xcbootinfo __attribute__(( section(".sl_untrusted_params") )) = {
	.magic = SL_PARAMETER_BLOCK_MAGIC,
};

XMHF_BOOTINFO *xcbootinfo = (XMHF_BOOTINFO *)&xmhf_rpb_start;
*/

/*
 * slab code
 * 
 * author: amit vasudevan (amitvasudevan@acm.org)
 */

void xcprimeon_startup(void){

	u32 runtime_physical_base;
	u32 runtime_size_2Maligned;

	//initialize debugging early on
	xmhf_debug_init((char *)&xcbootinfo->debugcontrol_buffer);

	_XDPRINTF_("%s: alive and starting...\n", __FUNCTION__);
	
	//debug: dump bootinfo
	_XDPRINTF_("SL: xcbootinfo at = 0x%08x\n", (u32)xcbootinfo);
	_XDPRINTF_("	numE820Entries=%u\n", xcbootinfo->memmapinfo_numentries);
	_XDPRINTF_("	system memory map buffer at 0x%08x\n", (u32)&xcbootinfo->memmapinfo_buffer);
	_XDPRINTF_("	numCPUEntries=%u\n", xcbootinfo->cpuinfo_numentries);
	_XDPRINTF_("	cpuinfo buffer at 0x%08x\n", (u32)&xcbootinfo->cpuinfo_buffer);
	_XDPRINTF_("	SL + core size= %u bytes\n", xcbootinfo->size);
	_XDPRINTF_("	OS bootmodule at 0x%08x, size=%u bytes\n", 
		xcbootinfo->richguest_bootmodule_base, xcbootinfo->richguest_bootmodule_size);
    _XDPRINTF_("\tcmdline = \"%s\"\n", xcbootinfo->cmdline_buffer);

	//get runtime physical base
	runtime_physical_base = __TARGET_BASE_SL;
	
	//compute 2M aligned runtime size
	runtime_size_2Maligned = (((xcbootinfo->size) + (1 << 21) - 1) & ~((1 << 21) - 1));
	

	_XDPRINTF_("SL: runtime at 0x%08x; size=0x%08x bytes adjusted to 0x%08x bytes (2M aligned)\n", 
			runtime_physical_base, xcbootinfo->size, runtime_size_2Maligned);


	
	//setup bootinfo with required parameters
	{
		_XDPRINTF_("SL: XMHF_BOOTINFO at 0x%08x, magic=0x%08x\n", (u32)xcbootinfo, xcbootinfo->magic);
		HALT_ON_ERRORCOND(xcbootinfo->magic == RUNTIME_PARAMETER_BLOCK_MAGIC);
			
		//store runtime physical and virtual base addresses along with size
		xcbootinfo->physmem_base = runtime_physical_base; 
		xcbootinfo->virtmem_base = __TARGET_BASE_SL;
		xcbootinfo->size = xcbootinfo->size;

		//store revised E820 map and number of entries
		//memcpy((void *)xcbootinfo->memmapinfo_buffer, (void *)&xcbootinfo->memmapinfo_buffer, (sizeof(GRUBE820) * xcbootinfo->memmapinfo_numentries) );
		//xcbootinfo->memmapinfo_numentries = xcbootinfo->memmapinfo_numentries; 

		//store CPU table and number of CPUs
		//memcpy((void *)xcbootinfo->cpuinfo_buffer, (void *)&xcbootinfo->cpuinfo_buffer, (sizeof(PCPU) * xcbootinfo->cpuinfo_numentries) );
		//xcbootinfo->cpuinfo_numentries = xcbootinfo->cpuinfo_numentries; 

		//setup guest OS boot module info in LPB	
		//xcbootinfo->richguest_bootmodule_base=xcbootinfo->richguest_bootmodule_base;
		//xcbootinfo->richguest_bootmodule_size=xcbootinfo->richguest_bootmodule_size;

		//pass optional app module if any
		//xcbootinfo->runtime_appmodule_base = 0;
		//xcbootinfo->runtime_appmodule_size = 0;

	//#if defined (__DEBUG_SERIAL__)
		//pass along UART config for serial debug output
		//xcbootinfo->RtmUartConfig = xcbootinfo->uart_config;
		//memcpy(&xcbootinfo->debugcontrol_buffer, &xcbootinfo->debugcontrol_buffer, sizeof(xcbootinfo->debugcontrol_buffer));
	//#endif

		//pass command line configuration forward 
		//COMPILE_TIME_ASSERT(sizeof(xcbootinfo->cmdline_buffer) == sizeof(xcbootinfo->cmdline_buffer));
		//strncpy(xcbootinfo->cmdline_buffer, (void *)&xcbootinfo->cmdline_buffer, sizeof(xcbootinfo->cmdline_buffer));
	}

	//[debug] dump E820
 	#ifndef __XMHF_VERIFICATION__
 	_XDPRINTF_("\nNumber of E820 entries = %u", xcbootinfo->memmapinfo_numentries);
	{
		int i;
		for(i=0; i < (int)xcbootinfo->memmapinfo_numentries; i++){
			_XDPRINTF_("\n0x%08x%08x, size=0x%08x%08x (%u)", 
			  xcbootinfo->memmapinfo_buffer[i].baseaddr_high, xcbootinfo->memmapinfo_buffer[i].baseaddr_low,
			  xcbootinfo->memmapinfo_buffer[i].length_high, xcbootinfo->memmapinfo_buffer[i].length_low,
			  xcbootinfo->memmapinfo_buffer[i].type);
		}
  	}
	#endif //__XMHF_VERIFICATION__


	//initialize basic platform elements
	//xmhf_sl_arch_baseplatform_initialize();
	xcprimeon_platform_arch_initialize();
	
	//sanitize cache/MTRR/SMRAM (most important is to ensure that MTRRs 
	//do not contain weird mappings)
#if defined (__DRT__)
    xmhf_sl_arch_sanitize_post_launch();
#endif	//__DRT__

#if defined (__DMAP__)    
	//setup DMA protection on runtime (secure loader is already DMA protected)
	//xmhf_sl_arch_early_dmaprot_init(xcbootinfo->runtime_size);
	xmhf_sl_arch_early_dmaprot_init(__TARGET_BASE_SL, xcbootinfo->size);
#endif

	//print out slab table
	{
			u32 i;
			
			for(i=0; i < XMHF_SLAB_NUMBEROFSLABS; i++){
				_XDPRINTF_("\nslab %u: dumping slab header", i);
				_XDPRINTF_("\n	slab_index=%u", _slab_table[i].slab_index);
				_XDPRINTF_("\n	slab_macmid=%08x", _slab_table[i].slab_macmid);
				_XDPRINTF_("\n	slab_privilegemask=%08x", _slab_table[i].slab_privilegemask);
				_XDPRINTF_("\n	slab_tos=%08x", _slab_table[i].slab_tos);
				_XDPRINTF_("\n  slab_rodata(%08x-%08x)", _slab_table[i].slab_rodata.start, _slab_table[i].slab_rodata.end);
				_XDPRINTF_("\n  slab_rwdata(%08x-%08x)", _slab_table[i].slab_rwdata.start, _slab_table[i].slab_rwdata.end);
				_XDPRINTF_("\n  slab_code(%08x-%08x)", _slab_table[i].slab_code.start, _slab_table[i].slab_code.end);
				_XDPRINTF_("\n  slab_stack(%08x-%08x)", _slab_table[i].slab_stack.start, _slab_table[i].slab_stack.end);
				//_XDPRINTF_("\n  slab_trampoline(%08x-%08x)", _slab_table[i].slab_trampoline.start, _slab_table[i].slab_trampoline.end);
				_XDPRINTF_("\n  slab_entrycr3=%08x", _slab_table[i].entry_cr3);
			}
	}

	//initialize slab page tables
	xcprimeon_initialize_slab_tables();
		
	//transfer control to runtime
	//xmhf_sl_arch_xfer_control_to_runtime(xcbootinfo);
	XMHF_SLAB_CALL(xmhf_runtime_entry());

#ifndef __XMHF_VERIFICATION__
	//we should never get here
	_XDPRINTF_("\nSL: Fatal, should never be here!");
	HALT();
#else
	return;
#endif
	 
	 
}

///////
XMHF_SLAB("xcprimeon")

//XMHF_SLAB_DEFINTERFACE(
//	XMHF_SLAB_DEFEXPORTFN(xcprimeon_startup, XMHF_SLAB_PRIMEON_FNSTARTUP, XMHF_SLAB_FN_RETTYPE_NORMAL)
//)
