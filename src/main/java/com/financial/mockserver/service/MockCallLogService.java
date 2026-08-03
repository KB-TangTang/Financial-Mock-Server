package com.financial.mockserver.service;

import com.financial.mockserver.domain.ResolvedScenario;

/**
 * mock_api_call_log 저장을 담당한다. 모든 API 호출은 성공/실패/fixture 여부와 무관하게 기록한다.
 */
public interface MockCallLogService {

    void save(ResolvedScenario context,
              String requestMethod,
              String requestPath,
              String requestJson,
              int responseStatus,
              String traceId,
              Long responseFixtureId);
}
