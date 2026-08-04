package com.financial.mockserver.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.financial.mockserver.domain.MockApiResponseFixture;
import com.financial.mockserver.domain.ResolvedScenario;
import com.financial.mockserver.dto.ApiEnvelope;
import com.financial.mockserver.service.MockCallLogService;
import com.financial.mockserver.service.MockFixtureService;
import com.financial.mockserver.support.MockApiResult;
import com.financial.mockserver.support.MockResponseSupport;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

/**
 * 6개 1차 API 서비스가 공통으로 따르는 요청 처리 흐름을 담는다.
 * (documents/IMPLEMENTATION_GUIDE.md "요청 처리 흐름" 1~7단계)
 *
 * 1. endpoint/scenarioKey/시나리오 확정 (MockFixtureService)
 * 2. scenarioKey로 사용자를 찾지 못하면 404 NOT_FOUND
 * 3. NORMAL 시나리오면 호출부가 넘긴 동적 조립 로직 실행
 * 4. 그 외 시나리오면 fixture 조회 후 그대로 반환, 없으면 404 NOT_FOUND
 * 5. 모든 분기에서 mock_api_call_log 저장
 */
abstract class AbstractMockApiService {

    @Autowired
    protected MockFixtureService fixtureService;

    @Autowired
    protected MockCallLogService callLogService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    interface NormalAssembler {
        ApiEnvelope<?> assemble(ResolvedScenario context, String traceId, String timestamp);
    }

    protected MockApiResult respond(String method,
                                     String path,
                                     String scenarioKey,
                                     String scenarioOverride,
                                     String requestJson,
                                     NormalAssembler normalAssembler) {
        String traceId = MockResponseSupport.generateTraceId();
        String timestamp = MockResponseSupport.currentTimestamp();
        ResolvedScenario context = fixtureService.resolveContext(method, path, scenarioKey, scenarioOverride);

        if (context.getUser() == null) {
            return notFound(context, method, path, requestJson, traceId, timestamp);
        }

        if (context.isNormal()) {
            ApiEnvelope<?> envelope = normalAssembler.assemble(context, traceId, timestamp);
            callLogService.save(context, method, path, requestJson, 200, traceId, null);
            return new MockApiResult(200, envelope);
        }

        Optional<MockApiResponseFixture> fixtureOpt = fixtureService.findFixture(context);
        if (fixtureOpt.isPresent()) {
            MockApiResponseFixture fixture = fixtureOpt.get();
            callLogService.save(context, method, path, requestJson, fixture.getHttpStatus(), traceId, fixture.getId());
            return new MockApiResult(fixture.getHttpStatus(), fixture.getResponseJson());
        }

        return notFound(context, method, path, requestJson, traceId, timestamp);
    }

    private MockApiResult notFound(ResolvedScenario context,
                                    String method,
                                    String path,
                                    String requestJson,
                                    String traceId,
                                    String timestamp) {
        ApiEnvelope<Object> envelope = MockResponseSupport.notFoundEnvelope(traceId, timestamp);
        callLogService.save(context, method, path, requestJson, 404, traceId, null);
        return new MockApiResult(404, envelope);
    }

    /**
     * mock_api_call_log.request_json에 저장할 JSON 문자열을 만든다.
     * key/value가 번갈아 들어오며, 값이 null인 항목은 제외한다. 남는 값이 없으면 null.
     */
    protected String buildRequestJson(Object... keyValuePairs) {
        Map<String, Object> requestParams = new LinkedHashMap<>();
        for (int i = 0; i + 1 < keyValuePairs.length; i += 2) {
            Object value = keyValuePairs[i + 1];
            if (value != null) {
                requestParams.put(String.valueOf(keyValuePairs[i]), value);
            }
        }
        if (requestParams.isEmpty()) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(requestParams);
        } catch (JsonProcessingException e) {
            return null;
        }
    }
}
