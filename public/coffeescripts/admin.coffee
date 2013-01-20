getRoutes = ()->
  '/admin/home':
    name: 'Home'
    arguments:
      templateUrl: '/partials/admin/home.html'
      controller: HomeCtrl
      resolve: HomeCtrl.resolve

  '/admin/login':
    name: 'Login'
    showIfLoggedIn: false
    arguments:
      templateUrl: '/partials/admin/login.html'
      controller: LoginCtrl
      bypassLogin: true

  '/admin/logout':
    name: 'Logout'
    showIfLoggedIn: true
    arguments:
      templateUrl: '/partials/admin/logout.html'
      controller: LogoutCtrl

  '/admin/register':
    name: 'Register'
    showIfLoggedIn: false
    arguments:
      templateUrl: '/partials/admin/register.html'
      controller: RegisterCtrl
      bypassLogin: true

  '/admin/disburse':
    name: 'Disburse Money'
    security: 'user'
    arguments:
      templateUrl: '/partials/admin/disburse.html'
      controller: DisburseCtrl

  '/admin/post-disburse/:disburseId':
    name: 'Post Disburse'
    security: 'user'
    showInNav: false
    arguments:
      templateUrl: '/partials/admin/post-disburse.html'
      controller: PostDisburseCtrl
      resolve: PostDisburseCtrl.resolve

  '/admin/manage-users':
    name: 'Manage Users'
    security: 'admin'
    arguments:
      templateUrl: '/partials/admin/manage-users.html'
      controller: UserManagementCtrl
      resolve: UserManagementCtrl.resolve

  '/admin/manage-disbursals':
    name: 'Manage Disbursals'
    security: 'user'
    arguments:
      templateUrl: '/partials/admin/manage-disbursals.html'
      controller: ManageDisbursalsCtrl
      resolve: ManageDisbursalsCtrl.resolve

  '/admin/view-donations':
    name: 'View Donations'
    security: 'admin'
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

  .run ($rootScope, $safeLocation, $notification, $users)->
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
        user = $users.get()
        if !user? and !next.$route?.bypassLogin?
          $safeLocation.path('/admin/login')

    $rootScope.$on '$routeChangeSuccess', (evt, next, current)->
      $notification.clear()


window.NavigationCtrl = ($rootScope, $scope, $location, $users)->
  getNavRoutes = (loading = false)->
    user = $users.get()
    routes = []
    for path, route of getRoutes()
      route.security ?= ''
      route.showIfLoggedIn ?= true
      route.showInNav ?= true

      showIfLoggedInCheck = false
      if user
        if route.showIfLoggedIn
          showIfLoggedInCheck = true
        else
          showIfLoggedInCheck = false
      else
        if route.showIfLoggedIn
          showIfLoggedInCheck = false
        else
          showIfLoggedInCheck = true

      securityCheck = false
      if route.security.length
        if user
          securityCheck = $users.hasAccess user, route.security
      else
        securityCheck = true

      if route.showInNav and showIfLoggedInCheck and securityCheck
        routes.push
          path: path
          name: route.name
          active: path == $location.path()
          loading: loading

    routes
  $scope.routes = getNavRoutes()

  $rootScope.$on '$routeChangeStart', ()->
    $scope.routes = getNavRoutes(true)

  $rootScope.$on '$routeChangeSuccess', ()->
    $scope.routes = getNavRoutes(false)

  $rootScope.$on '$routeChangeError', ()->
    $scope.routes = getNavRoutes(false)


LoginCtrl = ($scope, $safeLocation, $users)->
  $scope.register = ()->
    $safeLocation.path '/admin/register'

  $scope.login = ()->
    $users.login($scope.email, $scope.password)
      .then (user)->
        $safeLocation.path '/admin/home'
      , (err)->
        $scope.error = err.description
        $scope.$digest()

RegisterCtrl = ($scope, $safeLocation, $users)->
  $scope.signIn = ()->
    $safeLocation.path '/admin/login'

  $scope.register = ()->
    unless $scope.email.length and $scope.password.length && $scope.name
      $scope.error = 'All form fields are required'
    else
      $users.register($scope.email, $scope.password, $scope.name)
        .then ()->
          $safeLocation.path '/admin/home'
        , (e)->
          $scope.$safeApply $scope, ()->
            $scope.error = e.description

HomeCtrl = ($scope, user)->
  $scope.user = user

HomeCtrl.resolve =
  user: ($users)->
    $users.get()

LogoutCtrl = ($scope, $safeLocation, $users)->
  $users.logout()
  $safeLocation.path '/admin/login'

DisburseCtrl = ($scope, $safeLocation, $disbursements, $notification)->
  $scope.disburse = ()=>
    disbursement =
      firstName: $scope.firstName
      lastName: $scope.lastName
      amount: $scope.amount

    $disbursements.create(disbursement)
      .then (disbursement)->
        console.log 'Disbursement Ctrl', disbursement
#        $safeLocation.path '/admin/post-disburse/'+disbursement._id
      ,(e)->
        $notification.error
          message: e.description

PostDisburseCtrl = ($scope, $routeParams, disbursement)->
  $scope.disbursement = disbursement

PostDisburseCtrl.resolve =
  disbursement: ($route, $disbursements)->
    $disbursements.getById($route.current.params.disburseId)

UserManagementCtrl = ($scope, users, $users, $notification)->
  $scope.users = users

  $scope.setRole = (user, role, enabled)->
    $users.setRole(user, role, enabled)
      .then (usr)->
        user.role = usr.role
      , (err)->
        $notification.error
          message: err.message

  $scope.isRole = (user, type)->
    $users.isRole(user, type)

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
  disbursements: ($disbursements)->
    $disbursements.getAll()


DonationsCtrl = ($scope, donations)->
  $scope.donations = donations

DonationsCtrl.resolve =
  donations: ($donations)->
    $donations.getAll()
