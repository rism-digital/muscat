var activeadmin_filter_workaround = function () {
	function getQueryParams(qs) {
	    qs = qs.split('+').join(' ');

	    var params = {},
	        tokens,
	        re = /[?&]?([^=]+)=([^&]*)/g;

	    while (tokens = re.exec(qs)) {
	        params[decodeURIComponent(tokens[1])] = decodeURIComponent(tokens[2]);
	    }

	    return params;
	}

	var params = getQueryParams(document.location.search);
	
	if (params) {
		$("[name^=q]").each(function(){
			var input_name = $(this).attr("name");
			if ((input_name in params)) {
				
				if ($(this).val() == "" && params[input_name] != "") {
					$(this).val(params[input_name]);
					console.log("Filter bush fix: added value " + params[input_name] +
					" to filter " + input_name);
				}
				
			}
		});
	}
};

$(document).ready(activeadmin_filter_workaround);
// Fix for turbolinks: it will not call againg document.ready
$(document).on('page:load', activeadmin_filter_workaround);