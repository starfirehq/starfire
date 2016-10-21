z = require 'zorium'
Rx = require 'rx-lite'
_ = require 'lodash'
_map = require 'lodash/collection/map'
_mapValues = require 'lodash/object/mapValues'
_isEmpty = require 'lodash/lang/isEmpty'

config = require '../../config'
colors = require '../../colors'
Head = require '../../components/head'
AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
Cards = require '../../components/cards'
Icon = require '../../components/icon'

if window?
  require './index.styl'

module.exports = class CardsPage
  constructor: ({@model, requests, @router, serverData}) ->
    @$head = new Head({
      @model
      requests
      serverData
      meta: {
        title: 'Battle Cards'
        description: 'Battle Cards'
      }
    })
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model}

    @$cards = new Cards {@model, @router, sort: 'popular'}

  renderHead: => @$head

  render: =>
    z '.p-cards', {
      style:
        height: "#{window?.innerHeight}px"
    },
      z @$appBar, {
        title: 'Battle Cards'
        isFlat: true
        $topLeftButton: z @$buttonMenu, {color: colors.$primary900}
      }
      @$cards