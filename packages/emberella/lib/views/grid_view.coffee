#= require ./list_view

###
@module emberella
@submodule emberella-views
###

Emberella = window.Emberella
get = Ember.get
set = Ember.set

###
  `Emberella.GridView` is an `Ember.View` descendent designed to incrementally
  (or "lazily") display large lists without sacrificing performance.

  `Emberella.GridView` is an extension of `Emberella.ListView` with the ability
  to display listings in a grid-style layout.

  @class GridView
  @namespace Emberella
  @extends Emberella.ListView
###

Emberella.GridView = Emberella.ListView.extend

  ###
    Add the class name `emberella-grid-view`.

    @property classNames
    @type Array
    @default ['emberella-grid-view']
  ###
  classNames: ['emberella-grid-view']

  ###
    Specify the view class for each item listing. This view must be an instance
    of `Emberella.GridItemView` or otherwise fully implement the content
    recycling and re-positioning necessary for this incremental grid view to
    function as expected.

    @property itemViewClass
    @type Ember.View
    @default Emberella.GridItemView
  ###
  itemViewClass: Emberella.GridItemView

  ###
    Specify the width of each listing.

    @property columnWidth
    @type Integer
    @default 100
  ###
  columnWidth: 100

  ###
    In pixels, specify the space to leave to the left and right of
    each listing.

    Note: this "margin" is doubled between columns. For example, a margin
    of 10 would place the first column 10px from the left edge of the viewable
    area and a 20px gutter between the 1st and 2nd columns.

    @property columnWidth
    @type Integer
    @default 100
  ###
  margin: 10

  ###
    Computes the number of columns in the grid based on the columnWidth, the
    viewable area's width, and the margin.

    @property columns
    @type Integer
  ###
  columns: Ember.computed ->
    width = +get(@, 'width')
    columnWidth = +get(@, 'columnWidth')
    margin = +get(@, 'margin')
    result = Math.floor(width / (columnWidth + (2 * margin)))
    result = 1 if result < 1
    result
  .property 'columnWidth', 'margin', 'width'

  ###
    Recalculates column width to expand columns into the available
    viewable area.

    @property adjustedColumnWidth
    @type Integer
  ###
  adjustedColumnWidth: Ember.computed ->
    Math.floor(get(@, 'width') / get(@, 'columns'))
  .property 'columns', 'width'

  ###
    A computed property that indicates the height of the scrollable content.
    Typically calculated by multiplying the length of the content and the
    row height then dividing by the number of columns.

    Overrides standard `Emberella.ListView` behavior.

    @property totalHeight
    @type Integer
  ###
  totalHeight: Ember.computed ->
    contentLength = parseInt(get(@, 'content.length'), 10) || 0
    totalHeight = Math.ceil(contentLength / get(@, 'columns')) * get(@, 'rowHeight')
    totalHeight
  .property('content.length', 'rowHeight', 'height', 'columns')

  ###
    A computed property that indicates the index of the row closest to the
    top of the list that is (or should be) rendered.

    Overrides standard `Emberella.ListView` behavior to account for columns.

    @property startingIndex
    @type Integer
  ###
  startingIndex: Ember.computed ->
    idx = (Math.floor(get(@, 'scrollTop') / get(@, 'rowHeight')) - get(@, 'additionalRows')) * get(@, 'columns')
    if idx > 0 then idx else 0
  .property('scrollTop', 'rowHeight', 'additionalRows', 'columns')

  ###
    Calculates the specified item's scroll position from the top of the
    listing. Scrolling to the result should align the top of the item with the
    top of the viewable area.

    Overrides standard `Emberella.ListView` behavior to account for columns.

    @method computeItemScrollPosition
    @param {Integer} idx Index to calculate a scroll position for
    @return {Integer}
  ###
  computeItemScrollPosition: (idx) ->
    Math.floor(idx / get(@, 'columns')) * get(@, 'rowHeight')

  ###
    Calculates the number of list items to render.

    Overrides standard `Emberella.ListView` behavior to account for columns.

    @method numberOfVisibleItems
    @return {Integer}
  ###
  numberOfVisibleItems: ->
    items = get(@, 'visibleRows') * get(@, 'columns')
    Math.min items, get(@, 'content.length')

  ###
    @private

    Trigger event when the number of visible items appears to have changed.

    Overrides standard `Emberella.ListView` behavior to observe
    columns property.

    @method _visibleItemsDidChange
  ###
  _visibleItemsDidChange: Ember.observer ->
    @trigger('visibleItemsDidChange', (@numberOfVisibleItems() || 0))
  , 'visibleRows', 'columns'
