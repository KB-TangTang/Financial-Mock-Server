package com.financial.mockserver.controller;

import com.financial.mockserver.service.MockRawFinancialService;
import com.financial.mockserver.support.MockApiResult;
import com.financial.mockserver.support.MockResponseSupport;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MockRawFinancialController {

    @Autowired
    private MockRawFinancialService rawFinancialService;

    @GetMapping("/api/v1/accounts/{accountId}/transactions")
    public ResponseEntity<Object> getBankTransactions(
            @PathVariable Long accountId,
            @RequestParam(required = false) String scenarioKey,
            @RequestHeader(value = "X-Scenario-Key", required = false) String scenarioKeyHeader,
            @RequestParam(required = false) String scenario,
            @RequestHeader(value = "X-Mock-Scenario", required = false) String scenarioHeader,
            @RequestParam(required = false) String yearMonth) {
        MockApiResult result = rawFinancialService.getBankTransactions(
                MockResponseSupport.firstNonBlank(scenarioKey, scenarioKeyHeader),
                MockResponseSupport.firstNonBlank(scenario, scenarioHeader),
                accountId,
                yearMonth);
        return toResponseEntity(result);
    }

    @GetMapping("/api/v1/deposits/{depositAccountId}/transactions")
    public ResponseEntity<Object> getDepositTransactions(
            @PathVariable Long depositAccountId,
            @RequestParam(required = false) String scenarioKey,
            @RequestHeader(value = "X-Scenario-Key", required = false) String scenarioKeyHeader,
            @RequestParam(required = false) String scenario,
            @RequestHeader(value = "X-Mock-Scenario", required = false) String scenarioHeader,
            @RequestParam(required = false) String yearMonth) {
        MockApiResult result = rawFinancialService.getDepositTransactions(
                MockResponseSupport.firstNonBlank(scenarioKey, scenarioKeyHeader),
                MockResponseSupport.firstNonBlank(scenario, scenarioHeader),
                depositAccountId,
                yearMonth);
        return toResponseEntity(result);
    }

    @GetMapping("/api/v1/loans/{loanId}/transactions")
    public ResponseEntity<Object> getLoanTransactions(
            @PathVariable Long loanId,
            @RequestParam(required = false) String scenarioKey,
            @RequestHeader(value = "X-Scenario-Key", required = false) String scenarioKeyHeader,
            @RequestParam(required = false) String scenario,
            @RequestHeader(value = "X-Mock-Scenario", required = false) String scenarioHeader,
            @RequestParam(required = false) String yearMonth) {
        MockApiResult result = rawFinancialService.getLoanTransactions(
                MockResponseSupport.firstNonBlank(scenarioKey, scenarioKeyHeader),
                MockResponseSupport.firstNonBlank(scenario, scenarioHeader),
                loanId,
                yearMonth);
        return toResponseEntity(result);
    }

    @GetMapping("/api/v1/securities/{accountId}/transactions")
    public ResponseEntity<Object> getSecuritiesTransactions(
            @PathVariable Long accountId,
            @RequestParam(required = false) String scenarioKey,
            @RequestHeader(value = "X-Scenario-Key", required = false) String scenarioKeyHeader,
            @RequestParam(required = false) String scenario,
            @RequestHeader(value = "X-Mock-Scenario", required = false) String scenarioHeader,
            @RequestParam(required = false) String yearMonth) {
        MockApiResult result = rawFinancialService.getSecuritiesTransactions(
                MockResponseSupport.firstNonBlank(scenarioKey, scenarioKeyHeader),
                MockResponseSupport.firstNonBlank(scenario, scenarioHeader),
                accountId,
                yearMonth);
        return toResponseEntity(result);
    }

    @GetMapping("/api/v1/pay-money/{payMoneyId}/transactions")
    public ResponseEntity<Object> getPayMoneyTransactions(
            @PathVariable Long payMoneyId,
            @RequestParam(required = false) String scenarioKey,
            @RequestHeader(value = "X-Scenario-Key", required = false) String scenarioKeyHeader,
            @RequestParam(required = false) String scenario,
            @RequestHeader(value = "X-Mock-Scenario", required = false) String scenarioHeader,
            @RequestParam(required = false) String yearMonth) {
        MockApiResult result = rawFinancialService.getPayMoneyTransactions(
                MockResponseSupport.firstNonBlank(scenarioKey, scenarioKeyHeader),
                MockResponseSupport.firstNonBlank(scenario, scenarioHeader),
                payMoneyId,
                yearMonth);
        return toResponseEntity(result);
    }

    @GetMapping("/api/v1/cards")
    public ResponseEntity<Object> getCards(
            @RequestParam(required = false) String scenarioKey,
            @RequestHeader(value = "X-Scenario-Key", required = false) String scenarioKeyHeader,
            @RequestParam(required = false) String scenario,
            @RequestHeader(value = "X-Mock-Scenario", required = false) String scenarioHeader) {
        MockApiResult result = rawFinancialService.getCards(
                MockResponseSupport.firstNonBlank(scenarioKey, scenarioKeyHeader),
                MockResponseSupport.firstNonBlank(scenario, scenarioHeader));
        return toResponseEntity(result);
    }

    @GetMapping("/api/v1/cards/{cardId}/approvals")
    public ResponseEntity<Object> getCardApprovals(
            @PathVariable Long cardId,
            @RequestParam(required = false) String scenarioKey,
            @RequestHeader(value = "X-Scenario-Key", required = false) String scenarioKeyHeader,
            @RequestParam(required = false) String scenario,
            @RequestHeader(value = "X-Mock-Scenario", required = false) String scenarioHeader,
            @RequestParam(required = false) String yearMonth) {
        MockApiResult result = rawFinancialService.getCardApprovals(
                MockResponseSupport.firstNonBlank(scenarioKey, scenarioKeyHeader),
                MockResponseSupport.firstNonBlank(scenario, scenarioHeader),
                cardId,
                yearMonth);
        return toResponseEntity(result);
    }

    @GetMapping("/api/v1/cards/{cardId}/bills")
    public ResponseEntity<Object> getCardBills(
            @PathVariable Long cardId,
            @RequestParam(required = false) String scenarioKey,
            @RequestHeader(value = "X-Scenario-Key", required = false) String scenarioKeyHeader,
            @RequestParam(required = false) String scenario,
            @RequestHeader(value = "X-Mock-Scenario", required = false) String scenarioHeader,
            @RequestParam(required = false) String billingMonth) {
        MockApiResult result = rawFinancialService.getCardBills(
                MockResponseSupport.firstNonBlank(scenarioKey, scenarioKeyHeader),
                MockResponseSupport.firstNonBlank(scenario, scenarioHeader),
                cardId,
                billingMonth);
        return toResponseEntity(result);
    }

    private ResponseEntity<Object> toResponseEntity(MockApiResult result) {
        return ResponseEntity.status(result.getHttpStatus())
                .contentType(MediaType.APPLICATION_JSON)
                .body(result.getBody());
    }
}
