const dealers = [
    {
        name: "Bengaluru Central Dealer",
        state: "Karnataka",
        postalCode: "560001",
        latitude: 12.9716,
        longitude: 77.5946
    },
    {
        name: "Chennai City Dealer",
        state: "Tamil Nadu",
        postalCode: "600001",
        latitude: 13.0827,
        longitude: 80.2707
    },
    {
        name: "Mumbai EV Hub",
        state: "Maharashtra",
        postalCode: "400001",
        latitude: 19.0760,
        longitude: 72.8777
    }
];

const vehicles = {
    "Falcon EV": { stock: 5, price: "Rs. 32,00,000" },
    "Atlas SUV": { stock: 0, price: "Rs. 41,00,000" },
    "Aurora Hybrid": { stock: 7, price: "Rs. 36,00,000" }
};

const atlasBulkQuantity = 3;
const checklistKey = "whatnext-checklist-progress";

const metricCounters = document.querySelectorAll("[data-count]");
const tabButtons = document.querySelectorAll(".tab-button");
const tabPanels = document.querySelectorAll(".tab-panel");
const orderForm = document.getElementById("order-form");
const resultBadge = document.getElementById("result-badge");
const resultTitle = document.getElementById("result-title");
const resultSummary = document.getElementById("result-summary");
const assignedDealer = document.getElementById("assigned-dealer");
const assignmentRule = document.getElementById("assignment-rule");
const stockAfter = document.getElementById("stock-after");
const decisionTrail = document.getElementById("decision-trail");
const emailPreview = document.getElementById("email-preview");
const atlasStock = document.getElementById("atlas-stock");
const atlasStockLabel = document.getElementById("atlas-stock-label");
const stockBar = document.getElementById("stock-bar");
const orderBar = document.getElementById("order-bar");
const recoveryTitle = document.getElementById("recovery-title");
const recoverySummary = document.getElementById("recovery-summary");
const recoveryLog = document.getElementById("recovery-log");
const checklistInputs = document.querySelectorAll("[data-checklist]");
const checklistProgress = document.getElementById("checklist-progress");
const checklistFill = document.getElementById("checklist-fill");
const copyButtons = document.querySelectorAll("[data-copy-target]");

function animateCounters() {
    metricCounters.forEach((counter) => {
        const target = Number(counter.dataset.count || "0");
        let current = 0;
        const step = Math.max(1, Math.ceil(target / 24));
        const interval = window.setInterval(() => {
            current = Math.min(target, current + step);
            counter.textContent = String(current);
            if (current >= target) {
                window.clearInterval(interval);
            }
        }, 36);
    });
}

function setupTabs() {
    tabButtons.forEach((button) => {
        button.addEventListener("click", () => {
            const target = button.dataset.panelTarget;
            tabButtons.forEach((item) => {
                const isActive = item === button;
                item.classList.toggle("is-active", isActive);
                item.setAttribute("aria-selected", isActive ? "true" : "false");
            });
            tabPanels.forEach((panel) => {
                panel.classList.toggle("is-active", panel.dataset.panel === target);
            });
        });
    });
}

function toRadians(value) {
    return value * (Math.PI / 180);
}

function calculateDistanceKm(startLatitude, startLongitude, endLatitude, endLongitude) {
    const earthRadiusKm = 6371;
    const latDistance = toRadians(endLatitude - startLatitude);
    const lonDistance = toRadians(endLongitude - startLongitude);
    const originLatitude = toRadians(startLatitude);
    const destinationLatitude = toRadians(endLatitude);

    const haversine = Math.sin(latDistance / 2) ** 2
        + Math.cos(originLatitude) * Math.cos(destinationLatitude)
        * Math.sin(lonDistance / 2) ** 2;
    const centralAngle = 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine));
    return earthRadiusKm * centralAngle;
}

function getAssignedDealer(input) {
    const latitude = Number(input.latitude);
    const longitude = Number(input.longitude);
    const hasCoordinates = Number.isFinite(latitude) && Number.isFinite(longitude)
        && input.latitude !== "" && input.longitude !== "";

    if (hasCoordinates) {
        let nearestDealer = null;
        let nearestDistance = Number.POSITIVE_INFINITY;

        dealers.forEach((dealer) => {
            const distance = calculateDistanceKm(latitude, longitude, dealer.latitude, dealer.longitude);
            if (distance < nearestDistance) {
                nearestDistance = distance;
                nearestDealer = {
                    ...dealer,
                    rule: `Nearest by coordinates (${distance.toFixed(1)} km)`
                };
            }
        });

        if (nearestDealer) {
            return nearestDealer;
        }
    }

    const postalMatch = dealers.find((dealer) => dealer.postalCode === input.postalCode);
    if (postalMatch) {
        return { ...postalMatch, rule: "Exact postal-code match" };
    }

    const stateMatch = dealers.find((dealer) => dealer.state === input.state);
    if (stateMatch) {
        return { ...stateMatch, rule: "State fallback match" };
    }

    return { ...dealers[0], rule: "Default dealer fallback" };
}

function buildRetailEmail(customerName, vehicleName, dealerName) {
    return [
        `Hello ${customerName},`,
        "",
        `Your order for ${vehicleName} has been confirmed and assigned to ${dealerName}.`,
        "Inventory has been reserved successfully in the Salesforce order workflow.",
        "",
        "Thank you,",
        "WhatNext Vision Motors"
    ].join("\n");
}

function buildPendingEmail(customerName, vehicleName, dealerName) {
    return [
        `Hello ${customerName},`,
        "",
        `Your bulk order for ${vehicleName} is currently pending due to stock availability.`,
        `The request is still attached to ${dealerName} and will move to confirmed after the inventory batch finds enough stock.`,
        "",
        "Thank you,",
        "WhatNext Vision Motors"
    ].join("\n");
}

function renderDecisionTrail(items) {
    decisionTrail.innerHTML = "";
    items.forEach((item) => {
        const listItem = document.createElement("li");
        listItem.textContent = item;
        decisionTrail.appendChild(listItem);
    });
}

function renderSimulation(event) {
    if (event) {
        event.preventDefault();
    }

    const formData = new FormData(orderForm);
    const vehicleName = formData.get("vehicle");
    const quantity = Math.max(1, Number(formData.get("quantity") || 1));
    const orderType = formData.get("orderType");
    const postalCode = String(formData.get("postalCode") || "");
    const state = String(formData.get("state") || "");
    const latitude = String(formData.get("latitude") || "");
    const longitude = String(formData.get("longitude") || "");
    const customerName = orderType === "Bulk" ? "Fleet Buyer" : "Asha Raman";

    const vehicle = vehicles[vehicleName];
    const dealer = getAssignedDealer({ postalCode, state, latitude, longitude });

    let status = "Confirmed";
    let summary = "Stock is available, so the order confirms immediately and reserves inventory.";
    let stockAfterValue = vehicle.stock - quantity;
    const trail = [
        `${dealer.name} was selected using the rule: ${dealer.rule}.`,
        `${vehicleName} starts with ${vehicle.stock} units available at ${vehicle.price}.`
    ];

    if (orderType === "Retail" && vehicle.stock < quantity) {
        status = "Rejected";
        summary = "Retail ordering is blocked because the requested quantity is above available stock.";
        stockAfterValue = vehicle.stock;
        trail.push("Retail validation blocks the transaction before the order can be saved.");
        trail.push("No stock is reserved because the DML operation would fail in Salesforce.");
    } else if (orderType === "Bulk" && vehicle.stock < quantity) {
        status = "Pending";
        summary = "The bulk order is allowed, but it stays pending until the inventory batch confirms enough stock.";
        stockAfterValue = vehicle.stock;
        trail.push("Bulk ordering remains open even when stock is low.");
        trail.push("The nightly inventory batch will reevaluate the order status.");
    } else {
        trail.push("The requested quantity passes stock validation.");
        trail.push(`Vehicle stock is reserved immediately, leaving ${stockAfterValue} units available.`);
    }

    resultBadge.textContent = status;
    resultBadge.className = "result-badge";
    resultBadge.classList.add(
        status === "Confirmed" ? "is-confirmed" : status === "Pending" ? "is-pending" : "is-rejected"
    );

    resultTitle.textContent = `${vehicleName} routed to ${dealer.name}`;
    resultSummary.textContent = summary;
    assignedDealer.textContent = dealer.name;
    assignmentRule.textContent = dealer.rule;
    stockAfter.textContent = `${stockAfterValue} units`;
    renderDecisionTrail(trail);

    if (status === "Confirmed") {
        emailPreview.textContent = buildRetailEmail(customerName, vehicleName, dealer.name);
    } else if (status === "Pending") {
        emailPreview.textContent = buildPendingEmail(customerName, vehicleName, dealer.name);
    } else {
        emailPreview.textContent = [
            "Retail order blocked.",
            "",
            "Expected platform message:",
            "This vehicle is currently out of stock for the requested quantity and cannot be ordered."
        ].join("\n");
    }
}

function renderRecoveryLab() {
    const stock = Number(atlasStock.value);
    const remainingStock = Math.max(0, stock - atlasBulkQuantity);
    const canConfirm = stock >= atlasBulkQuantity;
    const status = canConfirm ? "Confirmed" : "Pending";

    atlasStockLabel.textContent = `${stock} units`;
    stockBar.style.width = `${(stock / 10) * 100}%`;
    orderBar.style.width = `${(atlasBulkQuantity / 10) * 100}%`;

    recoveryTitle.textContent = canConfirm
        ? "Atlas SUV can move to confirmed"
        : "Atlas SUV remains pending";
    recoverySummary.textContent = canConfirm
        ? `The batch process now sees enough inventory. After reserving 3 units for the pending bulk order, ${remainingStock} units remain.`
        : "There is still not enough stock to satisfy the pending bulk order of 3 units.";

    recoveryLog.innerHTML = "";
    [
        `Inventory batch checks Atlas SUV stock and availability flags.`,
        canConfirm
            ? "Pending bulk order changes to Confirmed because stock is now sufficient."
            : "Pending bulk order stays Pending because stock is still below the requested quantity.",
        canConfirm
            ? `Vehicle stock is reduced from ${stock} to ${remainingStock} after reservation.`
            : `Vehicle stock remains at ${stock} because no reservation occurs yet.`
    ].forEach((entry) => {
        const listItem = document.createElement("li");
        listItem.textContent = entry;
        recoveryLog.appendChild(listItem);
    });

    document.getElementById("recovery-result").dataset.status = status.toLowerCase();
}

function loadChecklistState() {
    let savedState = {};
    try {
        savedState = JSON.parse(window.localStorage.getItem(checklistKey) || "{}");
    } catch (error) {
        savedState = {};
    }

    checklistInputs.forEach((input) => {
        input.checked = Boolean(savedState[input.dataset.checklist]);
    });
    updateChecklistProgress();
}

function updateChecklistProgress() {
    const selectedCount = [...checklistInputs].filter((input) => input.checked).length;
    const progress = Math.round((selectedCount / checklistInputs.length) * 100);
    checklistProgress.textContent = `${progress}%`;
    checklistFill.style.width = `${progress}%`;

    const state = {};
    checklistInputs.forEach((input) => {
        state[input.dataset.checklist] = input.checked;
    });
    try {
        window.localStorage.setItem(checklistKey, JSON.stringify(state));
    } catch (error) {
        return;
    }
}

function fallbackCopy(text) {
    const helper = document.createElement("textarea");
    helper.value = text;
    helper.setAttribute("readonly", "true");
    helper.style.position = "absolute";
    helper.style.left = "-9999px";
    document.body.appendChild(helper);
    helper.select();
    document.execCommand("copy");
    document.body.removeChild(helper);
}

function setupCopyButtons() {
    copyButtons.forEach((button) => {
        button.addEventListener("click", async () => {
            const target = document.getElementById(button.dataset.copyTarget);
            if (!target) {
                return;
            }

            try {
                if (navigator.clipboard && window.isSecureContext) {
                    await navigator.clipboard.writeText(target.textContent || "");
                } else {
                    fallbackCopy(target.textContent || "");
                }
                const originalText = button.textContent;
                button.textContent = "Copied";
                window.setTimeout(() => {
                    button.textContent = originalText;
                }, 1200);
            } catch (error) {
                button.textContent = "Copy failed";
            }
        });
    });
}

animateCounters();
setupTabs();
renderSimulation();
renderRecoveryLab();
loadChecklistState();
setupCopyButtons();

orderForm.addEventListener("submit", renderSimulation);
atlasStock.addEventListener("input", renderRecoveryLab);
checklistInputs.forEach((input) => {
    input.addEventListener("change", updateChecklistProgress);
});
