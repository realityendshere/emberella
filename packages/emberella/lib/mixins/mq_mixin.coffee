#= require ../helpers/big_data_helpers

###
@module emberella
@submodule emberella-mixins
###

Emberella = window.Emberella
get = Ember.get
set = Ember.set
typeOf = Ember.typeOf

###
  Each item in the queue manages state with an instance of
  `Emberella.MQStateManager`.

  A queue item can be in one of four states: `queued`, `active`, `completed`,
  or `error`.

  When in its initial state, `queued`, an object is in the queue waiting for
  its turn to be processed. Before work begins on an object, it is "activated"
  and moved into the `active` state. From here, the processing will either
  succeed and reach the `completed` state or fail and land in an `error` state.

  Each state also has an associated boolean flag to more readily identify items
  in the same state.

  `queued`: `isQueueItemWaiting: true`
  `active`: `isQueueItemInProgress: true`
  `completed`: `isQueueItemComplete: true`
  `error`: `isQueueItemError: true`

  Lastly, as objects change state, the state manager will inform your queueable
  controller by calling various hooks. By overriding the following methods, you
  can inject custom processing, error handling, and general behavior into the
  queueable object.

  `didAddQueueItem` is called when entering `queued` state.
  `didActivateQueueItem` is called when work on an object should begin.
  `didCompleteQueueItem` is called when work on an object is successful
  `didQueueItemError` is called when something goes wrong
  `willRetryQueueItem` is called when trying to recover an object from an error

  @class MQStateManager
  @namespace Emberella
  @extends Ember.StateManager
###

Emberella.MQStateManager = Ember.StateManager.extend
  ###
    All objects in the queue begin in the `queued` state.

    @property initialState
    @type String
    @default 'queued'
    @final
  ###
  initialState: 'queued'

  ###
    The number of times processing of the queued object has been retried after
    entering the error state.

    @property retries
    @type Integer
    @default 0
  ###
  retries: 0

  invokeQueueCallback: (message) ->
    queueItem = get @, 'queueItem'
    queue = get queueItem, 'queue'
    privateFn = '_' + message
    if queue?
      queue[privateFn].call queue, queueItem if typeOf(queue[privateFn]) is 'function'
      queue[message].call queue, queueItem if typeOf(queue[message]) is 'function'

  unhandledEvent: (manager, eventName, e) ->
    Ember.debug("MQ state manager did not handle an event :: " + eventName)
    [manager, eventName, e]

  queued: Ember.State.create
    isQueueItemWaiting: true

    setup: (manager) ->
      manager.invokeQueueCallback 'didAddQueueItem'

    activate: (manager) ->
      manager.transitionTo('active')

    skip: (manager) ->
      manager.transitionTo('completed')

    didError: (manager) ->
      manager.transitionTo('error')

  active: Ember.State.create
    isQueueItemInProgress: true

    setup: (manager) ->
      manager.invokeQueueCallback 'didActivateQueueItem'

    finish: (manager) ->
      manager.transitionTo('completed')

    didError: (manager) ->
      manager.transitionTo('error')

  completed: Ember.State.create
    isQueueItemComplete: true

    setup: (manager) ->
      manager.invokeQueueCallback 'didCompleteQueueItem'

    didError: Ember.K

  error: Ember.State.create
    isQueueItemError: true

    setup: (manager) ->
      manager.invokeQueueCallback 'didQueueItemError'

    retry: (manager) ->
      manager.invokeQueueCallback 'willRetryQueueItem'
      manager.incrementProperty('retries')
      Ember.run -> manager.transitionTo('queued')

    didError: (manager) ->
      manager.transitionTo('error')

retrieveFromCurrentState = Ember.computed((key, value) ->
  !!get(get(@, 'mqStateManager.currentState'), key)
).property('mqStateManager.currentState').readOnly()

###
  Each queued item is wrapped in an `Emberella.MQObject` object proxy to enable
  state management. Ideally, any object can be queued for gradual or delayed
  processing. Wrapping queued objects in a proxy allows queue state to be
  managed without altering the original content. It also allows an object to be
  inserted into multiple queues.

  @class MQObject
  @namespace Emberella
  @extends Ember.ObjectProxy
###

Emberella.MQObject = Ember.ObjectProxy.extend
  init: ->
    @_super()

    # Setup a new state manager with a reference to this object instance
    stateManager = Emberella.MQStateManager.create queueItem: @
    set(@, 'mqStateManager', stateManager)
    get(@, 'mqStateManager.currentState')
    get(@, 'isQueueItemWaiting')
    get(@, 'isQueueItemInProgress')
    get(@, 'isQueueItemComplete')
    get(@, 'isQueueItemError')

  ###
    @property isQueueableItem
    @type Boolean
    @default true
    @final
  ###
  isQueueableItem: true #quack like a duck

  ###
    Holds a reference to this queued object's state manager.

    @property mqStateManager
    @type Emberella.MQStateManager
    @default null
  ###
  mqStateManager: null

  ###
    The number of times processing of the queued object has been retried after
    entering the error state.

    Bound to the `retries` property of this object's `mqStateManager`.

    @property retries
    @type Integer
    @default 0
  ###
  retries: Ember.computed.alias('mqStateManager.retries').readOnly()

  ###
    A computed property that returns true when this object is in the
    `queued` state.

    @property isQueueItemWaiting
    @type Boolean
    @default true
    @readOnly
  ###
  isQueueItemWaiting: retrieveFromCurrentState

  ###
    A computed property that returns true when this object is in the
    `active` state.

    @property isQueueItemInProgress
    @type Boolean
    @default false
    @readOnly
  ###
  isQueueItemInProgress: retrieveFromCurrentState

  ###
    A computed property that returns true when this object is in the
    `completed` state.

    @property isQueueItemComplete
    @type Boolean
    @default false
    @readOnly
  ###
  isQueueItemComplete: retrieveFromCurrentState

  ###
    A computed property that returns true when this object is in the
    `error` state.

    @property isQueueItemError
    @type Boolean
    @default false
    @readOnly
  ###
  isQueueItemError: retrieveFromCurrentState

  ###
    Send a message to the state manager. Valid messages may cause the state to
    change. Others will throw an exception.

    @method send
    @param String message to the state manager
    @param Mixed context
  ###
  send: (name, context) ->
    get(@, 'mqStateManager').send name, context
    context


###
  `Emberella.MQMixin` empowers an array controller to establish a queue of
  items or objects for further processing. Items will be processed a
  configurable number at a time in the order they are added. The queue also
  calculates how much of the queue has been completed.

  To add items to the queue, pass them as arguments to the `addToQueue` method.

  Currently, I use this mixin as part of a file uploader mechanism. Sending a
  large set of files to the server all at once flirts with disaster. Thus,
  files are queued and uploaded a few at a time.

  This mixin replaces the over-complex and less reliable
  `Emberella.QueueableMixin`.

  TODO: Testing
  TODO: Cross browser fixes as needed

  @class MQMixin
  @namespace Emberella
###
Emberella.MQMixin = Ember.Mixin.create()
Emberella.MQMixin.reopen
  init: ->
    ret = @_super.apply @, arguments

    # create the queue array
    set(@, 'queue', Ember.A())

    #"prime" critical computed properties
    get(@, 'waiting')
    get(@, 'inProgress')
    get(@, 'completed')
    get(@, 'isComplete')
    get(@, 'percentComplete')

    ret

  ###
    @property isQueueable
    @type Boolean
    @default true
    @final
  ###
  isQueueable: true #quack like a duck

  ###
    If true, the queue will stop moving objects into or out of the
    `inProgress` bucket.

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

  ###
    An array of objects in the queue. This property will always contain all
    queued items in any state. From here, various computed properties will help
    identify queued objects in active, completed, and error states.

    @property queue
    @type Array
    @default null
  ###
  queue: null

  ###
    A boolean property to observe on each object in the queue. When the
    property specified here changes from `false` to `true`, the queued object
    will move to the `completed` state.

    @property itemCompleteProperty
    @type String
    @default 'isComplete'
  ###
  itemCompleteProperty: 'isComplete'

  ###
    A boolean property to observe on each object in the queue. When the
    property specified here changes from `false` to `true`, the queued object
    will move to the `error` state.

    @property itemErrorProperty
    @type String
    @default 'isError'
  ###
  itemErrorProperty: 'isError'

  ###
    (length of completed items) / (length of queued items)

    Represented as a number between 0 and 1.

    @property percentComplete
    @type Number
    @default 0
    @readOnly
  ###
  percentComplete: Ember.computed ->
    queueLength = +get(@, 'queue.length')
    completedLength = +get(@, 'completed.length')
    return 0 if queueLength is 0 or completedLength is 0
    percent = completedLength / queueLength
    Math.min percent, 1
  .property('completed', 'completed.length', 'queued', 'queued.length').readOnly()

  ###
    Boolean flag that indicates if the queue has finished processing.

    @property isComplete
    @type Boolean
    @default false
  ###
  isComplete: Ember.computed ->
    queueLength = +get(@, 'queue.length')
    completedLength = +get(@, 'completed.length')
    inProgressLength = +get(@, 'inProgress.length')

    queueLength > 0 and completedLength >= queueLength and inProgressLength is 0
  .property 'queue.length', 'completed.length', 'inProgress.length'

  ###
    An array of objects waiting to be processed. Once items are added to the
    queue, this property will initially contain all objects in the queue.

    @property waiting
    @type Array
    @default []
    @readOnly
  ###
  waiting: Ember.computed ->
    return Ember.A() unless (queue = get(@, 'queue'))
    queue.filter((item) ->
      !!(get(item, 'isQueueItemWaiting'))
    )
  .property('queue.@each.isQueueItemWaiting').readOnly()

  ###
    An array of objects currently being processed. This array's length should
    never exceed the numeric value provided by the `simultaneous` property.

    @property inProgress
    @type Array
    @default []
    @readOnly
  ###
  inProgress: Ember.computed ->
    return Ember.A() unless (queue = get(@, 'queue'))
    queue.filter((item) ->
      !!(get(item, 'isQueueItemInProgress'))
    )
  .property('queue.@each.isQueueItemInProgress').readOnly()

  ###
    An array of objects that were successfully processed.

    @property completed
    @type Array
    @default []
    @readOnly
  ###
  completed: Ember.computed ->
    return Ember.A() unless (queue = get(@, 'queue'))
    queue.filter((item) ->
      !!(get(item, 'isQueueItemComplete'))
    )
  .property('queue.@each.isQueueItemComplete').readOnly()

  ###
    An array of objects that reported an error during processing.

    @property failed
    @type Array
    @default []
    @readOnly
  ###
  failed: Ember.computed ->
    get(@, 'queue').filter((item) ->
      !!(get(item, 'isQueueItemError'))
    )
  .property('queue.@each.isQueueItemError').readOnly()

  ###
    The next object waiting in line for processing.

    @property nextInQueue
    @type Object
    @readOnly
  ###
  nextInQueue: Ember.computed ->
    get(@, 'waiting.firstObject')
  .property('waiting').readOnly()

  ###
    Add an object, multiple object, or an array of object to the queue.

    This method will wrap each object in an `Emberella.MQObject` proxy.

    Notably, the `queue` and `content` properties are managed independently.

    @method addToQueue
    @param {Object|Array} items Objects to add to the queue for processing
    @chainable
  ###
  addToQueue: (items...) ->
    items = Ember.A([].concat.apply([], [].concat(items))) #flatten splat
    queue = get(@, 'queue')
    itemCompleteProperty = get @, 'itemCompleteProperty'
    itemErrorProperty = get @, 'itemErrorProperty'

    toBeAdded = []

    processItem = (item) ->
      queueItem = Emberella.MQObject.create(content: item, queue: @)

      #Skip items that are already complete
      if get(queueItem, itemCompleteProperty)
        queueItem.send 'skip'

      #If error, put into error state
      else if get(queueItem, itemErrorProperty)
        queueItem.send 'didError'

      toBeAdded.push(queueItem)

    Emberella.forEachAsync(@, items, processItem, ->
      queue.pushObjects(toBeAdded)
    )

    @

  ###
    Remove an object, multiple object, or an array of object from the queue.

    @method removeFromQueue
    @param {Object|Array} items Objects to remove from the queue
    @chainable
  ###
  removeFromQueue: (items...) ->
    items = [].concat.apply([], [].concat(items)) #flatten splat
    queue = get(@, 'queue')
    itemCompleteProperty = get @, 'itemCompleteProperty'
    itemErrorProperty = get @, 'itemErrorProperty'

    queueItems = items.map((item) =>
      queueItem = @searchQueue(item)
    ).compact()

    queueItems.forEach((item) =>
      @_removeObserversFromItem item
    )

    queue.removeObjects queueItems
    @

  ###
    Clears the queue array.

    @method emptyQueue
    @chainable
  ###
  emptyQueue: ->
    set(@, 'queue.length', 0)
    @

  ###
    Finds the first queue proxy object with content that matches the
    given item.

    @method searchQueue
    @param Mixed the queued item to search for
    @return Object matching MQObject or undefined
  ###
  searchQueue: (item) ->
    get(@, 'queue').find((queueItem) ->
      get(queueItem, 'content') is item
    )

  ###
    If more items can be activated, this method finds the next object in the
    queue and sends it to the active state.

    @method activateNextItem
    @chainable
  ###
  activateNextItem: Ember.observer ->
    simultaneous = get @, 'simultaneous'
    inProgressLength = get @, 'inProgress.length'

    return @ if inProgressLength >= simultaneous or get @, 'isPaused'

    nextInQueue = get @, 'nextInQueue'
    nextInQueue.send('activate') if nextInQueue? and (nextInQueue.get('mqStateManager.currentState.name') is 'queued')
    @
  .observes 'nextInQueue', 'isPaused', 'inProgress', 'inProgress.length'

  ###
    Calls `didCompleteQueue` hook when the queue finishes processing.

    @method queueCompleted
    @return null
  ###
  queueCompleted: Ember.observer ->
    return unless get(@, 'isComplete')
    @didCompleteQueue()
    null
  .observes 'isComplete'

  ###
    Pause the queue.

    @method pauseQueue
    @chainable
  ###
  pauseQueue: ->
    @set 'isPaused', true
    @

  ###
    Unpause the queue.

    @method resumeQueue
    @chainable
  ###
  resumeQueue: ->
    @set 'isPaused', false
    @

  ###
    Move the given queue object into a `completed` state.

    If the queue is paused, this method will wait until the queue resumes
    before placing any objects into a `completed` state.

    @method markAsComplete
    @param Emberella.MQObject the object to mark complete
    @chainable
  ###
  markAsComplete: (item) ->
    if !get item, 'isQueueableItem'
      Ember.warn "Item to mark as complete was not a queueable item."
      return @

    isPaused = get @, 'isPaused'

    markAsCompleteFn = ->
      return if get @, 'isPaused'
      @removeObserver 'isPaused', @, markAsCompleteFn
      unless get item, 'isQueueItemInProgress'
        Ember.warn "Item to mark as complete was not active or in progress."
      item.send 'finish'

    if isPaused
      @addObserver 'isPaused', @, markAsCompleteFn
    else
      markAsCompleteFn.call @

    @

  ###
    Move the given queue object into an `error` state.

    @method markAsError
    @param Emberella.MQObject the object with the error
    @chainable
  ###
  markAsError: (item) ->
    if !get item, 'isQueueableItem'
      Ember.warn "Item to put into error state was not a queueable item."
      return @

    item.send 'didError'

    @

  ###
    Recover an object from an error state. The given object will return to a
    `queued` state and call the `willRetryQueueItem` hook to allow the object
    to be prepared for re-processing.

    @method retry
    @param Emberella.MQObject the object to retry
    @chainable
  ###
  retry: (item) ->
    if !get item, 'isQueueableItem'
      Ember.warn "Item to retry was not a queueable item."
      return @

    item.send 'retry'

    @

  ###
    Override this method to add custom preparations for an object when it is
    added to the queue.

    @method didAddQueueItem
    @param Emberella.MQObject the object added to the queue
  ###
  didAddQueueItem: Ember.K

  ###
    Override this method to inject custom object processing instructions.

    This method is where your magic happens. The default behavior is simply to
    mark the object complete after 100ms.

    @method didActivateQueueItem
    @param Emberella.MQObject the queued proxy with content to process
  ###
  didActivateQueueItem: (item) ->
    itemCompleteProperty = get @, 'itemCompleteProperty'
    Ember.run.later item, ->
      item.set itemCompleteProperty, true
    , 100

  ###
    Hook for objects moving from in progress to completed. Override with your
    own handler to finalize processing for the given object.

    @method didCompleteQueueItem
    @param Emberella.MQObject the completed object
  ###
  didCompleteQueueItem: Ember.K

  ###
    Override this method to inject custom handling for queued objects entering
    an error state.

    @method didQueueItemError
    @param Emberella.MQObject the object that encountered an error
  ###
  didQueueItemError: Ember.K

  ###
    Override this method to prepare a queued object for processing after the
    previous attempt failed.

    @method willRetryQueueItem
    @param Emberella.MQObject the object to retry
  ###
  willRetryQueueItem: Ember.K

  ###
    Hook for performing actions after queue processing is complete.
    Override this method to add custom behavior.

    @method didCompleteQueue
  ###
  didCompleteQueue: Ember.K

  ###
    @private

    Setup and teardown observing for `itemCompleteProperty` and
    `itemErrorProperty` as objects move into an `active` state.

    @method _didActivateQueueItem
    @param Emberella.MQObject the queued proxy with content to process
  ###
  _didActivateQueueItem: (item) ->
    itemCompleteProperty = get @, 'itemCompleteProperty'
    itemErrorProperty = get @, 'itemErrorProperty'

    if get(item, itemCompleteProperty)
      Ember.run.next(@, -> @markAsComplete item )
    else if get(item, itemErrorProperty)
      @markAsError item
    else
      item.addObserver(itemCompleteProperty, @, '_handleStatusChange')
      item.addObserver(itemErrorProperty, @, '_handleStatusChange')

  ###
    @private

    Handle changes to completed/error properties on active queue objects.

    @method _handleStatusChange
    @param Emberella.MQObject the queued proxy with content to process
    @param String the property that changed
    @return Emberella.MQObject the target object
  ###
  _handleStatusChange: (item, property) ->
    return unless get(item, property)
    @_removeObserversFromItem item

    if property is get(@, 'itemCompleteProperty')
      @markAsComplete item
    else if property is get(@, 'itemErrorProperty')
      @markAsError item
    item

  ###
    @private

    Remove property observers from the given queue object.

    @method _removeObserversFromItem
    @param Emberella.MQObject the queued proxy with content to process
    @return Emberella.MQObject the target object
  ###
  _removeObserversFromItem: (item) ->
    itemCompleteProperty = get @, 'itemCompleteProperty'
    itemErrorProperty = get @, 'itemErrorProperty'
    item.removeObserver(itemCompleteProperty, @, '_handleStatusChange')
    item.removeObserver(itemCompleteProperty, @, '_handleStatusChange')
    item
