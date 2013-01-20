function onPreSave(request, response, modules){
  hasAccess(modules, 'user', request.username, function(err, canAccess){
    if(err){
      response.body = {description: err.message};
      response.complete(err.statusCode);
    }else if(canAccess){
      isCreate(request, modules, function(isFirstTime){
        if(isFirstTime){
          // This is the first time, match to donation!
          matchDonations(request.body.amount, modules, function(e, matchedDonations){
            if(e){
              response.body = {description: e.message };
              response.complete(500);
            }else{
              request.body.matchedDonations = matchedDonations;
              response.continue();
            }
          });
        }else{
          response.continue();
        }
      });
    }else{
      response.body = {error: 'You do not have access to update disbursements.'};
      response.complete(403);
    }
  });
}


/*

Okay, this gets a bit complicated. We want to remove X amount of money
from the remaining field of the donation entries. We want to track the
entries themselves, the amount of money coming out and provide a fallback
for when we run out of money or there is a duplicated write happening at the moment.

The approach:
We want each entry to control their save/rollback, that way we don't need to handle
 this on a per item basis. Passing out process and revert methods to the tracking object would be nice.

Recursion would solve this problem most likely, to sort down the stack, keeping an array of all the previous
entries, with their subsequent rollback methods. The rollback method needs to be atomic so we don't get into
weird states.

We need to fail/rollback when there is no more money left, if we encounter an update/logic error
we don't need to fail we can simply re-call ourselves and try again, this time hopefully we don't get hit.

 */

var matchDonations = function(amount, modules, cb){
  matchDonation([], amount, modules, cb);
}

var matchDonation = function(allDonations, amount, modules, cb){
  modules.collectionAccess.collection('donations').find(
    {remaining: {$gt: 0}},
    {sort:['createTime'], limit: 1},
    function (e, donations){
      if(e){
        revertDonations(allDonations, e.message, cb);
      }else{
        if(!donations.length){
          revertDonations(allDonations, 'Not enough funds available', cb);
        }else{

          //Reduce as much as we can reasonably do.
          var remaining = donations[0].remaining;
          var reductionAmount = amount;
          if(remaining < reductionAmount){
            reductionAmount = remaining;
          }

          var donationMatchObj = {
            amount: reductionAmount,
            entryId: donations[0]._id,
            revert: function(){
              modules.collectionAccess.collection('donations').update(
                {_id: donations[0]._id},
                {$inc:{remaining: reductionAmount}}
              );
            }
          };

          modules.collectionAccess.collection('donations').update(
            {_id: donations[0]._id, remaining: remaining},
            {$set:{remaining:remaining-reductionAmount}},
            function(e, updatedDoc){
              if(e){
                revertDonations(allDonations, e.message, cb);
              }else{
                //We have a successful update!
                allDonations.push(donationMatchObj);
                if(amount - reductionAmount > 0){
                  matchDonation(allDonations, amount-reductionAmount, modules, cb);
                }else{
                  //WOOO!! We have a succesful update and we have no more money left to need to disberse
                  for(var i=0;i<allDonations.length;i++){
                    delete allDonations[i].revert;
                  }
                  cb(null, allDonations);
                }
              }
            }
          );

        }
      }
    })
}

var revertDonations = function(allDonations, msg, cb){
  for(var i=0;i<allDonations.length;i++){
    allDonations[i].revert();
  }
  cb({message: msg});
}


var isCreate = function(request, modules, cb){
  // Figure out if this is an update or a first time save
  if(request.body._id){
    modules.collectionAccess.collection('disbursements').find({_id:request.body._id}, function(err, disbursements){
      if(disbursements.length){
        cb(false);
      }else{
        cb(true);
      }
    });
  }else{
    cb(true);
  }
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