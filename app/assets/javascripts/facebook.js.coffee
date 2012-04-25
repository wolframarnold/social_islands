$ ->
  sigRoot = $('#graph')

  window.sigInst = sigma.init(document.getElementById('graph'))

  window.testPointer = null

  sigInst.drawingProperties({
    defaultLabelColor: '#fff',
    defaultLabelSize: 14,
    defaultLabelBGColor: '#fff',
    defaultLabelHoverColor: '#000',
    labelThreshold: 6,
    defaultEdgeType: 'curve'
    }).graphProperties({
      minNodeSize: 0.5,
      maxNodeSize: 5,
      minEdgeSize: 0.3,
      maxEdgeSize: 0.3
      }).mouseProperties({
        maxRatio: 4
      });

  # import GEXF file
  sigInst.parseGexf('/facebook/graph.gexf')

  # Draw the graph :
  sigInst.draw()

#  window.highLightedGroup = -1
#  window.tthis = null
#  $('.button').click ->
#    console.log this
#    selected = this.id
#    console.log "selected id: ", selected
#    if selected < 8    #this is groupID
#      if window.highLightedGroup > -1   # a group already hightlighted, dehighlight first
#        console.log "dehighlight first"
#        deHighlightGroup()
#        $($('.button')[window.highLightedGroup]).removeClass('pressed')
#      if window.highLightedGroup != selected # a different group is selected
#        console.log "a new group is selected, old: #", window.highLightedGroup, " new: #", selected
#        $(this).addClass('pressed')
#        highlightGroup(parseInt(selected));
#        window.highLightedGroup = selected
#      else
#        console.log "deselecting"
#        window.highLightedGroup = -1
#    if selected == 'Rotate'
#      console.log "Rotating..."
#      rotate()
#    if window.highLightedGroup > -1       #If a valid group is selected, test if moving button is clicked
#      if selected == 'MoveLeft'
#        moveLeft(parseInt(window.highLightedGroup))
#      if selected == 'MoveRight'
#        moveRight(parseInt(window.highLightedGroup))
#      if selected == 'MoveUp'
#        moveUp(parseInt(window.highLightedGroup))
#      if selected == 'MoveDown'
#        moveDown(parseInt(window.highLightedGroup))
#    sigInst.draw()

#  $('.button').click ->
#    selected = 0
#    $('.button').each (idx, elem) =>  # fat arrow binds this to outside context of
#      selected = idx if elem == this
#      $(elem).removeClass('pressed')
#    $(this).addClass('pressed')
#    console.log 'selected: ', selected
#    highlightGroup(selected);
#    if selected == 8
#      rotate()
#    if selected == 9
#      moveRight(1)
#    sigInst.draw()

  # Show/hide rename link
  $('.island-label').mouseenter ->
    showLabelRenameLink $(this)
  $('.island-label').mouseleave ->
    hideLabelRenameLink $(this)

  # Island label button click -- highlight group, inhibit form submission
  $('.island-label button').click ->
    $(this).parents('#button-group').find('button.island-show').removeClass('active')
    $(this).toggleClass('active')
    false

  # Rename action
  $('a.rename').click ->
    showLabelEdit $(this)

  # Finishing name update, either by submit or by blur (cancel)
  $('.island-form').submit ->
    formElem = $(this)
    hideLabelEdit formElem
    jqxhr = $.post '/facebook/label', formElem.serialize()
    jqxhr.success ->
      $('#alert-success').text("Update Successful").fadeIn(500).delay(1000).fadeOut(1000)
      formElem.find('.island-label button').text(formElem.find('.island-label-edit input[type=text]').val())
    jqxhr.error (xhr) ->
      $('#alert-error').text("Server Error: " + JSON.parse(xhr.responseText).error).fadeIn(500).delay(1500).fadeOut(2000)
    false

  # ESC key when pressed in input box
  $('.island-label-edit input[name*=name]').keyup (event) ->
    if event.keyCode == 27 # ESC
      hideLabelEdit $(this).parents('.island-form')

  # Blur -- when clicking on rename of another intput box
  $('.island-label-edit input[name*=name]').blur ->
    hideLabelEdit $(this).parents('.island-form')


showLabelRenameLink = (elem) ->
  elem.find('a.rename').show();

hideLabelRenameLink = (elem) ->
  elem.find('a.rename').hide();

showLabelEdit = (a_elem) ->
  a_elem.closest('.island-label').hide().
  next('.island-label-edit').show().
  find('input[name*=name]').focus()

hideLabelEdit = (input_elem) ->
  input_elem.find('.island-label-edit').hide().prev('.island-label').show()

sendLabel = ->
  window.testPointer = this
  labelText = $(this).val()
  idx = this.id
  console.log $(this), idx
  #idx = $(this).next('input').val()
  #  console.log labelText, ', idx: ', idx
  $.post '/services/facebook/label', {groupId: idx, labelText: labelText}, ->
    console.log "success/failure"

  # evnet debugging
#  sigInst.bind 'overnodes', (event) ->
#    nodes = event.content
#    window.overnodeEvent = event
#    window.overnodeThis = this
#    console.log event
#    console.log this

rotate = ->
  sigInst.iterNodes (node) ->
    tmp = node.x
    #console.log "before", node.x, node.y
    node.x = node.y
    node.y = -tmp

moveLeft = (idx) ->
  console.log "move to right group #", idx
  sigInst.iterNodes (node) ->
    groupID = parseInt(node.attr.attributes[4].val)
    if groupID == idx
      node.x -= 50

moveRight = (idx) ->
  console.log "move to right group #", idx
  sigInst.iterNodes (node) ->
    groupID = parseInt(node.attr.attributes[4].val)
    if groupID == idx
      node.x += 50

moveUp = (idx) ->
  console.log "move to right group #", idx
  sigInst.iterNodes (node) ->
    groupID = parseInt(node.attr.attributes[4].val)
    if groupID == idx
      node.y -= 50

moveDown = (idx) ->
  console.log "move to right group #", idx
  sigInst.iterNodes (node) ->
    groupID = parseInt(node.attr.attributes[4].val)
    if groupID == idx
      node.y += 50


highlightGroup = (idx) ->
  console.log "inside highlightgroup for group #", idx
  numNode = 0
  sigInst.iterNodes (node) ->
    groupID = parseInt(node.attr.attributes[4].val)
#    console.log groupID
    if groupID == idx
      node.color = '#FFFFFF'
      numNode += 1
    else
      node.color = colorTable[groupID]
  console.log "done highlighing, total nodes affected ", numNode

deHighlightGroup = ->
  console.log "de-highlight groups"
  sigInst.iterNodes (node) ->
    groupID = parseInt(node.attr.attributes[4].val)
    node.color = colorTable[groupID]

