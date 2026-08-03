package com.financial.mockserver.controller;

import com.financial.mockserver.service.MockAssetService;
import com.financial.mockserver.support.MockApiResult;
import com.financial.mockserver.support.MockResponseSupport;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 은행/증권/대출/페이머니 자산 조회 API.
 * scenarioKey는 쿼리 파라미터(scenarioKey) 또는 헤더(X-Scenario-Key)로 전달하며,
 * 둘 다 없으면 demo-normal-user를 기본값으로 사용한다.
 * 특수 시나리오를 강제하려면 쿼리 파라미터(scenario) 또는 헤더(X-Mock-Scenario)로
 * mock_scenario.scenario_code 값을 지정한다 (예: TOKEN_EXPIRED, RATE_LIMITED).
 */
@RestController
@RequestMapping("/api/v1/assets")
public class MockAssetController {

    @Autowired
    private MockAssetService assetService;

    @GetMapping("/accounts")
    public ResponseEntity<Object> getAccounts(
            @RequestParam(required = false) String scenarioKey,
            @RequestHeader(value = "X-Scenario-Key", required = false) String scenarioKeyHeader,
            @RequestParam(required = false) String scenario,
            @RequestHeader(value = "X-Mock-Scenario", required = false) String scenarioHeader) {
        MockApiResult result = assetService.getBankAccounts(
                MockResponseSupport.firstNonBlank(scenarioKey, scenarioKeyHeader),
                MockResponseSupport.firstNonBlank(scenario, scenarioHeader));
        return toResponseEntity(result);
    }

    @GetMapping("/stocks")
    public ResponseEntity<Object> getStocks(
            @RequestParam(required = false) String scenarioKey,
            @RequestHeader(value = "X-Scenario-Key", required = false) String scenarioKeyHeader,
            @RequestParam(required = false) String scenario,
            @RequestHeader(value = "X-Mock-Scenario", required = false) String scenarioHeader) {
        MockApiResult result = assetService.getStocks(
                MockResponseSupport.firstNonBlank(scenarioKey, scenarioKeyHeader),
                MockResponseSupport.firstNonBlank(scenario, scenarioHeader));
        return toResponseEntity(result);
    }

    @GetMapping("/loans")
    public ResponseEntity<Object> getLoans(
            @RequestParam(required = false) String scenarioKey,
            @RequestHeader(value = "X-Scenario-Key", required = false) String scenarioKeyHeader,
            @RequestParam(required = false) String scenario,
            @RequestHeader(value = "X-Mock-Scenario", required = false) String scenarioHeader) {
        MockApiResult result = assetService.getLoans(
                MockResponseSupport.firstNonBlank(scenarioKey, scenarioKeyHeader),
                MockResponseSupport.firstNonBlank(scenario, scenarioHeader));
        return toResponseEntity(result);
    }

    @GetMapping("/payMoney")
    public ResponseEntity<Object> getPayMoney(
            @RequestParam(required = false) String scenarioKey,
            @RequestHeader(value = "X-Scenario-Key", required = false) String scenarioKeyHeader,
            @RequestParam(required = false) String scenario,
            @RequestHeader(value = "X-Mock-Scenario", required = false) String scenarioHeader) {
        MockApiResult result = assetService.getPayMoney(
                MockResponseSupport.firstNonBlank(scenarioKey, scenarioKeyHeader),
                MockResponseSupport.firstNonBlank(scenario, scenarioHeader));
        return toResponseEntity(result);
    }

    private ResponseEntity<Object> toResponseEntity(MockApiResult result) {
        return ResponseEntity.status(result.getHttpStatus())
                .contentType(MediaType.APPLICATION_JSON)
                .body(result.getBody());
    }
}
