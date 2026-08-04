package com.financial.mockserver.dto;

import lombok.Data;

@Data
public class CardResponse {
    private Long cardId;
    private String institutionCode;
    private String institutionName;
    private String cardNoMasked;
    private String productName;
    private String cardProductCode;
    private String cardTypeCode;
    private String cardStatusCode;
    private String currency;
    private String issuedAt;
    private String lastSyncAt;
}
