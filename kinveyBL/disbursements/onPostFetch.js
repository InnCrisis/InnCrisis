function onPostFetch(request,response,modules){
	var disbursements = response.body;
  if(disbursements.length){
    populateDonations(modules, disbursements, function(e, newDisbursements){
      if(e){
        response.continue();
      }else{
        response.body = newDisbursements;
        response.continue();
      }
    });
  }else{
    response.continue();
  }
}

var populateDonations = function(modules, disbursements, cb){
  if(disbursements.length){
    var counter = disbursements.length;
    for(var i=0;i<disbursements.length;i++){
      populateDonation(modules, disbursements[i], function(e){
        if(e){
          cb(e);
        }else{
          counter--;
          if(counter == 0){
            cb(null, disbursements);
          }
        }
      });
    }
  }
}

var populateDonation = function(modules, disbursement, cb){
  var matchedDonations = disbursement.matchedDonations;
  var subCounter = matchedDonations.length;
  for(var j=0;j<matchedDonations.length;j++){
    (function(matchedDonation){
      getDonation(modules,{_id: matchedDonation.entryId},function(e, response){
        if(e){
          cb(e);
        }else{
          subCounter--;
          matchedDonation.entry = response;
          modules.logger.info(response);
          if(subCounter == 0){
            cb();
          }
        }
      });
    })(matchedDonations[j]);
  }
}

var getDonation = function(modules, query, cb){
 modules.collectionAccess.collection('donations').find(query, function(err, docs){
   cb(err, docs);
 });
}