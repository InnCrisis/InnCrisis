(function() {
  var App, DisburseCtrl, DonateCtrl, DonationsCtrl, HomeCtrl, LoginCtrl, LogoutCtrl, ManageDisbursalsCtrl, PostDisburseCtrl, RegisterCtrl, ThankYouCtrl, UserManagementCtrl;

  Kinvey.init({
    appKey: 'kid_eeg1EyERV5',
    appSecret: '513acbb1a0154665853fb9f0f4f19fe7'
  });

  App = angular.module('innCrisis', []).config(function($routeProvider, $locationProvider) {
    $locationProvider.html5Mode(true).hashPrefix('!');
    return $routeProvider.when('/', {
      templateUrl: '/partials/landing.html'
    }).when('/donate', {
      templateUrl: '/partials/donate.html',
      controller: DonateCtrl
    }).when('/thankyou', {
      templateUrl: '/partials/thankyou.html',
      controller: ThankYouCtrl
    }).when('/admin/home', {
      templateUrl: '/partials/admin/home.html',
      controller: HomeCtrl
    }).when('/admin/login', {
      templateUrl: '/partials/admin/login.html',
      controller: LoginCtrl,
      bypassLogin: true
    }).when('/admin/logout', {
      templateUrl: '/partials/admin/logout.html',
      controller: LogoutCtrl
    }).when('/admin/register', {
      templateUrl: '/partials/admin/register.html',
      controller: RegisterCtrl,
      bypassLogin: true
    }).when('/admin/disburse', {
      templateUrl: '/partials/admin/disburse.html',
      controller: DisburseCtrl
    }).when('/admin/post-disburse/:disburseId', {
      templateUrl: '/partials/admin/post-disburse.html',
      controller: PostDisburseCtrl
    }).when('/admin/manage-users', {
      templateUrl: '/partials/admin/manage-users.html',
      controller: UserManagementCtrl
    }).when('/admin/manage-disbursals', {
      templateUrl: '/partials/admin/manage-disbursals.html',
      controller: ManageDisbursalsCtrl,
      resolve: ManageDisbursalsCtrl.resolve
    }).when('/admin/view-donations', {
      templateUrl: '/partials/admin/view-donations.html',
      controller: DonationsCtrl
    }).when('/404', {
      templateUrl: '/partials/404.html'
    }).otherwise({
      templateUrl: '/partials/404.html'
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
    $rootScope.$on('$routeChangeStart', function(evt, next, current) {
      var currentPath, user, _ref;
      currentPath = $location.path();
      if (currentPath.indexOf('/admin') === 0) {
        user = Kinvey.getCurrentUser();
        if (!(user != null) && !(((_ref = next.$route) != null ? _ref.bypassLogin : void 0) != null)) {
          return $location.path('/admin/login');
        } else if ((user != null) && !(next.$route != null)) {
          return $location.path('/admin/home');
        }
      }
    });
    $rootScope.$on('$routeChangeError', function() {
      return $location.path('/404').replace();
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
  }).service('$safeRedirect', function($rootScope, $location) {
    return this.path = function(url, replace, reload) {
      if (reload || $rootScope.$$phase) {
        return window.location = url;
      } else {
        $location.path(url);
        if (replace) return $location.replace();
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

  LoginCtrl = function($scope, $safeRedirect) {
    $scope.register = function() {
      return $safeRedirect.path('/admin/register');
    };
    return $scope.login = function() {
      var user;
      user = new Kinvey.User();
      return user.login($scope.email, $scope.password, {
        success: function(user) {
          return $safeRedirect.path('/admin/home');
        },
        error: function(err) {
          $scope.error = err.description;
          return $scope.$digest();
        }
      });
    };
  };

  RegisterCtrl = function($scope, $location) {
    $scope.signIn = function() {
      return $location.path('/admin/login');
    };
    return $scope.register = function() {
      if (!($scope.email.length && $scope.password.length && $scope.name)) {
        return $scope.error = 'All form fields are required';
      } else {
        return new Kinvey.User.create({
          username: $scope.email,
          password: $scope.password,
          name: $scope.name
        }, {
          success: function(user) {
            return $location.path('/admin/home');
          },
          error: function(err) {
            $scope.error = err.description;
            return $scope.$digest();
          }
        });
      }
    };
  };

  HomeCtrl = function($scope) {
    return $scope.user = Kinvey.getCurrentUser();
  };

  LogoutCtrl = function($scope, $location) {
    var user;
    user = Kinvey.getCurrentUser();
    if (user) user.logout();
    return $location.path('/admin/login');
  };

  DisburseCtrl = function($scope, $location) {
    var user;
    user = Kinvey.getCurrentUser();
    return $scope.disburse = function() {
      var disbursement;
      disbursement = new Kinvey.Entity({
        firstName: $scope.firstName,
        lastName: $scope.lastName,
        amount: $scope.amount
      }, 'disbursements');
      return disbursement.save({
        success: function(disbursement) {
          return window.location.href = '/admin/post-disburse/' + disbursement.get('_id');
        },
        error: function(e) {
          $scope.err = e.message;
          return $scope.$digest();
        }
      });
    };
  };

  PostDisburseCtrl = function($scope, $location, $routeParams) {
    var disbursements;
    disbursements = new Kinvey.Entity({}, 'disbursements');
    return disbursements.load($routeParams.disburseId, {
      success: function(disbursement) {
        $scope.disbursement = disbursement;
        return $scope.$digest();
      },
      error: function(e) {
        $scope.err = e.message;
        return $scope.$digest();
      }
    });
  };

  UserManagementCtrl = function($scope) {
    var updateUserList;
    updateUserList = function() {
      var users;
      users = new Kinvey.Collection('user');
      return users.fetch({
        resolve: ['role'],
        success: function(list) {
          $scope.users = list;
          return $scope.$digest();
        },
        error: function(e) {
          $scope.err = e.message;
          return $scope.$digest();
        }
      });
    };
    updateUserList();
    $scope.setAccess = function(user, role, enabled) {
      var roles;
      roles = new Kinvey.Entity({}, 'roles');
      return roles.load(role, {
        success: function(role) {
          if (enabled) {
            user.set('role', role);
          } else {
            user.set('role', null);
          }
          return user.save({
            success: function(response) {
              return updateUserList();
            },
            error: function(e) {
              return $scope.err = e.message;
            }
          });
        },
        error: function(e) {
          return $scope.err = e.message;
        }
      });
    };
    $scope.hasAccess = function(user, type) {
      var role;
      role = user.get('role');
      if (role != null) {
        return role.get('_id') === type;
      } else {
        return false;
      }
    };
    return $scope.destroy = function(user) {
      if (confirm('Are you sure you want to destroy this user? You can\'t undo this.')) {
        return user.destroy({
          success: function() {
            return updateUserList();
          },
          error: function(e) {
            return $scope.err = e.message;
          }
        });
      }
    };
  };

  ManageDisbursalsCtrl = function($scope, disbursements) {
    return $scope.disbursements = disbursements;
  };

  ManageDisbursalsCtrl.resolve = {
    disbursements: function($q, $rootScope) {
      var deferred, users;
      deferred = $q.defer();
      users = new Kinvey.Collection('disbursements');
      users.fetch({
        resolve: ['role'],
        success: function(list) {
          return $rootScope.$safeApply(null, function() {
            return deferred.resolve(list);
          });
        },
        error: function(e) {
          return deferred.reject(e.message);
        }
      });
      return deferred.promise;
    }
  };

  DonationsCtrl = function($scope) {
    var updateDonations;
    updateDonations = function() {
      var donations;
      donations = new Kinvey.Collection('donations');
      return donations.fetch({
        success: function(list) {
          var entry, index;
          $scope.donations = (function() {
            var _results;
            _results = [];
            for (index in list) {
              entry = list[index];
              _results.push(entry.toJSON(true));
            }
            return _results;
          })();
          return $scope.$digest();
        },
        error: function(e) {
          $scope.err = e.message;
          return $scope.$digest();
        }
      });
    };
    return updateDonations();
  };

}).call(this);
