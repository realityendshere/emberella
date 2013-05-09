#= require ../mixins/style_bindings

###
@module emberella
@submodule emberella-views
###

Emberella = window.Emberella
get = Ember.get
set = Ember.set

###
  `Emberella.ListItemView` is an `Ember.View` designed for use as a child
  listing of `Emberella.ListView`.

  This class requires the very handy `Ember.StyleBindingsMixin` that is
  packaged with
  [Ember TableView](https://github.com/Addepar/ember-table/ "Ember TableView")

  @class ListItemView
  @namespace Emberella
  @extends Emberella.View
  @uses Ember.StyleBindingsMixin
###

Emberella.ListItemView = Emberella.View.extend Ember.StyleBindingsMixin,

  ###
    Add the class name `emberella-list-item-view`.

    @property classNames
    @type Array
    @default ['emberella-list-item-view']
  ###
  classNames: ['emberella-list-item-view']

  ###
    Adds a `loading` class to the listing element if its content isn't loaded.

    @property classNameBindings
    @type Array
    @default ['isLoaded::loading']
  ###
  classNameBindings: ['isLoaded::loading']

  ###
    Loading state of view. Typically bound to the `isLoaded` property of the
    listing's content.

    @property isLoaded
    @type Boolean
  ###
  isLoadedBinding: 'content.isLoaded'

  ###
    Defines an array of properties to transform into styles on the listing's
    DOM element.

    Functionality provided by `Ember.StyleBindingsMixin`.

    @property styleBindings
    @type Array
    @default ['top', 'display', 'position', 'height']
  ###
  styleBindings: ['top', 'display', 'position', 'height']

  ###
    In pixels, the height of each listing. Typically, this value is provided
    by the `rowHeight` property of the parent `Emberella.ListView`.

    @property rowHeight
    @type Integer
  ###
  rowHeightBinding: 'parentView.rowHeight'

  ###
    Set `absolute` positioning for each listing.

    @property position
    @type String
    @default 'absolute'
  ###
  position: Ember.computed ->
    'absolute'
  .property()

  ###
    In pixels, calculate the distance from the top this listing should be
    positioned within the scrolling list.

    @property top
    @type Integer
  ###
  top: Ember.computed ->
    get(@, 'contentIndex') * get(@, 'rowHeight')
  .property 'contentIndex', 'rowHeight'

  ###
    In pixels, the height of this listing.

    @property height
    @type Integer
  ###
  height: Ember.computed ->
    +get(@, 'rowHeight')
  .property 'rowHeight'

  ###
    The display property for this listing 'none' or no value.

    Used to hide listings with null or undefined content.

    @property display
    @type String
  ###
  display: Ember.computed ->
    'none' if not get(@, 'content')
  .property 'content'

  ###
    Called before destruction of the view object.

    @method willDestroy
  ###
  willDestroy: ->
    set(@, 'content', null)
    @_super()

  ###
    Called after new content assigned to this listing. Override this method to
    inject special data processing or behavior.

    @method prepareContent
    @param {Integer} contentIndex
    @param {Boolean} dontFetch
  ###
  prepareContent: Ember.K

  ###
    Called before new content assigned to this listing. Override this method to
    inject special data processing or behavior.

    @method teardownContent
    @param {Integer} contentIndex
    @param {Boolean} dontFetch
  ###
  teardownContent: Ember.K
