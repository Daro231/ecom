package com.ecom.service;

import com.ecom.common.response.PageResponse;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface UserService {
    UserResponse me(Long userId);

    UserResponse updateProfile(Long userId, UpdateProfileRequest request);

    void changePassword(Long userId, ChangePasswordRequest request);

    List<AddressResponse> addresses(Long userId);

    AddressResponse addAddress(Long userId, AddressRequest request);

    AddressResponse updateAddress(Long userId, Long addressId, AddressRequest request);

    void deleteAddress(Long userId, Long addressId);

    AddressResponse setDefaultAddress(Long userId, Long addressId);

    PageResponse<UserResponse> search(String keyword, int page, int size);

    UserResponse changeRole(Long actorId, Long userId, Role role);

    UserResponse setEnabled(Long actorId, Long userId, boolean enabled);
}
