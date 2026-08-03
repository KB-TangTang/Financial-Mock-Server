package com.financial.mockserver.domain;

import lombok.Data;

/**
 * mock_api_endpoint 테이블 행 매핑.
 */
@Data
public class MockApiEndpoint {
    private Long id;
    private String provider;
    private String method;
    private String path;
    private String operationKey;
}
