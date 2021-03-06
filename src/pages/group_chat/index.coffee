z = require 'zorium'
isUuid = require 'isuuid'
_find = require 'lodash/find'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/combineLatest'

GroupChat = require '../../components/group_chat'
AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
ChannelDrawer = require '../../components/channel_drawer'
ProfileDialog = require '../../components/profile_dialog'
GroupUserSettingsDialog = require '../../components/group_user_settings_dialog'
Icon = require '../../components/icon'
Environment = require '../../services/environment'
colors = require '../../colors'

if window?
  require './index.styl'

BOTTOM_BAR_HIDE_DELAY_MS = 500

module.exports = class GroupChatPage
  isGroup: true
  @hasBottomBar: true

  constructor: (options) ->
    {@model, requests, @router, serverData,
      @overlay$, @group, @$bottomBar} = options

    conversationId = requests.map ({route}) ->
      route.params.conversationId

    minTimeUuid = requests.map ({req}) ->
      req.query.minTimeUuid

    @isChannelDrawerOpen = new RxBehaviorSubject false
    selectedProfileDialogUser = new RxBehaviorSubject null
    isLoading = new RxBehaviorSubject false
    me = @model.user.getMe()

    conversationsAndConversationIdAndMe = RxObservable.combineLatest(
      @group.switchMap (group) =>
        @model.conversation.getAllByGroupId group.id
      conversationId
      me
      (vals...) -> vals
    )

    currentConversationId = null
    conversation = conversationsAndConversationIdAndMe
    .switchMap ([conversations, conversationId, me]) ->
      # side effect
      if conversationId isnt currentConversationId
        # is set to false when messages load in conversation component
        isLoading.next true

      currentConversationId = conversationId
      conversationId ?= _find(conversations, ({data, isDefault}) ->
        isDefault or data?.name is 'general' or data?.name is 'geral'
      )?.id
      conversationId ?= conversations?[0]?.id
      if conversationId
        RxObservable.of _find conversations, {id: conversationId}
      else
        RxObservable.of null
    # breaks switching groups (leaves getMessagesStream as prev val)
    # .publishReplay(1).refCount()

    @hasBottomBarObs = @model.window.getBreakpoint().map (breakpoint) ->
      breakpoint isnt 'desktop'

    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$settingsIcon = new Icon()
    @$linkIcon = new Icon()
    @$channelsIcon = new Icon()

    @$groupChat = new GroupChat {
      @model
      @router
      @group
      selectedProfileDialogUser
      @overlay$
      @group
      isLoading: isLoading
      conversation: conversation
      minTimeUuid: minTimeUuid
      onScrollUp: @showBottomBar
      onScrollDown: @hideBottomBar
      hasBottomBar: @hasBottomBarObs
    }

    @$profileDialog = new ProfileDialog {
      @model
      @router
      @group
      selectedProfileDialogUser
      @group
    }
    @$groupUserSettingsDialog = new GroupUserSettingsDialog {
      @model
      @router
      @group
      @group
      @overlay$
    }

    @$channelDrawer = new ChannelDrawer {
      @model
      @router
      @group
      conversation
      @group
      isOpen: @isChannelDrawerOpen
    }

    @isBottomBarVisible = false

    @state = z.state
      windowSize: @model.window.getSize()
      breakpoint: @model.window.getBreakpoint()
      group: @group
      me: me
      selectedProfileDialogUser: selectedProfileDialogUser
      isChannelDrawerOpen: @isChannelDrawerOpen
      conversation: conversation
      shouldShowBottomBar: @hasBottomBarObs

  afterMount: (@$$el) =>
    @isMounted = true
    @$$content = @$$el?.querySelector '.content'
    @isBottomBarVisible = true

    @model.portal.call 'admob.hideBanner'

    @hideTimeout = setTimeout @hideBottomBar, BOTTOM_BAR_HIDE_DELAY_MS
    @mountDisposable = @hasBottomBarObs.subscribe (hasBottomBar) =>
      if not hasBottomBar and @isBottomBarVisible
        @hideBottomBar()
      else if hasBottomBar and not @isBottomBarVisible
        @showBottomBar()

  showBottomBar: =>
    {shouldShowBottomBar} = @state.getValue()
    if shouldShowBottomBar and not @isBottomBarVisible and @isMounted
      @isBottomBarVisible = true
      @$bottomBar.show()
      @$$content.style.transform = 'translateY(0)'

  hideBottomBar: =>
    {shouldShowBottomBar} = @state.getValue()
    if shouldShowBottomBar and @isBottomBarVisible and @isMounted
      @isBottomBarVisible = false
      @$bottomBar.hide()
      @$$content.style.transform = 'translateY(64px)'

  beforeUnmount: =>
    @showBottomBar()
    clearTimeout @hideTimeout
    @isMounted = false
    @mountDisposable?.unsubscribe()
    adId = if Environment.isiOS() \
           then 'ca-app-pub-9043203456638369/5699503414'
           else 'ca-app-pub-9043203456638369/2454362164'
    @model.portal.call 'admob.showBanner', {
      position: 'bottom'
      overlap: false
      adId: adId
    }

  getMeta: =>
    {
      title: @model.l.get 'groupChatPage.title'
    }

  render: =>
    {windowSize, group, me, conversation, isChannelDrawerOpen, breakpoint
      selectedProfileDialogUser, shouldShowBottomBar} = @state.getValue()

    hasAdminPermission = @model.group.hasPermission group, me, {level: 'admin'}

    z '.p-group-chat', {
      className: z.classKebab {shouldShowBottomBar}
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        isFullWidth: true
        title: z '.p-group-chat_title', {
          onclick: =>
            @isChannelDrawerOpen.next not isChannelDrawerOpen
        },
          z '.group', group?.name
          z '.channel',
            z 'span.hashtag', '#'
            conversation?.data?.name
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
        $topRightButton:
          z '.p-group-chat_top-right',
            z '.icon',
              z @$settingsIcon,
                icon: 'settings'
                color: colors.$header500Icon
                onclick: =>
                  @overlay$.next @$groupUserSettingsDialog
            z '.channels-icon',
              z @$channelsIcon,
                icon: 'channels'
                color: colors.$header500Icon
                onclick: =>
                  @isChannelDrawerOpen.next true
      }
      z '.content', {
        key: 'group-chat-content' # since we change css (transform) manually
      },
        z @$groupChat
        if breakpoint is 'desktop'
          z @$channelDrawer
      @$bottomBar

      if selectedProfileDialogUser
        z @$profileDialog

      if breakpoint isnt 'desktop'
        z @$channelDrawer
