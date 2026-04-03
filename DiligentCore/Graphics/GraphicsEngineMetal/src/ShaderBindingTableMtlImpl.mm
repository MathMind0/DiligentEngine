/*
 *  Copyright 2019-2026 Diligent Graphics LLC
 *  Copyright 2015-2019 Egor Yusov
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#include "pch.h"

#include "ShaderBindingTableMtlImpl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "PipelineStateMtlImpl.hpp"
#include "TopLevelASMtlImpl.hpp"
#include "BufferMtlImpl.hpp"

namespace Diligent
{

ShaderBindingTableMtlImpl::ShaderBindingTableMtlImpl(IReferenceCounters*           pRefCounters,
                                                     RenderDeviceMtlImpl*          pDevice,
                                                     const ShaderBindingTableDesc& SBTDesc,
                                                     bool                          bIsDeviceInternal) :
    TShaderBindingTableBase{pRefCounters, pDevice, SBTDesc, bIsDeviceInternal}
{
}

ShaderBindingTableMtlImpl::~ShaderBindingTableMtlImpl()
{
}

void ShaderBindingTableMtlImpl::GetData(BufferMtlImpl*& pSBTBufferMtl,
                                        BindingTable&   RayGenShaderRecord,
                                        BindingTable&   MissShaderTable,
                                        BindingTable&   HitGroupTable,
                                        BindingTable&   CallableShaderTable)
{
    TShaderBindingTableBase::GetData(pSBTBufferMtl, RayGenShaderRecord, MissShaderTable, HitGroupTable, CallableShaderTable);
}

} // namespace Diligent
