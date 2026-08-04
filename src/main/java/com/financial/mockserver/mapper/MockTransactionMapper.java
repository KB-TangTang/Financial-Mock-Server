package com.financial.mockserver.mapper;

import com.financial.mockserver.dto.TransactionResponse;
import org.apache.ibatis.annotations.Param;

import java.util.List;

public interface MockTransactionMapper {
    List<TransactionResponse> findTransactions(@Param("userId") Long userId, @Param("yearMonth") String yearMonth);
}
