# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  sigRoot = $('#graph')

  sigInst = sigma.init(document.getElementById('graph'))

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
      minEdgeSize: 1,
      maxEdgeSize: 1
      }).mouseProperties({
        maxRatio: 32
      });

  # import GEXF file
  sigInst.parseGexf('/test2.gexf')

  # Draw the graph :
  sigInst.draw()

