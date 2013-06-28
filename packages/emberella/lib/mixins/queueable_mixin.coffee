###
@module emberella
@submodule emberella-mixins
###

Emberella = window.Emberella
get = Ember.get
set = Ember.set
guidFor = Ember.guidFor

###
  `Emberella.QueueableMixin` empowers an array controller to establish a queue
  of items or objects for further processing. Items will be processed a
  configurable number at a time in the order they are added. The queue also
  calculates how much of the queue has been completed.

  To add items to the queue, pass them as arguments to the `addToQueue` method.

  Currently, I use this mixin as part of a file uploader mechanism. Sending a
  large set of files to the server all at once flirts with disaster. Thus,
  files are queued and uploaded a few at a time.

  This mixin is rough around the edges and is not verified to work
  across browsers.

  TODO: Refactor. Still feels a bit over-complex and in need of testing.

  @class QueueableMixin
  @namespace Emberella
###

Emberella.QueueableMixin = Ember.Mixin.create

  ###
    @property isQueueable
    @type Boolean
    @default true
    @final
  ###
  isQueueable: true #quack like a duck

  ###
    The reference to the queue array. This array keeps a reference to all
    objects added to the queue, including items in progress or completed.

    @property queued
    @type Array
    @default null
  ###
  queued: null

  ###
    An array of objects currently being processed.

    @property inProgress
    @type Array
    @default null
  ###
  inProgress: null

  ###
    An array of objects marked as completed.

    @property completed
    @type Array
    @default null
  ###
  completed: null

  ###
    If true, the queue will stop adding objects from the queue to an in
    progress state.

    @property isPaused
    @type Boolean
    @default false
  ###
  isPaused: false

  ###
    The maximum number of objects allowed into the `inProgress` array.

    @property simultaneous
    @type Integer
    @default 4
  ###
  simultaneous: 4

  ###
    @deprecated Use `queued` instead
    @property in_queue
  ###
  in_queue: Ember.computed.alias 'queued'

  ###
    @deprecated Use `inProgress` instead
    @property in_progress
  ###
  in_progress: Ember.computed.alias 'inProgress'

  ###
    @deprecated Use `completed` instead
    @property is_complete
  ###
  is_complete: Ember.computed.alias 'completed'

  init: (simultaneous = 4) ->
    # create all the queue arrays
    set(@, 'queued', Ember.A())
    set(@, 'inProgress', Ember.A())
    set(@, 'completed', Ember.A())
    @_super()

  ###
    (length of completed items) / (length of queued items)

    Represented as a number between 0 and 1.

    @property percentComplete
    @type Number
    @default 0
  ###
  percentComplete: Ember.computed ->
    queuedLength = +get(@, 'queued.length')
    completedLength = +get(@, 'completed.length')
    return 0 if queuedLength is 0 or completedLength is 0
    percent = completedLength / queuedLength
    Math.min percent, 1
  .property 'completed', 'completed.length', 'queued', 'queued.length'

  ###
    Boolean flag that indicates if the queue has finished being processed.

    @property isComplete
    @type Boolean
    @default false
  ###
  isComplete: Ember.computed ->
    !!(get(@, 'queued.length') > 0 and get(@, 'completed.length') >= get(@, 'queued.length') and get(@, 'inProgress.length') is 0)
  .property 'completed', 'queued', 'inProgress', 'completed.length', 'queued.length', 'inProgress.length'

  ###
    A state property to inject into queued objects.

    @property stateKey
    @type String
  ###
  stateKey: Ember.computed ->
    [guidFor(@), 'queue-state'].join('-')

  ###
    An error property to inject into queued objects.

    @property errorKey
    @type String
  ###
  errorKey: Ember.computed ->
    [guidFor(@), 'queue-attempts'].join('-')

  ###
    Updates state of completed items.

    @method queueCompleted
    @return null
  ###
  queueCompleted: Ember.observer ->
    return unless get(@, 'isComplete')
    get(@, 'completed').invoke('set', get(@, 'stateKey'), 'was_completed')
    @didCompleteQueue()
    null
  .observes 'isComplete'

  ###
    Add items from the queue into the in progress stack until the number of
    items in progress equals the number of items specified in the
    `simultaneous` property.

    @method manageQueue
    @return null
  ###
  manageQueue: Ember.observer ->
    stateKey = get(@, 'stateKey')
    return if get(@, 'isPaused')
    if +get(@, 'inProgress.length') < get(@, 'simultaneous')
      item = get(@, 'queued').find((obj) -> get(obj, stateKey) is 'in_queue')
      get(@, 'inProgress').addObject(item) if item
    null
  .observes 'inProgress', 'inProgress.length', 'queued', 'queued.length', 'simultaneous', 'isPaused'

  ###
    Begin processing of objects newly added to the `inProgress` array.

    @method activateQueued
    @return null
  ###
  activateQueued: Ember.observer ->
    stateKey = get(@, 'stateKey')
    get(@, 'inProgress').forEach((item) =>
      unless get(item, stateKey) is 'in_progress' or get(item, stateKey) is 'isError'
        set(item, stateKey, 'in_progress')
        @didActivateQueueItem item
    )
    null
  .observes 'inProgress', 'inProgress.length'

  ###
    Cleanup queues when items removed from content array.

    @method removeDeletedItemsFromQueues
    @return null
  ###
  removeDeletedItemsFromQueues: Ember.observer ->
    return unless get(@, 'queued')

    filterFn = (item) =>
      !@contains(item)

    remove = get(@, 'queued').filter filterFn
    get(@, 'completed').removeObjects remove
    get(@, 'queued').removeObjects remove
    get(@, 'inProgress').removeObjects remove
    null
  .observes 'content'

  ###
    Add an item, multiple items, or an array of items to the queue.

    @method addToQueue
    @param {Object|Array} items Objects to add to the queue for processing
    @chainable
  ###
  addToQueue: (items...) ->
    items = [].concat.apply([], [].concat(items)) #flatten splat
    stateKey = get(@, 'stateKey')
    for item in items
      obj = if (item instanceof Ember.Object) then item else Ember.Object.create('isQueueableItem': true, 'content': item)
      unless obj.get(stateKey)
        set(obj, stateKey, 'in_queue')
        get(@, 'in_queue').pushObject(obj)
    @

  ###
    Retry an item that reported an error during processing.

    @method retry
    @param {Object|Array} items Objects to recover from error state
    @chainable
  ###
  retry: (items...) ->
    stateKey = get(@, 'stateKey')
    items = [].concat.apply([], [].concat(items)) #flatten splat
    items = get(@, 'queued').filter((obj) -> obj.get(stateKey) is 'isError') unless items.length
    for item in items
      set(item, stateKey, 'in_queue') unless @willRetryQueueItem(item) is false
    @propertyDidChange('queued') if items.length
    @

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
    get(@, 'inProgress').removeObjects(get(@, 'completed'))
    @

  ###
    Flag a queued object as completed and move it into the completed pile.

    @method markAsComplete
    @param {Object} item Object to mark as complete
    @chainable
  ###
  markAsComplete: (item) ->
    set(item, get(@, 'stateKey'), 'is_complete')
    get(@, 'completed').pushObject(item)
    @didCompleteQueueItem item
    if get(item, 'isQueueableItem')
      set(item, 'content', null)
      item.destroy()
    get(@, 'inProgress').removeObject(item) unless get(@, 'isPaused')
    @

  ###
    Place a queued object into an error state.

    @method markAsError
    @param {Object} item Object to put into an error state
    @chainable
  ###
  markAsError: (item) ->
    errorKey = get(@, 'errorKey')
    set(item, get(@, 'stateKey'), 'isError')
    item.incrementProperty(errorKey, 1)
    get(@, 'inProgress').removeObject(item) unless @didQueueItemError(item, get(item, errorKey)) is false
    @

  ###
    Reset all queue arrays.

    @method clearAll
    @chainable
  ###
  clearAll: ->
    @clearQueue().clearInProgress().clearComplete()

  ###
    Reset the `queued` array.

    @method clearQueue
    @chainable
  ###
  clearQueue: ->
    @_clearQueued()
    @

  ###
    Reset the `inProgress` array.

    @method clearInProgress
    @chainable
  ###
  clearInProgress: ->
    @_clearInProgress()
    @

  ###
    Reset the `completed` array.

    @method clearComplete
    @chainable
  ###
  clearComplete: ->
    @_clearCompleted()
    @

  ###
    Remove completed items from the queue management arrays.

    @method removePreviouslyCompletedItems
    @chainable
  ###
  removePreviouslyCompletedItems: ->
    stateKey = get(@, 'stateKey')
    previouslyComplete = get(@, 'queued').filter((item) ->
      item.get(stateKey) is 'was_completed'
    )
    get(@, 'queued').removeObjects previouslyComplete
    get(@, 'completed').removeObjects previouslyComplete
    @

  ###
    Hook for intercepting queued objects that experienced errors during
    processing and are about to be retried.

    Override to add pre-processing of queued items to be retried. Return
    `false` to prevent the retry attempt.

    @method willRetryQueueItem
    @param {Object} item The item about to be retried
  ###
  willRetryQueueItem: Ember.K

  ###
    Hook for intercepting queued objects that experienced and error during
    processing.

    Override to add custom error handling for the queued item.

    @method didQueueItemError
    @param {Object} item The item with the error
  ###
  didQueueItemError: Ember.K

  ###
    Hook for objects moving from the queue to in progress. Override with your
    own handler to begin processing for the given object.

    @method didActivateQueueItem
  ###
  didActivateQueueItem: (item) ->
    @markAsComplete(item)

  ###
    Hook for objects moving from in progress to completed. Override with your
    own handler to finalize processing for the given object.

    @method didCompleteQueueItem
  ###
  didCompleteQueueItem: Ember.K

  ###
    Hook for performing actions after queue processing is complete.
    Override this method to add custom behavior.

    @method didCompleteQueue
  ###
  didCompleteQueue: Ember.K

  # QUEUE ARRAY EVENTS/OBSERVERS

  ###
    Hook for responding to the queued array being replaced with a new
    array instance. Override to add custom handling.

    @method queuedWillChange
    @param {Object} self
  ###
  queuedWillChange: Ember.K

  ###
    Hook for responding to the queued array being replaced with a new
    array instance. Override to add custom handling.

    @method queuedDidChange
    @param {Object} self
  ###
  queuedDidChange: Ember.K

  ###
    Hook for responding to impending updates to the queued array. Override to
    add custom handling for array updates.

    @method queuedArrayWillChange
    @param {Array} array The array instance being updated
    @param {Integer} idx The index where changes applied
    @param {Integer} removedCount
    @param {Integer} addedCount
  ###
  queuedArrayWillChange: (array, idx, removedCount, addedCount) ->
    @

  ###
    Hook for responding to updates to the queued array. Override to
    add custom handling for array updates.

    @method queuedArrayDidChange
    @param {Array} array The array instance being updated
    @param {Integer} idx The index where changes applied
    @param {Integer} removedCount
    @param {Integer} addedCount
  ###
  queuedArrayDidChange: (array, idx, removedCount, addedCount) ->
    @

  ###
    @private

    Queue array change handler.

    @method _queuedWillChange
  ###
  _queuedWillChange: Ember.beforeObserver ->
    queued = get(@, 'queued')
    len = if queued then get(queued, 'length') else 0

    @queuedArrayWillChange @, 0, len, undefined
    @queuedWillChange @
    @_teardownQueued queued
  , 'queued'

  ###
    @private

    Queue array change handler.

    @method _queuedDidChange
  ###
  _queuedDidChange: Ember.observer ->
    queued = get(@, 'queued')
    len = if queued then get(queued, 'length') else 0

    @_setupQueued queued
    @queuedDidChange @
    @queuedArrayDidChange @, 0, undefined, len
  , 'queued'

  ###
    @private

    Remove change observing on queued array.

    @method _teardownQueued
  ###
  _teardownQueued: ->
    @_clearQueued()
    queued = get(@, 'queued')
    if queued
      queued.removeArrayObserver @,
        willChange: 'queuedArrayWillChange',
        didChange: 'queuedArrayDidChange'

  ###
    @private

    Begin change observing on queued array.

    @method _setupQueued
  ###
  _setupQueued: ->
    queued = get(@, 'queued')
    if queued
      queued.addArrayObserver @,
        willChange: 'queuedArrayWillChange',
        didChange: 'queuedArrayDidChange'

  ###
    @private

    Empty the queued array.

    @method _clearQueued
  ###
  _clearQueued: ->
    queued = get(@, 'queued')
    queued.clear() if queued

  # IN PROGRESS ARRAY EVENTS/OBSERVERS

  ###
    Hook for responding to the inProgress array being replaced with a new
    array instance. Override to add custom handling.

    @method inProgressWillChange
    @param {Object} self
  ###
  inProgressWillChange: Ember.K

  ###
    Hook for responding to the inProgress array being replaced with a new
    array instance. Override to add custom handling.

    @method inProgressDidChange
    @param {Object} self
  ###
  inProgressDidChange: Ember.K

  ###
    Hook for responding to impending updates to the inProgress array. Override to
    add custom handling for array updates.

    @method inProgressArrayWillChange
    @param {Array} array The array instance being updated
    @param {Integer} idx The index where changes applied
    @param {Integer} removedCount
    @param {Integer} addedCount
  ###
  inProgressArrayWillChange: (array, idx, removedCount, addedCount) ->
    @

  ###
    Hook for responding to updates to the inProgress array. Override to
    add custom handling for array updates.

    @method inProgressArrayDidChange
    @param {Array} array The array instance being updated
    @param {Integer} idx The index where changes applied
    @param {Integer} removedCount
    @param {Integer} addedCount
  ###
  inProgressArrayDidChange: (array, idx, removedCount, addedCount) ->
    @

  ###
    @private

    In progress array change handler.

    @method _inProgressWillChange
  ###
  _inProgressWillChange: Ember.beforeObserver ->
    inProgress = get(@, 'inProgress')
    len = if inProgress then get(inProgress, 'length') else 0

    @inProgressArrayWillChange @, 0, len, undefined
    @inProgressWillChange @
    @_teardownInProgress inProgress
  , 'inProgress'

  ###
    @private

    In progress array change handler.

    @method _inProgressDidChange
  ###
  _inProgressDidChange: Ember.observer ->
    inProgress = get(@, 'inProgress')
    len = if inProgress then get(inProgress, 'length') else 0

    @_setupInProgress inProgress
    @inProgressDidChange @
    @inProgressArrayDidChange @, 0, undefined, len
  , 'inProgress'

  ###
    @private

    Remove change observing on in progress array.

    @method _teardownInProgress
  ###
  _teardownInProgress: ->
    @_clearInProgress()
    inProgress = get(@, 'inProgress')
    if inProgress
      inProgress.removeArrayObserver @,
        willChange: 'inProgressArrayWillChange',
        didChange: 'inProgressArrayDidChange'

  ###
    @private

    Begin change observing on in progress array.

    @method _setupInProgress
  ###
  _setupInProgress: ->
    inProgress = get(@, 'inProgress')
    if inProgress
      inProgress.addArrayObserver @,
        willChange: 'inProgressArrayWillChange',
        didChange: 'inProgressArrayDidChange'

  ###
    @private

    Empty the in progress array.

    @method _clearInProgress
  ###
  _clearInProgress: ->
    inProgress = get(@, 'inProgress')
    inProgress.clear() if inProgress

  # COMPLETED ARRAY EVENTS/OBSERVERS

  ###
    Hook for responding to the completed array being replaced with a new
    array instance. Override to add custom handling.

    @method completedWillChange
    @param {Object} self
  ###
  completedWillChange: Ember.K

  ###
    Hook for responding to the completed array being replaced with a new
    array instance. Override to add custom handling.

    @method completedWillChange
    @param {Object} self
  ###
  completedDidChange: Ember.K

  ###
    Hook for responding to impending updates to the completed array. Override to
    add custom handling for array updates.

    @method completedArrayWillChange
    @param {Array} array The array instance being updated
    @param {Integer} idx The index where changes applied
    @param {Integer} removedCount
    @param {Integer} addedCount
  ###
  completedArrayWillChange: (array, idx, removedCount, addedCount) ->
    @

  ###
    Hook for responding to updates to the completed array. Override to
    add custom handling for array updates.

    @method completedArrayDidChange
    @param {Array} array The array instance being updated
    @param {Integer} idx The index where changes applied
    @param {Integer} removedCount
    @param {Integer} addedCount
  ###
  completedArrayDidChange: (array, idx, removedCount, addedCount) ->
    @

  ###
    @private

    Completed array change handler.

    @method _completedWillChange
  ###
  _completedWillChange: Ember.beforeObserver ->
    completed = get(@, 'completed')
    len = if completed then get(completed, 'length') else 0

    @completedArrayWillChange @, 0, len, undefined
    @completedWillChange @
    @_teardownCompleted completed
  , 'completed'

  ###
    @private

    Completed array change handler.

    @method _completedDidChange
  ###
  _completedDidChange: Ember.observer ->
    completed = get(@, 'completed')
    len = if completed then get(completed, 'length') else 0

    @_setupCompleted completed
    @completedDidChange @
    @completedArrayDidChange @, 0, undefined, len
  , 'completed'

  ###
    @private

    Remove change observing on completed array.

    @method _teardownCompleted
  ###
  _teardownCompleted: ->
    @_clearCompleted()
    completed = get(@, 'completed')
    if completed
      completed.removeArrayObserver @,
        willChange: 'completedArrayWillChange',
        didChange: 'completedArrayDidChange'

  ###
    @private

    Begin change observing on completed array.

    @method _setupCompleted
  ###
  _setupCompleted: ->
    completed = get(@, 'completed')
    if completed
      completed.addArrayObserver @,
        willChange: 'completedArrayWillChange',
        didChange: 'completedArrayDidChange'

  ###
    @private

    Empty the completed array.

    @method _clearCompleted
  ###
  _clearCompleted: ->
    completed = get(@, 'completed')
    completed.clear() if completed

  # DESTROY/CLEANUP

  ###
    Called before destruction of the host object.

    @method willDestroy
  ###
  willDestroy: ->
    @_super()
    @_teardownQueued()
    @_teardownInProgress()
    @_teardownCompleted()
