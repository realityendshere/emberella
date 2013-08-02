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

###

  @class SourceListView
  @namespace Emberella
###

Emberella.SourceListView = Emberella.CollectionView.extend Emberella.MembershipMixin,
  # Private bookkeeping property
  _listingDepth: 0

  leadViewBinding: '_self'

  classNames: [ "emberella-source-list" ]

  defaultGroupNameProperty: 'groupName'

  isVisibleBinding: 'parentView.isListingVisible'

  isListingVisible: true

  indentSize: 10

  groupName: ''

  groupNameProperty: Ember.computed.defaultTo 'defaultGroupNameProperty'

  contentPathBinding: 'content.contentPath'

  defaultTemplate: Ember.Handlebars.compile [
    '{{view.displayContent}}'
  ].join(' ')

  listings: Ember.computed ->
    @getListings()
  .property('childViews.@each', 'childViews.@each.listings')

  visibleListings: Ember.computed ->
    @getVisibleListings()
  .property('childViews.@each', 'childViews.@each.isVisible', 'childViews.@each.visibleListings')

  getVisibleListings: ->
    @getListings true

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

  listingDepth: Ember.computed (key, value) ->
    privateKey = '_' + key

    if arguments.length is 1
      parentDepth = parseInt get(@, 'parentView.listingDepth'), 10
      return if isNaN(parentDepth) then get(@, privateKey) else parentDepth + 1

    else
      return set(@, privateKey, value)
  .property('parentView.listingDepth')

  toggleVisibility: ->
    @toggleProperty('isListingVisible')

  headingViewClass: 'Emberella.SourceListHeadingView'

  itemViewClass: 'Emberella.SourceListItemView'

  createChildView: (viewClass, attrs) ->
    groupName = get(attrs, 'content.groupName') if attrs?
    children = get(attrs, 'content.children') if attrs?

    if (children?)
      return @createChildView(@constructor,
        groupName: groupName
        content: children
        leadViewBinding: 'parentView.leadView'
        indentSizeBinding: 'leadView.indentSize'
        groupNamePropertyBinding: 'leadView.groupNameProperty'
      )

    @_super(viewClass, attrs)

  arrayDidChange: (content, start, removed, added) ->
    @_super(content, start, removed, added)

    unless Ember.isEmpty(groupName = get(@, 'groupName'))
      groupNameProperty = get @, 'groupNameProperty'
      headingViewClass = @_getViewClass 'headingViewClass'
      headingView = @createChildView(headingViewClass,
        # contentBinding: 'parentView.content.' + groupNameProperty
        groupName: groupName
      )
      @insertAt(0, headingView)

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


Emberella.SourceListHeadingView = Emberella.View.extend Ember.StyleBindingsMixin, Emberella.MembershipMixin,
  inherit: ['isListingVisible', 'listingDepth', 'indentSize', 'groupNameProperty']

  classNames: [ "emberella-source-list-heading" ]

  ###
    Toggle the `display` style based on the property of the same name.

    @property styleBindings
    @type Array
    @default ['display']
  ###
  styleBindings: ['display', 'identation:padding-left']

  groupName: ''

  content: Ember.computed ->
    groupNameProperty = get @, 'groupNameProperty'
    displayContent = get(@, 'parentView.content.' + groupNameProperty)
    if (Ember.isEmpty(displayContent)) then get(@, 'groupName') else displayContent
  .property('groupName', 'groupNameProperty').readOnly()

  defaultTemplate: Ember.Handlebars.compile([
    '<span class="emberella-source-list-heading-content">'
      '{{view.content}}'
    '</span>'
  ].join(' '))

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


Emberella.SourceListItemView = Emberella.View.extend Ember.StyleBindingsMixin, Emberella.MembershipMixin,
  inherit: ['template', 'contentPath', 'isVisible:isListingVisible', 'listingDepth', 'indentSize']

  styleBindings: ['identation:padding-left']

  identation: Ember.computed (key, value) ->
    indentSize = (parseInt(get(@, 'indentSize'), 10) || 0)
    if indentSize then ((parseInt(get(@, 'listingDepth'), 10) || 0) + 1) * indentSize else undefined
  .property('listingDepth', 'indentSize').readOnly()

  displayContent: Ember.computed (key, value) ->
    return '' if Ember.isEmpty(content = get(@, 'content'))
    contentPath = get(@, 'contentPath') ? ''
    get(content, contentPath) ? content
  .property('content', 'contentPath').readOnly()

  classNames: [ "emberella-source-list-item" ]

