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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * documents/IMPLEMENTATION_GUIDE.md "요청 처리 흐름" 1~5단계 검증.
 * 실제 DB 없이 mapper를 stub으로 대체해 시나리오 확정 로직만 검증한다.
 */
class MockFixtureServiceImplTest {

    private static final MockApiEndpoint ENDPOINT = endpoint(100L, "GET", "/api/v1/assets/accounts");

    private static final MockScenario NORMAL = scenario(1L, "NORMAL", 200, true);
    private static final MockScenario TOKEN_EXPIRED = scenario(3L, "TOKEN_EXPIRED", 401, false);

    private static final MockUser NORMAL_USER = user(10L, "demo-normal-user");
    private static final MockUser EMPTY_USER = user(20L, "demo-empty-user");

    private MockFixtureServiceImpl service;
    private Long assignedScenarioId;

    @BeforeEach
    void setUp() {
        service = new MockFixtureServiceImpl();

        ReflectionTestUtils.setField(service, "endpointMapper", stubEndpointMapper());
        ReflectionTestUtils.setField(service, "userMapper", stubUserMapper());
        ReflectionTestUtils.setField(service, "scenarioMapper", stubScenarioMapper());
        ReflectionTestUtils.setField(service, "assignmentMapper", stubAssignmentMapper());
        ReflectionTestUtils.setField(service, "fixtureMapper", stubFixtureMapper());
    }

    @Test
    void resolveContext_defaultsToNormalUserAndNormalScenario_whenNothingSpecified() {
        ResolvedScenario ctx = service.resolveContext("GET", "/api/v1/assets/accounts", null, null);

        assertEquals(NORMAL_USER.getId(), ctx.getUser().getId());
        assertTrue(ctx.isNormal());
    }

    @Test
    void resolveContext_returnsNullUser_whenScenarioKeyUnknown() {
        ResolvedScenario ctx = service.resolveContext("GET", "/api/v1/assets/accounts", "unknown-user", null);

        assertNull(ctx.getUser());
        // override/assignment이 없으므로 기본(NORMAL) 시나리오로 폴백한다.
        assertTrue(ctx.isNormal());
    }

    @Test
    void resolveContext_appliesOverride_regardlessOfAssignment() {
        assignedScenarioId = NORMAL.getId();

        ResolvedScenario ctx = service.resolveContext(
                "GET", "/api/v1/assets/accounts", "demo-normal-user", "TOKEN_EXPIRED");

        assertFalse(ctx.isNormal());
        assertEquals("TOKEN_EXPIRED", ctx.getScenario().getScenarioCode());
    }

    @Test
    void resolveContext_appliesAssignment_whenNoOverrideGiven() {
        assignedScenarioId = TOKEN_EXPIRED.getId();

        ResolvedScenario ctx = service.resolveContext(
                "GET", "/api/v1/assets/accounts", "demo-normal-user", null);

        assertFalse(ctx.isNormal());
        assertEquals("TOKEN_EXPIRED", ctx.getScenario().getScenarioCode());
    }

    @Test
    void resolveContext_fallsBackToDefaultScenario_whenNoOverrideOrAssignment() {
        assignedScenarioId = null;

        ResolvedScenario ctx = service.resolveContext(
                "GET", "/api/v1/assets/accounts", "demo-empty-user", null);

        assertEquals(EMPTY_USER.getId(), ctx.getUser().getId());
        assertTrue(ctx.isNormal());
    }

    @Test
    void findFixture_returnsEmpty_whenNoFixtureRegistered() {
        ResolvedScenario ctx = new ResolvedScenario(NORMAL_USER, ENDPOINT, TOKEN_EXPIRED);

        Optional<MockApiResponseFixture> fixture = service.findFixture(ctx);

        assertTrue(fixture.isPresent());
        assertEquals("token-expired-fixture", fixture.get().getResponseJson());
    }

    private MockApiEndpointMapper stubEndpointMapper() {
        return (method, path) ->
                (ENDPOINT.getMethod().equals(method) && ENDPOINT.getPath().equals(path)) ? ENDPOINT : null;
    }

    private MockUserMapper stubUserMapper() {
        Map<String, MockUser> users = new HashMap<>();
        users.put(NORMAL_USER.getScenarioKey(), NORMAL_USER);
        users.put(EMPTY_USER.getScenarioKey(), EMPTY_USER);
        return users::get;
    }

    private MockScenarioMapper stubScenarioMapper() {
        Map<String, MockScenario> byCode = new HashMap<>();
        byCode.put(NORMAL.getScenarioCode(), NORMAL);
        byCode.put(TOKEN_EXPIRED.getScenarioCode(), TOKEN_EXPIRED);
        Map<Long, MockScenario> byId = new HashMap<>();
        byId.put(NORMAL.getId(), NORMAL);
        byId.put(TOKEN_EXPIRED.getId(), TOKEN_EXPIRED);

        return new MockScenarioMapper() {
            @Override
            public MockScenario findByCode(String scenarioCode) {
                return byCode.get(scenarioCode);
            }

            @Override
            public MockScenario findById(Long id) {
                return byId.get(id);
            }

            @Override
            public MockScenario findDefault() {
                return NORMAL;
            }
        };
    }

    private MockScenarioAssignmentMapper stubAssignmentMapper() {
        return (userId, endpointId) -> assignedScenarioId;
    }

    private MockFixtureMapper stubFixtureMapper() {
        return (endpointId, scenarioId) -> {
            if (TOKEN_EXPIRED.getId().equals(scenarioId)) {
                MockApiResponseFixture fixture = new MockApiResponseFixture();
                fixture.setId(999L);
                fixture.setResponseJson("token-expired-fixture");
                fixture.setHttpStatus(401);
                fixture.setAppCode("TOKEN_EXPIRED");
                return fixture;
            }
            return null;
        };
    }

    private static MockApiEndpoint endpoint(Long id, String method, String path) {
        MockApiEndpoint e = new MockApiEndpoint();
        e.setId(id);
        e.setMethod(method);
        e.setPath(path);
        e.setOperationKey("asset_account_list");
        return e;
    }

    private static MockScenario scenario(Long id, String code, int httpStatus, boolean isDefault) {
        MockScenario s = new MockScenario();
        s.setId(id);
        s.setScenarioCode(code);
        s.setHttpStatus(httpStatus);
        s.setAppCode(code);
        s.setIsDefault(isDefault);
        return s;
    }

    private static MockUser user(Long id, String scenarioKey) {
        MockUser u = new MockUser();
        u.setId(id);
        u.setScenarioKey(scenarioKey);
        u.setNickname(scenarioKey);
        u.setIsActive(true);
        return u;
    }
}
