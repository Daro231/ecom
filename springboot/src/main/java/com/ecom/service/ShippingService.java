package com.ecom.service;

import com.ecom.common.response.PageResponse;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface ShippingService {
    List<ShippingMethodResponse> methods();

    ShipmentResponse tracking(Long userId, String orderNumber);

    ShipmentResponse updateShipmentStatus(Long shipmentId, ShipmentStatus status);
}
