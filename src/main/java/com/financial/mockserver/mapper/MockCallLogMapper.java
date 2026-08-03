package com.financial.mockserver.mapper;

import com.financial.mockserver.domain.MockApiCallLog;

public interface MockCallLogMapper {
    void insert(MockApiCallLog callLog);
}
