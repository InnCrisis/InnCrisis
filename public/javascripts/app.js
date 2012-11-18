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
      query.on('amount').equal(20);
      wepay = new Kinvey.Collection('WePay');
      return wepay.fetch({
        success: function() {
          return console.log(arguments);
        },
        error: function(error) {
          console.log('ERROR');
          return console.log(error);
        }
      });
    };
  };

}).call(this);
