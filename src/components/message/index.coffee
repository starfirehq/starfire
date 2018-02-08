z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_truncate = require 'lodash/truncate'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Avatar = require '../avatar'
Icon = require '../icon'
ConversationImageView = require '../conversation_image_view'
FormatService = require '../../services/format'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

TITLE_LENGTH = 30
DESCRIPTION_LENGTH = 100

module.exports = class Message
  constructor: (options) ->
    {message, @$body, isGrouped, isMe, @model, @overlay$,
      @selectedProfileDialogUser, @router, @messageBatchesStreams} = options

    @$avatar = new Avatar()
    @$trophyIcon = new Icon()
    @$statusIcon = new Icon()
    @$starIcon = new Icon()
    @$verifiedIcon = new Icon()
    @$fireIcon = new Icon()

    @imageData = new RxBehaviorSubject null
    @$conversationImageView = new ConversationImageView {
      @model
      @imageData
      @overlay$
      @router
    }

    me = @model.user.getMe()

    @state = z.state
      message: message
      isMe: isMe
      isGrouped: isGrouped
      isMeMentioned: me.map (me) ->
        mentions = message?.body?.match? config.MENTION_REGEX
        _find mentions, (mention) ->
          username = mention.replace('@', '').toLowerCase()
          username and username is me?.username
      windowSize: @model.window.getSize()

  render: ({isTextareaFocused, openProfileDialogFn, isTimeAlignedLeft}) =>
    {isMe, message, isGrouped, isMeMentioned, windowSize} = @state.getValue()

    {user, groupUser, time, card, id, clientId} = message

    groupUpgrades = _filter user?.upgrades, {groupId: groupUser?.groupId}
    hasBadge = _find groupUpgrades, {upgradeType: 'fireBadge'}

    avatarSize = if windowSize.width > 840 \
                 then '40px'
                 else '40px'

    onclick = ->
      unless isTextareaFocused
        openProfileDialogFn id, user, groupUser

    oncontextmenu = ->
      openProfileDialogFn id, user

    isVerified = user and user.gameData?.isVerified
    isModerator = groupUser?.roleNames and
                  groupUser.roleNames.indexOf('mods') isnt -1

    z '.z-message', {
      # re-use elements in v-dom. doesn't seem to work with prepending more
      key: "message-#{id or clientId}"
      className: z.classKebab {isGrouped, isMe, isMeMentioned}
      oncontextmenu: (e) ->
        e?.preventDefault()
        oncontextmenu?()
    },
      z '.avatar', {
        onclick
        style:
          width: avatarSize
      },
        unless isGrouped
          z @$avatar, {
            user
            groupUser
            size: avatarSize
            bgColor: colors.$grey200
          }
        # z '.level', 1

      z '.content',
        unless isGrouped
          z '.author', {onclick},
            if user?.flags?.isStar
              z '.icon',
                z @$starIcon,
                  icon: 'star-tag'
                  color: colors.$tertiary900Text
                  isTouchTarget: false
                  size: '22px'
            if user?.flags?.isDev
              z '.icon',
                z @$statusIcon,
                  icon: 'dev'
                  color: colors.$tertiary900Text
                  isTouchTarget: false
                  size: '22px'
            else if user?.flags?.isModerator or isModerator
              z '.icon',
                z @$statusIcon,
                  icon: 'mod'
                  color: colors.$tertiary900Text
                  isTouchTarget: false
                  size: '22px'
            z '.name', @model.user.getDisplayName user
            z '.icons',
              if isVerified
                z '.icon',
                  z @$verifiedIcon,
                    icon: 'verified'
                    color: colors.$tertiary900Text
                    isTouchTarget: false
                    size: '14px'
              if hasBadge
                z '.icon',
                  z @$fireIcon,
                    icon: 'fire'
                    color: colors.$quaternary500
                    isTouchTarget: false
                    size: '14px'
            z '.time', {
              className: z.classKebab {isAlignedLeft: isTimeAlignedLeft}
            },
              if time
              then DateService.fromNow time
              else '...'
            z '.middot',
              innerHTML: '&middot;'
            z '.trophies',
              FormatService.number user?.gameData?.data?.trophies
              z '.icon',
                z @$trophyIcon,
                  icon: 'trophy'
                  color: colors.$tertiary900Text54
                  isTouchTarget: false
                  size: '16px'

        z '.body',
          @$body

        if card
          z '.card', {
            onclick: (e) =>
              e?.stopPropagation()
              @router.openLink card.url
          },
            z '.title', _truncate card.title, {length: TITLE_LENGTH}
            z '.description', _truncate card.description, {
              length: DESCRIPTION_LENGTH
            }