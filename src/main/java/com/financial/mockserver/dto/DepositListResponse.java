package com.financial.mockserver.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DepositListResponse {
    private List<DepositResponse> deposits;
    private BigDecimal totalPrincipal;
    private BigDecimal totalBalance;
    private String lastSyncAt;
}
