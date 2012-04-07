# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  sigRoot = $('#graph')

  window.sigInst = sigma.init(document.getElementById('graph'))


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
      minEdgeSize: 0.2,
      maxEdgeSize: 0.2
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

  $('.button').click ->
    selected = 0
    $('.button').each (idx, elem) =>  # fat arrow binds this to outside context of
      selected = idx if elem == this
      $(elem).removeClass('pressed')
    $(this).addClass('pressed')
    console.log 'selected: ', selected
    highlightGroup(selected);
    if selected == 8
      rotate()



  $('.label input').blur(sendLabel)
  $('.label input').change(sendLabel)

sendLabel = ->
  labelText = $(this).val()
  idx = $(this).next('input').val()
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
  sigInst.draw()  # maybe there is a lighter weight method to refresh just the affected nodes


highlightGroup = (idx) ->
  console.log "highlight group #", idx
  sigInst.iterNodes (node) ->
    groupID = parseInt(node.attr.attributes[4].val)
    if groupID == idx
      node.color = '#FFFFFF'
    else
      node.color = colorTable[groupID]
  sigInst.draw()  # maybe there is a lighter weight method to refresh just the affected nodes


