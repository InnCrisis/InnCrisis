(function() {
  var DonateCtrl;

  Kinvey.init({
    appKey: 'kid_eeg1EyERV5',
    appSecret: '513acbb1a0154665853fb9f0f4f19fe7'
  });

  angular.module('innCrisis', []).config(function($routeProvider, $locationProvider) {
    $locationProvider.html5Mode(true).hashPrefix('!');
    return $routeProvider.when('/', {
      templateUrl: 'templates/landing.html'
    }).when('/donate', {
      templateUrl: 'templates/donate.html',
      controller: DonateCtrl
    }).otherwise({
      redirectTo: '/'
    });
  });

  DonateCtrl = function($scope) {
    return $scope.donate = function() {
      var query, wepay;
      query = new Kinvey.Query();
      query.on('amount').equal($scope.donationAmount);
      wepay = new Kinvey.Collection('WePay', {
        query: query
      });
      return wepay.fetch({
        success: function(response) {
          return window.location.href = response[0].get('checkout_uri');
        },
        error: function(error) {
          console.log('ERROR');
          return console.log(error);
        }
      });
    };
  };

}).call(this);
