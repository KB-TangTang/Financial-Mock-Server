package com.financial.mockserver.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class LoanTransactionResponse {
    private Long transactionId;
    private Long loanId;
    private String institutionCode;
    private String institutionName;
    private String loanNoMasked;
    private String productName;
    private String accountTypeCode;
    private String transactedAt;
    private String transTypeCode;
    private String transTypeName;
    private BigDecimal amount;
    private BigDecimal principalAmount;
    private BigDecimal interestAmount;
    private BigDecimal balanceAfter;
    private String description;
    private String currency;
    private String rawJson;
}
