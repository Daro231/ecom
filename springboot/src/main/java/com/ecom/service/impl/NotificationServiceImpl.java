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
@Slf4j
public class NotificationServiceImpl implements NotificationService {
    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final List<NotificationSender> senders;

    @Override
    @Transactional
    public void notifyUser(User user, NotificationType type, String title, String message) {
        notifyUser(user, type, NotificationPriority.NORMAL, title, message);
    }

    private void notifyUser(User user, NotificationType type, NotificationPriority priority, String title, String message) {
        Notification notification = notificationRepository.save(Notification.builder().user(user).type(type)
                .priority(priority).title(title).message(message).build());
        for (NotificationSender sender : senders) {
            if (sender.supports(type)) {
                try {
                    sender.send(notification);
                } catch (RuntimeException ex) {
                    log.warn("Sender {} failed for notification {}: {}", sender.getClass().getSimpleName(), notification.getId(), ex.getMessage());
                }
            }
        }
    }

    @Override
    @Transactional
    public void notifyAdmins(NotificationType type, String title, String message) {
        notifyAdmins(type, NotificationPriority.NORMAL, title, message);
    }

    @Override
    @Transactional
    public void notifyAdmins(NotificationType type, NotificationPriority priority, String title, String message) {
        userRepository.findByRoleAndEnabledTrue(Role.ADMIN).forEach(admin -> notifyUser(admin, type, priority, title, message));
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<NotificationResponse> list(Long userId, int page, int size) {
        return PageResponse.of(notificationRepository.findByUserId(userId, PageUtil.newestFirst(page, size)), NotificationResponse::from);
    }

    @Override
    @Transactional
    public NotificationResponse markRead(Long userId, Long notificationId) {
        Notification n = notificationRepository.findByIdAndUserId(notificationId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found"));
        n.setRead(true);
        return NotificationResponse.from(n);
    }

    @Override
    @Transactional
    public int markAllRead(Long userId) {
        return notificationRepository.markAllRead(userId);
    }

    @Override
    @Transactional(readOnly = true)
    public long unreadCount(Long userId) {
        return notificationRepository.countUnread(userId);
    }
}
