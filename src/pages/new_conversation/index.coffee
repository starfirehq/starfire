z = require 'zorium'

Head = require '../../components/head'
NewConversation = require '../../components/new_conversation'

if window?
  require './index.styl'

module.exports = class NewConversationPage
  hideDrawer: true

  constructor: ({model, requests, @router, serverData}) ->
    group = requests.flatMapLatest ({route}) =>
      @model.group.getById route.params.id

    @$head = new Head({
      model
      requests
      serverData
      meta: {
        title: 'New Conversation'
        description: 'New Conversation'
      }
    })
    @$newConversation = new NewConversation {model, @router, serverData, group}

  renderHead: => @$head

  render: =>
    z '.p-new-conversation', {
      style:
        height: "#{window?.innerHeight}px"
    },
      @$newConversation
