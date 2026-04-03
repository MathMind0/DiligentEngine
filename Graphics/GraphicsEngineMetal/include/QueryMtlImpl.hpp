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
/// Declaration of Diligent::QueryMtlImpl class

#include <array>

#include "EngineMtlImplTraits.hpp"
#include "QueryBase.hpp"

#import <Metal/Metal.h>

namespace Diligent
{

class QueryManagerMtl;

/// Query implementation in Metal backend.
class QueryMtlImpl final : public QueryBase<EngineMtlImplTraits>
{
public:
    using TQueryBase = QueryBase<EngineMtlImplTraits>;

    QueryMtlImpl(IReferenceCounters* pRefCounters,
                 RenderDeviceMtlImpl* pRenderDeviceMtlImpl,
                 const QueryDesc&    Desc,
                 bool                IsDeviceInternal = false);
    ~QueryMtlImpl();

    IMPLEMENT_QUERY_INTERFACE_IN_PLACE(IID_QueryMtl, TQueryBase)

    /// Implementation of IQuery::GetData().
    virtual bool DILIGENT_CALL_TYPE GetData(void* pData, Uint32 DataSize, bool AutoInvalidate) override final;

    /// Implementation of IQuery::Invalidate().
    virtual void DILIGENT_CALL_TYPE Invalidate() override final;

    /// Returns the query pool index for the specified query ID.
    /// For duration queries, QueryId can be 0 (start) or 1 (end).
    Uint32 GetQueryPoolIndex(Uint32 QueryId) const
    {
        VERIFY_EXPR(QueryId == 0 || m_Desc.Type == QUERY_TYPE_DURATION && QueryId == 1);
        return m_QueryPoolIndex[QueryId];
    }

    /// Called when BeginQuery is invoked on the device context.
    void OnBeginQuery(DeviceContextMtlImpl* pContext);

    /// Called when EndQuery is invoked on the device context.
    void OnEndQuery(DeviceContextMtlImpl* pContext);

    /// Returns the visibility result buffer offset for occlusion queries.
    Uint32 GetVisibilityResultOffset() const
    {
        return m_QueryPoolIndex[0] * sizeof(Uint64);
    }

private:
    /// Allocates queries from the query manager.
    bool AllocateQueries();

    /// Discards queries back to the query manager.
    void DiscardQueries();

    /// Query pool indices (for duration queries, we need two indices)
    std::array<Uint32, 2> m_QueryPoolIndex = {InvalidIndex, InvalidIndex};

    /// Fence value when the query was ended
    Uint64 m_QueryEndFenceValue = ~Uint64{0};

    /// Pointer to the query manager
    QueryManagerMtl* m_pQueryMgr = nullptr;

    /// Invalid index constant
    static constexpr Uint32 InvalidIndex = static_cast<Uint32>(-1);
};

} // namespace Diligent
