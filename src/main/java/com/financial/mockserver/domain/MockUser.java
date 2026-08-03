package com.financial.mockserver.domain;

import lombok.Data;

/**
 * mock_user 테이블 행 매핑.
 */
@Data
public class MockUser {
    private Long id;
    private String scenarioKey;
    private String nickname;
    private String email;
    private Boolean isActive;
}
