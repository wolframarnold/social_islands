# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

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
  sigInst.parseGexf('/services/facebook/graph.gexf')

  window.testNode = sigInst.iterNodes ((n) ->
    n
  ), ["595045215"]

  window.colorTable = new Array()
  sigInst.iterNodes (node) ->
    colorTable[parseInt(node.attr.attributes[4].val)] = node.color
    #console.log node.attr.attributes[4].val, 'color', node.color
    $('.group1').first().css('background-color', colorTable[0])
    $('.group2').first().css('background-color', colorTable[1])
    $('.group3').first().css('background-color', colorTable[2])
    $('.group4').first().css('background-color', colorTable[3])
    $('.group5').first().css('background-color', colorTable[4])
    $('.group6').first().css('background-color', colorTable[5])
    $('.group7').first().css('background-color', colorTable[6])
    $('.group8').first().css('background-color', colorTable[7])
    $('.group9').first().css('background-color', colorTable[8])



# Draw the graph :
  sigInst.draw()

  window.highLightedGroup = -1
  window.tthis = null
  $('.button').click ->
    console.log this
    selected = this.id
    console.log "selected id: ", selected
    if selected < 8    #this is groupID
      if window.highLightedGroup > -1   # a group already hightlighted, dehighlight first
        console.log "dehighlight first"
        deHighlightGroup()
        $($('.button')[window.highLightedGroup]).removeClass('pressed')
      if window.highLightedGroup != selected # a different group is selected
        console.log "a new group is selected, old: #", window.highLightedGroup, " new: #", selected
        $(this).addClass('pressed')
        highlightGroup(parseInt(selected));
        window.highLightedGroup = selected
      else
        console.log "deselecting"
        window.highLightedGroup = -1
    if selected == 'Rotate'
      console.log "Rotating..."
      rotate()
    if window.highLightedGroup > -1       #If a valid group is selected, test if moving button is clicked
      if selected == 'MoveLeft'
        moveLeft(parseInt(window.highLightedGroup))
      if selected == 'MoveRight'
        moveRight(parseInt(window.highLightedGroup))
      if selected == 'MoveUp'
        moveUp(parseInt(window.highLightedGroup))
      if selected == 'MoveDown'
        moveDown(parseInt(window.highLightedGroup))
    sigInst.draw()

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



  $('.label input').blur(sendLabel)
  $('.label input').change(sendLabel)

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

