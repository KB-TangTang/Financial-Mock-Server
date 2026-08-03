package com.financial.mockserver.service.impl;

import com.financial.mockserver.domain.MockApiEndpoint;
import com.financial.mockserver.domain.MockApiResponseFixture;
import com.financial.mockserver.domain.MockScenario;
import com.financial.mockserver.domain.MockUser;
import com.financial.mockserver.domain.ResolvedScenario;
import com.financial.mockserver.mapper.MockApiEndpointMapper;
import com.financial.mockserver.mapper.MockFixtureMapper;
import com.financial.mockserver.mapper.MockScenarioAssignmentMapper;
import com.financial.mockserver.mapper.MockScenarioMapper;
import com.financial.mockserver.mapper.MockUserMapper;
import com.financial.mockserver.service.MockFixtureService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class MockFixtureServiceImpl implements MockFixtureService {

    private static final String DEFAULT_SCENARIO_KEY = "demo-normal-user";

    @Autowired
    private MockApiEndpointMapper endpointMapper;

    @Autowired
    private MockUserMapper userMapper;

    @Autowired
    private MockScenarioMapper scenarioMapper;

    @Autowired
    private MockScenarioAssignmentMapper assignmentMapper;

    @Autowired
    private MockFixtureMapper fixtureMapper;

    @Override
    public ResolvedScenario resolveContext(String method, String path, String scenarioKey, String scenarioOverride) {
        MockApiEndpoint endpoint = endpointMapper.findByMethodAndPath(method, path);
        if (endpoint == null) {
            throw new IllegalStateException("등록되지 않은 mock_api_endpoint 입니다: " + method + " " + path);
        }

        String effectiveScenarioKey = (scenarioKey == null || scenarioKey.trim().isEmpty())
                ? DEFAULT_SCENARIO_KEY
                : scenarioKey.trim();
        MockUser user = userMapper.findByScenarioKey(effectiveScenarioKey);

        MockScenario scenario = resolveScenario(endpoint, user, scenarioOverride);

        return new ResolvedScenario(user, endpoint, scenario);
    }

    private MockScenario resolveScenario(MockApiEndpoint endpoint, MockUser user, String scenarioOverride) {
        if (scenarioOverride != null && !scenarioOverride.trim().isEmpty()) {
            MockScenario overridden = scenarioMapper.findByCode(scenarioOverride.trim().toUpperCase());
            if (overridden != null) {
                return overridden;
            }
            // 알 수 없는 override 값이면 기본 시나리오로 안전하게 폴백한다.
            return requireDefaultScenario();
        }

        if (user != null) {
            Long assignedScenarioId = assignmentMapper.findActiveScenarioId(user.getId(), endpoint.getId());
            if (assignedScenarioId != null) {
                MockScenario assigned = scenarioMapper.findById(assignedScenarioId);
                if (assigned != null) {
                    return assigned;
                }
            }
        }

        return requireDefaultScenario();
    }

    private MockScenario requireDefaultScenario() {
        MockScenario defaultScenario = scenarioMapper.findDefault();
        if (defaultScenario == null) {
            throw new IllegalStateException("mock_scenario에 기본(is_default=1) 시나리오가 설정되어 있지 않습니다.");
        }
        return defaultScenario;
    }

    @Override
    public Optional<MockApiResponseFixture> findFixture(ResolvedScenario context) {
        return Optional.ofNullable(
                fixtureMapper.findFixture(context.getEndpoint().getId(), context.getScenario().getId()));
    }
}
