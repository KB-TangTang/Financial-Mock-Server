package com.financial.mockserver.service.impl;

import com.financial.mockserver.domain.MockApiCallLog;
import com.financial.mockserver.domain.ResolvedScenario;
import com.financial.mockserver.mapper.MockCallLogMapper;
import com.financial.mockserver.service.MockCallLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class MockCallLogServiceImpl implements MockCallLogService {

    @Autowired
    private MockCallLogMapper callLogMapper;

    @Override
    public void save(ResolvedScenario context,
                      String requestMethod,
                      String requestPath,
                      String requestJson,
                      int responseStatus,
                      String traceId,
                      Long responseFixtureId) {
        MockApiCallLog callLog = new MockApiCallLog();
        callLog.setEndpointId(context.getEndpoint() != null ? context.getEndpoint().getId() : null);
        callLog.setScenarioId(context.getScenario() != null ? context.getScenario().getId() : null);
        callLog.setUserId(context.getUser() != null ? context.getUser().getId() : null);
        callLog.setResponseFixtureId(responseFixtureId);
        callLog.setRequestMethod(requestMethod);
        callLog.setRequestPath(requestPath);
        callLog.setRequestJson(requestJson);
        callLog.setResponseStatus(responseStatus);
        callLog.setTraceId(traceId);

        callLogMapper.insert(callLog);
    }
}
