(function () {
  function clamp(n, min, max) {
    return Math.max(min, Math.min(max, n));
  }

  function parseDone(data) {
    if (data.progress_stage === null || data.progress_stage === undefined || data.progress_stage === "") return false;
    return (data.progress_stage === "succeeded" || data.progress_stage === "error");
  }

  function parseDoneWithError(data) {
    if (data.progress_stage === null || data.progress_stage === undefined || data.progress_stage === "") return false;
    return (data.progress_stage === "error");
  }

  function parsePercent(data) {
    var pct = null;

    if (typeof data.percentage === "number") pct = data.percentage;

    return pct === null ? null : clamp(pct, 0, 100);
  }

  function parseStatusText(data, done) {
    if (data.progress_stage === null || data.progress_stage === undefined) return I18n.t("jobs.waiting");
    
    return (
      (done ? I18n.t("jobs.ok") : "[" + data.progress_stage + "]")
    );
  }

  function isJobError(data) {
      return (data.failed_at !== null);
  }

  function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  function initJobWait(root) {
    var pollUrl = root.getAttribute("data-poll-url");
    var redirectUrl = root.getAttribute("data-redirect-url");
    var intervalMs = parseInt(root.getAttribute("data-poll-interval-ms") || "1000", 10);

    var statusEl = root.querySelector("[data-job-wait-status]");
    var percentEl = root.querySelector("[data-job-wait-percent]");
    var errorEl = root.querySelector("[data-job-wait-error]");

    var stopped = false;

    var actionsEl = root.querySelector("[data-job-wait-actions]");
    var backBtn = root.querySelector("[data-job-wait-back]");

    var spinnerEl = root.querySelector(".job-wait__barber")

    if (backBtn) {
      backBtn.addEventListener("click", function () {
        if (history.length > 1) {
          history.back();
        } else {
          window.location.assign("/admin"); // fallback; change if you want
        }
      });
    }

    function spinnerError() {
        if (spinnerEl) {
          spinnerEl.classList.add("stopped");
          spinnerEl.classList.add("error");
        }
    }

    function spinnerOk() {
        if (spinnerEl) {
          spinnerEl.classList.add("stopped");
          spinnerEl.classList.add("ok");
        }
    }

    function scheduleNext() {
      window.setTimeout(tick, intervalMs);
    }

    function showError(msg) {
      stopped = true;

      spinnerError();

      if (errorEl) {
        errorEl.style.display = "block";
        errorEl.textContent = msg || I18n.t("jobs.no_status");
      }

      if (actionsEl) {
        actionsEl.style.display = "block";
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
          const done = parseDone(data);
          const statusText = parseStatusText(data, done);
          const pct = parsePercent(data);
          const jobError = isJobError(data);

          // The job failed
          if (jobError) {
            showError(data.progress_stage);
          }

          if (statusEl) statusEl.textContent = statusText;
          if (percentEl) percentEl.textContent = (pct === null ? "" : (pct + "%"));

          if (data.error) throw new Error(data.error);

          if (done) {
            // In case the job finished, but there was an error
            if (parseDoneWithError(data))
              spinnerError();
            else
              spinnerOk();

            stopped = true;
            sleep(500).then(function () {
              var target = data.redirect_url || redirectUrl;
              if (target) window.location.assign(target);
            });
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