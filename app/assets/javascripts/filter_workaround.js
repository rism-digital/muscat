/*

	Workaround for custom-defined ransak filters, as they do not show
	in the text box after filtering.
	It requires on each page a div filter_workaround, with the params[] data
	from rails. This is necessary because params will contain the filters
	restored in config.before_action :restore_search_filters
	so the saved string is persistent.
	See the ActiveAdmin bug here:
	https://github.com/activeadmin/activeadmin/issues/4554
	https://github.com/activeadmin/activeadmin/issues/3510
	
*/

var activeadmin_filter_workaround = function () {

	if ($("#filter_workaround").length == 0) {
		// no partial
		//console.log("No #filter_workaround div");
		return;
	}

	var params = JSON.parse($("#filter_workaround").attr("data-params"));
	var queries = {};
	
	if (!("q" in params) || !params) {
		return;
	}
	
	for (var key in params["q"]) {
		queries["q_" + key] = params["q"][key];
	}
	console.log(queries);
	
	if (queries) {
		$("[id^=q_]").each(function(){
			var input_name = $(this).attr("id");
			if (input_name in queries) {
				
				if ($(this).val() == "" && queries[input_name] != "") {
					$(this).val(queries[input_name]);
					console.log("Filter bush fix: added value " + queries[input_name] +
					" to filter " + input_name);
				}
				
			}
		});
	}
};

$(document).ready(activeadmin_filter_workaround);
// Fix for turbolinks: it will not call againg document.ready
$(document).on('page:load', activeadmin_filter_workaround);
