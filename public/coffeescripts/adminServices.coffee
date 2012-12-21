window.App
  .service '$users', ($q, $rootScope)->
    @getAll = ()->
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

    @setAccess = (user, role, enabled)->
      deferred = $q.defer()
      roles = new Kinvey.Entity {}, 'roles'
      roles.load role,
        success: (role)->
          if enabled
            user.set('role', role)
          else
            user.set('role', null)

          user.save
            success: (response)->
              $rootScope.$safeApply null, ()->
                deferred.resolve()
            error: (e)->
              $rootScope.$safeApply null, ()->
                deferred.reject
                  message: e.description

        error: (e)->
          $rootScope.$safeApply null, ()->
            deferred.reject
              message: e.description

      deferred.promise

    @hasAccess = (user, type)->
      role = user.get('role')
      if role?
        role.get('_id') == type
      else
        false

    @destroy = (user)->
      deferred = $q.defer()
      if confirm('Are you sure you want to destroy this user? You can\'t undo this.')
        user.destroy
          success: ()->
            $rootScope.$safeApply null, ()->
              deferred.resolve()
          error: (e)->
            $rootScope.$safeApply null, ()->
              deferred.reject(e)
      deferred.promise
