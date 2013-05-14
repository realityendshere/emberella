#= require ../mixins/style_bindings
#= require ../mixins/focusable_mixin

###
@module emberella
@submodule emberella-views
###

Emberella = window.Emberella
jQuery = window.jQuery
get = Ember.get
set = Ember.set
SIZER_PROPERTY = '_sizing_element'
SIZER_CLASS = 'flexible-text-area-sizer'

###
  `Emberella.FlexibleTextArea` enhances Ember's standard TextArea with the
  ability to expand vertically as the value grows in length. Thus, a string
  that requires 8 lines to display without truncation will be twice as tall as
  a string that is 4 lines tall.

  Values in the `FlexibleTextArea` may also be modified automatically to trim
  whitespace and collapse consecutive line breaks.

  @class FlexibleTextArea
  @namespace Emberella
  @extends Ember.TextArea
###

Emberella.FlexibleTextArea = Ember.TextArea.extend Ember.StyleBindingsMixin, Emberella.FocusableMixin,

  ###
    Defines an array of properties to transform into styles on the listing's
    DOM element.

    Functionality provided by `Ember.StyleBindingsMixin`.

    @property styleBindings
    @type Array
    @default ['height']
  ###
  styleBindings: ['height']

  ###
    Add the class name `emberella-flexible-text-area`.

    @property classNames
    @type Array
    @default ['emberella-flexible-text-area']
  ###
  classNames: ['emberella-flexible-text-area']

  ###
    If true, leading and trailing whitespace will be trimmed from the value of
    the text area each time it loses focus.

    @property trimWhitespace
    @type Boolean
    @default true
  ###
  trimWhitespace: true

  ###
    Sequences of multiple line breaks will be reduced to the number of line
    feeds specified by the `collapseWhitespace` property when the text area
    loses focus.

    For example, if `collapseWhitespace` is 2 and the value contains a sequence
    of 4 consecutive new lines, the 4 line breaks will be replaced with 2.

    Set to `0` if you do not wish to collapse line breaks.

    @property collapseWhitespace
    @type Integer
    @default 2
  ###
  collapseWhitespace: 2

  ###
    In pixels, the maximum height allowed for the text area regardless of the
    value's length.

    Set to 0 to allow the text area to grow as tall as needed to display
    its value.

    @property maxHeight
    @type Integer
    @default 0
  ###
  maxHeight: 0

  ###
    In pixels, the current height of the text area.

    Note: the initial value of `null` is critical for allowing the flexible
    text area to accurately calculate the height necessary to display
    its value.

    @property height
    @type Integer|Null
    @default null
  ###
  height: null

  ###
    @private

    A reference to the sizing element used to calculate the height necessary
    to display the current value of the text area without truncation.

    @property _sizing_element
    @type jQuery
    @default null
  ###
  _sizing_element: null

  ###
    After the value changes, recalculate the height of the text area

    @method adjustHeight
  ###
  adjustHeight: Ember.observer ->
    sizer = @updateSizer()

    #Run later to allow the DOM to update sizer node prior to computing height
    Ember.run.later(@, ->
      height = +sizer.height()
      maxHeight = +get(@, 'maxHeight')
      height = maxHeight if maxHeight and height > maxHeight
      set @, 'height', height
    , 1)
  , "value", "hasFocus"

  ###
    Create an invisible element to "mirror" the text area. Uses a jQuery
    object to quickly duplicate the styling of the text area to better
    ensure height calculations compensate for borders, padding, margins,
    fonts, etc.

    @method createSizer
    @return jQuery A reference to the sizer node
  ###
  createSizer: ->
    sizer = jQuery('<div/>') #create jQuery element
    sizer.addClass SIZER_CLASS #make it stylable

    #copy styles from text area to sizer node
    sizer.attr('style', getComputedStyle(get(@, 'element'), "").cssText)

    #hide the sizer node
    sizer.css(
      position: 'absolute'
      zIndex: -1000
      visibility: 'hidden'
    )

    #Insert the sizer node and stash a reference to it in a property
    @$().after(sizer)
    set(@, SIZER_PROPERTY, sizer)
    sizer

  ###
    Update the size calculation node with the current value of the text area.

    Will create the sizer node if it hasn't already been created.

    @method updateSizer
    @return jQuery A reference to the sizer node
  ###
  updateSizer: ->
    value = get(@, 'value') ? ''
    sizer = get(@, SIZER_PROPERTY) ? @createSizer()
    sizer.html(value.replace(/(\r\n|\n|\r)/gm, " <br/> "))
    sizer

  ###
    Removes the sizer node from the DOM.

    @method removeSizer
    @return null
  ###
  removeSizer: ->
    get(@, SIZER_PROPERTY)?.remove()
    set(@, SIZER_PROPERTY, null)
    null

  ###
    Handle imminent destruction.

    @event willDestroyElement
  ###
  willDestroyElement: ->
    @removeSizer()
    @_super()

  ###
    Handle blur event.

    @event focusOut
  ###
  focusOut: ->
    set @, 'hasFocus', false

    # Update whitespace as needed then scroll
    set(@, 'value', jQuery.trim(get(@, 'value'))) if get(@, 'trimWhitespace')
    @_collapseWhitespace() if get(@, 'collapseWhitespace')
    get(@, 'element').scrollTop = 0

  ###
    @private

    Replace long sequences of consecutive line feeds with the number of line
    feeds specified in the `collapseWhitespace` property.

    @method _collapseWhitespace
  ###
  _collapseWhitespace: ->
    collapseWhitespace = +get(@, 'collapseWhitespace')
    return unless collapseWhitespace
    value = (get(@, 'value') || '')
    exp = new RegExp("(\r\n|\n|\r){" + collapseWhitespace + ",}", 'gm')
    set @, 'value', value.replace(exp, new Array(collapseWhitespace + 1).join('$1'))
