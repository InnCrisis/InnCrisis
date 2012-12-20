getRoutes = ()->
  '/admin/home':
    name: 'Home'
    security: ''
    showInNav: true
    arguments:
      templateUrl: '/partials/admin/home.html'
      controller: HomeCtrl

  '/admin/login':
    name: 'Login'
    security: ''
    showInNav: true
    arguments:
      templateUrl: '/partials/admin/login.html'
      controller: LoginCtrl
      bypassLogin: true

  '/admin/logout':
    name: 'Logout'
    security: ''
    showInNav: true
    arguments:
      templateUrl: '/partials/admin/logout.html'
      controller: LogoutCtrl

  '/admin/register':
    name: 'Register'
    security: ''
    showInNav: true
    arguments:
      templateUrl: '/partials/admin/register.html'
      controller: RegisterCtrl
      bypassLogin: true

  '/admin/disburse':
    name: 'Disburse Money'
    security: 'user'
    showInNav: true
    arguments:
      templateUrl: '/partials/admin/disburse.html'
      controller: DisburseCtrl

  '/admin/post-disburse/:disburseId':
    name: 'Post Disburse'
    security: 'user'
    arguments:
      templateUrl: '/partials/admin/post-disburse.html'
      controller: PostDisburseCtrl

  '/admin/manage-users':
    name: 'Manage Users'
    security: 'admin'
    showInNav: true
    arguments:
      templateUrl: '/partials/admin/manage-users.html'
      controller: UserManagementCtrl
      resolve: UserManagementCtrl.resolve

  '/admin/manage-disbursals':
    name: 'Manage Disbursals'
    security: 'user'
    showInNav: true
    arguments:
      templateUrl: '/partials/admin/manage-disbursals.html'
      controller: ManageDisbursalsCtrl
      resolve: ManageDisbursalsCtrl.resolve

  '/admin/view-donations':
    name: 'View Donations'
    security: 'user'
    showInNav: true
    arguments:
      templateUrl: '/partials/admin/view-donations.html'
      controller: DonationsCtrl
      resolve: DonationsCtrl.resolve

window.App
  .config ($routeProvider, $locationProvider)->
    $locationProvider.html5Mode(true).hashPrefix('!');
    # Bind routes!
    for routePath, route of getRoutes()
      $routeProvider.when routePath, route.arguments

  .run ($rootScope, $safeLocation, $location)->
    $rootScope.$on "$routeChangeError", (event, current, previous, rejection)->
      if rejection
        $rootScope.errorCode = 500
        $rootScope.errorMessage = rejection;
        $location.path '/admin/500'
      else
        $location.path '/admin/404'

    $rootScope.$on '$routeChangeStart', (evt, next, current)->
      currentPath = $location.path()
      if currentPath.indexOf('/admin') == 0
        user = Kinvey.getCurrentUser()
        if !user? and !next.$route?.bypassLogin?
          $location.path('/admin/login')

window.NavigationCtrl = ($rootScope, $scope, $location)->
  getNavRoutes = ()->
    routes = []
    for path, route of getRoutes()
      if route.showInNav?
        routes.push
          path: path
          name: route.name
          active: path == $location.path()
    routes
  $scope.routes = getNavRoutes()
  $rootScope.$on '$routeChangeSuccess', ()->
    $scope.routes = getNavRoutes()


LoginCtrl = ($scope, $safeLocation)->
  $scope.register = ()->
    $safeLocation.path '/admin/register'

  $scope.login = ()->
    user = new Kinvey.User()
    user.login $scope.email, $scope.password,
      success: (user)->
        $safeLocation.path '/admin/home'
      error: (err)->
        $scope.error = err.description
        $scope.$digest()

RegisterCtrl = ($scope, $location)->
  $scope.signIn = ()->
    $location.path '/admin/login'

  $scope.register = ()->
    unless $scope.email.length and $scope.password.length && $scope.name
      $scope.error = 'All form fields are required'
    else
      new Kinvey.User.create
        username: $scope.email
        password: $scope.password
        name: $scope.name
      ,
        success: (user)->
          $location.path '/admin/home'
        error: (err)->
          $scope.error = err.description
          $scope.$digest()

HomeCtrl = ($scope)->
  $scope.user = Kinvey.getCurrentUser()

LogoutCtrl = ($scope, $location)->
  user = Kinvey.getCurrentUser()
  if user
    user.logout()
  $location.path '/admin/login'

DisburseCtrl = ($scope, $location)->
  user = Kinvey.getCurrentUser()
  $scope.disburse = ()->
    disbursement = new Kinvey.Entity
      firstName: $scope.firstName
      lastName: $scope.lastName
      amount: $scope.amount
    , 'disbursements'
    disbursement.save
      success: (disbursement)->
        window.location.href =  '/admin/post-disburse/'+disbursement.get('_id')
      error: (e)->
        $scope.err = e.message
        $scope.$digest()

PostDisburseCtrl = ($scope, $location, $routeParams)->
  disbursements = new Kinvey.Entity {}, 'disbursements'
  disbursements.load $routeParams.disburseId,
    success: (disbursement)->
      $scope.disbursement = disbursement
      $scope.$digest()
    error: (e)->
      $scope.err = e.message
      $scope.$digest()


UserManagementCtrl = ($scope, users)->
  $scope.users = users

  $scope.setAccess = (user, role, enabled)->
    roles = new Kinvey.Entity {}, 'roles'
    roles.load role,
      success: (role)->
        if enabled
          user.set('role', role)
        else
          user.set('role', null)

        user.save
          success: (response)->
            updateUserList()

          error: (e)->
            $scope.err = e.message

      error: (e)->
        $scope.err = e.message

  $scope.hasAccess = (user, type)->
    role = user.get('role')
    if role?
      role.get('_id') == type
    else
      false

  $scope.destroy = (user)->
    if confirm('Are you sure you want to destroy this user? You can\'t undo this.')
      user.destroy
        success: ()->
          updateUserList()
        error: (e)->
          $scope.err = e.message

UserManagementCtrl.resolve =
  users: ($q, $rootScope)->
    deferred = $q.defer()
    users = new Kinvey.Collection('user')
    users.fetch
      resolve: ['role'],
      success: (list)->
        $rootScope.$safeApply null, ()->
          deferred.resolve(list)
      error: (e)->
        $rootScope.$safeApply null, ()->
          deferred.reject(e.message)
    deferred.promise


ManageDisbursalsCtrl = ($scope, disbursements)->
  $scope.disbursements = disbursements

ManageDisbursalsCtrl.resolve =
  disbursements: ($q, $rootScope)->
    deferred = $q.defer()
    users = new Kinvey.Collection('disbursements')
    users.fetch
      resolve: ['role'],
      success: (list)->
        $rootScope.$safeApply null, ()->
          deferred.resolve(list)
      error: (e)->
        deferred.reject(e.message)
    return deferred.promise

DonationsCtrl = ($scope, donations)->
  $scope.donations = donations

DonationsCtrl.resolve =
  donations: ($q, $rootScope)->
    deferred = $q.defer()
    donations = new Kinvey.Collection('donations');
    donations.fetch
      success: (list)->
        $rootScope.$safeApply null, ()->
          deferred.resolve (entry.toJSON(true) for index, entry of list)
      error: (e)->
        $rootScope.$safeApply null, ()->
          deferred.reject e.message
    deferred.promise
