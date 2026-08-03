package com.financial.mockserver.mapper;

import com.financial.mockserver.domain.MockApiResponseFixture;
import org.apache.ibatis.annotations.Param;

public interface MockFixtureMapper {
    MockApiResponseFixture findFixture(@Param("endpointId") Long endpointId, @Param("scenarioId") Long scenarioId);
}
