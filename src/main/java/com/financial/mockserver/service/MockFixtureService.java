package com.financial.mockserver.service;

import com.financial.mockserver.domain.MockApiResponseFixture;
import com.financial.mockserver.domain.ResolvedScenario;

import java.util.Optional;

/**
 * documents/IMPLEMENTATION_GUIDE.md "요청 처리 흐름"의 1~5단계를 담당한다.
 * endpoint/user/scenario를 확정하고, 특수 시나리오에 대한 fixture를 조회한다.
 */
public interface MockFixtureService {

    /**
     * method/path로 endpoint를, scenarioKey로 user를, override 또는 시나리오 할당으로
     * 최종 시나리오를 확정한다.
     *
     * @param method           HTTP method (예: GET)
     * @param path             mock_api_endpoint.path와 일치하는 요청 경로
     * @param scenarioKey      요청의 scenarioKey (없으면 demo-normal-user 기본값 적용)
     * @param scenarioOverride 특정 시나리오를 강제하기 위한 override 값 (scenario_code), 없으면 null
     */
    ResolvedScenario resolveContext(String method, String path, String scenarioKey, String scenarioOverride);

    /**
     * 특수 시나리오(NORMAL이 아닌 경우)에 대해 fixture를 조회한다.
     * 매칭되는 fixture가 없으면 empty를 반환하며, 호출부는 404 NOT_FOUND envelope으로 응답해야 한다.
     */
    Optional<MockApiResponseFixture> findFixture(ResolvedScenario context);
}
