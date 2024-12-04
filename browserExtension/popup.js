function hasNumbers(domain) {
  return /\d/.test(domain);
}

function isIPAddress(domain) {
  return /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(domain);
}

document.addEventListener("DOMContentLoaded", function () {
  document
    .getElementById("thirdPartyContainer")
    .addEventListener("click", function () {
      this.classList.toggle("expanded");
      document.getElementById("thirdPartyList").classList.toggle("visible");
    });

  document
    .getElementById("globalToggle")
    .addEventListener("change", function (e) {
      chrome.runtime.sendMessage(
        {
          toggleBlocking: e.target.checked,
        },
        function (response) {
          updatePopupContent();
        }
      );
    });

  updatePopupContent();

  chrome.tabs.onActivated.addListener(updatePopupContent);
  chrome.tabs.onUpdated.addListener((tabId, changeInfo) => {
    if (changeInfo.status === "complete") {
      updatePopupContent();
    }
  });
});

async function updatePopupContent() {
  const { siteStats } = await chrome.storage.local.get("siteStats");
  if (!siteStats) return;

  updateSecurityStatus(siteStats.currentSite);
  updateSecurityWarnings(siteStats.currentSite);
  updateBlockedSummary(siteStats.globalStats.trackers);
  updateTrackerList(siteStats.globalStats);
  updateGrade(siteStats.globalStats, siteStats.currentSite);
}

function updateSecurityWarnings(siteInfo) {
  const warningsContainer = document.getElementById("securityWarnings");
  warningsContainer.innerHTML = "";
  const warnings = [];

  if (isIPAddress(siteInfo.domain)) {
    warnings.push({
      text: "This website is using an IP address instead of a domain name. This is unusual and potentially suspicious.",
      highPriority: true,
      iconClass: "ip-warning",
    });
  }

  if (hasNumbers(siteInfo.domain)) {
    warnings.push({
      text: "This domain contains numbers, which might indicate a suspicious or temporary website.",
      highPriority: false,
      iconClass: "numeric-warning",
    });
  }

  if (!siteInfo.isSecure) {
    warnings.push({
      text: "This website is not using HTTPS. Your connection is not secure.",
      highPriority: true,
      iconClass: "https-warning",
    });
  }

  warnings.forEach((warning) => {
    const warningElement = document.createElement("div");
    warningElement.className = `warning-item ${
      warning.highPriority ? "high-warning" : ""
    }`;
    warningElement.innerHTML = `
      <div class="warning-icon ${warning.iconClass}"></div>
      <span class="warning-text">${warning.text}</span>
    `;
    warningsContainer.appendChild(warningElement);
  });

  return warnings.length;
}

// if (siteInfo.isSecure) {
//   connectionIcon.className = 'status-icon secure';
//   connectionStatus.textContent = 'Secure Connection (HTTPS)';
// } else {
//   connectionIcon.className = 'status-icon insecure';
//   connectionStatus.textContent = 'Insecure Connection (HTTP)';
// }

// // Tracker Status
// if (siteInfo.blockedRequests.length > 0) {
//   trackerIcon.className = 'status-icon secure';
//   trackerStatus.textContent = `${siteInfo.blockedRequests.length} trackers blocked`;
// } else {
//   trackerIcon.className = 'status-icon neutral';
//   trackerStatus.textContent = 'No trackers detected';
// }

// // Third-party Status
// if (siteInfo.thirdPartyRequests.length > 0) {
//   thirdPartyIcon.className = 'status-icon insecure';
//   thirdPartyStatus.textContent = `${siteInfo.thirdPartyRequests.length} third-party requests`;
//   // ... rest of the code remains the same
// } else {
//   thirdPartyIcon.className = 'status-icon secure';
//   thirdPartyStatus.textContent = 'No third-party requests';

function updateSecurityStatus(siteInfo) {
  const connectionIcon = document.getElementById("connectionIcon");
  const connectionStatus = document.getElementById("connectionStatus");

  if (siteInfo.isSecure) {
    connectionIcon.className = "status-icon secure";
    connectionStatus.textContent = "Secure Connection (HTTPS)";
  } else {
    connectionIcon.className = "status-icon insecure";
    connectionStatus.textContent = "Insecure Connection (HTTP)";
  }

  const trackerIcon = document.getElementById("trackerIcon");
  const trackerStatus = document.getElementById("trackerStatus");

  if (siteInfo.blockedRequests.length > 0) {
    trackerIcon.className = "status-icon secure";
    trackerStatus.textContent = `${siteInfo.blockedRequests.length} trackers blocked`;
  } else {
    trackerIcon.className = "status-icon neutral";
    trackerStatus.textContent = "No trackers detected";
  }

  const thirdPartyIcon = document.getElementById("thirdPartyIcon");
  const thirdPartyStatus = document.getElementById("thirdPartyStatus");
  const thirdPartyList = document.getElementById("thirdPartyList");

  if (siteInfo.thirdPartyRequests.length > 0) {
    thirdPartyIcon.className = "status-icon insecure";
    thirdPartyStatus.textContent = `${siteInfo.thirdPartyRequests.length} third-party requests`;

    thirdPartyList.innerHTML = "";
    const sortedDomains = [...siteInfo.thirdPartyRequests].sort();

    sortedDomains.forEach((domain) => {
      const domainElement = document.createElement("div");
      domainElement.className = "third-party-item";

      const isTracker = siteInfo.blockedRequests.includes(domain);

      domainElement.innerHTML = `
        <span class="domain">${domain}</span>
        ${isTracker ? '<span class="tracker-badge">Tracker</span>' : ""}
      `;

      thirdPartyList.appendChild(domainElement);
    });
  } else {
    thirdPartyIcon.className = "status-icon secure";
    thirdPartyStatus.textContent = "No third-party requests";
    thirdPartyList.innerHTML =
      '<div class="third-party-item">No third-party requests detected</div>';
  }
}

function updateBlockedSummary(trackers) {
  const summary = document.getElementById("blockedSummary");

  const blockedCompanies = new Set();
  Object.keys(trackers).forEach((domain) => {
    if (trackers[domain].blocked > 0) {
      const company = domain.split(".").slice(-2)[0];
      blockedCompanies.add(company);
    }
  });

  if (blockedCompanies.size > 0) {
    const companies = Array.from(blockedCompanies);
    let summaryText = "We blocked trackers from ";

    if (companies.length === 1) {
      summaryText += companies[0];
    } else if (companies.length === 2) {
      summaryText += `${companies[0]} and ${companies[1]}`;
    } else {
      const lastCompany = companies.pop();
      summaryText += `${companies.join(", ")}, and ${lastCompany}`;
    }

    summary.textContent = summaryText;
  } else {
    summary.textContent = "No trackers have been blocked on this site yet";
  }
}

function updateTrackerList(globalStats) {
  const trackerList = document.getElementById("trackerList");
  trackerList.innerHTML = "";

  const sortedTrackers = Object.entries(globalStats.trackers).sort(
    ([, a], [, b]) => b.detected - a.detected
  );

  for (const [domain, tracker] of sortedTrackers) {
    const item = document.createElement("div");
    item.className = "tracker-item";

    const riskLevel =
      tracker.weight >= 3
        ? "high-risk"
        : tracker.weight >= 2
        ? "medium-risk"
        : "";

    item.innerHTML = `
      <div class="tracker-info">
        <div class="${riskLevel}">${domain}</div>
        <div class="tracker-stats">
          Detected: ${tracker.detected} | Blocked: ${tracker.blocked}
        </div>
      </div>
      <label class="switch">
        <input type="checkbox" data-domain="${domain}" 
               ${globalStats.blockedDomains.includes(domain) ? "checked" : ""}>
        <span class="slider"></span>
      </label>
    `;

    const toggle = item.querySelector('input[type="checkbox"]');
    toggle.addEventListener("change", function (e) {
      chrome.runtime.sendMessage(
        {
          toggleDomain: {
            domain: this.dataset.domain,
            blocked: this.checked,
          },
        },
        function (updatedStats) {
          updatePopupContent();
        }
      );
    });

    trackerList.appendChild(item);
  }
}

function updateGrade(stats, siteInfo) {
  if (!stats || !siteInfo) return;

  chrome.runtime.sendMessage({ getGrade: true, stats, siteInfo }, (grade) => {
    const gradeElem = document.getElementById("grade");
    gradeElem.textContent = grade;
    gradeElem.className = `grade ${grade}`;
  });
}
