package com.financial.mockserver.domain;

import lombok.Data;

/**
 * mock_scenario 테이블 행 매핑.
 */
@Data
public class MockScenario {
    private Long id;
    private String scenarioCode;
    private Integer httpStatus;
    private String appCode;
    private Boolean isDefault;
}
