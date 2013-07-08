###
@module emberella
@submodule emberella-mixins
###

Emberella = window.Emberella
get = Ember.get
set = Ember.set
typeOf = Ember.typeOf

Emberella.MQStateManager = Ember.StateManager.extend
  initialState: 'queued'

  retries: 0

  invokeQueueCallback: (message) ->
    queueItem = get @, 'queueItem'
    queue = get queueItem, 'queue'
    privateFn = '_' + message
    if queue?
      queue[privateFn].call queue, queueItem if typeOf(queue[privateFn]) is 'function'
      queue[message].call queue, queueItem if typeOf(queue[message]) is 'function'

  queued: Ember.State.create
    isQueueItemWaiting: true

    enter: (manager) ->
      manager.invokeQueueCallback 'didAddQueueItem'

    activate: (manager) ->
      manager.transitionTo('active')

    didError: (manager) ->
      manager.transitionTo('error')

  active: Ember.State.create
    isQueueItemInProgress: true

    enter: (manager) ->
      manager.invokeQueueCallback 'didActivateQueueItem'

    finish: (manager) ->
      manager.transitionTo('completed')

    didError: (manager) ->
      manager.transitionTo('error')

  completed: Ember.State.create
    isQueueItemComplete: true

    enter: (manager) ->
      manager.invokeQueueCallback 'didCompleteQueueItem'

    didError: Ember.K

  error: Ember.State.create
    isQueueItemError: true

    enter: (manager) ->
      manager.invokeQueueCallback 'didQueueItemError'

    retry: (manager) ->
      manager.invokeQueueCallback 'willRetryQueueItem'
      manager.incrementProperty('retries')
      manager.transitionTo('queued')

    didError: (manager) ->
      manager.transitionTo('error')

retrieveFromCurrentState = Ember.computed((key, value) ->
  !!get(get(@, 'mqStateManager.currentState'), key)
).property('mqStateManager.currentState').readOnly()

Emberella.MQItem = Ember.ObjectProxy.extend
  isQueueableItem: true
  mqStateManager: null

  retriesBinding: 'mqStateManager.retries'

  isQueueItemWaiting: retrieveFromCurrentState
  isQueueItemInProgress: retrieveFromCurrentState
  isQueueItemComplete: retrieveFromCurrentState
  isQueueItemError: retrieveFromCurrentState

  init: ->
    @_super()

    stateManager = stateManager = Emberella.MQStateManager.create queueItem: @
    set(this, 'mqStateManager', stateManager)

  send: (name, context) ->
    get(@, 'mqStateManager').send name, context


Emberella.MQMixin = Ember.Mixin.create()

Emberella.MQMixin.reopen
  ###
    @property isQueueable
    @type Boolean
    @default true
    @final
  ###
  isQueueable: true #quack like a duck

  ###
    If true, the queue will stop adding objects from the queue to an in
    progress state.

    @property isPaused
    @type Boolean
    @default false
  ###
  isPaused: false

  ###
    The maximum number of objects allowed to be in progress at a given time.

    @property simultaneous
    @type Integer
    @default 4
  ###
  simultaneous: 4

  queue: null

  itemCompleteProperty: 'isComplete'

  itemErrorProperty: 'isError'

  percentComplete: Ember.computed ->
    queueLength = +get(@, 'queue.length')
    completedLength = +get(@, 'completed.length')
    return 0 if queueLength is 0 or completedLength is 0
    percent = completedLength / queueLength
    Math.min percent, 1
  .property 'completed', 'completed.length', 'queued', 'queued.length'

  isComplete: Ember.computed ->
    queueLength = +get(@, 'queue.length')
    completedLength = +get(@, 'completed.length')
    inProgressLength = +get(@, 'inProgress.length')

    queueLength > 0 and completedLength >= queueLength and inProgressLength is 0
  .property 'queue.length', 'completed.length', 'inProgress.length'

  waiting: Ember.computed ->
    return Ember.A() unless (queue = get(@, 'queue'))
    queue.filter((item) ->
      !!(get(item, 'isQueueItemWaiting'))
    )
  .property 'queue.@each.isQueueItemWaiting'

  inProgress: Ember.computed ->
    return Ember.A() unless (queue = get(@, 'queue'))
    queue.filter((item) ->
      !!(get(item, 'isQueueItemInProgress'))
    )
  .property 'queue.@each.isQueueItemInProgress'

  completed: Ember.computed ->
    return Ember.A() unless (queue = get(@, 'queue'))
    queue.filter((item) ->
      !!(get(item, 'isQueueItemComplete'))
    )
  .property 'queue.@each.isQueueItemComplete'

  failed: Ember.computed ->
    get(@, 'queue').filter((item) ->
      !!(get(item, 'isQueueItemError'))
    )
  .property 'queue.@each.isQueueItemError'

  nextItem: Ember.computed ->
    get(@, 'waiting.firstObject')
  .property 'waiting'

  init: ->
    # create the queue arrays
    set(@, 'queue', Ember.A())
    @_super.apply @, arguments

  ###
    Add an item, multiple items, or an array of items to the queue.

    @method addToQueue
    @param {Object|Array} items Objects to add to the queue for processing
    @chainable
  ###
  addToQueue: (items...) ->
    items = [].concat.apply([], [].concat(items)) #flatten splat
    queue = get(@, 'queue')

    for item in items
      queueItem = Emberella.MQItem.create(content: item, queue: @)
      queue.pushObject(queueItem)

    @

  removeFromQueue: (items...) ->
    items = [].concat.apply([], [].concat(items)) #flatten splat
    queue = get(@, 'queue')

    queueItems = items.map((item) =>
      queueItem = @searchQueue(item)
    ).compact()

    queue.removeObjects queueItems
    @

  emptyQueue: ->
    set(@, 'queue.length', 0)

  searchQueue: (item) ->
    get(@, 'queue').find((queueItem) ->
      get(queueItem, 'content') is item
    )

  activateNextItem: Ember.observer ->
    simultaneous = get @, 'simultaneous'
    inProgressLength = get @, 'inProgress.length'

    return @ if inProgressLength >= simultaneous or get @, 'isPaused'

    nextItem = get @, 'nextItem'
    nextItem.send('activate') if nextItem? and (nextItem.get('mqStateManager.currentState.name') is 'queued')
    @
  .observes 'nextItem', 'isPaused', 'inProgress', 'inProgress.length'

  ###
    Updates state of completed items.

    @method queueCompleted
    @return null
  ###
  queueCompleted: Ember.observer ->
    return unless get(@, 'isComplete')
    @didCompleteQueue()
    null
  .observes 'isComplete'

  ###
    Put the queue into a paused state.

    @method pauseQueue
    @chainable
  ###
  pauseQueue: ->
    set(@, 'isPaused', true)
    @

  ###
    Unpause the queue.

    @method resumeQueue
    @chainable
  ###
  resumeQueue: ->
    set(@, 'isPaused', false)
    @

  markAsComplete: (item) ->
    if !get item, 'isQueueableItem'
      Ember.warn "Item to mark as complete was not a queueable item."
      return @

    unless get item, 'isQueueItemInProgress'
      Ember.warn "Item to mark as complete was not active or in progress."
      return @

    isPaused = get @, 'isPaused'

    markAsCompleteFn = ->
      return if get @, 'isPaused'
      @removeObserver 'isPaused', @, markAsCompleteFn
      item.send 'finish'

    if isPaused
      @addObserver 'isPaused', @, markAsCompleteFn
    else
      markAsCompleteFn.call @

  markAsError: (item) ->
    if !get item, 'isQueueableItem'
      Ember.warn "Item to put into error state was not a queueable item."
      return @

    item.send 'didError'

    @

  retry: (item) ->
    if !get item, 'isQueueableItem'
      Ember.warn "Item to retry was not a queueable item."
      return @

    item.send 'retry'

    @

  didAddQueueItem: Ember.K

  didReadyQueueItem: Ember.K

  didActivateQueueItem: (item) ->
    itemCompleteProperty = get @, 'itemCompleteProperty'
    Ember.run.later item, ->
      item.set itemCompleteProperty, true
    , 100

  ###
    Hook for objects moving from in progress to completed. Override with your
    own handler to finalize processing for the given object.

    @method didCompleteQueueItem
  ###
  didCompleteQueueItem: Ember.K

  willRetryQueueItem: Ember.K

  didQueueItemError: Ember.K

  ###
    Hook for performing actions after queue processing is complete.
    Override this method to add custom behavior.

    @method didCompleteQueue
  ###
  didCompleteQueue: Ember.K

  _didActivateQueueItem: (item) ->
    itemCompleteProperty = get @, 'itemCompleteProperty'
    itemErrorProperty = get @, 'itemErrorProperty'

    completeFn = ->
      return unless get(item, itemCompleteProperty)
      item.removeObserver(itemCompleteProperty, @, completeFn)
      item.removeObserver(itemErrorProperty, @, errorFn)
      @markAsComplete item

    errorFn = ->
      return unless get(item, itemErrorProperty)
      item.removeObserver(itemCompleteProperty, @, completeFn)
      item.removeObserver(itemErrorProperty, @, errorFn)
      @markAsError item

    item.addObserver(itemCompleteProperty, @, completeFn)
    item.addObserver(itemErrorProperty, @, errorFn)
