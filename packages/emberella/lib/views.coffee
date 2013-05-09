Emberella.BaseViewMixin = Ember.Mixin.create
  baseViewBinding: 'parentView.baseView'
  init: ->
    @_super()
    @set '_self', @

Emberella.View           = Ember.View.extend           Emberella.BaseViewMixin
Emberella.ContainerView  = Ember.ContainerView.extend  Emberella.BaseViewMixin
Emberella.CollectionView = Ember.CollectionView.extend Emberella.BaseViewMixin
