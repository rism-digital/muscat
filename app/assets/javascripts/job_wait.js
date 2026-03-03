(function () {
  function clamp(n, min, max) {
    return Math.max(min, Math.min(max, n));
  }

  function parseDone(data) {
    if (data.progress_stage === null || data.progress_stage === undefined || data.progress_stage === "") return false;
    return (
      data.progress_stage === "succeeded"
    );
  }

  function parsePercent(data) {
    var pct = null;

    if (typeof data.percentage === "number") pct = data.percentage;

    return pct === null ? null : clamp(pct, 0, 100);
  }

  function parseStatusText(data, done) {
    if (data.progress_stage === null || data.progress_stage === undefined) return "Waiting for job to start…";

    return (
      (done ? "Done" : "Working… [" + data.progress_stage + "]")
    );
  }

  function initJobWait(root) {
    var pollUrl = root.getAttribute("data-poll-url");
    var redirectUrl = root.getAttribute("data-redirect-url");
    var intervalMs = parseInt(root.getAttribute("data-poll-interval-ms") || "1000", 10);

    var statusEl = root.querySelector("[data-job-wait-status]");
    var percentEl = root.querySelector("[data-job-wait-percent]");
    var errorEl = root.querySelector("[data-job-wait-error]");

    var stopped = false;

    function scheduleNext() {
      window.setTimeout(tick, intervalMs);
    }

    function showError(msg) {
      stopped = true;
      if (errorEl) {
        errorEl.style.display = "block";
        errorEl.textContent = msg || "Job status polling failed";
      }
    }

    function tick() {
      if (stopped) return;

      fetch(pollUrl, {
        method: "GET",
        headers: { "Accept": "application/json" },
        credentials: "same-origin"
      })
        .then(function (res) {
          if (!res.ok) throw new Error("Status check failed: " + res.status + " " + res.statusText);
          return res.json();
        })
        .then(function (data) {
          var done = parseDone(data);
          var statusText = parseStatusText(data, done);
          var pct = parsePercent(data);

          if (statusEl) statusEl.textContent = statusText;
          if (percentEl) percentEl.textContent = (pct === null ? "" : (pct + "%"));

          if (data.error) throw new Error(data.error);

          if (done) {
            stopped = true;
            var target = data.redirect_url || redirectUrl;
            if (target) window.location.assign(target);
            return;
          }

          scheduleNext();
        })
        .catch(function (e) {
          showError(e && e.message ? e.message : null);
        });
    }

    tick();
  }

  function boot() {
    var nodes = document.querySelectorAll("[data-job-wait]");
    for (var i = 0; i < nodes.length; i++) initJobWait(nodes[i]);
  }

  document.addEventListener("DOMContentLoaded", boot);
})();