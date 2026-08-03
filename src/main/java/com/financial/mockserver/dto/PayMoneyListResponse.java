package com.financial.mockserver.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * GET /api/v1/assets/payMoney 응답 data.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PayMoneyListResponse {
    private List<PayMoneyResponse> payMoney;
    private BigDecimal totalBalance;
    private BigDecimal totalPointAmount;
}
