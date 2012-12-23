function onPreFetch(request,response,modules){
  hasAccess(modules, 'user', request.username, function(err, canAccess){
    if(err){
      response.body = err.message;
      response.complete(err.statusCode);
    }else if(canAccess){
      response.continue();
    }else{
      response.body = '{"description":"You do not have access to view disbursements."}'
      response.complete(403);
    }
  });
}
