z = require 'zorium'

Head = require '../../components/head'
NewDeck = require '../../components/new_deck'

if window?
  require './index.styl'

module.exports = class NewDeckPage
  constructor: ({model, requests, @router, serverData}) ->
    @$head = new Head({
      model
      requests
      serverData
      meta: {
        title: 'New Deck'
        description: 'New Deck'
      }
    })
    @$newDeck = new NewDeck {model, @router}

  renderHead: => @$head

  render: =>
    z '.p-new-deck', {
      style:
        height: "#{window?.innerHeight}px"
    },
      @$newDeck
