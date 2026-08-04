package com.financial.mockserver.domain;

import lombok.Data;

/**
 * mock_api_call_log 저장용 파라미터.
 */
@Data
public class MockApiCallLog {
    private Long endpointId;
    private Long scenarioId;
    private Long userId;
    private Long responseFixtureId;
    private String requestMethod;
    private String requestPath;
    private String requestJson;
    private Integer responseStatus;
    private String traceId;
}
