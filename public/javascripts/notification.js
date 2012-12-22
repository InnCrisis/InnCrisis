
  window.App.service('$notification', function($rootScope) {
    var clear, notificationTimeout, showNotification;
    notificationTimeout = {};
    clear = this.clear = function() {
      clearTimeout(notificationTimeout);
      return $rootScope.$safeApply(null, function() {
        return delete $rootScope.notification;
      });
    };
    this.error = function(opts) {
      opts["class"] = 'alert-error';
      return showNotification(opts);
    };
    return showNotification = function(opts) {
      var displayClass, _ref;
      clearTimeout(notificationTimeout);
      displayClass = opts["class"];
      if (!(opts.loaderError != null)) displayClass += ' notification';
      $rootScope.$safeApply(null, function() {
        return $rootScope.notification = {
          "class": displayClass,
          title: opts.title,
          message: opts.message,
          loaderError: opts.loaderError != null
        };
      });
      if ((_ref = opts.duration) == null) opts.duration = 2000;
      if (opts.duration !== false && !opts.loaderError) {
        return notificationTimeout = setTimeout(function() {
          return clear();
        }, opts.duration);
      }
    };
  });
