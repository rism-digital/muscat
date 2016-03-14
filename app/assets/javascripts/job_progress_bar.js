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
		var interval = setInterval(function(){
			$.ajax({
				url: '/progress-job/' + job_id,
				success: function(job){
					var stage, progress;

					stage = "Job enqueued"
					if (job.progress_stage != null){
						stage = job.progress_stage;
						
						if (banner && banner.hasClass("no")) {
							banner.removeClass();
							banner.addClass("status_tag");
							banner.addClass("no");
							banner.html('Waiting');
						}
					}
					
					// If there are errors
					if (job.last_error != null) {
						stat.addClass("error");
						bar.addClass("error");
						if (stat) {
							stat.html("ERROR: " + stage);
						}
						
						if (banner) {
							banner.removeClass();
							banner.addClass("status_tag");
							banner.addClass("error");
							banner.html('Failed');
						}
						
						clearInterval(interval);
						return;
					}
					
					
					progress = job.progress_current / job.progress_max * 100;
					bar.css('width', progress + '%').text(truncateDecimals(progress, 2) + '%');
					if (stat) {
						stat.html(stage);
					}
					
					// Update banner, but only if running
					if (banner && !banner.hasClass("ok") && job.progress_stage != null) {
						banner.removeClass();
						banner.addClass("status_tag");
						banner.addClass("ok");
						banner.html('Running');
					}

				},
				error: function(){
					if (stat) {
						stat.html('Job ended successfully');
					}
					if (banner) {
						banner.removeClass();
						banner.addClass("status_tag");
						banner.addClass("yes");
						banner.html('Finished');
					}
					
					bar.css('width', '100%').text("100%");
					clearInterval(interval);
				}
			})

		},1000);
	});
});