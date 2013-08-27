# require ../mixins/membership_mixin

###
@module emberella
@submodule emberella-views
###

Emberella = window.Emberella
jQuery = window.jQuery
get = Ember.get
set = Ember.set
typeOf = Ember.typeOf

DEFAULT_ITEM_TEMPLATE = Ember.Handlebars.compile [
  '{{view.displayContent}}'
].join(' ')

DEFAULT_HEADING_TEMPLATE = Ember.Handlebars.compile([
  '<span class="emberella-source-list-heading-content">'
    '{{view.content}}'
  '</span>'
].join(' '))

###
  Displays a "source listing" with distinctive heading views with their own
  styling, content, and interaction patterns. In theory,
  `Emberella.SourceListView` can be used as the basis for creating a sidebar
  similar to "iTunes" or "iPhoto".

  @class SourceListView
  @namespace Emberella
  @extends Emberella.CollectionView
  @uses Emberella.MembershipMixin
###
Emberella.SourceListView = Emberella.ContainerView.extend Emberella.MembershipMixin,
  # Private bookkeeping property
  _listingDepth: 0

  leadViewBinding: '_self'

  isVisibleBinding: 'parentView.isVisible'

  ###
    @private

    The default `headingProperty` if the `headingProperty` is empty.

    @property defaultGroupNameProperty
    @type String
    @default 'heading'
    @final
  ###
  defaultHeadingProperty: 'heading'

  ###
    Add the 'emberella-source-list' class to the listing element. Use this
    class to style your source listing view.

    @property classNames
    @type Array
    @default ["emberella-source-list"]
  ###
  classNames: [ "emberella-source-list" ]

  classNameBindings: [ 'isOriginalSource:emberella-source-original', 'listingDepthClassName' ]

  ###
    Specifies which child views to render

    @property childViews
    @type Array
    @default ['headingView', 'listView']
  ###
  childViews: ['headingView', 'listView']

  ###
    Flag to indicate if this is the root of the source listing tree.

    @property isOriginalSource
    @type Boolean
    @default true
  ###
  isOriginalSource: true

  ###
    Specify if item views in this collection should be visible.

    @property isListingVisible
    @type Boolean
    @default true
  ###
  isListingVisible: true

  ###
    The number of pixels to indent listing content.

    If `0`, no styles will be added to the DOM.

    @property indentSize
    @type Integer
    @default 10
  ###
  indentSize: 10

  ###
    Text to display above this listing if getting a value from the content's
    `headingProperty` is fruitless.

    For example, if the `heading` is `"Libraries"` and the `headingProperty` is
    `"myDisplayTitle"`, then the heading view will first try to display
    `content.myDisplayTitle`. If `content.myDisplayTitle` is empty, then the
    heading view will render "Libraries" instead.

    @property heading
    @type String
    @default ''
  ###
  heading: ''

  ###
    The property in this view's content to get a heading from.

    For example, if the `headingProperty` is `"myDisplayTitle"`, the view will
    look at `content.myDisplayTitle` for heading text to display above
    the listing.

    @property headingProperty
    @type String
    @default 'heading'
  ###
  headingProperty: Ember.computed.defaultTo 'defaultHeadingProperty'

  ###
    The `content` for this view will typically be an array of objects. Thus,
    the content for each individual listing view will typically be a single
    object. The `contentPath` informs the item listings which property or
    attribute to display in the default template.

    As a default, this property is bound to `content.contentPath`.

    @property contentPath
    @type String
  ###
  contentPathBinding: 'content.contentPath'

  ###
    An `Ember.View` class to use to render a heading above this source listing.

    @property headingViewClass
    @type {String|Class}
    @default 'Emberella.SourceListHeadingView'
  ###
  headingViewClass: 'Emberella.SourceListHeadingView'

  ###
    An `Ember.CollectionView` class to use to render the content list.

    @property listViewClass
    @type {String|Class}
    @default 'Emberella.SourceCollectionView'
  ###
  listViewClass: 'Emberella.SourceCollectionView'

  ###
    An `Ember.View` class to use to render each item listing.

    @property itemViewClass
    @type {String|Class}
    @default 'Emberella.SourceListItemView'
  ###
  itemViewClass: 'Emberella.SourceListItemView'

  ###
    Computes the root source listing: the ancestor view that ultimately spawned
    this view isntance.

    @property originalSource
    @type Ember.View
  ###
  originalSource: Ember.computed ->
    result = @

    findOriginalSource = (view) ->
      result = if get(view, 'isOriginalSource') then view else findOriginalSource(get(view, 'parentView'))

    findOriginalSource @

    result
  .property('isOriginalSource', 'parentView').readOnly()

  ###
    The heading view instance.

    @property headingView
    @type Ember.View
  ###
  headingView: Ember.computed ->
    @_getViewClass('headingViewClass')
  .property 'headingViewClass'

  ###
    The collection view instance.

    @property listView
    @type Ember.View
  ###
  listView: Ember.computed ->
    @_getViewClass('listViewClass')
  .property 'listViewClass'

  ###
    An array of all item listings contained in this view.

    @readOnly
    @property listings
    @type Array
  ###
  listings: Ember.computed ->
    @getListings()
  .volatile().readOnly()

  ###
    An array of all visible (i.e. `isVisible` is `true`) item listings
    contained in this view.

    @readOnly
    @property visibleListings
    @type Array
  ###
  visibleListings: Ember.computed ->
    @getVisibleListings()
  .volatile().readOnly()

  ###
    How far removed from the base listing this view instance is.

    @property listingDepth
    @type Integer
  ###
  listingDepth: Ember.computed (key, value) ->
    privateKey = '_' + key

    if arguments.length is 1
      return if (get(@, 'isOriginalSource') or isNaN(listingDepth = parseInt(get(@, 'leadView.listingDepth'), 10))) then get(@, privateKey) else listingDepth + 1

    else
      return set(@, privateKey, value)
  .property('leadView.listingDepth')

  ###
    Generates a class name to indicate (and allow styling for) the current
    "depth" of this source listing instance.

    @property listingDepthClassName
    @type String
  ###
  listingDepthClassName: Ember.computed ->
    'emberella-source-list-' + get(@, 'listingDepth')
  .property('listingDepth')

  ###
    Assembles an array of all visible (i.e. `isVisible` is `true`) item
    listings contained in this view.

    @method getVisibleListings
    @return Array
  ###
  getVisibleListings: ->
    @getListings(true)

  ###
    Assembles an array of listings contained in this view.

    @method getListings
    @param Boolean visibleOnly If true, include visible listings only
    @return Array
  ###
  getListings: (visibleOnly) ->
    results = Ember.A()
    itemViewClass = get(@, 'itemViewClass')

    extractItems = (view) ->
      childViews = get view, 'childViews'
      for childView in childViews
        continue if visibleOnly and !get(childView, 'isVisible')
        if (childView instanceof itemViewClass)
          results.push(childView)
        else
          extractItems(childView)
      results

    extractItems(@)

    results

  ###
    Toggles the `isListingVisible` property to show or hide this view's
    descendants.

    @method toggleVisibility
    @chainable
  ###
  toggleVisibility: ->
    @toggleProperty('isListingVisible')
    @

  ###
    @private

    Attempts to retrieve a view class from a given property name.

    @method _getViewClass
    @return Ember.View
  ###
  _getViewClass: (property) ->
    viewClass = get(@, property)
    viewClass = get(viewClass) if typeOf(viewClass) is 'string'
    viewClass


###############################################################################
###############################################################################


###
  `Emberella.SourceListHeadingView` is the default `headingViewClass` for an
  `Emberella.SourceListView`. It can be extended or replaced as needed to
  customize the look or behavior of the headings in a source listing.

  @class SourceListHeadingView
  @namespace Emberella
  @extends Emberella.View
  @uses Ember.StyleBindingsMixin
  @uses Emberella.MembershipMixin
###
Emberella.SourceListHeadingView = Emberella.View.extend Ember.StyleBindingsMixin, Emberella.MembershipMixin,
  inherit: ['isListingVisible', 'listingDepth', 'indentSize', 'heading', 'headingProperty']

  ###
    @private

    The default template for heading views.

    @property defaultTemplate
    @type Handlebars
    @final
  ###
  defaultTemplate: DEFAULT_HEADING_TEMPLATE

  ###
    Add the 'emberella-source-list-heading' class to the heading element.
    Use this class to style your heading views.

    @property classNames
    @type Array
    @default ["emberella-source-list-heading"]
  ###
  classNames: [ "emberella-source-list-heading" ]

  ###
    Toggle the `display` style based on the property of the same name.

    Set the `padding-left` style based on the `identation` property.

    @property styleBindings
    @type Array
    @default ['display', 'identation:padding-left']
  ###
  styleBindings: ['display', 'identation:padding-left']

  ###
    The heading content to display.

    @property content
    @type String
  ###
  content: Ember.computed ->
    headingProperty = get @, 'headingProperty'
    displayContent = get(@, 'parentView.content.' + headingProperty)
    if (Ember.isEmpty(displayContent)) then get(@, 'heading') else displayContent
  .property('heading', 'headingProperty').readOnly()

  ###
    How many pixels to indent this heading from the left.

    @property identation
    @type Integer
  ###
  identation: Ember.computed ->
    indentSize = (parseInt(get(@, 'indentSize'), 10) || 0)
    if indentSize then ((parseInt(get(@, 'listingDepth'), 10) || 0)) * indentSize else undefined
  .property('listingDepth', 'indentSize').readOnly()

  ###
    Set display style to 'none' when content is empty.

    @property display
    @type String
  ###
  display: Ember.computed ->
    if Ember.isEmpty(get(@, 'content')) then 'none' else undefined
  .property 'content'


###############################################################################
###############################################################################


###
  `Emberella.SourceCollectionView` is the default `listViewClass` for an
  `Emberella.SourceListView`. It offers support for recursive creation of
  source listing views.

  @class SourceListItemView
  @namespace Emberella
  @extends Emberella.View
  @uses Ember.StyleBindingsMixin
  @uses Emberella.MembershipMixin
###
Emberella.SourceCollectionView = Emberella.CollectionView.extend Emberella.MembershipMixin,
  inherit: ['itemViewClass', 'content', 'listingDepth', 'isVisible:isListingVisible']

  ###
    Add the 'emberella-source-collection' class to the collection element. Use this
    class to style your source listing's collection view.

    @property classNames
    @type Array
    @default ["emberella-source-collection"]
  ###
  classNames: [ "emberella-source-collection" ]

  # Overrides `Ember.CollectionView`
  createChildView: (viewClass, attrs) ->
    heading = get(attrs, 'content.heading') if attrs?
    children = get(attrs, 'content.children') if attrs?

    if (children?)
      return @createChildView(get(@, 'leadView.constructor'),
        isOriginalSource: false
        elementId: null
        heading: heading
        content: children
        leadViewBinding: 'parentView.leadView'
        indentSizeBinding: 'leadView.indentSize'
        headingPropertyBinding: 'leadView.headingProperty'
      )

    @_super(viewClass, attrs)


###############################################################################
###############################################################################


###
  `Emberella.SourceListItemView` is the default `itemViewClass` for an
  `Emberella.SourceListView`. It can be extended or replaced as needed to
  customize the look or behavior of the listings in a source listing.

  @class SourceListItemView
  @namespace Emberella
  @extends Emberella.View
  @uses Ember.StyleBindingsMixin
  @uses Emberella.MembershipMixin
###
Emberella.SourceListItemView = Emberella.View.extend Ember.StyleBindingsMixin, Emberella.MembershipMixin,
  inherit: ['contentPath', 'isVisible:isListingVisible', 'listingDepth', 'indentSize']

  leadViewBinding: 'parentView.leadView'

  ###
    @private

    The default template for item listings.

    @property defaultTemplate
    @type Handlebars
    @final
  ###
  defaultTemplate: DEFAULT_ITEM_TEMPLATE

  ###
    Add the 'emberella-source-list-item' class to the listing element.
    Use this class to style your listing views.

    @property classNames
    @type Array
    @default ["emberella-source-list-item"]
  ###
  classNames: [ "emberella-source-list-item" ]

  ###
    Set the `padding-left` style based on the `identation` property.

    @property styleBindings
    @type Array
    @default ['identation:padding-left']
  ###
  styleBindings: ['identation:padding-left']

  ###
    How many pixels to indent this listing from the left.

    @property identation
    @type Integer
  ###
  identation: Ember.computed (key, value) ->
    indentSize = (parseInt(get(@, 'indentSize'), 10) || 0)
    if indentSize then ((parseInt(get(@, 'listingDepth'), 10) || 0) + 1) * indentSize else undefined
  .property('listingDepth', 'indentSize').readOnly()

  ###
    The computed content to display.

    @property content
    @type String
  ###
  displayContent: Ember.computed (key, value) ->
    return '' if Ember.isEmpty(content = get(@, 'content'))
    contentPath = get(@, 'contentPath') ? ''
    get(content, contentPath) ? content
  .property('content', 'contentPath').readOnly()
