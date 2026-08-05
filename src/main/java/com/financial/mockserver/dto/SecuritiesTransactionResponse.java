package com.financial.mockserver.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class SecuritiesTransactionResponse {
    private Long transactionId;
    private Long securitiesAccountId;
    private String institutionCode;
    private String institutionName;
    private String accountNoMasked;
    private String productName;
    private String accountTypeCode;
    private String transactedAt;
    private String transTypeCode;
    private String transTypeName;
    private String securityProductCode;
    private String securityProductName;
    private BigDecimal quantity;
    private BigDecimal unitPrice;
    private BigDecimal transactionAmount;
    private String description;
    private String currency;
}
