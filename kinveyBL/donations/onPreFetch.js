function onPreFetch(request,response,modules){
	if(request.body._id){
		response.continue();
	}else{
		hasAccess(modules, 'admin', request.username, function(err, canAccess){
			if(err){
				response.body = err.message;
				response.complete(err.statusCode);
			}else if(canAccess){
				response.continue();
			}else{
				response.body = {description:"You do not have access to view donations."}
				response.complete(403);
			}
		});
	}
}