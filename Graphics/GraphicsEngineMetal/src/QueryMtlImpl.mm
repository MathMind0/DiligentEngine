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
#include "QueryMtlImpl.hpp"
#include "QueryManagerMtl.hpp"
#include "RenderDeviceMtlImpl.hpp"
#include "DeviceContextMtlImpl.hpp"
#include "GraphicsAccessories.hpp"

namespace Diligent
{

QueryMtlImpl::QueryMtlImpl(IReferenceCounters* pRefCounters,
                           RenderDeviceMtlImpl* pRenderDeviceMtlImpl,
                           const QueryDesc&    Desc,
                           bool                IsDeviceInternal) :
    TQueryBase{pRefCounters, pRenderDeviceMtlImpl, Desc, IsDeviceInternal}
{
    LOG_INFO_MESSAGE("Created Metal query of type: ", GetQueryTypeString(Desc.Type));
}

QueryMtlImpl::~QueryMtlImpl()
{
    DiscardQueries();
}

bool QueryMtlImpl::AllocateQueries()
{
    // Note: Query allocation is deferred until OnBeginQuery/OnEndQuery
    return true;
}

void QueryMtlImpl::DiscardQueries()
{
    if (m_pQueryMgr == nullptr)
        return;

    // Discard both query indices (for duration queries)
    if (m_QueryPoolIndex[0] != InvalidIndex)
    {
        m_pQueryMgr->DiscardQuery(m_Desc.Type, m_QueryPoolIndex[0]);
        m_QueryPoolIndex[0] = InvalidIndex;
    }

    if (m_QueryPoolIndex[1] != InvalidIndex)
    {
        m_pQueryMgr->DiscardQuery(m_Desc.Type, m_QueryPoolIndex[1]);
        m_QueryPoolIndex[1] = InvalidIndex;
    }

    m_pQueryMgr = nullptr;
}

void QueryMtlImpl::OnBeginQuery(DeviceContextMtlImpl* pContext)
{
    if (m_Desc.Type == QUERY_TYPE_TIMESTAMP)
    {
        // Timestamp queries don't use BeginQuery
        LOG_ERROR_MESSAGE("BeginQuery is not applicable to timestamp queries. Use EndQuery to record the timestamp.");
        return;
    }

    if (m_Desc.Type == QUERY_TYPE_DURATION)
    {
        // Duration queries are started with BeginQuery
        // Allocate the start query index
        if (m_pQueryMgr == nullptr)
        {
            // TODO: Get the query manager from the context
        }

        if (m_pQueryMgr == nullptr)
        {
            LOG_ERROR_MESSAGE("Query manager is not initialized");
            return;
        }

        m_QueryPoolIndex[0] = m_pQueryMgr->AllocateQuery(m_Desc.Type);
        if (m_QueryPoolIndex[0] == InvalidIndex)
        {
            LOG_ERROR_MESSAGE("Failed to allocate query");
            return;
        }
    }

    TQueryBase::OnBeginQuery(pContext);
}

void QueryMtlImpl::OnEndQuery(DeviceContextMtlImpl* pContext)
{
    if (m_Desc.Type == QUERY_TYPE_TIMESTAMP)
    {
        // For timestamp queries, allocate the index on EndQuery
        if (m_pQueryMgr == nullptr)
        {
            // TODO: Get the query manager from the context
        }

        if (m_pQueryMgr == nullptr)
        {
            LOG_ERROR_MESSAGE("Query manager is not initialized");
            return;
        }

        m_QueryPoolIndex[0] = m_pQueryMgr->AllocateQuery(QUERY_TYPE_TIMESTAMP);
        if (m_QueryPoolIndex[0] == InvalidIndex)
        {
            LOG_ERROR_MESSAGE("Failed to allocate timestamp query");
            return;
        }
    }
    else if (m_Desc.Type == QUERY_TYPE_DURATION)
    {
        // Allocate the end query index for duration queries
        if (m_pQueryMgr == nullptr)
        {
            LOG_ERROR_MESSAGE("Query manager is not initialized");
            return;
        }

        m_QueryPoolIndex[1] = m_pQueryMgr->AllocateQuery(m_Desc.Type);
        if (m_QueryPoolIndex[1] == InvalidIndex)
        {
            LOG_ERROR_MESSAGE("Failed to allocate duration query end");
            return;
        }
    }

    TQueryBase::OnEndQuery(pContext);
}

bool QueryMtlImpl::GetData(void* pData, Uint32 DataSize, bool AutoInvalidate)
{
    // Validate data pointer and size
    TQueryBase::CheckQueryDataPtr(pData, DataSize);

    // Check if the query has been ended
    if (TQueryBase::GetState() != QueryState::Ended)
    {
        LOG_ERROR_MESSAGE("Query data is not available because the query has not been ended");
        return false;
    }

    bool ResultAvailable = false;

    switch (m_Desc.Type)
    {
        case QUERY_TYPE_OCCLUSION:
        {
            QueryDataOcclusion OcclusionData{};
            Uint64             VisibilityResult = 0;
            if (m_pQueryMgr != nullptr && m_pQueryMgr->ReadVisibilityResult(m_QueryPoolIndex[0], VisibilityResult))
            {
                OcclusionData.NumSamples = VisibilityResult;
                memcpy(pData, &OcclusionData, sizeof(OcclusionData));
                ResultAvailable = true;
            }
        }
        break;

        case QUERY_TYPE_BINARY_OCCLUSION:
        {
            QueryDataBinaryOcclusion BinaryData{};
            Uint64                   VisibilityResult = 0;
            if (m_pQueryMgr != nullptr && m_pQueryMgr->ReadVisibilityResult(m_QueryPoolIndex[0], VisibilityResult))
            {
                BinaryData.AnySamplePassed = (VisibilityResult > 0) ? True : False;
                memcpy(pData, &BinaryData, sizeof(BinaryData));
                ResultAvailable = true;
            }
        }
        break;

        case QUERY_TYPE_TIMESTAMP:
        {
            QueryDataTimestamp TimestampData{};
            Uint64             Timestamp = 0;
            if (m_pQueryMgr != nullptr && m_pQueryMgr->ReadTimestamp(m_QueryPoolIndex[0], Timestamp))
            {
                TimestampData.Counter = Timestamp;
                memcpy(pData, &TimestampData, sizeof(TimestampData));
                ResultAvailable = true;
            }
        }
        break;

        case QUERY_TYPE_DURATION:
        {
            QueryDataDuration DurationData{};
            Uint64            StartTimestamp = 0;
            Uint64            EndTimestamp = 0;
            if (m_pQueryMgr != nullptr &&
                m_pQueryMgr->ReadTimestamp(m_QueryPoolIndex[0], StartTimestamp) &&
                m_pQueryMgr->ReadTimestamp(m_QueryPoolIndex[1], EndTimestamp))
            {
                DurationData.Duration = EndTimestamp - StartTimestamp;
                memcpy(pData, &DurationData, sizeof(DurationData));
                ResultAvailable = true;
            }
        }
        break;

        case QUERY_TYPE_PIPELINE_STATISTICS:
        {
            QueryDataPipelineStatistics PipelineStatsData{};
            // TODO: Implement pipeline statistics query
            LOG_ERROR_MESSAGE("Pipeline statistics queries are not yet implemented for Metal backend");
            memcpy(pData, &PipelineStatsData, sizeof(PipelineStatsData));
        }
        break;

        default:
            LOG_ERROR_MESSAGE("Unknown query type: ", static_cast<int>(m_Desc.Type));
            break;
    }

    if (ResultAvailable && AutoInvalidate)
    {
        Invalidate();
    }

    return ResultAvailable;
}

void QueryMtlImpl::Invalidate()
{
    DiscardQueries();
    // Reset query state
    TQueryBase::m_State = QueryState::Inactive;
}

} // namespace Diligent
