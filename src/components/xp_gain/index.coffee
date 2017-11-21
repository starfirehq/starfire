z = require 'zorium'
Environment = require 'clay-environment'

colors = require '../../colors'

if window?
  require './index.styl'

# adding to DOM directly is faster than doing a full re-render

ANIMATION_TIME_MS = 1050

module.exports = class XpGain
  type: 'Widget'

  constructor: ({@model}) -> null

  afterMount: (@$$el) =>
    $$xp = document.createElement 'div'
    $$xp.className = 'xp'
    @mountDisposable = @model.xpGain.getXp().subscribe ({xp, x, y} = {}) =>
      $$xp.innerText = "+#{xp}xp"
      $$xp.style.left = x + 'px'
      $$xp.style.top = y + 'px'
      @$$el.appendChild $$xp
      setTimeout =>
        @$$el.removeChild $$xp
      , ANIMATION_TIME_MS

  beforeUnmount: =>
    @mountDisposable?.unsubscribe()

  render: ->
    z '.z-xp-gain'
