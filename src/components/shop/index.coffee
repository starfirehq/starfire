z = require 'zorium'
_isEmpty = require 'lodash/isEmpty'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'
_orderBy = require 'lodash/orderBy'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/operator/map'
require 'rxjs/add/observable/of'

Spinner = require '../spinner'
Icon = require '../icon'
CurrencyIcon = require '../currency_icon'
PrimaryButton = require '../primary_button'
BuyGiftCardDialog = require '../buy_gift_card_dialog'
OpenPack = require '../open_pack'
ConfirmProductPurchase = require '../confirm_product_purchase'
UiCard = require '../ui_card'
DateService = require '../../services/date'
FormatService = require '../../services/format'
colors = require '../../colors'
config = require '../../config'

ONE_DAY_MS = 24 * 3600 * 1000

if window?
  require './index.styl'

module.exports = class Shop
  constructor: (options) ->
    {@model, @router, products, @overlay$, @goToEarnFireFn
      @goToEarnCurrencyFn, group} = options
    @$spinner = new Spinner()

    me = @model.user.getMe()
    products ?= @model.product.getAll()
    @purchaseLoadingKey = new RxBehaviorSubject null

    @$infoCard = new UiCard()
    @$moreFireIcon = new Icon()
    @$moreCurrencyIcon = new CurrencyIcon {
      itemKey: group.map (group) ->
        group?.currency?.itemKey
    }

    @state = z.state
      me: @model.user.getMe()
      purchaseLoadingKey: @purchaseLoadingKey
      isInfoCardVisible: window? and not localStorage?['hideShopInfo']
      group: group
      products: products.map (products) =>
        products = _orderBy products, 'cost', 'asc'
        _map products, (product) =>
          {
            $buyButton: new PrimaryButton()
            $fireIcon: new Icon()
            $currencyIcon: new CurrencyIcon {itemKey: product.currency}
            product: product
            onPurchase: (items) =>
              # buying anything removes ads for day
              if product.cost > 0
                @model.ad.hideAds ONE_DAY_MS
              if product.type is 'pack'
                overlay$ = @overlay$.getValue()
                @overlay$.next [overlay$].concat [new OpenPack {
                  @model
                  @router
                  pack: product
                  group: group
                  items: RxObservable.of items
                  onClose: =>
                    @overlay$.next null
                }]
              else
                Promise.resolve()

            onBeforePurchase: =>
              if product.key.match(/google_play|visa_10/)
                new Promise (resolve, reject) =>
                  $buyGiftCardDialog = new BuyGiftCardDialog {
                    @model, @router, @overlay$
                  }
                  @overlay$.next z $buyGiftCardDialog, {
                    onSubmit: resolve, onLeave: reject
                  }
              else
                new Promise (resolve, reject) =>
                 # TODO: groupid
                  @overlay$.next new ConfirmProductPurchase {
                    @model, @router, @overlay$,
                    @purchaseLoadingKey, product, group
                    onConfirm: resolve, onCancel: =>
                      @overlay$.next null
                      reject()
                  }
          }

  render: =>
    {me, products, purchaseLoadingKey,
      isInfoCardVisible, group} = @state.getValue()

    z '.z-shop',
      z '.g-grid',
        if isInfoCardVisible
          z '.info-card',
            z @$infoCard,
              $content: @model.l.get 'shop.infoCardText'
              submit:
                text: @model.l.get 'installOverlay.closeButtonText'
                onclick: =>
                  @state.set isInfoCardVisible: false
                  localStorage?['hideShopInfo'] = '1'
        if products and _isEmpty products
          z '.no-products',
            @model.l.get 'shop.empty'
        else if products
          z '.g-cols.no-padding',
            [
              _map products, (options) =>
                {product, $buyButton, $fireIcon, $currencyIcon,
                  onPurchase, onBeforePurchase} = options

                isDisabled = product.isLocked
                isFree = product.cost is 0
                z '.g-col.g-xs-6.g-md-2', {
                  style:
                    backgroundImage: "url(#{product.data?.backgroundImage})"
                    backgroundColor: product.data?.backgroundColor
                  onclick: =>
                    ga? 'send', 'event', 'product', 'buy', product.key
                    unless isDisabled
                      (onBeforePurchase?() or Promise.resolve())
                      .then (data) =>
                        @purchaseLoadingKey.next product.key
                        @model.product.buy _defaults data, {key: product.key}
                      .then onPurchase
                      .then =>
                        @purchaseLoadingKey.next null
                },
                  z '.info',
                    z '.name', product.name
                    # if product.isLimited
                    #   z '.limited', @model.l.get 'spendFire.limited'
                    if purchaseLoadingKey is product.key
                      @model.l.get 'general.loading'
                    else
                      z '.cost',
                        z '.amount',
                          if product.isLocked
                          then DateService.formatSeconds \
                                product.lockExpireSeconds
                          else if isFree \
                          then @model.l.get 'general.free'
                          else FormatService.number product.cost
                        z '.icon',
                          if product.currency is 'fire'
                            z $fireIcon,
                              icon: if product.isLocked \
                                    then 'lock-outline'
                                    else 'fire'
                              size: '16px'
                              color: colors.$quaternary500
                              isTouchTarget: false
                          else
                            z $currencyIcon, {size: '16px'}
              # z '.g-col.g-xs-6.g-md-2.earn-more', {
              #   onclick: =>
              #     @goToEarnFireFn?()
              # },
              #   z '.more',
              #     z '.icon',
              #       z @$moreFireIcon,
              #         icon: 'fire'
              #         isTouchTarget: false
              #         color: colors.$quaternary500
              #         size: '96px'
              #   z '.info',
              #     z '.name', @model.l.get 'shop.earnMoreFire'

              if group?.currency
                z '.g-col.g-xs-6.g-md-2.earn-more', {
                  onclick: =>
                    @goToEarnCurrencyFn?()
                },
                  z '.more',
                    z '.icon',
                      z @$moreCurrencyIcon,
                        size: '96px'
                  z '.info',
                    z '.name',
                    @model.l.get 'shop.earnMore', {
                      replacements:
                        currency: group.currency.name
                    }
            ]
        else
          @$spinner
