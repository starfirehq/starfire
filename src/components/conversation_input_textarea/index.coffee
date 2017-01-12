z = require 'zorium'
Rx = require 'rx-lite'
Environment = require 'clay-environment'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

DEFAULT_TEXTAREA_HEIGHT = 54

module.exports = class ConversationInputTextarea
  constructor: (options) ->
    {@message, @onPost, @onResize, @isTextareaFocused,
      @hasText, @model} = options

    @$sendIcon = new Icon()

    @isTextareaFocused ?= new Rx.BehaviorSubject false

    @state = z.state
      isTextareaFocused: @isTextareaFocused
      textareaHeight: DEFAULT_TEXTAREA_HEIGHT
      hasText: @hasText

  afterMount: (@$$el) =>
    null

  setMessageFromEvent: (e) =>
    e or= window.event
    if e.keyCode is 13 and not e.shiftKey
      e.preventDefault()
      @postMessage()
    else
      @setMessage e.target.value

  setMessage: (message) =>
    currentValue = @message.getValue()
    if not currentValue and message
      @hasText.onNext true
    else if currentValue and not message
      @hasText.onNext false
    @message.onNext message

  postMessage: (e) =>
    $$textarea = @$$el.querySelector('#textarea')
    $$textarea?.focus()
    $$textarea?.style.height = 'auto'
    @onPost?()
    $$textarea?.value = ''

  resizeTextarea: (e) =>
    {textareaHeight} = @state.getValue()
    $$textarea = e.target
    $$textarea.style.height = "#{DEFAULT_TEXTAREA_HEIGHT}px"
    newHeight = $$textarea.scrollHeight
    $$textarea.style.height = "#{newHeight}px"
    $$textarea.scrollTop = newHeight
    unless textareaHeight is newHeight
      @state.set textareaHeight: newHeight
      @onResize?()

  getHeightPx: =>
    {textareaHeight} = @state.getValue()
    textareaHeight

  render: =>
    {isTextareaFocused, hasText, textareaHeight} = @state.getValue()

    z '.z-conversation-input-textarea',
        z 'textarea.textarea',
          id: 'textarea'
          key: 'conversation-input-textarea'
          # for some reason necessary on iOS to get it to focus properly
          onclick: (e) ->
            setTimeout ->
              e?.target?.focus()
            , 0
          style:
            height: "#{textareaHeight}px"
          placeholder: 'Type a message'
          onkeyup: @setMessageFromEvent
          onkeydown: (e) ->
            if e.keyCode is 13 and not e.shiftKey
              e.preventDefault()
          oninput: @resizeTextarea
          ontouchstart: =>
            unless Environment.isGameApp config.GAME_KEY
              @model.window.pauseResizing()
          onfocus: =>
            unless Environment.isGameApp config.GAME_KEY
              @model.window.pauseResizing()
            clearTimeout @blurTimeout
            @isTextareaFocused.onNext true
            @onResize?()
          onblur: (e) =>
            @blurTimeout = setTimeout =>
              isFocused = e.target is document.activeElement
              unless isFocused
                unless Environment.isGameApp config.GAME_KEY
                  @model.window.resumeResizing()
                @isTextareaFocused.onNext false
            , 350

        z '.right-icons',
          z '.send-icon', {
            onclick: @postMessage
          },
            z @$sendIcon,
              icon: 'send'
              color: if hasText \
                     then colors.$white
                     else colors.$white30