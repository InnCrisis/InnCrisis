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

  .run ($rootScope, $safeLocation, $notification)->
    # Sometimes when we try to resolve a path we get a rejection due to security reasons or something else
    # This should be able to take the current page, stop rendering the template and render our error template
    $rootScope.$on '$routeChangeError', (event, current, previous, rejection)->
      currentPath = $safeLocation.path()
      if currentPath.indexOf('/admin') == 0
        if rejection
          $notification.error
            loaderError: true
            title: rejection.error
            message: rejection.description

        else
          $notification.error
            loaderError: true
            title: '404'
            message: 'Page not found'

    $rootScope.$on '$routeChangeStart', (evt, next, current)->
      currentPath = $safeLocation.path()
      if currentPath.indexOf('/admin') == 0
        user = Kinvey.getCurrentUser()
        if !user? and !next.$route?.bypassLogin?
          $safeLocation.path('/admin/login')

    $rootScope.$on '$routeChangeSuccess', (evt, next, current)->
      $notification.clear()


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

  $rootScope.$on '$routeChangeStart', ()->
    $scope.routes = getNavRoutes()

window.ErrorCtrl = ($scope, $rootScope)->
  $rootScope

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


UserManagementCtrl = ($scope, users, $users, $notification)->
  $scope.users = users

  $scope.setAccess = (user, role, enabled)->
    $users.setAccess(user, role, enabled)
      .then (usr)->
        user.role = usr.role
      , (err)->
        $notification.error
          message: err.message

  $scope.hasAccess = (user, type)->
    $users.hasAccess(user, type)

  $scope.destroy = (user)->
    $users.destroy(user)
      .then ()->
        $scope.users = $users.getAll()
      , (err)->
        $scope.$parent.error = err


UserManagementCtrl.resolve =
  users: ($users)->
    $users.getAll()


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
        $rootScope.$safeApply null, ()->
          deferred.reject(e)
    return deferred.promise

DonationsCtrl = ($scope, donations)->
  $scope.donations = donations

DonationsCtrl.resolve =
  donations: ($donations)->
    $donations.getAll()
