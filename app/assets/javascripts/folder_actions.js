function create_folder(path) {
	
	fname = $('#folder_name').val();
	// This is ugly, find a better solution
	window.location = path + "&folder_name=" + fname;
	
}