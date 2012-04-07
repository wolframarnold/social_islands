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


highlightGroup = (idx) ->
  console.log "highlight group #", idx
  sigInst.iterNodes (node) ->
    if parseInt(node.attr.attributes[4].val) == idx
      node.color = '#FFFFFF'
  sigInst.draw()  # maybe there is a lighter weight method to refresh just the affected nodes


