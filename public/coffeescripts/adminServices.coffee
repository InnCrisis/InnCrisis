window.App
  .service '$safeLocation', ($rootScope, $location)->
    @path = (url, replace, reload)->
      if !url?
        $location.path()
      else
        if(reload || $rootScope.$$phase)
          console.log 'PHASE'
          window.location = url;
        else
          $rootScope.$safeApply null, ()->
            $location.path url
            if replace
              $location.replace()

  .service '$users', ($q, $rootScope)->
    getById = (id, callback)->
      userEntity = new Kinvey.Entity({}, 'user');
      userEntity.load id,
        resolve: ['role'],
        success: (user)->
          callback null, user
        error: (e)->
          callback e

    @get = ()->
      Kinvey.getCurrentUser().toJSON(true)

    @register = (username, password, name)->
      deferred = $q.defer()
      new Kinvey.User.create
        username: username
        password: password
        name: name
      ,
        success: (user)->
          $rootScope.$safeApply null, ()->
            deferred.resolve user.toJSON(true)
        error: (e)->
          $rootScope.$safeApply null, ()->
            deferred.reject e

      deferred.promise

    @login = (username, password)->
      deferred = $q.defer()
      user = new Kinvey.User()
      user.login $scope.email, $scope.password,
        success: (user)->
          $rootScope.$safeApply null, ()->
            deferred.resolve user.toJSON(true)
        error: (e)->
          $rootScope.$safeApply null, ()->
            deferred.reject e
      deferred.promise

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
            deferred.reject e
      deferred.promise

    @setRole = (usr, role, enabled)->
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

    @isRole = (user, type)->
      role = user.role
      if role?
        role._id == type
      else
        false


    roleCache = {}
    @hasAccess = (user, type)->
      deferred = $q.defer()
      if user.role?
        if user.role._id == type
          deferred.resolve true
        else
          cacheString = user.role._id+type

          # If we don't have this request cached for this round then update it
          if !roleCache[cacheString]
            roleCache[cacheString] = deferred
            # We need to look up the role inheritence
            roles = new Kinvey.Entity {}, 'roles',
              store: 'cached'
              options:
                policy: 'cachefirst'

            roles.load user.role._id,
              success: (role)->
                roleCache[user.role._id] = role
                $rootScope.$safeApply null, ()->
                  deferred.resolve role.get('inherits') == type
              error: (e)->
                $rootScope.$safeApply null, ()->
                  deferred.reject
                    message: e.description
          else # Hey look, we have a request processing for this role right now
            deferred = roleCache[cacheString]

      else
        deferred.resolve false
      deferred.promise

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

  .service '$disbursements', ($q, $rootScope)->
    @getById = (id)->
      deferred = $q.defer()
      disbursements = new Kinvey.Entity {}, 'disbursements'
      disbursements.load id,
        success: (disbursement)->
          $rootScope.$safeApply null, ()->
            deferred.resolve disbursement.toJSON(true)
        error: (e)->
          $rootScope.$safeApply null, ()->
            deferred.reject e

      deferred.promise

    @getAll = ()->
      deferred = $q.defer()
      disbursements = new Kinvey.Collection('disbursements')
      disbursements.fetch
        resolve: ['role'],
        success: (list)->
          $rootScope.$safeApply null, ()->
            deferred.resolve (entry.toJSON(true) for index, entry of list)
        error: (e)->
          $rootScope.$safeApply null, ()->
            deferred.reject(e)
      deferred.promise

    @create = (disbursement)->
      deferred = $q.defer()
      kDisbursement = new Kinvey.Entity
        firstName: $scope.firstName
        lastName: $scope.lastName
        amount: $scope.amount
      , 'disbursements'

      kDisbursement.save
        success: (kDisbursement)->
          $rootScope.$safeApply null, ()->
            deferred.resolve kDisbursement.toJSON(true)
        error: (e)->
          $rootScope.$safeApply null, ()->
            deferred.reject(e)

      deferred.promise
