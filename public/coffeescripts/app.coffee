Kinvey.init({
    appKey: 'kid_eeg1EyERV5',
    appSecret: '513acbb1a0154665853fb9f0f4f19fe7'
});

angular.module('innCrisis', [])
  .config ($routeProvider, $locationProvider)->
    $locationProvider.html5Mode(true).hashPrefix('!');
    $routeProvider
      .when '/',
        templateUrl: 'templates/landing.html'
      .when '/donate',
        templateUrl: 'templates/donate.html'
        controller: DonateCtrl
      .otherwise
        redirectTo: '/'


DonateCtrl = ($scope)->
  $scope.donate = ()->
    query = new Kinvey.Query()
    query.on('amount').equal(20)

    wepay = new Kinvey.Collection 'WePay'
#      query: query
#

    wepay.fetch
      success: ()->
        console.log arguments
      error: (error)->
        console.log 'ERROR'
        console.log error