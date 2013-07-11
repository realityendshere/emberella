#= require ../mixins/style_bindings

###
@module emberella
@submodule emberella-views
###

Emberella = window.Emberella
get = Ember.get
set = Ember.set

LIST_ITEM_CLASS = 'emberella-list-item-view'

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
  classNames: [LIST_ITEM_CLASS]

  ###
    Adds a `loading` class to the listing element if its content isn't loaded.

    @property classNameBindings
    @type Array
    @default ['isLoaded::loading']
  ###
  classNameBindings: ['fluctuateListingClass', 'isLoaded::loading']

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
  styleBindings: ['top', 'display', 'position', 'height', 'pointer-events']

  ###
    In pixels, the height of each listing. Typically, this value is provided
    by the `rowHeight` property of the parent `Emberella.ListView`.

    @property rowHeight
    @type Integer
  ###
  rowHeightBinding: 'parentView.rowHeight'

  ###
    Give each child listing an additional class name based on the child's
    content index.

    For example, setting this property to 2 will cause listings to alternate
    between a class containing 0 or 1. (contentIndex % 2)

    @property fluctuateListing
    @type Integer
    @default 2
  ###
  fluctuateListing: 2

  ###
    The seed for the fluctuated class name.

    For example, setting this property to `item-listing` would result in class
    names like `item-listing-0` and `item-listing-1`.

    @property fluctuateListingPrefix
    @type String
    @default 'emberella-list-item-view'
  ###
  fluctuateListingPrefix: LIST_ITEM_CLASS

  "pointer-events": Ember.computed ->
    if get(@, 'parentView.isScrolling') then 'none' else undefined
  .property('parentView.isScrolling')

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
    Additional class name for this listing.

    @property fluctuateListingClass
    @type String
  ###
  fluctuateListingClass: Ember.computed ->
    contentIndex = get @, 'contentIndex'
    fluctuateListing = parseInt get(@, 'fluctuateListing'), 10
    fluctuateListingPrefix = get @, 'fluctuateListingPrefix'
    return '' unless fluctuateListing and fluctuateListing > 0
    [fluctuateListingPrefix, (contentIndex % fluctuateListing)].join('-')
  .property 'contentIndex', 'fluctuateListing', 'fluctuateListingPrefix'

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
