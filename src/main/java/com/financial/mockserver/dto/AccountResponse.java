package com.financial.mockserver.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * GET /api/v1/assets/accounts 응답 항목 (은행 계좌 1건).
 */
@Data
public class AccountResponse {
    private Long accountId;
    private String institutionCode;
    private String institutionName;
    private String accountTypeCode;
    private String accountStatusCode;
    private String productName;
    private String accountNoMasked;
    private String currency;
    private BigDecimal balance;
    private BigDecimal availableAmount;
    private String lastSyncAt;
}
