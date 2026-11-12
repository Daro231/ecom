package com.ecom.util;

import java.text.Normalizer;
import java.util.Locale;
import java.util.function.Predicate;

public final class SlugUtil {
    private SlugUtil() {
    }

    public static String slugify(String input) {
        String normalized = Normalizer.normalize(input == null ? "" : input, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("(^-|-$)", "");
        return normalized.isEmpty() ? "item" : normalized;
    }

    /** Builds a slug that does not collide, appending -2, -3 ... when needed. */
    public static String uniqueSlug(String input, Predicate<String> exists) {
        String base = slugify(input);
        String candidate = base;
        int counter = 2;
        while (exists.test(candidate)) {
            candidate = base + "-" + counter++;
        }
        return candidate;
    }
}
