package com.financial.mockserver.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 요청 1건에 대해 확정된 사용자/엔드포인트/시나리오 컨텍스트.
 * scenarioCode가 NORMAL이면 mock_codef_* 원천 테이블에서 동적 조립하고,
 * 그 외에는 mock_api_response_fixture를 조회해 그대로 반환한다.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ResolvedScenario {
    private MockUser user;
    private MockApiEndpoint endpoint;
    private MockScenario scenario;

    public boolean isNormal() {
        return scenario != null && "NORMAL".equals(scenario.getScenarioCode());
    }
}
