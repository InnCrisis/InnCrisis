function onPreDelete(request,response,modules){
  //Figure out if they are deleting themselves
  modules.collectionAccess.collection('user').find({username: request.username}, function(err, users){
    if(err){
      response.body = '{"description":"'+err.message+'"}';
      response.complete(500);
    }else if(users.length && users[0]._id == request.body._id){
      response.continue();
    }else{
      //Figure out if the person deleting is an admin
      hasAccess(modules, 'admin', request.username, function(err, canAccess){
        if(err){
          response.body = {description:err.message};
          response.complete(err.statusCode);
        }else if(canAccess){
          response.continue();
        }else{
          response.body = {description:"You do not have access to manage users."}
          response.complete(403);
        }
      });
    }
  });
}