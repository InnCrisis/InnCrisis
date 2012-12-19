Kinvey.init({
    appKey: 'kid_eeg1EyERV5',
    appSecret: '513acbb1a0154665853fb9f0f4f19fe7'
});

angular.module('innCrisis', [])
  .config ($routeProvider, $locationProvider)->
    $locationProvider.html5Mode(true).hashPrefix('!');
    $routeProvider
      .when '/',
        templateUrl: '/partials/landing.html'

      .when '/donate',
        templateUrl: '/partials/donate.html'
        controller: DonateCtrl

      .when '/thankyou',
        templateUrl: '/partials/thankyou.html'
        controller: ThankYouCtrl

      .when '/admin/home',
        templateUrl: '/partials/admin/home.html'
        controller: HomeCtrl

      .when '/admin/login',
        templateUrl: '/partials/admin/login.html'
        controller: LoginCtrl
        bypassLogin: true

      .when '/admin/logout',
        templateUrl: '/partials/admin/logout.html'
        controller: LogoutCtrl

      .when '/admin/register',
        templateUrl: '/partials/admin/register.html'
        controller: RegisterCtrl
        bypassLogin: true

      .when '/admin/disburse',
        templateUrl: '/partials/admin/disburse.html'
        controller: DisburseCtrl

      .when '/admin/post-disburse/:disburseId',
        templateUrl: '/partials/admin/post-disburse.html'
        controller: PostDisburseCtrl

      .when '/admin/manage-users',
        templateUrl: '/partials/admin/manage-users.html'
        controller: UserManagementCtrl

      .when '/admin/manage-disbursals'
        templateUrl: '/partials/admin/manage-disbursals.html'
        controller: ManageDisbursalsCtrl

      .when '/admin/view-donations',
        templateUrl: '/partials/admin/view-donations.html'
        controller: DonationsCtrl

      .otherwise
        templateUrl: '/partials/404.html'

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
        user = Kinvey.getCurrentUser()

        if !user? and !next.$route?.bypassLogin?
          $location.path('/admin/login')
        else if user? and !next.$route?
          $location.path('/admin/home')



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

  donation = new Kinvey.Entity
    _id: checkoutId
    , 'donations'
  donation.save
    success: (savedDonation)->
      $scope.loading = false
      $scope.donation = savedDonation.toJSON(true)
      $scope.$digest()

    error: (error)->
      console.log 'Error Saving Donation', error
      $scope.err = error.message
      $scope.digest()




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
        $location.path '/admin/home'
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


UserManagementCtrl = ($scope)->
  updateUserList = ()->
    users = new Kinvey.Collection('user')
    users.fetch
      resolve: ['role'],
      success: (list)->
        $scope.users = list
        $scope.$digest()
      error: (e)->
        $scope.err = e.message
        $scope.$digest()
  updateUserList()

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

ManageDisbursalsCtrl = ($scope)->
  updateDisbursals = ()->
    users = new Kinvey.Collection('disbursements')
    users.fetch
      resolve: ['role'],
      success: (list)->
        $scope.disbursements = list
        $scope.$digest()
      error: (e)->
        $scope.err = e.message
        $scope.$digest()
  updateDisbursals()

DonationsCtrl = ($scope)->
  updateDonations = ()->
    donations = new Kinvey.Collection('donations');
    donations.fetch
      success: (list)->
        $scope.donations = (entry.toJSON(true) for index, entry of list)
        $scope.$digest()
      error: (e)->
        $scope.err = e.message
        $scope.$digest()
  updateDonations()