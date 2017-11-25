z = require 'zorium'
Environment = require 'clay-environment'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_find = require 'lodash/find'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/observable/combineLatest'
require 'rxjs/operator/map'
require 'rxjs/operator/switchMap'

Base = require '../base'
Icon = require '../icon'
Spinner = require '../spinner'
PrimaryButton = require '../primary_button'
FormatService = require '../../services/format'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

# TODO: make it clear that they earn xp for sticker packs

module.exports = class GroupEarnXp
  constructor: ({@model, @router, group, sort, filter, gameKey}) ->
    @$spinner = new Spinner()

    groupAndGameKey = RxObservable.combineLatest(
      group
      gameKey
      (vals...) -> vals
    )

    xpActions = groupAndGameKey.switchMap ([group, gameKey]) =>
      @model.groupUserXpTransaction.getAllByGroupId group.id
      .map (xpTransactions) =>
        videoTransaction = _find xpTransactions, {actionKey: 'rewardedVideos'}
        videosLeft = 3 - (videoTransaction?.count or 0)
        _filter [
          if Environment.isGameApp(config.GAME_KEY)
            {
              action: 'Watch ad'
              actionKey: 'rewardedVideos'
              xp: 1
              $claimButton: new PrimaryButton()
              $claimButtonText: "Watch (#{videosLeft} left)"
              isClaimed: not videosLeft
              onclick: =>
                @state.set loadingActionKey: 'rewardedVideos'
                @model.portal.call 'admob.prepareRewardedVideo', {
                  adId: if Environment.isiOS() \
                        then 'ca-app-pub-9043203456638369/5979905134'
                        else 'ca-app-pub-9043203456638369/8896044215'
                }
                .then =>
                  timestamp = Date.now()
                  @model.portal.call 'admob.showRewardedVideo', {timestamp}
                  .then (successKey) =>
                    @state.set loadingActionKey: null
                    @model.groupUserXpTransaction.incrementByGroupIdAndActionKey(
                      group.id, 'rewardedVideos', {timestamp, successKey}
                    )
                .catch =>
                  @state.set loadingActionKey: null
            }
          {
            action: 'Daily visit'
            actionKey: 'dailyVisit'
            xp: 5
            $claimButton: new PrimaryButton()
            $claimButtonText: 'Claim'
            isClaimed: _find xpTransactions, {actionKey: 'dailyVisit'}
            onclick: (e) =>
              @state.set loadingActionKey: 'dailyVisit'
              @model.groupUserXpTransaction.incrementByGroupIdAndActionKey(
                group.id, 'dailyVisit'
              )
              .catch -> null
              .then =>
                $$button = e?.target
                if $$button
                  boundingRect = $$button.getBoundingClientRect?()
                  x = boundingRect?.left + boundingRect?.width / 2
                  y = boundingRect?.top
                else
                  x = e?.clientX
                  y = e?.clientY
                @model.xpGain.show {xp: 5, x, y}
                @state.set loadingActionKey: null
          }
          {
            action: 'Daily chat message'
            actionKey: 'dailyChatMessage'
            route:
              key: 'groupChat'
              replacements: {id: group.key or group.id, gameKey}
            xp: 5
            $claimButton: new PrimaryButton()
            $claimButtonText: 'Go to chat'
            isClaimed: _find xpTransactions, {actionKey: 'dailyChatMessage'}
          }
          if group.id is 'ad25e866-c187-44fc-bdb5-df9fcc4c6a42'
            {
              action: 'Daily video watched'
              actionKey: 'dailyVideoView'
              route:
                key: 'groupVideos'
                replacements: {id: group.key or group.id, gameKey}
              xp: 5
              $claimButton: new PrimaryButton()
              $claimButtonText: 'Go to videos'
              isClaimed: _find xpTransactions, {actionKey: 'dailyVideoView'}
            }
        ]

    @state = z.state
      me: @model.user.getMe()
      xpActions: xpActions
      loadingActionKey: null

  render: =>
    {me, xpActions, loadingActionKey} = @state.getValue()

    z '.z-group-earn-xp',
      z '.g-grid',
        z '.g-cols',
        _map xpActions, (item) =>
          {action, route, xp, onclick, isClaimed, actionKey,
            $claimButton, $claimButtonText} = item
          isLoading = loadingActionKey is actionKey
          z '.g-col.g-xs-12.g-md-6',
            z '.action',
              # z '.icon',
              #   style:
              #     backgroundImage: "url(#{config.CDN_URL}/movie.png)"

              z '.title', action
              z '.amount',
                z 'span',
                  innerHTML: '&nbsp;&middot;&nbsp;'
                "#{xp}xp"
              z '.button',
                if isClaimed
                  'Claimed'
                else
                  z $claimButton,
                    text: if isLoading \
                          then @model.l.get 'general.loading'
                          else $claimButtonText
                    onclick: (e) =>
                      onclick? e
                      if route
                        @router.go route.key, route.replacements
