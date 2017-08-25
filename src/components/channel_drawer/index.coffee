z = require 'zorium'
Rx = require 'rx-lite'
_map = require 'lodash/map'

Icon = require '../icon'
ChannelList = require '../channel_list'
GroupBadge = require '../group_badge'
colors = require '../../colors'

if window?
  require './index.styl'

DRAWER_RIGHT_PADDING = 56
DRAWER_MAX_WIDTH = 336

module.exports = class ChannelDrawer
  constructor: ({@model, @router, @isOpen, group, conversation}) ->
    me = @model.user.getMe()

    @$channelList = new ChannelList {@model, @router, group}
    @$manageChannelsSettingsIcon = new Icon()

    @$groupBadge = new GroupBadge {@model, group}

    @state = z.state
      isOpen: @isOpen
      group: group
      conversation: conversation
      me: @model.user.getMe()

  render: =>
    {isOpen, group, me, conversation} = @state.getValue()

    hasAdminPermission = @model.group.hasPermission group, me, {level: 'admin'}

    z '.z-channel-drawer', {
      onclick: =>
        @isOpen.onNext false
    },
      z '.drawer', {
        onclick: (e) ->
          e?.stopPropagation()
      },
        z '.title', @model.l.get 'channelDrawer.title'

        z @$channelList, {
          selectedConversationId: conversation?.id
          onclick: (e, {id}) =>
            @router.go "/group/#{group?.id}/chat/#{id}", {
              ignoreHistory: true
            }
            @isOpen.onNext false
        }

        if hasAdminPermission
          [
            z '.divider'
            z '.manage-channels', {
              onclick: =>
                @router.go "/group/#{group?.id}/manage-channels"
            },
              z '.icon',
                z @$manageChannelsSettingsIcon,
                  icon: 'settings'
                  isTouchTarget: false
                  color: colors.$primary500
              z '.text', 'Manage channels'
          ]
