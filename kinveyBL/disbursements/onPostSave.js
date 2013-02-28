function onPostSave(request,response,modules){
  if(response.body && response.body.matchedDonations && response.body.matchedDonations.length){
    var matches = response.body.matchedDonations;
    var count = matches.length;
    for(var i=0;i<matches.length;i++){
      modules.logger.info(matches[i]);
      bindMatchedDonation(modules, {
        donationId:matches[i].entryId,
        amount:matches[i].amount,
        disbursementId:response.body._id
      },function(e){
        if(e){
          modules.logger.error(e);
          response.body = {description: e.message};
          response.complete(e.statusCode);
        }else{
          count--;
          if(count == 0){
            response.continue();
          }
        }
      });
    }
  }else{
    response.continue();
  }
}

var bindMatchedDonation = function(modules, options, cb){
  modules.collectionAccess.collection('donations').update(
    {_id:options.donationId},
    {$push:{
      matchedDisbursals:{
        entryId: options.disbursementId,
        amount: options.amount
      }
    }},
    function(e){
      if(e){
        cb({
          message: e.message,
          statusCode: 500
        })
      }else{
        cb()
      }
    }
  );
}