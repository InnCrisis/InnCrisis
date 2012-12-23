function onPreDelete(request,response,modules){
	hasAccess(modules, 'admin', request.username, function(err, canAccess){
		if(err){
			response.body = err.message;
			response.complete({description:err.statusCode});
		}else if(canAccess){
			response.continue();
		}else{
			response.body = {description:"You do not have access to delete donations."}
			response.complete(403);
		}
	});
}
