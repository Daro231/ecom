package com.ecom.model.response;

import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public record CartPreviewResponse(String couponCode, BigDecimal subtotal, BigDecimal discount, BigDecimal shippingFee,
                                  BigDecimal total) {
}
