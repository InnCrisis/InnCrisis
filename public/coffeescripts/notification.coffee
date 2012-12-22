window.App
  .service '$notification', ($rootScope)->
    notificationTimeout = {}
    clear = @clear = ()->
      clearTimeout notificationTimeout
      $rootScope.$safeApply null, ()->
        delete $rootScope.notification

    @error = (opts)->
      opts.class = 'alert-error'
      showNotification(opts)

    showNotification = (opts)->
      clearTimeout notificationTimeout
      displayClass = opts.class
      if !opts.loaderError?
        displayClass += ' notification'

      $rootScope.$safeApply null, ()->
        $rootScope.notification =
          class: displayClass
          title: opts.title
          message: opts.message
          loaderError: opts.loaderError?

      opts.duration ?= 2000

      if opts.duration != false and !opts.loaderError
        notificationTimeout = setTimeout ()->
          clear()
        , opts.duration
