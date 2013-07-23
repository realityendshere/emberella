###
@module emberella
@submodule emberella-views
###

Emberella = window.Emberella
jQuery = window.jQuery
get = Ember.get
set = Ember.set
SIZER_PROPERTY = '_sizing_element'
SIZER_CLASS = 'flexible-text-field-sizer'

###
  `Emberella.FlexibleTextField` enhances Ember's standard TextField with the
  ability to expand horizontally as the value grows in length.

  @class FlexibleTextField
  @namespace Emberella
  @extends Ember.TextField
###

Emberella.FlexibleTextField = Ember.TextField.extend Ember.StyleBindingsMixin, Emberella.FocusableMixin,

  ###
    Defines an array of properties to transform into styles on the listing's
    DOM element.

    Functionality provided by `Ember.StyleBindingsMixin`.

    @property styleBindings
    @type Array
    @default ['width']
  ###
  styleBindings: ['width', 'max-width']

  ###
    Add the class name `emberella-flexible-text-field`.

    @property classNames
    @type Array
    @default ['emberella-flexible-text-field']
  ###
  classNames: ['emberella-flexible-text-field']

  ###
    If true, leading and trailing whitespace will be trimmed from the value of
    the text field each time it loses focus.

    @property trimWhitespace
    @type Boolean
    @default true
  ###
  trimWhitespace: true

  ###
    In pixels, the maximum width allowed for the text field regardless of the
    value's length.

    Set to 0 to allow the text field to grow as tall as needed to display
    its value.

    @property maxWidth
    @type Integer
    @default 0
  ###
  maxWidth: 0

  ###
    In pixels, the minimum width allowed for the text field regardless of the
    value's length.

    @property minWidth
    @type Integer
    @default 4
  ###
  minWidth: 4

  ###
    In pixels, the current width of the text field.

    Note: the initial value of `null` is critical for allowing the flexible
    text field to accurately calculate the width necessary to display
    its value.

    @property width
    @type Integer|Null
    @default null
  ###
  width: Ember.computed.defaultTo 'minWidth'

  ###
    A max-width style of 100% to keep the text field from easily growing out
    of bounds.

    @property max-width
    @type String
    @default '100%'
  ###
  'max-width': '100%'

  ###
    @private

    A reference to the sizing element used to calculate the width necessary
    to display the current value of the text field without truncation.

    @property _sizing_element
    @type jQuery
    @default null
  ###
  _sizing_element: null

  ###
    After the value changes, recalculate the width of the text field

    @method adjustWidth
  ###
  adjustWidth: Ember.observer ->
    sizer = @updateSizer()
    value = get @, 'value'

    #Run later to allow the DOM to update sizer node prior to computing width
    Ember.run.later(@, ->
      return if get(@, 'isDestroyed') or get(@, 'isDestroying')
      width = if value is '' then (2 + sizer.outerWidth()) else sizer.outerWidth()
      width = Math.max(width, get(@, 'minWidth'))
      width = width + 4 if value isnt ''
      maxWidth = +get(@, 'maxWidth')
      width = maxWidth if maxWidth and width > maxWidth
      set @, 'width', width
    , 1)
  , "value", "placeholder", "hasFocus"

  ###
    Create an invisible element to "mirror" the text field. Uses a jQuery
    object to quickly duplicate the styling of the text field to better
    ensure width calculations compensate for borders, padding, margins,
    fonts, etc.

    @method createSizer
    @return jQuery A reference to the sizer node
  ###
  createSizer: ->
    sizer = jQuery('<div/>') #create jQuery element
    sizer.addClass SIZER_CLASS #make it stylable

    syncStyles = ->
      #copy styles from text field to sizer node
      element = get(@, 'element')
      return unless element
      sizer.attr('style', getComputedStyle(element, "").cssText)

      #hide the sizer node
      sizer.css(
        position: 'absolute'
        zIndex: -1000
        visibility: 'hidden'
        width: 'auto'
        whiteSpace: 'nowrap'
      )

      #Insert the sizer node
      @$().after(sizer)

    Ember.run.schedule 'afterRender', @, syncStyles
    set(@, SIZER_PROPERTY, sizer)
    sizer

  ###
    Update the size calculation node with the current value of the text field.

    Will create the sizer node if it hasn't already been created.

    @method updateSizer
    @return jQuery A reference to the sizer node
  ###
  updateSizer: ->
    value = get(@, 'value') ? ''
    value = get(@, 'placeholder') if value is ''
    sizer = get(@, SIZER_PROPERTY) ? @createSizer()
    value = sizer.text(value).html().replace(/\s/gm, "&nbsp;")
    sizer.html(value)
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
    Adjust width after entry into the DOM.

    @event didInsertElement
  ###
  didInsertElement: ->
    @_super()
    @adjustWidth()

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

    # Update whitespace as needed
    set(@, 'value', jQuery.trim(get(@, 'value'))) if get(@, 'trimWhitespace')
