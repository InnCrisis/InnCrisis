Kinvey.init({
    appKey: 'kid_eeg1EyERV5',
    appSecret: '513acbb1a0154665853fb9f0f4f19fe7'
});

angular.module('innCrisis', [])
  .config ($routeProvider, $locationProvider)->
    $locationProvider.html5Mode(true).hashPrefix('!');
    $routeProvider
      .when '/',
        templateUrl: 'partials/landing.html'

      .when '/donate',
        templateUrl: 'partials/donate.html'
        controller: DonateCtrl

      .when '/thankyou',
        templateUrl: 'partials/thankyou.html'
        controller: ThankYouCtrl

      .when '/admin/home',
        templateUrl: 'partials/admin/home.html'
        controller: AdminHome

      .when '/admin/login',
        templateUrl: 'partials/admin/login.html'
        controller: LoginCtrl
        bypassLogin: true

      .when '/admin/register',
        templateUrl: 'partials/admin/register.html'
        controller: RegisterCtrl
        bypassLogin: true

      .when '/admin',
        templateUrl: 'partials/admin/login.html'
        controller: LoginCtrl

      .when '/admin/*',
        templateUrl: 'partials/admin/login.html'
        controller: LoginCtrl

      .otherwise
        redirectTo: '/'

  .filter 'moment', ()->
    return (dateString, format)->
      if dateString
        moment.unix(dateString).format(format)
      else
        ''
  .run ($rootScope, $location)->
    $rootScope.$on '$routeChangeStart', (evt, next, current)->
      currentPath = $location.path()

      if currentPath.indexOf('/admin') == 0
        user =  Kinvey.getCurrentUser()
        if user
          user.logout()
        user = Kinvey.getCurrentUser()

        if user == null and !next.$route?.bypassLogin?
          console.log 'redirect'
#          $location.path('/admin/login')
        else if user == null
          console.log 'Route bypassed'


DonateCtrl = ($scope)->
  $scope.donate = ()->
    query = new Kinvey.Query()
    query.on('amount').equal( $scope.donationAmount )
    query.on('redirectURI').equal( 'http://kinvey.dev:3000/thankyou' )

    wepay = new Kinvey.Collection 'WePay',
      query: query

    wepay.fetch
      success: (response)->
        window.location.href = response[0].get('checkout_uri')
      error: (error)->
        console.log 'ERROR'
        console.log error


ThankYouCtrl = ($scope)->
  $scope.loading = true
  checkoutId = window.location.search.replace('?checkout_id=','')
  query = new Kinvey.Query()
  query.on('checkoutId').equal( checkoutId )

  wepay = new Kinvey.Collection 'WePayDonations',
    query: query

  wepay.fetch
    success: (response)->
      $scope.loading = false
      $scope.donation = response[0].attr
      $scope.$digest()

    error: (error)->
      console.log 'ERROR'
      console.log error




############################################
##
## ADMIN Section
##
############################################

LoginCtrl = ($scope, $location)->
  $scope.register = ()->
    $location.path '/admin/register'

  $scope.login = ()->
    user = new Kinvey.User()
    user.login $scope.email, $scope.password,
      success: (user)->
        console.log user
      error: (err)->
        $scope.error = err.description

RegisterCtrl = ($scope, $location)->
  $scope.signIn = ()->
    $location.path '/admin/login'

  $scope.register = ()->
    new Kinvey.User.create
      username: $scope.email
      password: $scope.password
      name: $scope.name
    ,
      success: (user)->
        console.log user
      error: (err)->
        $scope.registerError = err.description

AdminHome = ($scope)->
  console.log 'Yay Admin Home!'