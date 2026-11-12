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
public class FileStorageServiceImpl implements FileStorageService {
    private static final Map<String, String> TYPES = Map.of("image/jpeg", ".jpg", "image/png", ".png", "image/webp", ".webp", "image/gif", ".gif");

    private final java.nio.file.Path root;

    public FileStorageServiceImpl(@org.springframework.beans.factory.annotation.Value("${app.upload-dir}") String uploadDir) {
        this.root = java.nio.file.Path.of(uploadDir).toAbsolutePath().normalize();
    }

    @Override
    public UploadResponse store(org.springframework.web.multipart.MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("File is required");
        }
        String extension = TYPES.get(file.getContentType());
        if (extension == null) {
            throw new BadRequestException("Only JPEG, PNG, WEBP and GIF images are allowed");
        }
        String filename = UUID.randomUUID() + extension;
        try {
            java.nio.file.Files.createDirectories(root);
            file.transferTo(root.resolve(filename));
        } catch (java.io.IOException ex) {
            throw new IllegalStateException("Could not store file", ex);
        }
        return new UploadResponse(filename, "/uploads/" + filename, file.getSize());
    }
}
