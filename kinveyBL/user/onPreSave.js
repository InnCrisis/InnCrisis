function onPreSave(request,response,modules){
  //Figure out if this is user creation or update...
  if(request.body._id){
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
  }else{
    response.continue();
  }
}


var appKid = "kid_eeg1EyERV5";
var hasAccess = function(modules, checkRole, username, cb){
  var logger = modules.logger;
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
          logger.info(user);
          if(user.role){
            modules.collectionAccess.collection('roles').find({_id: user.role._id}, function(err, roles){
              if(err){
                logger.error(err);
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