window.App
  .service '$users', ($q, $rootScope)->
    getById = (id, callback)->
      userEntity = new Kinvey.Entity({}, 'user');
      userEntity.load id,
        resolve: ['role'],
        success: (user)->
          callback null, user
        error: (e)->
          callback e

    @getAll = ()->
      deferred = $q.defer()
      query = new Kinvey.Query()
      query.on('name').exist()
      users = new Kinvey.Collection('user', {query: query})
      users.fetch
        resolve: ['role'],
        success: (list)->
          $rootScope.$safeApply null, ()->
            deferred.resolve  (entry.toJSON(true) for index, entry of list)
        error: (e)->
          $rootScope.$safeApply null, ()->
            deferred.reject(e)
      deferred.promise

    @setAccess = (usr, role, enabled)->
      deferred = $q.defer()
      getById usr._id , (e, user)->
        if e
          $rootScope.$safeApply null, ()->
            deferred.reject
              message: e.description
        else
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
                    deferred.resolve response.toJSON(true)
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
      role = user.role
      if role?
        role._id == type
      else
        false

    @destroy = (usr)->
      deferred = $q.defer()
      if confirm('Are you sure you want to destroy this user? You can\'t undo this.')
        getById usr._id, (e, user)->
          if e
            $rootScope.$safeApply null, ()->
              deferred.reject e
          else
            user.destroy
              success: ()->
                $rootScope.$safeApply null, ()->
                  deferred.resolve()
              error: (e)->
                $rootScope.$safeApply null, ()->
                  deferred.reject e

      deferred.promise

  .service '$donations', ($q, $rootScope)->
    @getAll = ()->
      deferred = $q.defer()
      donations = new Kinvey.Collection('donations');
      donations.fetch
        success: (list)->
          $rootScope.$safeApply null, ()->
            deferred.resolve (entry.toJSON(true) for index, entry of list)
        error: (e)->
          $rootScope.$safeApply null, ()->
            deferred.reject e
      deferred.promise
