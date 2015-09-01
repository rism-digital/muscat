var init_marc_messages = function () {
	
	//$('.flashes').empty();
	
	$('div[data-flash]').each(function() {
		text = $(this).data("flash");
		type = $(this).data("type");
		
		$('<div/>', {
		    "class": 'flash flash_' + type,
		    text: text
		}).appendTo('.marc_flashes');
		i = 0;
	});
	
};

$(document).ready(init_marc_messages);
// Fix for turbolinks: it will not call againg document.ready
$(document).on('page:load', init_marc_messages);