package com.financial.mockserver.mapper;

import com.financial.mockserver.domain.MockUser;
import org.apache.ibatis.annotations.Param;

public interface MockUserMapper {
    MockUser findByScenarioKey(@Param("scenarioKey") String scenarioKey);
}
