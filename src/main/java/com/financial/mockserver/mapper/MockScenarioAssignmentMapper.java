package com.financial.mockserver.mapper;

import org.apache.ibatis.annotations.Param;

public interface MockScenarioAssignmentMapper {
    /**
     * 사용자에게 활성 상태로 할당된 시나리오 ID를 조회한다.
     * endpoint별 할당이 있으면 우선하고, 없으면 endpoint_id가 NULL인 전역 할당을 사용한다.
     */
    Long findActiveScenarioId(@Param("userId") Long userId, @Param("endpointId") Long endpointId);
}
