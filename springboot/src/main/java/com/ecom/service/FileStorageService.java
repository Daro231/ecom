package com.ecom.service;

import com.ecom.model.response.UploadResponse;
import org.springframework.web.multipart.MultipartFile;

public interface FileStorageService {
    UploadResponse store(MultipartFile file);
}
