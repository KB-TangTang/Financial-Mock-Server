package com.financial.mockserver.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class CardBillResponse {
    private Long billId;
    private Long cardId;
    private String institutionCode;
    private String institutionName;
    private String cardNoMasked;
    private String productName;
    private String cardProductCode;
    private String billingMonth;
    private String dueDate;
    private String billStatusCode;
    private String billStatusName;
    private BigDecimal totalAmount;
    private BigDecimal paidAmount;
}
