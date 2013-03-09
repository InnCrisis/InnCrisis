Kinvey.init({
    appKey: 'kid_eeg1EyERV5',
    appSecret: '513acbb1a0154665853fb9f0f4f19fe7'
});

window.App = App = angular.module('innCrisis', [])
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

      .otherwise
        templateUrl: '/partials/error.html'
        controller: ErrorCtrl

  .filter 'moment', ()->
    return (dateString, format)->
      if dateString
        moment.unix(dateString).format(format)
      else
        ''
  .run ($rootScope, $location)->
    $rootScope.$on "$routeChangeError", (event, current, previous, rejection)->
      currentPath = $location.path()
      if currentPath.indexOf('/admin') == -1
        if rejection
          $rootScope.errorCode = 500
          $rootScope.errorMessage = rejection;
          $location.path('/500').replace()
        else
          $location.path('/404').replace()

    $rootScope.$safeApply = ($scope, fn = ->)->
      $scope = $scope || $rootScope;
      if($scope.$$phase)
        fn();
      else
        $scope.$apply(fn);



DonateCtrl = ($scope)->
  $scope.donate = ()->
    query = new Kinvey.Query()
    query.on('amount').equal( $scope.donationAmount )
    query.on('redirectURI').equal( "#{window.location.origin}/thankyou" )

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

ErrorCtrl = ($rootScope, $scope)->
  if $rootScope.errorCode
    $scope.errorCode = $rootScope.errorCode
    delete $rootScope.errorCode

  if $rootScope.errorMessage
    $scope.errorMessage = $rootScope.errorMessage
    delete $rootScope.errorMessage

  if !$scope.errorCode
    $scope.errorCode = 404
    $scope.errorMessage = "Page not found";