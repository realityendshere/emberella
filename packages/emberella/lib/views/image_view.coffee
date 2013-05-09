###
@module emberella
@submodule emberella-views
###

Emberella = window.Emberella
jQuery = window.jQuery
get = Ember.get
set = Ember.set

###
  `Emberella.ImageView` creates an `<img>` element with load event handling
  that can be used to notify a parent view when a new source image begins and
  completes loading.

  This view can be used with `Emberella.ListView` to address a bug that causes
  the image defined by the `src` attribute of previous content to appear for a
  few moments until an updated image loads.

  @class ImageView
  @namespace Emberella
  @extends Ember.View
###

Emberella.ImageView = Ember.View.extend

  ###
    Add the class name `emberella-image`.

    @property classNames
    @type Array
    @default ['emberella-image']
  ###
  classNames: ['emberella-image']

  ###
    Adds a `loading` class to the image element if its src isn't loaded.

    @property classNameBindings
    @type Array
    @default [ 'loading' ]
  ###
  classNameBindings: [ 'loading' ]

  ###
    The type of element to create for this view.

    @property tagName
    @type String
    @default 'img'
  ###
  tagName: 'img'

  ###
    A list of element attributes to keep in sync with properties of this
    view instance.

    @property attributeBindings
    @type Array
    @default ['style', 'alt', 'title', 'draggable', 'width', 'height']
  ###
  attributeBindings: ['style', 'alt', 'title', 'draggable', 'width', 'height']

  ###
    Tracks loading state of the image element. Should be true when an image
    is being fetched and false once the image finishes loading.

    @property loading
    @type Boolean
    @default false
  ###
  loading: false

  ###
    The src path (URL) of the image to display in this element.

    @property src
    @type String
    @default ''
  ###
  src: ''

  ###
    Image load event handler reference.

    @property didImageLoad
    @type Function
  ###
  didImageLoad: Ember.computed ->
    view = @

    didImageLoad = (e) ->
      img = this
      img.removeEventListener('load', didImageLoad, false)

      #Do nothing if view instance is destroyed
      return if get(view, 'isDestroyed')

      #Do nothing if src has changed again since loading began
      current = get(view, 'src') ? ''
      loaded = img.src.substr(-(current.length))
      return unless loaded is current

      set view, 'loading', false #exit loading state

  ###
    Update the src attribute of the `<img>` element. Once the corresponding
    image loads, update the `loading` property.

    @method updateSrc
    @chainable
  ###
  updateSrc: ->
    view = @
    img = get view, 'element'
    src = get(@, 'src')
    didImageLoad = get @, 'didImageLoad'

    # Do nothing if the src property is empty
    if jQuery.trim(src) is ''
      img.removeAttribute 'src'
      return @

    set view, 'loading', true #enter loading state

    img.addEventListener('load', didImageLoad, false)
    img.src = src
    didImageLoad.call(img) if img.complete
    @

  ###
    Respond to changes of the `src` property

    @method srcDidChange
    @chainable
  ###
  srcDidChange: Ember.observer ->
    @updateSrc()
  , 'src'

  ###
    Trigger events in the parent view when the loading state changes. This
    allows styling a parent element differently while waiting for an image to
    finish loading.

    Triggers an `imageWillLoad` event on the parent when loading begins.

    Trigger an `imageDidLoad` event on the parent when loading completes.

    @method loadingDidChange
    @chainable
  ###
  loadingDidChange: Ember.observer ->
    evt = if get(@, 'loading') then 'imageWillLoad' else 'imageDidLoad'
    get(@, 'parentView').trigger(evt)
    @
  , 'loading'

  ###
    Handle insertion into the DOM.

    @event didInsertElement
  ###
  didInsertElement: ->
    @_super()
    @updateSrc()

  ###
    Handle imminent destruction.

    @event willDestroyElement
  ###
  willDestroyElement: ->
    img = get @, 'element'
    didImageLoad = get @, 'didImageLoad'
    img.removeEventListener('load', didImageLoad, false)
    @_super()
