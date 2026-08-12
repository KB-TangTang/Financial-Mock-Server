package com.financial.mockserver.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class BankTransactionResponse {
    private Long transactionId;
    private Long accountId;
    private String institutionCode;
    private String institutionName;
    private String accountNoMasked;
    private String productName;
    private String transactedAt;
    private String transTypeCode;
    private String transTypeName;
    private BigDecimal amount;
    private BigDecimal balanceAfter;
    private String description;
    private String currency;
    private String rawJson;
}
