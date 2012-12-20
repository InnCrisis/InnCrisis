(function() {
  var DisburseCtrl, DonationsCtrl, HomeCtrl, LoginCtrl, LogoutCtrl, ManageDisbursalsCtrl, PostDisburseCtrl, RegisterCtrl, UserManagementCtrl, getRoutes;

  getRoutes = function() {
    return {
      '/admin/home': {
        name: 'Home',
        security: '',
        showInNav: true,
        arguments: {
          templateUrl: '/partials/admin/home.html',
          controller: HomeCtrl
        }
      },
      '/admin/login': {
        name: 'Login',
        security: '',
        showInNav: true,
        arguments: {
          templateUrl: '/partials/admin/login.html',
          controller: LoginCtrl,
          bypassLogin: true
        }
      },
      '/admin/logout': {
        name: 'Logout',
        security: '',
        showInNav: true,
        arguments: {
          templateUrl: '/partials/admin/logout.html',
          controller: LogoutCtrl
        }
      },
      '/admin/register': {
        name: 'Register',
        security: '',
        showInNav: true,
        arguments: {
          templateUrl: '/partials/admin/register.html',
          controller: RegisterCtrl,
          bypassLogin: true
        }
      },
      '/admin/disburse': {
        name: 'Disburse Money',
        security: 'user',
        showInNav: true,
        arguments: {
          templateUrl: '/partials/admin/disburse.html',
          controller: DisburseCtrl
        }
      },
      '/admin/post-disburse/:disburseId': {
        name: 'Post Disburse',
        security: 'user',
        arguments: {
          templateUrl: '/partials/admin/post-disburse.html',
          controller: PostDisburseCtrl
        }
      },
      '/admin/manage-users': {
        name: 'Manage Users',
        security: 'admin',
        showInNav: true,
        arguments: {
          templateUrl: '/partials/admin/manage-users.html',
          controller: UserManagementCtrl,
          resolve: UserManagementCtrl.resolve
        }
      },
      '/admin/manage-disbursals': {
        name: 'Manage Disbursals',
        security: 'user',
        showInNav: true,
        arguments: {
          templateUrl: '/partials/admin/manage-disbursals.html',
          controller: ManageDisbursalsCtrl,
          resolve: ManageDisbursalsCtrl.resolve
        }
      },
      '/admin/view-donations': {
        name: 'View Donations',
        security: 'user',
        showInNav: true,
        arguments: {
          templateUrl: '/partials/admin/view-donations.html',
          controller: DonationsCtrl,
          resolve: DonationsCtrl.resolve
        }
      }
    };
  };

  window.App.config(function($routeProvider, $locationProvider) {
    var route, routePath, _ref, _results;
    $locationProvider.html5Mode(true).hashPrefix('!');
    _ref = getRoutes();
    _results = [];
    for (routePath in _ref) {
      route = _ref[routePath];
      _results.push($routeProvider.when(routePath, route.arguments));
    }
    return _results;
  }).run(function($rootScope, $safeLocation, $location) {
    $rootScope.$on("$routeChangeError", function(event, current, previous, rejection) {
      if (rejection) {
        $rootScope.errorCode = 500;
        $rootScope.errorMessage = rejection;
        return $location.path('/admin/500');
      } else {
        return $location.path('/admin/404');
      }
    });
    return $rootScope.$on('$routeChangeStart', function(evt, next, current) {
      var currentPath, user, _ref;
      currentPath = $location.path();
      if (currentPath.indexOf('/admin') === 0) {
        user = Kinvey.getCurrentUser();
        if (!(user != null) && !(((_ref = next.$route) != null ? _ref.bypassLogin : void 0) != null)) {
          return $location.path('/admin/login');
        }
      }
    });
  });

  window.NavigationCtrl = function($rootScope, $scope, $location) {
    var getNavRoutes;
    getNavRoutes = function() {
      var path, route, routes, _ref;
      routes = [];
      _ref = getRoutes();
      for (path in _ref) {
        route = _ref[path];
        if (route.showInNav != null) {
          routes.push({
            path: path,
            name: route.name,
            active: path === $location.path()
          });
        }
      }
      return routes;
    };
    $scope.routes = getNavRoutes();
    return $rootScope.$on('$routeChangeSuccess', function() {
      return $scope.routes = getNavRoutes();
    });
  };

  LoginCtrl = function($scope, $safeLocation) {
    $scope.register = function() {
      return $safeLocation.path('/admin/register');
    };
    return $scope.login = function() {
      var user;
      user = new Kinvey.User();
      return user.login($scope.email, $scope.password, {
        success: function(user) {
          return $safeLocation.path('/admin/home');
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

  UserManagementCtrl = function($scope, users) {
    $scope.users = users;
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

  UserManagementCtrl.resolve = {
    users: function($q, $rootScope) {
      var deferred, users;
      deferred = $q.defer();
      users = new Kinvey.Collection('user');
      users.fetch({
        resolve: ['role'],
        success: function(list) {
          return $rootScope.$safeApply(null, function() {
            return deferred.resolve(list);
          });
        },
        error: function(e) {
          return $rootScope.$safeApply(null, function() {
            return deferred.reject(e.message);
          });
        }
      });
      return deferred.promise;
    }
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

  DonationsCtrl = function($scope, donations) {
    return $scope.donations = donations;
  };

  DonationsCtrl.resolve = {
    donations: function($q, $rootScope) {
      var deferred, donations;
      deferred = $q.defer();
      donations = new Kinvey.Collection('donations');
      donations.fetch({
        success: function(list) {
          return $rootScope.$safeApply(null, function() {
            var entry, index;
            return deferred.resolve((function() {
              var _results;
              _results = [];
              for (index in list) {
                entry = list[index];
                _results.push(entry.toJSON(true));
              }
              return _results;
            })());
          });
        },
        error: function(e) {
          return $rootScope.$safeApply(null, function() {
            return deferred.reject(e.message);
          });
        }
      });
      return deferred.promise;
    }
  };

}).call(this);
