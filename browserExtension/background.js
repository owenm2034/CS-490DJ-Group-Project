const trackerWeights = {
  "google-analytics.com": 3,
  "doubleclick.net": 4,
  "facebook.com": 4,
  "analytics.tiktok.com": 3,
  "clarity.ms": 2,
  "hotjar.com": 2,
  "criteo.com": 3,
  "adnxs.com": 3,
  "segment.io": 2,
};

const defaultBlockedDomains = [
  "doubleclick.net",
  "google-analytics.com",
  "scorecardresearch.com",
  "facebook.com",
  "analytics.tiktok.com",
  "clarity.ms",
  "hotjar.com",
  "criteo.com",
  "adnxs.com",
  "mouseflow.com",
  "quantserve.com",
  "segment.io",
];

let siteStats = {
  currentSite: {
    domain: "",
    isSecure: false,
    thirdPartyRequests: [],
    blockedRequests: [],
  },
  globalStats: {
    detected: 0,
    blocked: 0,
    isBlocking: true,
    trackers: {},
    blockedDomains: defaultBlockedDomains,
  },
};

function extractDomain(url) {
  try {
    if (!url || url === "about:blank" || url.startsWith("chrome://")) {
      return null;
    }
    const urlObj = new URL(url);
    return urlObj.hostname;
  } catch (e) {
    console.error("Error extracting domain:", e);
    return null;
  }
}

function calculateGrade(stats, siteInfo) {
  if (!stats || !siteInfo) return "A";

  let totalWeight = 0;
  let blockedWeight = 0;

  for (const [domain, tracker] of Object.entries(stats.trackers)) {
    const weight = trackerWeights[domain] || 1;
    totalWeight += weight * tracker.detected;
    blockedWeight += weight * tracker.blocked;
  }

  let ratio = totalWeight === 0 ? 1 : blockedWeight / totalWeight;

  const securityPenalties = [];

  if (!siteInfo.isSecure) {
    securityPenalties.push(0.2); // 20% penalty
  }

  if (/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(siteInfo.domain)) {
    securityPenalties.push(0.3); // 30% penalty
  }

  if (/\d/.test(siteInfo.domain)) {
    securityPenalties.push(0.1); // 10% penalty
  }

  securityPenalties.forEach((penalty) => {
    ratio *= 1 - penalty;
  });

  const weightedRatio = ratio * (1 - Object.keys(stats.trackers).length / 20);

  let grade = "A";
  if (weightedRatio < 0.95) grade = "B";
  if (weightedRatio < 0.85) grade = "C";
  if (weightedRatio < 0.75) grade = "D";
  if (weightedRatio < 0.65) grade = "F";

  if (
    /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(siteInfo.domain) ||
    (!siteInfo.isSecure && totalWeight > 0)
  ) {
    grade = "F";
  }

  return grade;
}

function updateBadge() {
  const grade = calculateGrade(siteStats.globalStats, siteStats.currentSite);
  chrome.action.setBadgeText({ text: grade });
  chrome.action.setBadgeBackgroundColor({
    color:
      grade === "F"
        ? "#F44336"
        : grade === "D"
        ? "#FF9800"
        : grade === "C"
        ? "#FFC107"
        : grade === "B"
        ? "#8BC34A"
        : "#4CAF50",
  });
}

chrome.webRequest.onBeforeRequest.addListener(
  (details) => {
    if (!details.initiator || details.initiator.startsWith("chrome://")) return;

    try {
      const requestUrl = new URL(details.url);
      const initiatorUrl = new URL(details.initiator);

      if (requestUrl.hostname !== initiatorUrl.hostname) {
        if (
          !siteStats.currentSite.thirdPartyRequests.includes(
            requestUrl.hostname
          )
        ) {
          siteStats.currentSite.thirdPartyRequests.push(requestUrl.hostname);
        }

        if (isTracker(requestUrl.hostname)) {
          handleTrackerDetection(requestUrl.hostname);
        }

        chrome.storage.local.set({ siteStats });
      }
    } catch (e) {
      console.error("Error processing request:", e);
    }
  },
  { urls: ["<all_urls>"] }
);

function isTracker(domain) {
  return siteStats.globalStats.blockedDomains.some((tracker) =>
    domain.includes(tracker)
  );
}

function handleTrackerDetection(domain) {
  if (!siteStats.currentSite.blockedRequests.includes(domain)) {
    siteStats.currentSite.blockedRequests.push(domain);
  }

  if (!siteStats.globalStats.trackers[domain]) {
    siteStats.globalStats.trackers[domain] = {
      detected: 0,
      blocked: 0,
      lastSeen: new Date().toISOString(),
      weight: trackerWeights[domain] || 1,
    };
  }

  siteStats.globalStats.detected++;
  siteStats.globalStats.trackers[domain].detected++;

  if (siteStats.globalStats.isBlocking) {
    siteStats.globalStats.blocked++;
    siteStats.globalStats.trackers[domain].blocked++;
  }

  updateBadge();
}

chrome.tabs.onActivated.addListener(async (activeInfo) => {
  try {
    const tab = await chrome.tabs.get(activeInfo.tabId);
    if (tab.url && !tab.url.startsWith("chrome://")) {
      updateCurrentSite(tab.url);
    }
  } catch (e) {
    console.error("Error in onActivated:", e);
  }
});

chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.url && !changeInfo.url.startsWith("chrome://")) {
    updateCurrentSite(changeInfo.url);
  }
});

function updateCurrentSite(url) {
  try {
    if (!url || url === "about:blank" || url.startsWith("chrome://")) {
      return;
    }
    const urlObj = new URL(url);
    siteStats.currentSite = {
      domain: urlObj.hostname,
      isSecure: urlObj.protocol === "https:",
      thirdPartyRequests: [],
      blockedRequests: [],
    };

    siteStats.currentSite.isIPAddress =
      /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(urlObj.hostname);
    siteStats.currentSite.hasNumbers = /\d/.test(urlObj.hostname);

    chrome.storage.local.set({ siteStats });
    updateBadge();
  } catch (e) {
    console.error("Error updating current site:", e);
  }
}

chrome.storage.local.get(["siteStats"], function (data) {
  if (data.siteStats) {
    siteStats = {
      ...siteStats,
      ...data.siteStats,
      globalStats: {
        ...siteStats.globalStats,
        ...data.siteStats.globalStats,
        blockedDomains: defaultBlockedDomains,
      },
    };
  }
  updateBadge();
});

chrome.runtime.onMessage.addListener(function (request, sender, sendResponse) {
  if (request.getStats) {
    sendResponse(siteStats);
  }
  if (request.getGrade) {
    const grade = calculateGrade(request.stats, request.siteInfo);
    sendResponse(grade);
    return true;
  }
  if (request.toggleBlocking !== undefined) {
    siteStats.globalStats.isBlocking = request.toggleBlocking;

    chrome.declarativeNetRequest
      .updateEnabledRulesets({
        enableRulesetIds: request.toggleBlocking ? ["ruleset_1"] : [],
        disableRulesetIds: request.toggleBlocking ? [] : ["ruleset_1"],
      })
      .then(() => {
        chrome.storage.local.set({ siteStats });
        updateBadge();
        sendResponse(siteStats);
      });

    return true;
  }
  if (request.toggleDomain) {
    const { domain, blocked } = request.toggleDomain;
    const index = siteStats.globalStats.blockedDomains.indexOf(domain);

    if (blocked && index === -1) {
      siteStats.globalStats.blockedDomains.push(domain);
    } else if (!blocked && index > -1) {
      siteStats.globalStats.blockedDomains.splice(index, 1);
    }

    chrome.storage.local.set({ siteStats });
    updateBadge();
    sendResponse(siteStats);
  }
});
