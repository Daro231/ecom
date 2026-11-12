package com.ecom.controller;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MvcResult;

import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class ProductControllerTest extends AbstractIntegrationTest {

    @Test
    void publicCanBrowseSeededCatalogWithoutToken() throws Exception {
        mvc.perform(get("/api/v1/products?size=100", null))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements", greaterThanOrEqualTo(25)))
                .andExpect(jsonPath("$.data.content[0].category.name").exists())
                .andExpect(jsonPath("$.data.content[0].images").isArray());
        mvc.perform(get("/api/v1/categories", null)).andExpect(status().isOk()).andExpect(jsonPath("$.data.length()", greaterThanOrEqualTo(5)));
        mvc.perform(get("/api/v1/brands", null)).andExpect(status().isOk()).andExpect(jsonPath("$.data.length()", greaterThanOrEqualTo(7)));
    }

    @Test
    void combinedFiltersReturnOnlyMatchingProducts() throws Exception {
        long dellId = brandId("Dell");
        MvcResult result = mvc.perform(get("/api/v1/products?keyword=laptop&minPrice=500&maxPrice=1000&brandId=" + dellId + "&ram=16&size=100", null))
                .andExpect(status().isOk()).andReturn();

        JsonNode content = read(result).at("/data/content");
        assertThat(content.size()).isGreaterThan(0);
        boolean foundInspiron = false;
        for (JsonNode p : content) {
            assertThat(p.at("/price").decimalValue().doubleValue()).isBetween(500.0, 1000.0);
            assertThat(p.at("/brand/name").asText()).isEqualTo("Dell");
            assertThat(p.at("/ram").asInt()).isEqualTo(16);
            foundInspiron |= p.at("/name").asText().equals("Dell Inspiron 15 3530");
        }
        assertThat(foundInspiron).isTrue();
    }

    @Test
    void keywordSearchesNameDescriptionAndCpu() throws Exception {
        mvc.perform(get("/api/v1/products?keyword=thinkpad", null))
                .andExpect(jsonPath("$.data.content[0].name").value(containsString("ThinkPad")));
        mvc.perform(get("/api/v1/products?keyword=Ryzen 5 7530U", null))
                .andExpect(jsonPath("$.data.content[0].cpu").value("AMD Ryzen 5 7530U"));
        mvc.perform(get("/api/v1/products?keyword=zzzz-no-match", null))
                .andExpect(jsonPath("$.data.totalElements").value(0));
    }

    @Test
    void categoryFilterAndSortingByPrice() throws Exception {
        long monitors = categoryRepository.findAll().stream().filter(c -> c.getName().equals("Monitor")).findFirst().orElseThrow().getId();

        MvcResult asc = mvc.perform(get("/api/v1/products?categoryId=" + monitors + "&sort=price_asc", null)).andReturn();
        JsonNode items = read(asc).at("/data/content");
        assertThat(items.size()).isGreaterThanOrEqualTo(4);
        double previous = 0;
        for (JsonNode p : items) {
            assertThat(p.at("/category/name").asText()).isEqualTo("Monitor");
            double price = p.at("/price").asDouble();
            assertThat(price).isGreaterThanOrEqualTo(previous);
            previous = price;
        }

        MvcResult desc = mvc.perform(get("/api/v1/products?categoryId=" + monitors + "&sort=price_desc", null)).andReturn();
        assertThat(read(desc).at("/data/content/0/price").asDouble()).isEqualTo(previous);
    }

    @Test
    void pagingReturnsRequestedPageSize() throws Exception {
        mvc.perform(get("/api/v1/products?size=5&page=0", null))
                .andExpect(jsonPath("$.data.content.length()").value(5))
                .andExpect(jsonPath("$.data.page").value(0))
                .andExpect(jsonPath("$.data.size").value(5))
                .andExpect(jsonPath("$.data.last").value(false))
                .andExpect(jsonPath("$.data.totalPages", greaterThan(1)));
        mvc.perform(get("/api/v1/products?size=5&page=1000", null))
                .andExpect(jsonPath("$.data.content.length()").value(0))
                .andExpect(jsonPath("$.data.last").value(true));
    }

    @Test
    void inStockAndMinRatingFilters() throws Exception {
        var soldOut = newProduct("Sold Out Gadget", "10.00", 0);
        MvcResult res = mvc.perform(get("/api/v1/products?keyword=sold out gadget&inStock=true", null)).andReturn();
        assertThat(read(res).at("/data/totalElements").asInt()).isZero();
        MvcResult all = mvc.perform(get("/api/v1/products?keyword=sold out gadget", null)).andReturn();
        assertThat(read(all).at("/data/content/0/id").asLong()).isEqualTo(soldOut.getId());

        JsonNode rated = read(mvc.perform(get("/api/v1/products?minRating=4.5&size=100", null)).andReturn()).at("/data/content");
        for (JsonNode p : rated) {
            assertThat(p.at("/averageRating").asDouble()).isGreaterThanOrEqualTo(4.5);
        }
    }

    @Test
    void popularSortUsesSoldCount() throws Exception {
        mvc.perform(get("/api/v1/products?sort=popular&size=3", null))
                .andExpect(jsonPath("$.data.content[0].soldCount", greaterThanOrEqualTo(80)));
    }

    @Test
    void detailBySlugAndId() throws Exception {
        MvcResult res = mvc.perform(get("/api/v1/products/slug/macbook-air-13-m3", null))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.brand.name").value("Apple"))
                .andExpect(jsonPath("$.data.ram").value(8))
                .andExpect(jsonPath("$.data.images.length()").value(2)).andReturn();
        long id = read(res).at("/data/id").asLong();

        mvc.perform(get("/api/v1/products/" + id, null)).andExpect(status().isOk()).andExpect(jsonPath("$.data.slug").value("macbook-air-13-m3"));
    }

    @Test
    void unknownProductIsNotFound() throws Exception {
        mvc.perform(get("/api/v1/products/9999999", null)).andExpect(status().isNotFound()).andExpect(jsonPath("$.success").value(false));
        mvc.perform(get("/api/v1/products/slug/nope-nope", null)).andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/products/9999999/reviews", null)).andExpect(status().isNotFound());
    }

    @Test
    void invalidParameterTypeIsBadRequest() throws Exception {
        mvc.perform(get("/api/v1/products/abc", null)).andExpect(status().isBadRequest());
        mvc.perform(get("/api/v1/products?minPrice=cheap", null)).andExpect(status().isBadRequest());
    }

    private long brandId(String name) {
        return brandRepository.findAll().stream().filter(b -> b.getName().equals(name)).findFirst().orElseThrow().getId();
    }
}
