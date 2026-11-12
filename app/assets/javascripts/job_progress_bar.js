jQuery(document).ready(function() {
	$(".progress_bar_content").each(function(){
		var job_id = $(this).data("job-id");
		var bar = $(this);
		var stat = $("#progress-status-" + job_id);
		var banner = $("#job-banner-" + job_id);
		var percent_span = $('#progress-percent-' + job_id);
		var interval = setInterval(function(){
			$.ajax({
				url: '/progress-job/' + job_id,
				success: function(job){
					var stage = job.progress_stage || "Job enqueued";
					var progress = job.percentage;

					if (job.status === "complete") {
						if (stat.length) stat.text(I18n.t("jobs.ok"));
						if (banner.length) {
							banner.removeClass().addClass("status_tag ok").text(I18n.t("finished"));
						}
						percent_span.text("100%");
						bar.css("width", "100%");
						clearInterval(interval);
						return;
					}

					if (job.status === "failed") {
						stage = job.progress_stage || I18n.t("jobs.not_set");
						if (stat.length) stat.addClass("error").text(I18n.t("jobs.error") + stage);
						if (banner.length) {
							banner.removeClass().addClass("status_tag error").text(I18n.t("failed"));
						}
						clearInterval(interval);
						return;
					}

					if (job.status !== "queued" && job.status !== "running") {
						if (stat.length) stat.text(I18n.t("jobs.no_status"));
						clearInterval(interval);
						return;
					}

					if (job.status === "queued") {
						if (banner.length) {
							banner.removeClass().addClass("status_tag no").text(I18n.t("waiting"));
						}
						bar.css("width", "0%");
						percent_span.text("0.0%");
					} else {
						if (banner.length) {
							banner.removeClass().addClass("status_tag yes").text(I18n.t("running"));
						}
						if (typeof progress === "number") {
							bar.css("width", progress + "%").removeClass("progress-bar-striped active");
							percent_span.text(progress.toFixed(1) + "%");
						} else {
							bar.css("width", "0%");
						}
					}

					if (stat.length) stat.text(stage);

				},
				error: function(){
					if (stat.length) stat.text(I18n.t("jobs.no_status"));
					if (banner.length) banner.removeClass().addClass("status_tag error").text(I18n.t("failed"));
					clearInterval(interval);
				}
			})

		},1000);
	});
});
