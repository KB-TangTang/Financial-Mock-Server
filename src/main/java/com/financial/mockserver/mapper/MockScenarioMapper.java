package com.financial.mockserver.mapper;

import com.financial.mockserver.domain.MockScenario;
import org.apache.ibatis.annotations.Param;

public interface MockScenarioMapper {
    MockScenario findByCode(@Param("scenarioCode") String scenarioCode);

    MockScenario findById(@Param("id") Long id);

    MockScenario findDefault();
}
