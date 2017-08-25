z = require 'zorium'
Rx = require 'rx-lite'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'

ActionBar = require '../../components/action_bar'
Toggle = require '../toggle'
PrimaryInput = require '../primary_input'
PrimaryTextarea = require '../primary_textarea'
Icon = require '../icon'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Settings
  constructor: ({@model, @portal, @router, group}) ->
    notificationTypes = [
      {
        name: @model.l.get 'groupSettings.chatMessage'
        key: 'chatMessage'
      }
      # {
      #   name: 'New announcments'
      #   key: 'announcement'
      # }
    ]

    me = @model.user.getMe()
    @nameValueStreams = new Rx.ReplaySubject 1
    @nameValueStreams.onNext (group?.map (group) ->
      group.name) or Rx.Observable.just null
    @nameError = new Rx.BehaviorSubject null

    @descriptionValueStreams = new Rx.ReplaySubject 1
    @descriptionValueStreams.onNext (group?.map (group) ->
      group.description) or Rx.Observable.just null
    @descriptionError = new Rx.BehaviorSubject null

    @passwordValueStreams = new Rx.ReplaySubject 1
    @passwordValueStreams.onNext (group?.map (group) ->
      group.password) or Rx.Observable.just null
    @passwordError = new Rx.BehaviorSubject null

    @isPrivateStreams = new Rx.ReplaySubject 1
    @isPrivateStreams.onNext (group?.map (group) ->
      group.mode is 'private') or Rx.Observable.just null

    @$actionBar = new ActionBar {@model}
    @$leaveIcon = new Icon()
    @$manageRecordsIcon = new Icon()

    @$nameInput = new PrimaryInput
      valueStreams: @nameValueStreams
      error: @nameError

    @$descriptionTextarea = new PrimaryTextarea
      valueStreams: @descriptionValueStreams
      error: @descriptionError

    @$passwordInput = new PrimaryInput
      valueStreams: @passwordValueStreams
      error: @passwordError

    @$isPrivateToggle = new Toggle {isSelectedStreams: @isPrivateStreams}

    @state = z.state
      me: me
      group: group
      isSaving: false
      isLeaveGroupLoading: false
      name: @nameValueStreams.switch()
      description: @descriptionValueStreams.switch()
      password: @passwordValueStreams.switch()
      isPrivate: @isPrivateStreams.switch()
      notificationTypes: group.flatMapLatest (group) =>
        @model.userGroupData.getMeByGroupId(group.id).map (data) ->
          _map notificationTypes, (type) ->
            isSelected = new Rx.BehaviorSubject(
              not data.globalBlockedNotifications?[type.key]
            )

            _defaults {
              $toggle: new Toggle {isSelected}
              isSelected: isSelected
            }, type

  leaveGroup: =>
    {isLeaveGroupLoading, group} = @state.getValue()

    unless isLeaveGroupLoading
      @state.set isLeaveGroupLoading: true
      @model.group.leaveById group.id
      .then =>
        @state.set isLeaveGroupLoading: false
        @router.go '/social'

  save: =>
    {group, name, description, password,
      isPrivate, isSaving} = @state.getValue()

    if isSaving
      return

    @state.set isSaving: true
    @passwordError.onNext null

    @model.group.updateById group.id, {name, description, password, isPrivate}
    .then =>
      @state.set isSaving: false
      @router.go "/group/#{group?.id}/chat"

  render: =>
    {me, notificationTypes, group, isLeaveGroupLoading, isSaving,
      isPrivate} = @state.getValue()

    items = []

    hasAdminPermission = @model.group.hasPermission group, me, {level: 'admin'}
    unless hasAdminPermission
      items = items.concat [
        {
          $icon: @$leaveIcon
          icon: 'subtract-circle'
          text: if isLeaveGroupLoading \
                then @model.l.get 'general.loading'
                else @model.l.get 'groupSettings.leaveGroup'
          onclick: @leaveGroup
        }
      ]

    if hasAdminPermission
      items = items.concat [
        {
          $icon: @$manageRecordsIcon
          icon: 'edit'
          text: 'Manage Records'
          onclick: =>
            @router.go "/group/#{group?.id}/manage-records"
        }
      ]

    z '.z-group-settings',
      z @$actionBar, {
        isSaving: isSaving
        title: @model.l.get 'groupSettingsPage.title'
        cancel:
          onclick: =>
            @router.back()
        save:
          onclick: @save
      }
      z '.g-grid',
        z '.title', @model.l.get 'general.general'

        if hasAdminPermission
          [
            z '.input',
              z @$nameInput,
                hintText: @model.l.get 'claimClanDialog.groupNameHintText'

            z '.input',
              z @$descriptionTextarea,
                hintText: @model.l.get 'general.description'

            if isPrivate
              z '.input',
                z @$passwordInput,
                  hintText: @model.l.get 'groupSettings.passwordToJoin'
          ]

        z 'ul.list',
          if hasAdminPermission
            z 'li.item',
              z '.text', 'Private (password required)'
              z '.toggle',
                @$isPrivateToggle

          _map items, ({$icon, icon, text, onclick}) ->
            z 'li.item', {onclick},
              z '.icon',
                z $icon,
                  icon: icon
                  isTouchTarget: false
                  color: colors.$primary500
              z '.text', text
        z '.title', @model.l.get 'general.notifications'
        z 'ul.list',
          _map notificationTypes, ({name, key, $toggle, isSelected}) =>
            z 'li.item',
              z '.text', name
              z '.toggle',
                z $toggle, {
                  onToggle: (isSelected) =>
                    @model.userGroupData.updateMeByGroupId group.id, {
                      globalBlockedNotifications:
                        "#{key}": not isSelected
                    }
                }
