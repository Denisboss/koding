kd                 = require 'kd'
React              = require 'kd-react'
classnames         = require 'classnames'
Encoder            = require 'htmlencode'
KeyboardKeys       = require 'app/util/keyboardKeys'
ActivityFlux       = require 'activity/flux'
ButtonWithMenu     = require 'app/components/buttonwithmenu'
StartVideoCallLink = require 'activity/components/common/startvideocalllink'
ChannelLabel       = require 'activity/components/channellabel'

module.exports = class ThreadHeader extends React.Component

  @defaultProps =
    thread                     : null
    onInvitePeople             : kd.noop
    onUpdatePurpose            : kd.noop
    onLeaveChannel             : kd.noop
    onShowNotificationSettings : kd.noop


  constructor: (props) ->

    super props

    @state = { editingPurpose: no, thread: @props.thread }


  channel: (keyPath...) -> @state.thread.getIn ['channel'].concat keyPath


  componentWillReceiveProps: (nextProps) ->

    return  unless @props.thread and nextProps.thread

    nextState = { thread: nextProps.thread }

    id = @props.thread.get 'channelId'
    nextId = nextProps.thread.get 'channelId'

    # make sure that editing purpose is set back to no if channel is changing.
    nextState['editingPurpose'] = no  if id isnt nextId

    @setState nextState


  getMenuItems: ->
    return [
      title   : 'Invite people'
      key     : 'invitepeople'
      onClick : @props.onInvitePeople
    ,
      title   : 'Leave channel'
      key     : 'leavechannel'
      onClick : @props.onLeaveChannel
    ,
      title   : 'Update purpose'
      key     : 'updatepurpose'
      onClick : @bound 'onUpdatePurpose'
    ,
      title   : 'Notification settings'
      key     : 'notificationsettings'
      onClick : @props.onShowNotificationSettings
    ]


  onUpdatePurpose: ->

    @setState { editingPurpose: yes }, =>
      kd.utils.moveCaretToEnd @refs.purposeInput


  getPurposeAreaClassNames: -> classnames
    'ChannelThreadPane-purposeWrapper': yes
    'editing': @state.editingPurpose


  handlePurposeInputChange: (newValue) ->

    thread = @state.thread

    unless @channel '_originalPurpose'
      thread = thread.setIn ['channel', '_originalPurpose'], @channel 'purpose'

    thread = thread.setIn ['channel', 'purpose'], newValue
    @setState { thread }


  onKeyDown: (event) ->

    { ENTER, ESC } = KeyboardKeys
    thread         = @state.channelThread

    if event.which is ESC
      _originalPurpose = @channel '_originalPurpose'
      purpose = _originalPurpose or @channel 'purpose'
      thread  = thread.setIn ['channel', 'purpose'], purpose
      @setState channelThread: thread
      return @setState editingPurpose: no

    if event.which is ENTER
      id = @channel 'id'
      purpose = @channel('purpose').trim()
      { updateChannel } = ActivityFlux.actions.channel

      updateChannel({ id, purpose }).then => @setState editingPurpose: no


  renderPurposeArea: ->

    return  unless @props.thread

    purpose = Encoder.htmlDecode @channel 'purpose'

    valueLink =
      value         : purpose
      requestChange : @bound 'handlePurposeInputChange'

    <div className={@getPurposeAreaClassNames()}>
      <span className='ChannelThreadPane-purpose'>{purpose}</span>
      <input
        ref='purposeInput'
        type='text'
        valueLink={valueLink}
        onKeyDown={@bound 'onKeyDown'} />
    </div>


  render: ->
    return null  unless @state.thread

    <div className={kd.utils.curry "ThreadHeader", @props.className}>
      <ChannelLabel thread={@state.thread} />
      <ButtonWithMenu
        listClass='ChannelThreadPane-menuItems'
        items={@getMenuItems()} />
      {@renderPurposeArea()}
      <StartVideoCallLink onStart={@bound 'onVideoStart'}/>
    </div>


