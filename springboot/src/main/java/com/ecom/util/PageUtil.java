package com.ecom.util;

import com.ecom.common.constant.AppConstants;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

public final class PageUtil {
    private PageUtil() {
    }

    public static Pageable of(int page, int size, Sort sort) {
        int safePage = Math.max(page, 0);
        int safeSize = size <= 0 ? AppConstants.DEFAULT_PAGE_SIZE : Math.min(size, AppConstants.MAX_PAGE_SIZE);
        return PageRequest.of(safePage, safeSize, sort);
    }

    public static Pageable of(int page, int size) {
        return of(page, size, Sort.unsorted());
    }

    public static Pageable newestFirst(int page, int size) {
        return of(page, size, Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id")));
    }
}
