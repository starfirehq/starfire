_ = require 'lodash'
z = require 'zorium'
log = require 'loga'
Rx = require 'rx-lite'

config = require '../../config'

if window?
  require './index.styl'

module.exports = class GroupInfo
  constructor: ({@model, @router}) ->
    @state = z.state {}

  render: =>
    {} = @state.getValue()

    z '.z-group-info',
      'test'
