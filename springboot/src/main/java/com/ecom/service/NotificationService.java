package com.ecom.service;

import com.ecom.common.response.PageResponse;
import com.ecom.model.entity.*;
import com.ecom.model.enumerate.*;
import com.ecom.model.request.*;
import com.ecom.model.response.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface NotificationService {
    void notifyUser(User user, NotificationType type, String title, String message);

    void notifyAdmins(NotificationType type, String title, String message);

    void notifyAdmins(NotificationType type, NotificationPriority priority, String title, String message);

    PageResponse<NotificationResponse> list(Long userId, int page, int size);

    NotificationResponse markRead(Long userId, Long notificationId);

    int markAllRead(Long userId);

    long unreadCount(Long userId);
}
