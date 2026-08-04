package com.financial.mockserver.mapper;

import com.financial.mockserver.domain.MockApiEndpoint;
import org.apache.ibatis.annotations.Param;

public interface MockApiEndpointMapper {
    MockApiEndpoint findByMethodAndPath(@Param("method") String method, @Param("path") String path);
}
