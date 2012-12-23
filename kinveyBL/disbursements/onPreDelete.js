function onPreDelete(request,response,modules){
  hasAccess(modules, 'user', request.username, function(err, canAccess){
    if(err){
      response.body = err.message;
      response.complete(err.statusCode);
    }else if(canAccess){
      response.continue();
    }else{
      response.body = "You do not have access to delete disbursements."
      response.complete(403);
    }
  });
}