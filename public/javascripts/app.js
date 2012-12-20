(function() {
  var App, DonateCtrl, ErrorCtrl, ThankYouCtrl;

  Kinvey.init({
    appKey: 'kid_eeg1EyERV5',
    appSecret: '513acbb1a0154665853fb9f0f4f19fe7'
  });

  window.App = App = angular.module('innCrisis', []).config(function($routeProvider, $locationProvider) {
    $locationProvider.html5Mode(true).hashPrefix('!');
    return $routeProvider.when('/', {
      templateUrl: '/partials/landing.html'
    }).when('/donate', {
      templateUrl: '/partials/donate.html',
      controller: DonateCtrl
    }).when('/thankyou', {
      templateUrl: '/partials/thankyou.html',
      controller: ThankYouCtrl
    }).otherwise({
      templateUrl: '/partials/error.html',
      controller: ErrorCtrl
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
    $rootScope.$on("$routeChangeError", function(event, current, previous, rejection) {
      if (rejection) {
        $rootScope.errorCode = 500;
        $rootScope.errorMessage = rejection;
        return $location.path('/500').replace();
      } else {
        return $location.path('/404').replace();
      }
    });
    return $rootScope.$safeApply = function($scope, fn) {
      $scope = $scope || $rootScope;
      fn = fn || function() {};
      if ($scope.$$phase) {
        return fn();
      } else {
        return $scope.$apply(fn);
      }
    };
  }).service('$safeLocation', function($rootScope, $location) {
    return this.path = function(url, replace, reload) {
      if (url != null) {
        return $location.path();
      } else {
        if (reload || $rootScope.$$phase) {
          return window.location = url;
        } else {
          $location.path(url);
          if (replace) $location.replace();
          return $rootScope.$apply();
        }
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
    var checkoutId, donation, query;
    $scope.loading = true;
    checkoutId = window.location.search.replace('?checkout_id=', '');
    query = new Kinvey.Query();
    query.on('checkoutId').equal(checkoutId);
    donation = new Kinvey.Entity({
      _id: checkoutId
    }, 'donations');
    return donation.save({
      success: function(savedDonation) {
        $scope.loading = false;
        $scope.donation = savedDonation.toJSON(true);
        return $scope.$digest();
      },
      error: function(error) {
        console.log('Error Saving Donation', error);
        $scope.err = error.message;
        return $scope.digest();
      }
    });
  };

  ErrorCtrl = function($rootScope, $scope) {
    if ($rootScope.errorCode) {
      $scope.errorCode = $rootScope.errorCode;
      delete $rootScope.errorCode;
    }
    if ($rootScope.errorMessage) {
      $scope.errorMessage = $rootScope.errorMessage;
      delete $rootScope.errorMessage;
    }
    if (!$scope.errorCode) {
      $scope.errorCode = 404;
      return $scope.errorMessage = "Page not found";
    }
  };

}).call(this);
