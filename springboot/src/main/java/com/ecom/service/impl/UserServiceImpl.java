package com.ecom.service.impl;

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
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {
    private final UserRepository userRepository;
    private final AddressRepository addressRepository;
    private final PasswordEncoder passwordEncoder;
    private final NotificationService notificationService;

    private User load(Long id) {
        return userRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    @Override
    @Transactional(readOnly = true)
    public UserResponse me(Long userId) {
        return UserResponse.from(load(userId));
    }

    @Override
    @Transactional
    public UserResponse updateProfile(Long userId, UpdateProfileRequest request) {
        User user = load(userId);
        user.setFullName(request.fullName().trim());
        user.setPhone(request.phone());
        return UserResponse.from(user);
    }

    @Override
    @Transactional
    public void changePassword(Long userId, ChangePasswordRequest request) {
        User user = load(userId);
        if (!passwordEncoder.matches(request.currentPassword(), user.getPassword())) {
            throw new BadRequestException("Current password is incorrect");
        }
        user.setPassword(passwordEncoder.encode(request.newPassword()));
        notificationService.notifyUser(user, NotificationType.ACCOUNT, "Password changed",
                "Your password was changed. If this was not you, contact support immediately.");
    }

    @Override
    @Transactional(readOnly = true)
    public List<AddressResponse> addresses(Long userId) {
        return addressRepository.findByUserIdOrderByIdAsc(userId).stream().map(AddressResponse::from).toList();
    }

    @Override
    @Transactional
    public AddressResponse addAddress(Long userId, AddressRequest request) {
        User user = load(userId);
        List<Address> existing = addressRepository.findByUserIdOrderByIdAsc(userId);
        boolean makeDefault = Boolean.TRUE.equals(request.isDefault()) || existing.isEmpty();
        if (makeDefault) {
            existing.forEach(a -> a.setDefault(false));
        }
        Address address = Address.builder().user(user).receiverName(request.receiverName()).phone(request.phone())
                .line1(request.line1()).city(request.city()).isDefault(makeDefault)
                .latitude(coord(request.latitude())).longitude(coord(request.longitude())).build();
        return AddressResponse.from(addressRepository.save(address));
    }

    @Override
    @Transactional
    public AddressResponse updateAddress(Long userId, Long addressId, AddressRequest request) {
        Address address = findAddress(userId, addressId);
        address.setReceiverName(request.receiverName());
        address.setPhone(request.phone());
        address.setLine1(request.line1());
        address.setCity(request.city());
        address.setLatitude(coord(request.latitude()));
        address.setLongitude(coord(request.longitude()));
        if (Boolean.TRUE.equals(request.isDefault())) {
            makeDefault(userId, address);
        }
        return AddressResponse.from(address);
    }

    @Override
    @Transactional
    public void deleteAddress(Long userId, Long addressId) {
        Address address = findAddress(userId, addressId);
        boolean wasDefault = address.isDefault();
        addressRepository.delete(address);
        addressRepository.flush();
        if (wasDefault) {
            addressRepository.findByUserIdOrderByIdAsc(userId).stream().findFirst().ifPresent(a -> a.setDefault(true));
        }
    }

    @Override
    @Transactional
    public AddressResponse setDefaultAddress(Long userId, Long addressId) {
        Address address = findAddress(userId, addressId);
        makeDefault(userId, address);
        return AddressResponse.from(address);
    }

    private void makeDefault(Long userId, Address address) {
        addressRepository.findByUserIdOrderByIdAsc(userId).forEach(a -> a.setDefault(a.getId().equals(address.getId())));
    }

    private static java.math.BigDecimal coord(java.math.BigDecimal v) {
        return v == null ? null : v.setScale(6, java.math.RoundingMode.HALF_UP);
    }

    private Address findAddress(Long userId, Long addressId) {
        return addressRepository.findByIdAndUserId(addressId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Address not found"));
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<UserResponse> search(String keyword, int page, int size) {
        String kw = "%" + (keyword == null ? "" : keyword.trim().toLowerCase()) + "%";
        return PageResponse.of(userRepository.search(kw, PageUtil.of(page, size, Sort.by(Sort.Direction.DESC, "id"))), UserResponse::from);
    }

    @Override
    @Transactional
    public UserResponse changeRole(Long actorId, Long userId, Role role) {
        if (actorId.equals(userId)) {
            throw new BadRequestException("You cannot change your own role");
        }
        User user = load(userId);
        user.setRole(role);
        return UserResponse.from(user);
    }

    @Override
    @Transactional
    public UserResponse setEnabled(Long actorId, Long userId, boolean enabled) {
        if (actorId.equals(userId)) {
            throw new BadRequestException("You cannot disable your own account");
        }
        User user = load(userId);
        user.setEnabled(enabled);
        return UserResponse.from(user);
    }
}
