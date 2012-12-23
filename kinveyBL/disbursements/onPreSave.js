function onPreSave(request,response,modules){
  hasAccess(modules, 'user', request.username, function(err, canAccess){
    if(err){
      response.body = err.message;
      response.complete(err.statusCode);
    }else if(canAccess){
      response.continue();
    }else{
      response.body = {error: 'You do not have access to update disbursements.'}
      response.complete(403);
    }
  });
}


var appKid = "kid_eeg1EyERV5";
var hasAccess = function(modules, checkRole, username, cb){
  if(username == appKid){ //They are using the master secret. Give it access.
    cb(null, true);
  }else{
    modules.collectionAccess.collection('user').find({username: username}, function(err, users){
      if(err){
        cb({
          message: err.message,
          statusCode: 500
        });
      }else{
        if(users.length){
          user = users[0];
          if(user.role){
            modules.collectionAccess.collection('roles').find({_id: user.role._id}, function(err, roles){
              if(err){
                cb({
                  message: err.message,
                  statusCode: 500
                });
              }else{
                if(roles.length){
                  if(roles[0]._id == checkRole || roles[0].inherits == checkRole){
                    cb(null, true);
                  }else{
                    cb(null, false);
                  }
                }else{
                  cb(null, false);
                }
              }
            });
          }else{
            cb(null, false);
          }
        }else{
          cb({
            message: "Could not find user entry.",
            statusCode: 500
          });
        }
      }
    });
  }
}