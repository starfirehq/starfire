z = require 'zorium'
Rx = require 'rx-lite'
Environment = require 'clay-environment'

PrimaryInput = require '../primary_input'
PrimaryButton = require '../primary_button'
FlatButton = require '../flat_button'
InfoBlock = require '../info_block'
Form = require '../form'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class SetAddress
  constructor: ({@model, @router}) ->
    @$skipButton = new FlatButton()
    @$continueButton = new PrimaryButton()

    @countryValue = new Rx.BehaviorSubject ''
    @addressValue = new Rx.BehaviorSubject ''
    @cityValue = new Rx.BehaviorSubject ''
    @zipValue = new Rx.BehaviorSubject ''
    @countryError = new Rx.BehaviorSubject null
    @addressError = new Rx.BehaviorSubject null
    @cityError = new Rx.BehaviorSubject null
    @zipError = new Rx.BehaviorSubject null
    @$countryInput = new PrimaryInput
      value: @countryValue
      error: @countryError
    @$addressInput = new PrimaryInput
      value: @addressValue
      error: @addressError
    @$cityInput = new PrimaryInput
      value: @cityValue
      error: @cityError
    @$zipInput = new PrimaryInput
      value: @zipValue
      error: @zipError

    @$infoBlock = new InfoBlock()
    @$form = new Form()

    @state = z.state
      isLoading: false
      isSkipLoading: false

  setAddress: (e) =>
    e?.preventDefault()

    @state.set isLoading: true
    @model.userData.setAddress {
      country: @countryValue.getValue()
      address: @addressValue.getValue()
      city: @cityValue.getValue()
      zip: @zipValue.getValue()
    }
    .then =>
      @state.set isLoading: false
      if Environment.isGameApp config.GAME_KEY
        @router.go '/'
      else
        @router.go '/getApp'
    .catch (err) =>
      @addressError.onNext err.message
      @state.set isLoading: false

  render: =>
    {isLoading, isSkipLoading} = @state.getValue()

    z '.z-set-address',
      z @$infoBlock,
        $title: 'Membership card'
        $content: [
          z 'p',
            'The first 100 members of Red Tritium get a sweet
            metal membership card. If you would like one,
            provide your address below.'
          z 'p',
          'We don\'t use this info for anything else, and it is optional
          (but the card is pretty cool)'
        ]
        $form: z @$form,
          onsubmit: @setAddress
          $inputs: [
            z @$countryInput,
              hintText: 'Country'
            z @$addressInput,
              type: 'text'
              hintText: 'Address'
            z @$cityInput,
              type: 'text'
              hintText: 'City'
            z @$zipInput,
              type: 'text'
              hintText: 'Zip'
          ]
          $buttons: [
            z @$continueButton,
              type: 'submit'
              text: if isLoading then 'Loading...' else 'Continue'
            z @$skipButton,
              text: if isSkipLoading then 'Loading...' else 'Skip'
              onclick: =>
                @state.set isSkipLoading: true
                @model.user.setFlags {isAddressSkipped: true}
                .then =>
                  @state.set isSkipLoading: false
                  @router.go '/getApp'
          ]