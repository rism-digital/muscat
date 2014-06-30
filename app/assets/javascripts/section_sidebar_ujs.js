$(document).ready(function(){
	$('a[data-scroll-target]').click(function(e){
		e.preventDefault();
		tname = $(this).data("scroll-target");
		$.scrollTo($("[name=" + tname + "]"), 100, {offset: -10});
	})
})
