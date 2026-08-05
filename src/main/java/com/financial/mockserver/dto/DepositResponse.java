package com.financial.mockserver.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class DepositResponse {
    private Long depositAccountId;
    private String institutionCode;
    private String institutionName;
    private String depositTypeCode;
    private String accountStatusCode;
    private String productName;
    private String accountNoMasked;
    private String currency;
    private BigDecimal principal;
    private BigDecimal balance;
    private BigDecimal interestRate;
    private String openedAt;
    private String maturityDate;
    private String lastSyncAt;
}
