package com.ecom.model.response;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public record AddressResponse(Long id, String receiverName, String phone, String line1, String city, boolean isDefault,
                              BigDecimal latitude, BigDecimal longitude) {
    public static AddressResponse from(Address a) {
        return new AddressResponse(a.getId(), a.getReceiverName(), a.getPhone(), a.getLine1(), a.getCity(), a.isDefault(),
                a.getLatitude(), a.getLongitude());
    }
}
