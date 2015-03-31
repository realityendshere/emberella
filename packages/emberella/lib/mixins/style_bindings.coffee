# Copied from https://github.com/Addepar/ember-table/blob/master/dependencies/ember-addepar-mixins/style_bindings.js

# TODO: Improve CSS value escaping
escapeCSS = (value) ->
  # Eliminate semi-colons and any content following a semi-colon
  # This prevents anything other than a single style from being
  # set. However, this may disrupt some legitimate styles and
  # and doesn't cover all XSS attack vectors.
  return '' unless Ember.typeOf(value) is 'string'
  value.replace /;.*$/, ''

Ember.StyleBindingsMixin = Ember.Mixin.create
  isStyleBindings: true

  init: ->
    @applyStyleBindings()
    @_super()

  concatenatedProperties: ['styleBindings']

  attributeBindings: ['style']

  unitType: 'px'

  createStyleString: (styleName, property) ->
    value = @get property
    return unless value?
    @makeStyleProperty styleName, value

  makeStyleProperty: (styleName, value) ->
    if Ember.typeOf(value) is 'number'
      value = value + @get('unitType')
    else
      value = escapeCSS value
    "#{styleName}:#{value};"

  applyStyleBindings: ->
    styleBindings = @styleBindings
    return unless styleBindings

    # get properties from bindings e.g. ['width', 'top']
    lookup = {}
    styleBindings.forEach (binding) ->
      [property, style] = binding.split(':')
      lookup[(style or property)] = property
    styles     = Ember.keys(lookup)
    properties = styles.map (style) -> lookup[style]

    # create computed property
    styleComputed = Ember.computed =>
      styleTokens = styles.map (style) =>
        @createStyleString style, lookup[style]
      styleString = styleTokens.join('')
      # TODO: Figure out better way to return empty style without deprecation warning
      new Ember.Handlebars.SafeString(if (styleString.length is 0) then '' else styleString)

    # add dependents to computed property
    styleComputed.property.apply(styleComputed, properties)

    # define style computed properties
    Ember.defineProperty @, 'style', styleComputed
