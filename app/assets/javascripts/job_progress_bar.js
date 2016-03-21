// Courtesy of StackOverflow, I'm too lazy to implement truncation
// which should be in the std library anyways
function truncateDecimals (num, digits)  {
    var numS = num.toString();
    var decPos = numS.indexOf('.');
    var substrLength = decPos == -1 ? numS.length : 1 + decPos + digits;
    var trimmedResult = numS.substr(0, substrLength);
    var finalResult = isNaN(trimmedResult) ? 0 : trimmedResult;

    // adds leading zeros to the right
    if (decPos != -1){
        var s = trimmedResult+"";
        decPos = s.indexOf('.');
        var decLength = s.length - decPos;

            while (decLength <= digits){
                s = s + "0";
                decPos = s.indexOf('.');
                decLength = s.length - decPos;
                substrLength = decPos == -1 ? s.length : 1 + decPos + digits;
            };
        finalResult = s;
    }
    return finalResult;
};

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
					if (job == "none") {
						if (stat) {
							stat.html(I18n.t("jobs.ok"));
						}
						if (banner) {
							banner.removeClass();
							banner.addClass("status_tag");
							banner.addClass("ok");
							banner.html((I18n.t("finished"));
						}
					
						percent_span.html("100%");
						bar.css('width', '100%');
						clearInterval(interval);
						return;
					}
					
					// Valid job
					var stage, progress;

					if (job.progress_stage != null){
						stage = job.progress_stage;
						
						if (job.progress_current != null && job.progress_current > -1) {
							progress = job.progress_current / job.progress_max * 100;
							bar.css('width', progress + '%');
							percent_span.html(truncateDecimals(progress, 1) + "%");
							bar.removeClass('progress-bar-striped');
							bar.removeClass('active');
						} else {
							// If the progress is NULL OR it is indefinite
							// put the bar to indefinite
							bar.css('width','0%');
						}
					
						// Set the banner to running
						banner.removeClass();
						banner.addClass("status_tag");
						banner.addClass("yes");
						banner.html((I18n.t("running"));
					} else {
						stage = "Job enqueued"
						
						// Set the banner to waiting
						banner.removeClass();
						banner.addClass("status_tag");
						banner.addClass("no");
						banner.html((I18n.t("waiting"));
						
						// put the progressbar to indefinite
						bar.css('width','0%');
						percent_span.html("0.0%");
					}
					
					// Always update the stage
					if (stat) {
						stat.html(stage);
					}
					
					// If there are errors
					if (job.last_error != null) {
						
						if (!job.progress_stage) {
							stage = I18n.t("jobs.not_set")
						}
						
						stat.addClass("error");
						if (stat) {
							stat.html(I18n.t("jobs.error") + stage);
						}
						
						if (banner) {
							banner.removeClass();
							banner.addClass("status_tag");
							banner.addClass("error");
							banner.html(I18n.t("failed"));
);
						}
						
						clearInterval(interval);
						return;
					}

				},
				error: function(){
					if (stat) {
						stat.html(I18n.t("jobs.no_status"));
					}
					if (banner) {
						banner.removeClass();
						banner.addClass("status_tag");
						banner.addClass("error");
						banner.html('Error');
					}
					clearInterval(interval);
				}
			})

		},1000);
	});
});