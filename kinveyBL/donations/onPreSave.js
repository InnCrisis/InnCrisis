function onPreSave(request,response,modules){
  var logger = modules.logger;
  logger.info(request.body);
  // Make sure they are passing in a checkout ID as the _id
  if(request.body && request.body._id && request.body._id.length){
    var checkoutId = request.body._id;
    //Get the donation so we can determine if its an update or a save
    getDonation(modules, {_id: checkoutId}, function(err, donations){
      if(err){
        response.body = {description:err.message};
        response.complete(500);
      }else{
        //New Donation
        if(!donations.length){
          //Get the wepay entry
          getWePayEntry(modules, checkoutId, function(err, wepay){
            if(err){
              response.body = {description:err.message};
              response.complete(err.status);
            }else{
              request.body.wepay = wepay;
              request.body.remaining = wepay.amount;
              request.body.createTime = (new Date()).getTime();
              request.continue();
            }
          });
        }else{
          //Updating existing donation, make sure they are an admin
          hasAccess(modules, 'admin', request.username, function(err, canAccess){
            if(err){
              response.body = err.message;
              response.complete({description: err.statusCode});
            }else if(canAccess){
              response.continue();
            }else{
              response.body = {description:"You do not have access to delete donations."}
              response.complete(403);
            }
          });
        }
      }
    });
  }else{
    response.body = {description: "_id referencing checkoutId required in request body"};
    response.complete(400);
  }
}

var getDonation = function(modules, query, cb){
  modules.collectionAccess.collection('donations').find(query, function(err, docs){
    cb(err, docs);
  });
}


var getWePayEntry = function(modules, checkoutId, cb){
  modules.request.get({
    uri:'https://stage.wepayapi.com/v2/checkout/?checkout_id='+checkoutId,
    headers:{
      'Authorization':"Bearer 654d1dee01cd77a3aec989b216997396ff937c5c501e18f45a2af82ec36b7fcd",
      "User-Agent":"Kinvey Console"
    }
  }, function(err, res, body){
    if(err){
      cb({
        status: 500,
        message: err.message
      });
    }else{
      if(res.status == 200){
        cb(null, JSON.parse(body))
      }else{
        cb({
          status: res.status,
          message: res.body
        });
      }
    }
  });
};

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