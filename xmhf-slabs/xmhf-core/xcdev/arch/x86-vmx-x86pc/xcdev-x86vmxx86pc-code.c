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

/*
 * XMHF core device initialization slab (xcdev), x86-vmx-x86pc arch. backend
 * author: amit vasudevan (amitvasudevan@acm.org)
 */

#include <xmhf.h>
#include <xmhf-core.h>
#include <xmhf-debug.h>

#include <xcdev.h>
#include <xcapi.h>


bool xcdev_arch_initialize(u32 partition_index){
    u32 i;
    xc_platformdevice_desc_t ddescs;
    context_desc_t ctx;

    ctx.cpu_desc.cpu_index = 0;
    ctx.cpu_desc.isbsp = true;
    ctx.partition_desc.partition_index = partition_index;

    ddescs = XMHF_SLAB_CALL(xc_api_platform_initializeandenumeratedevices(ctx));

    if(!ddescs.desc_valid){
        _XDPRINTF_("%s: Error: could not obtain platform device descriptors\n",
                    __FUNCTION__);
        return false;
    }

    for(i=0; i < ddescs.numdevices; i++){
        _XDPRINTF_("  %02x:%02x.%1x -> vendor_id=%04x, device_id=%04x\n", ddescs.arch_desc[i].pci_bus,
          ddescs.arch_desc[i].pci_device, ddescs.arch_desc[i].pci_function,
          ddescs.arch_desc[i].vendor_id, ddescs.arch_desc[i].device_id);
    }

    if(!XMHF_SLAB_CALL(xc_api_platform_allocdevices_to_partition(ctx, ddescs))){
            _XDPRINTF_("%s: Halting.unable to allocate devices to partition %u\n",
                        __FUNCTION__, partition_index);
            HALT();
    }

    return true;
}