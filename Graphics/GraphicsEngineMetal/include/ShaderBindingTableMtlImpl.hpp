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

#pragma once

/// \file
/// Declaration of Diligent::ShaderBindingTableMtlImpl class

#include "EngineMtlImplTraits.hpp"
#include "ShaderBindingTableBase.hpp"
#include "TopLevelASMtlImpl.hpp"

namespace Diligent
{

/// Shader binding table object implementation in Metal backend.
class ShaderBindingTableMtlImpl final : public ShaderBindingTableBase<EngineMtlImplTraits>
{
public:
    using TShaderBindingTableBase = ShaderBindingTableBase<EngineMtlImplTraits>;

    ShaderBindingTableMtlImpl(IReferenceCounters*           pRefCounters,
                              RenderDeviceMtlImpl*          pDeviceMtl,
                              const ShaderBindingTableDesc& Desc,
                              bool                          bIsDeviceInternal = false);
    ~ShaderBindingTableMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_ShaderBindingTable, TShaderBindingTableBase)

    using BindingTable = TShaderBindingTableBase::BindingTable;
    void GetData(BufferMtlImpl*&   pSBTBufferMtl,
                 BindingTable&     RayGenShaderRecord,
                 BindingTable&     MissShaderTable,
                 BindingTable&     HitGroupTable,
                 BindingTable&     CallableShaderTable);
};

} // namespace Diligent