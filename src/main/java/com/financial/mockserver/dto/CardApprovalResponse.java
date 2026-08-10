package com.financial.mockserver.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class CardApprovalResponse {
    private Long approvalId;
    private Long cardId;
    private String institutionCode;
    private String institutionName;
    private String cardNoMasked;
    private String productName;
    private String cardProductCode;
    private String approvalNo;
    private String approvedAt;
    private String approvalTypeCode;
    private String approvalTypeName;
    private String merchantName;
    private String merchantBusinessNo;
    private String merchantCategoryCode;
    private BigDecimal approvedAmount;
    private String currency;
    private String description;
}
