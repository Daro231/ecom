package com.ecom.service.impl;

import com.ecom.common.constant.AppConstants;
import com.ecom.common.exception.*;
import com.ecom.common.response.PageResponse;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;
import com.ecom.repository.*;
import com.ecom.service.*;
import com.ecom.util.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ShippingServiceImpl implements ShippingService {
    private final OrderRepository orderRepository;
    private final ShipmentRepository shipmentRepository;
    private final OrderService orderService;

    @Override
    public List<ShippingMethodResponse> methods() {
        return Arrays.stream(ShippingMethod.values()).map(m -> new ShippingMethodResponse(m, m.getLabel(), m.getFee(),
                m.getEstimatedDelivery(), AppConstants.FREE_SHIPPING_THRESHOLD)).toList();
    }

    @Override
    @Transactional(readOnly = true)
    public ShipmentResponse tracking(Long userId, String orderNumber) {
        Order order = orderRepository.findByOrderNumberAndUserId(orderNumber, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found"));
        return ShipmentResponse.from(shipmentRepository.findByOrderId(order.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Shipment not found")));
    }

    @Override
    @Transactional
    public ShipmentResponse updateShipmentStatus(Long shipmentId, ShipmentStatus status) {
        Shipment shipment = shipmentRepository.findById(shipmentId).orElseThrow(() -> new ResourceNotFoundException("Shipment not found"));
        switch (status) {
            case OUT_FOR_DELIVERY -> {
                if (shipment.getStatus() != ShipmentStatus.IN_TRANSIT) {
                    throw new BadRequestException("Shipment must be IN_TRANSIT first");
                }
                shipment.setStatus(ShipmentStatus.OUT_FOR_DELIVERY);
            }
            case DELIVERED -> {
                if (shipment.getStatus() != ShipmentStatus.IN_TRANSIT && shipment.getStatus() != ShipmentStatus.OUT_FOR_DELIVERY) {
                    throw new BadRequestException("Shipment has not been shipped yet");
                }
                orderService.changeStatus(shipment.getOrder(), OrderStatus.DELIVERED, null);
            }
            default -> throw new BadRequestException("Status " + status + " cannot be set here; use the ship endpoint");
        }
        return ShipmentResponse.from(shipment);
    }
}
