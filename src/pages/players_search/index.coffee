z = require 'zorium'

PlayersSearch = require '../../components/players_search'
AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class PlayersSearchPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$playersSearch = new PlayersSearch {@model, @router, serverData}

    @state = z.state
      windowSize: @model.window.getSize()

  getMeta: =>
    {
      title: @model.l.get 'playersSearchPage.title'
      description: @model.l.get 'playersSearchPage.title'
    }

  render: =>
    {windowSize} = @state.getValue()

    z '.p-players-search', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: @model.l.get 'playersSearchPage.title'
        style: 'primary'
        isFlat: true
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      @$playersSearch
