function onPostFetch(request,response,modules){
	var donations = response.body;
  if(donations.length){
    populateDisbersements(modules, donations, function(e, newDonations){
      if(e){
        response.continue();
      }else{
        response.body = newDonations;
        response.continue();
      }
    });
  }else{
    response.continue();
  }
}

var populateDisbersements = function(modules, donations, cb){
  if(donations.length){
    var counter = donations.length;
    for(var i=0;i<donations.length;i++){
      populateDisbersment(modules, donations[i], function(e){
        if(e){
          cb(e);
        }else{
          counter--;
          if(counter == 0){
            cb(null, donations);
          }
        }
      });
    }
  }
}

var populateDisbersment = function(modules, donation, cb){
  var matchedDisburals = donation.matchedDisbursals;
  if(matchedDisburals){
    var subCounter = matchedDisburals.length;
    for(var j=0;j<matchedDisburals.length;j++){
      (function(matchedDisbursal){
        getDisbursal(modules,{_id: matchedDisbursal.entryId},function(e, response){
          if(e){
            cb(e);
          }else{
            subCounter--;
            matchedDisbursal.entry = response;
            if(subCounter == 0){
              cb();
            }
          }
        });
      })(matchedDisburals[j]);
    }
  }else{
    cb();
  }
}

var getDisbursal = function(modules, query, cb){
  modules.logger.info(query);
  modules.collectionAccess.collection('disbursals').find(query, function(err, docs){
     cb(err, docs);
  });
}