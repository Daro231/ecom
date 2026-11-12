import { expect, test } from "@playwright/test";
import { apiGet, apiToken, API, loginUI, shot } from "./helpers";

// Real Nominatim answer for a pin in Khan Sen Sok (khan is in `town`, province in `state`)
const NOMINATIM = { place_id: 1, display_name: "Street 1003, Sen Sok, Phnom Penh, Cambodia", address: { road: "Street 1003", suburb: "Phumi Tuek Thla", town: "Khan Sen Sok", state: "Phnom Penh", country: "Cambodia" } };

interface Addr { id: number; line1: string; latitude?: number; longitude?: number }
const route = (page: import("@playwright/test").Page) =>
  page.route("https://nominatim.openstreetmap.org/**", (r) => r.fulfill({ json: NOMINATIM, headers: { "access-control-allow-origin": "*" } }));

test.describe("address map", () => {
  test.use({ geolocation: { latitude: 11.5564, longitude: 104.9282, accuracy: 25 }, permissions: ["geolocation"] });

  test("use my location -> save -> card shows map; text edit keeps coordinates", async ({ page, context, request }) => {
    await route(page);
    await loginUI(page, "customer", "/profile/addresses");
    await page.getByRole("button", { name: "Add address" }).click();
    const dlg = page.getByRole("dialog");
    await dlg.getByLabel("Receiver name").fill("Map Tester");
    await dlg.getByLabel("Phone").fill("012999888");

    await dlg.getByRole("button", { name: "Use my current location" }).click();
    await expect(dlg.getByText("11.556400, 104.928200")).toBeVisible();
    await expect(dlg.getByTestId("accuracy-warning")).toHaveCount(0); // 25 m is precise enough
    // reverse geocoding fills the empty fields (debounce 1 s)
    await expect(dlg.getByRole("textbox", { name: "Address", exact: true })).toHaveValue("Street 1003, Phumi Tuek Thla, Khan Sen Sok", { timeout: 8000 });
    await expect(dlg.getByRole("textbox", { name: "City", exact: true })).toHaveValue("Phnom Penh");
    await shot(page, "15-address-map");
    await dlg.getByRole("button", { name: "Save address" }).click();

    const card = page.getByTestId("address-card").filter({ hasText: "Map Tester" });
    await expect(card.getByTestId("static-map")).toBeVisible();
    let saved = (await apiGet<Addr[]>(request, "/users/me/addresses", "customer")).find((a) => a.line1.includes("Street 1003"))!;
    expect(saved.latitude).toBeCloseTo(11.5564, 5);
    expect(saved.longitude).toBeCloseTo(104.9282, 5);

    // edit ONLY the text: coordinates must survive (PUT replaces all fields)
    await card.getByRole("button", { name: "Edit" }).click();
    await dlg.getByRole("textbox", { name: "Address", exact: true }).fill("No. 7, Street 1003, Sen Sok");
    await dlg.getByRole("button", { name: "Save address" }).click();
    await expect(page.getByTestId("address-card").filter({ hasText: "No. 7, Street 1003" }).getByTestId("static-map")).toBeVisible();
    saved = (await apiGet<Addr[]>(request, "/users/me/addresses", "customer")).find((a) => a.id === saved.id)!;
    expect(saved.line1).toBe("No. 7, Street 1003, Sen Sok");
    expect(saved.latitude).toBeCloseTo(11.5564, 5);
    expect(saved.longitude).toBeCloseTo(104.9282, 5);

    // approximate location (desktop PC without GPS): warning + dragging/clicking is the fix
    await context.setGeolocation({ latitude: 11.57, longitude: 104.9, accuracy: 2500 });
    await page.getByTestId("address-card").filter({ hasText: "No. 7, Street 1003" }).getByRole("button", { name: "Edit" }).click();
    await dlg.getByRole("button", { name: "Use my current location" }).click();
    await expect(dlg.getByTestId("accuracy-warning")).toContainText("approximate (±2,500 m / ±2.5 km)");
    await dlg.getByRole("button", { name: "Remove pin" }).click();
    await expect(dlg.getByText("Click the map to place a pin (optional)")).toBeVisible();
    await page.keyboard.press("Escape");

    // cleanup
    const t = await apiToken(request, "customer");
    await request.delete(`${API}/users/me/addresses/${saved.id}`, { headers: { Authorization: `Bearer ${t}` } });
  });
});

test("denied location shows a clear message and never places a pin", async ({ browser }) => {
  const ctx = await browser.newContext({ permissions: [] });
  const page = await ctx.newPage();
  await loginUI(page, "customer", "/profile/addresses");
  await page.getByRole("button", { name: "Add address" }).click();
  const dlg = page.getByRole("dialog");
  await dlg.getByRole("button", { name: "Use my current location" }).click();
  await expect(dlg.getByTestId("geo-error")).toBeVisible();
  await expect(dlg.getByText("Click the map to place a pin (optional)")).toBeVisible();
  await ctx.close();
});
