package com.financial.mockserver.controller;

import com.financial.mockserver.dto.CodefBalanceRequest;
import com.financial.mockserver.service.MockCodefService;
import com.financial.mockserver.support.MockApiResult;
import com.financial.mockserver.support.MockResponseSupport;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * CODEF 잔액 응답을 모사하는 목 API.
 * 실제 CODEF 호출 대신 이 서버가 bank_account의 원천 잔액 필드를 조회해 응답한다.
 */
@RestController
public class MockCodefController {

    @Autowired
    private MockCodefService codefService;

    @PostMapping("/codef/v1/account/balance")
    public ResponseEntity<Object> getBalance(
            @RequestBody(required = false) CodefBalanceRequest request,
            @RequestParam(required = false) String scenarioKey,
            @RequestHeader(value = "X-Scenario-Key", required = false) String scenarioKeyHeader,
            @RequestParam(required = false) String scenario,
            @RequestHeader(value = "X-Mock-Scenario", required = false) String scenarioHeader) {
        String bodyScenarioKey = request != null ? request.getScenarioKey() : null;
        String account = request != null ? request.getAccount() : null;

        MockApiResult result = codefService.getBalance(
                MockResponseSupport.firstNonBlank(bodyScenarioKey, scenarioKey, scenarioKeyHeader),
                account,
                MockResponseSupport.firstNonBlank(scenario, scenarioHeader));
        return ResponseEntity.status(result.getHttpStatus())
                .contentType(MediaType.APPLICATION_JSON)
                .body(result.getBody());
    }
}
