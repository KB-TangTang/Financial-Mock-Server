package com.financial.mockserver.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.financial.mockserver.service.MockAssetService;
import com.financial.mockserver.support.MockApiResult;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;

/**
 * mapper/service에서 예상치 못한 런타임 예외가 발생했을 때
 * GlobalExceptionHandler가 500 + 공통 envelope 형태로 응답하는지 검증한다.
 */
class GlobalExceptionHandlerTest {

    @Test
    void unexpectedException_isConvertedToCommonEnvelope() throws Exception {
        MockAssetController controller = new MockAssetController();
        ReflectionTestUtils.setField(controller, "assetService", throwingAssetService());

        MockMvc mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();

        MockHttpServletResponse response = mockMvc.perform(get("/api/v1/assets/accounts"))
                .andReturn()
                .getResponse();

        assertEquals(500, response.getStatus());
        assertTrue(response.getContentType().contains("application/json"));

        JsonNode body = new ObjectMapper().readTree(response.getContentAsString());
        assertEquals("INTERNAL_ERROR", body.get("code").asText());
        assertTrue(body.get("data").isNull());
        assertFalse(body.get("traceId").asText().isEmpty());
        assertFalse(body.get("timestamp").asText().isEmpty());
    }

    private MockAssetService throwingAssetService() {
        return new MockAssetService() {
            @Override
            public MockApiResult getBankAccounts(String scenarioKey, String scenarioOverride) {
                throw new RuntimeException("DB down");
            }

            @Override
            public MockApiResult getDeposits(String scenarioKey, String scenarioOverride) {
                throw new UnsupportedOperationException();
            }

            @Override
            public MockApiResult getStocks(String scenarioKey, String scenarioOverride) {
                throw new UnsupportedOperationException();
            }

            @Override
            public MockApiResult getLoans(String scenarioKey, String scenarioOverride) {
                throw new UnsupportedOperationException();
            }

            @Override
            public MockApiResult getPayMoney(String scenarioKey, String scenarioOverride) {
                throw new UnsupportedOperationException();
            }
        };
    }
}
