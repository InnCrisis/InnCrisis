(function() {
  var AdminHome, DonateCtrl, LoginCtrl, RegisterCtrl, ThankYouCtrl;

  Kinvey.init({
    appKey: 'kid_eeg1EyERV5',
    appSecret: '513acbb1a0154665853fb9f0f4f19fe7'
  });

  angular.module('innCrisis', []).config(function($routeProvider, $locationProvider) {
    $locationProvider.html5Mode(true).hashPrefix('!');
    return $routeProvider.when('/', {
      templateUrl: 'partials/landing.html'
    }).when('/donate', {
      templateUrl: 'partials/donate.html',
      controller: DonateCtrl
    }).when('/thankyou', {
      templateUrl: 'partials/thankyou.html',
      controller: ThankYouCtrl
    }).when('/admin/home', {
      templateUrl: 'partials/admin/home.html',
      controller: AdminHome
    }).when('/admin/login', {
      templateUrl: 'partials/admin/login.html',
      controller: LoginCtrl,
      adminWhitelist: true
    }).when('/admin/register', {
      templateUrl: 'partials/admin/register.html',
      controller: RegisterCtrl,
      adminWhitelist: true
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
  }).run(function($rootScope, $location) {
    return $rootScope.$on('$routeChangeStart', function(evt, next, current) {
      console.log($location.path());
      return $location.path('/admin/login');
    });
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

  LoginCtrl = function($scope, $location) {
    $scope.register = function() {
      return $location.path('/admin/register');
    };
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

  RegisterCtrl = function($scope, $location) {
    $scope.signIn = function() {
      return $location.path('/admin/login');
    };
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

  AdminHome = function($scope) {
    return console.log('Yay Admin Home!');
  };

}).call(this);
