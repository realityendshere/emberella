###
@module emberella
@submodule emberella-mixins
###

Emberella = window.Emberella
get = Ember.get
MAP_SUFFIX = 'Pressed'
UNMAPPED_PREFIX = 'key'

###
  `Emberella.KeyboardControlMixin` adds keyboard event handling to a
  view class.

  Maps key codes for most of the non-alpha-numeric keys on the keyboard to more
  human readable method names.

  For example, pressing the left arrow key will cause this mixin to look for a
  `leftArrowPressed` method and call it.

  If a key code isn't mapped, the keyboard event will cause this mixin to look
  for a method with the key code included with the prefix `key`.

  For example, pressing the 'A' key would map to a method called `key65Pressed`.

  The keyboard event handling methods are passed the DOM event and boolean
  values representing the pressed state of the ALT, CTRL, META/COMMAND, and
  SHIFT keys.

  For example, to perform an action (e.g. select all) when the user presses
  CRTL+A, your view class might include the following:

  @example
    key65Pressed: function(e, alt, ctrl, meta, shift) {
      if (ctrl) {
        // DO SOMETHING INTERESTING
      }
    }

  Please note: this mixin actually responds to the `keyDown` event despite
  calling methods in the host view that contain the word `Pressed`.

  @class KeyboardControlMixin
  @namespace Emberella
###

Emberella.KeyboardControlMixin = Ember.Mixin.create
  ###
    @property isKeyboardControl
    @type Boolean
    @default true
    @final
  ###
  isKeyboardControl: true # quack like a duck

  ###
    Handle the DOM's `keyDown` event. Maps the key code of the event to a
    method to call on the host view.

    @event keyDown
  ###
  keyDown: (e) ->
    map = Emberella.KeyboardControlMixin.KEY_MAP
    code = e.keyCode
    method = @_methodNameForKeyCode code
    alt = e.altKey
    ctrl = e.ctrlKey
    meta = e.metaKey
    shift = e.shiftKey
    nodeName = e.target.nodeName.toUpperCase()

    if Ember.typeOf(@[method]) is 'function' and map[code]? and
    not(nodeName in ["INPUT", "SELECT", "TEXTAREA"])
      e.preventDefault()

    e.method = method
    @trigger(method, e, alt, ctrl, meta, shift) unless get(@, 'disabled')

  ###
    @private

    Makes a method name out of a key code.

    @method _methodNameForKeyCode
    @return String
  ###
  _methodNameForKeyCode: (code) ->
    map = Emberella.KeyboardControlMixin.KEY_MAP
    name = map[code] ? (UNMAPPED_PREFIX + code)
    name + MAP_SUFFIX

# Map of key codes to human-readable names.
Emberella.KeyboardControlMixin.KEY_MAP =
  8:    'backspace'
  9:    'tab'
  13:   'enter'
  16:   'shift'
  17:   'ctrl'
  18:   'alt'
  20:   'capslock'
  27:   'esc'
  33:   'pageUp'
  34:   'pageDown'
  35:   'end'
  36:   'home'
  37:   'leftArrow'
  38:   'upArrow'
  39:   'rightArrow'
  40:   'downArrow'
  46:   'delete' #"forward delete"
  93:   'meta'
  112:  'f1'
  113:  'f2'
  114:  'f3'
  115:  'f4'
  116:  'f5'
  117:  'f6'
  118:  'f7'
  119:  'f8'
  120:  'f9'
  121:  'f10'
  122:  'f11'
  123:  'f12'
  124:  'f13'
  125:  'f14'
  126:  'f15'
  127:  'f16'
  128:  'f17'
  129:  'f18'
  130:  'f19'
