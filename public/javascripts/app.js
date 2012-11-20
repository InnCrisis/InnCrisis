(function() {
  var DonateCtrl, LoginCtrl, RegisterCtrl, ThankYouCtrl;

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
    }).when('/thankyou', {
      templateUrl: 'templates/thankyou.html',
      controller: ThankYouCtrl
    }).when('/admin', {
      templateUrl: 'templates/login.html',
      controller: LoginCtrl
    }).when('/register', {
      templateUrl: 'templates/register.html',
      controller: RegisterCtrl
    }).otherwise({
      redirectTo: '/'
    });
  }).filter('moment', function() {
    return function(dateString, format) {
      if (dateString) {
        return moment.unix(dateString).format(format);
      } else {
        return '';
      }
    };
  });

  DonateCtrl = function($scope) {
    return $scope.donate = function() {
      var query, wepay;
      query = new Kinvey.Query();
      query.on('amount').equal($scope.donationAmount);
      query.on('redirectURI').equal('http://kinvey.dev:3000/thankyou');
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

  ThankYouCtrl = function($scope) {
    var checkoutId, query, wepay;
    $scope.loading = true;
    checkoutId = window.location.search.replace('?checkout_id=', '');
    query = new Kinvey.Query();
    query.on('checkoutId').equal(checkoutId);
    wepay = new Kinvey.Collection('WePayDonations', {
      query: query
    });
    return wepay.fetch({
      success: function(response) {
        $scope.loading = false;
        $scope.donation = response[0].attr;
        return $scope.$digest();
      },
      error: function(error) {
        console.log('ERROR');
        return console.log(error);
      }
    });
  };

  LoginCtrl = function($scope) {
    return $scope.login = function() {
      var user;
      user = new Kinvey.User();
      return user.login($scope.email, $scope.password, {
        success: function(user) {
          return console.log(user);
        },
        error: function(err) {
          return $scope.error = err.description;
        }
      });
    };
  };

  RegisterCtrl = function($scope) {
    return $scope.register = function() {
      return new Kinvey.User.create({
        username: $scope.email,
        password: $scope.password,
        name: $scope.name
      }, {
        success: function(user) {
          return console.log(user);
        },
        error: function(err) {
          return $scope.registerError = err.description;
        }
      });
    };
  };

}).call(this);
