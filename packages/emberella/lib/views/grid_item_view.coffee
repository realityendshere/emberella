#= require ./list_item_view

###
@module emberella
@submodule emberella-views
###

Emberella = window.Emberella
get = Ember.get
set = Ember.set

###
  `Emberella.GridItemView` is an `Ember.View` designed for use as a child
  listing of `Emberella.GridView`.

  Extends `Emberella.ListItemView` and adds left and width position styling to
  support columns.

  @class GridItemView
  @namespace Emberella
  @extends Emberella.ListItemView
###

Emberella.GridItemView = Emberella.ListItemView.extend

  ###
    Add the class name `emberella-grid-item-view`.

    @property classNames
    @type Array
    @default ['emberella-grid-item-view']
  ###
  classNames: ['emberella-grid-item-view']

  ###
    Defines an array of properties to transform into styles on the listing's
    DOM element.

    Functionality provided by `Ember.StyleBindingsMixin`.

    @property styleBindings
    @type Array
    @default ['top', 'left', 'width', 'display', 'position']
  ###
  styleBindings: ['top', 'left', 'width', 'display', 'position']

  ###
    In pixels, the width of this listing. Typically, this value is provided
    by the `adjustedColumnWidth` property of the parent `Emberella.GridView`.

    @property columnWidth
    @type Integer
  ###
  columnWidthBinding: 'parentView.adjustedColumnWidth'

  ###
    The number of columns to account for when calculating the position of
    this listing. This value is obtained from the `columns` property of the
    parent `Emberella.GridView`.

    @property columns
    @type Integer
  ###
  columnsBinding: 'parentView.columns'

  ###
    In pixels, the size of the margin to incorporate into this listing's
    positioning calculations. This value is obtained from the `margin` property
    of the parent `Emberella.GridView`.

    @property margin
    @type Integer
  ###
  marginBinding: 'parentView.margin'

  ###
    In pixels, calculate the distance from the top this listing should be
    positioned within the scrolling list.

    Adjusts styling to account for the number of columns in the grid.

    @property top
    @type Integer
  ###
  top: Ember.computed ->
    columns = get(@, 'columns')
    columns = 1 if columns < 1
    Math.floor(get(@, 'contentIndex') / columns) * get(@, 'rowHeight')
  .property 'contentIndex', 'rowHeight', 'columns'

  ###
    In pixels, calculate the distance from the left this listing should be
    positioned within the scrolling list.

    @property left
    @type Integer
  ###
  left: Ember.computed ->
    columns = get(@, 'columns')
    columns = 1 if columns < 1
    ((get(@, 'contentIndex') % columns) * get(@, 'columnWidth')) + get(@, 'margin')
  .property 'contentIndex', 'columns', 'columnWidth'

  ###
    In pixels, the width of this listing.

    @property width
    @type Integer
  ###
  width: Ember.computed ->
    get(@, 'columnWidth') - (2 * get(@, 'margin'))
  .property 'margin', 'columnWidth'
