package com.financial.mockserver.domain;

import lombok.Data;

/**
 * mock_api_response_fixture 테이블 행 매핑.
 * response_json은 MySQL JSON 컬럼을 문자열로 그대로 받아 그대로 반환한다.
 */
@Data
public class MockApiResponseFixture {
    private Long id;
    private String responseJson;
    private Integer httpStatus;
    private String appCode;
}
