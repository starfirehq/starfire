z = require 'zorium'

Avatar = require '../avatar'
PrimaryButton = require '../primary_button'

if window?
  require './index.styl'

module.exports = class Profile
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()
    @$avatar = new Avatar()
    @$editButton = new PrimaryButton()

    @state = z.state
      me: me
  render: =>
    {me} = @state.getValue()

    z '.z-profile',
      z '.header',
        z '.avatar',
          z @$avatar, {user: me, size: '158px'}
        z '.name',
          @model.user.getDisplayName me
        z '.edit-button',
          z @$editButton,
            text: 'Edit profile'
            onclick: =>
              @router.go '/editProfile'

      z '.g-grid',
        z '.section',
          z '.top',
            z '.left',
              z '.title', ''
