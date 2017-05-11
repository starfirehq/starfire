z = require 'zorium'
_map = require 'lodash/map'
_take = require 'lodash/take'
_startCase = require 'lodash/startCase'
_upperFirst = require 'lodash/upperFirst'
_camelCase = require 'lodash/camelCase'
Rx = require 'rx-lite'
Environment = require 'clay-environment'
moment = require 'moment'

Icon = require '../icon'
UiCard = require '../ui_card'
RequestNotificationsCard = require '../request_notifications_card'
PrimaryButton = require '../primary_button'
SecondaryButton = require '../secondary_button'
FormatService = require '../../services/format'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ProfileInfo
  constructor: ({@model, @router, user}) ->
    @$trophyIcon = new Icon()
    @$arenaIcon = new Icon()
    @$levelIcon = new Icon()
    @$refreshIcon = new Icon()
    @$splitsInfoCard = new UiCard()
    @$followButton = new PrimaryButton()
    @$moreDetailsButton = new SecondaryButton()

    isRequestNotificationCardVisible = new Rx.BehaviorSubject(
      window? and not Environment.isGameApp(config.GAME_KEY) and
        not localStorage?['hideNotificationCard']
    )
    @$requestNotificationsCard = new RequestNotificationsCard {
      @model
      isVisible: isRequestNotificationCardVisible
    }

    @state = z.state {
      isRequestNotificationCardVisible
      hasUpdatedPlayer: false
      isRefreshing: false
      isSplitsInfoCardVisible: window? and not localStorage?['hideSplitsInfo']
      user: user
      me: @model.user.getMe()
      player: user.flatMapLatest ({id}) =>
        @model.player.getByUserIdAndGameId id, config.CLASH_ROYALE_ID
    }

  getWinRateFromStats: (stats) ->
    winsAndLosses = stats?.wins + stats?.losses
    winRate = FormatService.percentage(
      if winsAndLosses and not isNaN winsAndLosses
      then stats?.wins / winsAndLosses
      else 0
    )

  getTypeStats: (stats) =>
    [
      {
        name: @model.l.get 'profileInfo.statWins'
        value: FormatService.number stats?.wins
      }
      {
        name: @model.l.get 'profileInfo.statLosses'
        value: FormatService.number stats?.losses
      }
      {
        name: @model.l.get 'profileInfo.statDraws'
        value: FormatService.number stats?.draws
      }
      {
        name: @model.l.get 'profileInfo.statWinRate'
        value: @getWinRateFromStats stats
      }
      {
        name: @model.l.get 'profileInfo.statCrownsEarned'
        value: FormatService.number stats?.crownsEarned
      }
      {
        name: @model.l.get 'profileInfo.statCrownsLost'
        value: FormatService.number stats?.crownsLost
      }
      {
        name: @model.l.get 'profileInfo.statCurrentWinStreak'
        value: FormatService.number stats?.currentWinStreak
      }
      {
        name: @model.l.get 'profileInfo.statCurrentLossStreak'
        value: FormatService.number stats?.currentLossStreak
      }
      {
        name: @model.l.get 'profileInfo.statMaxWinStreak'
        value: FormatService.number stats?.maxWinStreak
      }
      {
        name: @model.l.get 'profileInfo.statMaxLossStreak'
        value: FormatService.number stats?.maxLossStreak
      }
    ]

  render: =>
    {player, isRequestNotificationCardVisible, hasUpdatedPlayer, isRefreshing
      isSplitsInfoCardVisible, user, me} = @state.getValue()

    isMe = user?.id and user?.id is me?.id
    isFollowing = @model.user.isFollowing me, user?.id

    metrics =
      stats: [
        {
          name: @model.l.get 'profileInfo.statWins'
          value: FormatService.number player?.data?.stats.wins
        }
        {
          name: @model.l.get 'profileInfo.statLosses'
          value: FormatService.number player?.data?.stats.losses
        }
        {
          name: @model.l.get 'profileInfo.statWinRate'
          value: @getWinRateFromStats player?.data?.stats
        }
        {
          name: @model.l.get 'profileInfo.statFavoriteCard'
          value: _startCase player?.data?.stats.favoriteCard
        }
        {
          name: @model.l.get 'profileInfo.statThreeCrowns'
          value: FormatService.number player?.data?.stats.threeCrowns
        }
        {
          name: @model.l.get 'profileInfo.statCardsFound'
          value: FormatService.number player?.data?.stats.cardsFound
        }
        {
          name: @model.l.get 'profileInfo.statMaxTrophies'
          value: FormatService.number player?.data?.stats.maxTrophies
        }
        {
          name: @model.l.get 'profileInfo.statTotalDonations'
          value: FormatService.number player?.data?.stats.totalDonations
        }
      ]
      ladder: @getTypeStats player?.data?.splits?.ladder
      grandChallenge: @getTypeStats player?.data?.splits?.grandChallenge
      classicChallenge: @getTypeStats player?.data?.splits?.classicChallenge

    lastUpdateTime = if player?.lastDataUpdateTime > player?.lastMatchesUpdateTime \
                     then player?.lastDataUpdateTime
                     else player?.lastMatchesUpdateTime

    z '.z-profile-info',
      z '.header',
        z '.g-grid',
          z '.info',
            z '.left',
              z '.name', player?.data?.name
              z '.tag', "##{player?.id}"
            if player?.data?.clan
              z '.right',
                z '.clan-name', player?.data?.clan.name
                z '.clan-tag', "##{player?.data?.clan.tag}"
          z '.g-cols',
            z '.g-col.g-xs-4',
              z '.icon',
                z @$trophyIcon,
                  icon: 'trophy'
                  color: colors.$secondary500
              z '.text', player?.data?.trophies
            z '.g-col.g-xs-4',
              z '.icon',
                z @$arenaIcon,
                  icon: 'castle'
                  color: colors.$secondary500
              z '.text', "Arena #{player?.data?.arena?.number}"
              if player?.data?.league
                z '.text', player?.data?.league?.name
            z '.g-col.g-xs-4',
              z '.icon',
                z @$levelIcon,
                  icon: 'crown'
                  color: colors.$secondary500
              z '.text', "Level #{player?.data?.level}"
        z '.divider'
        z '.g-grid',
          z '.last-updated',
            z '.time',
              @model.l.get 'profileInfo.lastUpdatedTime'
              ' '
              moment(lastUpdateTime).fromNowModified()
            if player?.isUpdatable and not hasUpdatedPlayer
              z '.refresh',
                if isRefreshing
                  '...'
                else
                  z @$refreshIcon,
                    icon: 'refresh'
                    isTouchTarget: false
                    color: colors.$primary500
                    onclick: =>
                      tag = player?.id
                      @state.set isRefreshing: true
                      @model.clashRoyaleAPI.refreshByPlayerTag tag
                      .then =>
                        @state.set hasUpdatedPlayer: true, isRefreshing: false

          unless isMe
            z '.follow-button',
              z @$followButton,
                text: if isFollowing \
                    then @model.l.get 'profileInfo.followButtonIsFollowingText'
                    else @model.l.get 'profileInfo.followButtonText'
                onclick: =>
                  if isFollowing
                    @model.userData.unfollowByUserId user?.id
                  else
                    @model.userData.followByUserId user?.id
      z '.content',
        if isRequestNotificationCardVisible and isMe
          z '.card',
            z '.g-grid',
              z @$requestNotificationsCard

        if player?.data?.chestCycle
          z '.block',
            z '.g-grid',
              z '.title', @model.l.get 'profileChests.chestsTitle'
              z '.chests', {
                ontouchstart: (e) ->
                  e?.stopPropagation()
              },
                _map _take(player?.data.chestCycle.chests, 10), (chest) ->
                  z 'img.chest',
                    src: "#{config.CDN_URL}/chests/#{chest}_chest.png"
                    width: 90
                    height: 90
              z '.chests-button',
                z @$moreDetailsButton,
                  text: @model.l.get 'profileInfo.moreDetailsButtonText'
                  onclick: =>
                    @router.go "/user/id/#{user?.id}/chests"

        z '.block',
          _map metrics, (stats, key) =>
            z '.g-grid',
              if key is 'ladder' and isSplitsInfoCardVisible
                z '.splits-info-card',
                  z @$splitsInfoCard,
                    text: @model.l.get 'profileInfo.splitsInfoCardText'
                    submit:
                      text: @model.l.get 'installOverlay.closeButtonText'
                      onclick: =>
                        @state.set isSplitsInfoCardVisible: false
                        localStorage?['hideSplitsInfo'] = '1'
              z '.title',
                @model.l.get 'profileInfo.subhead' + _upperFirst _camelCase key
              z '.g-cols',
                _map stats, ({name, value}) ->
                  z '.g-col.g-xs-6',
                    z '.name', name
                    z '.value', value
