package com.financial.mockserver.controller;

import com.financial.mockserver.service.MockTransactionService;
import com.financial.mockserver.support.MockApiResult;
import com.financial.mockserver.support.MockResponseSupport;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 은행·증권·대출·페이머니 통합 거래내역 조회 API.
 * fixture를 사용하지 않고 업권별 원천 거래 테이블을 조회해 조립한다.
 * 시연 중 새 거래를 INSERT하면 다음 조회부터 그대로 반영된다.
 */
@RestController
public class MockTransactionController {

    @Autowired
    private MockTransactionService transactionService;

    @GetMapping("/api/v1/transactions")
    public ResponseEntity<Object> getTransactions(
            @RequestParam(required = false) String scenarioKey,
            @RequestHeader(value = "X-Scenario-Key", required = false) String scenarioKeyHeader,
            @RequestParam(required = false) String scenario,
            @RequestHeader(value = "X-Mock-Scenario", required = false) String scenarioHeader,
            @RequestParam(required = false) String yearMonth) {
        MockApiResult result = transactionService.getTransactions(
                MockResponseSupport.firstNonBlank(scenarioKey, scenarioKeyHeader),
                MockResponseSupport.firstNonBlank(scenario, scenarioHeader),
                yearMonth);
        return ResponseEntity.status(result.getHttpStatus())
                .contentType(MediaType.APPLICATION_JSON)
                .body(result.getBody());
    }
}
