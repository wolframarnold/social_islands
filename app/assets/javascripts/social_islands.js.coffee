######################
#      On Load       #
######################
$ ->
  window.overlayNodeID = 0;   #used for overlaying nodes and edges for photo stream
  window.overlayEdgeID=100000000;

  sigRoot = $('#graph')
  if sigRoot.length > 0
    window.sigInst = sigma.init(document.getElementById('graph'))

    sigInst.drawingProperties({
      defaultLabelColor: '#fff',
      defaultLabelSize: 14,
      defaultLabelBGColor: '#fff',
      defaultLabelHoverColor: '#000',
      labelThreshold: 9,
      defaultEdgeType: 'curve'
      }).graphProperties({
        minNodeSize: 0.3,
        maxNodeSize: 8,
        minEdgeSize: 0.0,
        maxEdgeSize: 10.0,
        }).mouseProperties({
          maxRatio: 4
        });

    if window.graph_ready is true
      loadAndDrawGraph()
    else
      showModalSpinner(30)

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

  # In case the labels/buttons are loaded from the ESHQ push, we can't bind
  # event handlers to the (non-existing) elements, we need to use jQuery's on()
  # mechanism

  # Show/hide rename link
  $('#button-group').on 'mouseenter', '.island-label', ->
    showLabelRenameLink $(this)
  $('#button-group').on 'mouseleave', '.island-label', ->
    hideLabelRenameLink $(this)

  # Island label button click -- highlight group, inhibit form submission
  $('#button-group').on 'click', '.island-label button', ->
    $(this).parents('#button-group').find('button.island-show').removeClass('active')
    $(this).toggleClass('active')
    false

  # Rename action
  $('#button-group').on 'click', 'a.rename', ->
    showLabelEdit $(this)

  # Finishing name update, either by submit or by blur (cancel)
  $('#button-group').on 'submit', '.island-form', ->
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
  $('#button-group').on 'keyup', '.island-label-edit input[name*=name]', (event) ->
    if event.keyCode == 27 # ESC
      hideLabelEdit $(this).parents('.island-form')

  # Blur -- when clicking on rename of another intput box
  $('#button-group').on 'blur', '.island-label-edit input[name*=name]', ->
    hideLabelEdit $(this).parents('.island-form')

  setupESHQ();

#  # Triggers for transition effects for overlays
#  $('#island-feed-link').click ->
#    slide_in_overlays()
#    $('#island-feed').removeClass('slide-out').addClass('slide-in')
#  $('#stats-link').click ->
#    slide_in_overlays()
#    $('#stats').removeClass('slide-out').addClass('slide-in')
#
#  $('.overlay .close').click(slide_in_overlays)

  # Social Sharing Facebook
  $('#share-on-facebook-button').click ->
    FB.getLoginStatus (resp) ->
      post_obj = null
      switch resp.status
        when 'connected'
          if window.graph_ready isnt true
            $('#alert-info').text("Still computing... try again when graph appears.").fadeIn(500).delay(1000).fadeOut(1000)
          else
            post_obj =
              picture: window.protocol_host_port+'/facebook/png'
              caption: 'My Islands'
        when 'not_authorized'  # logged into FB, but app not authorized--> can still post to wall
          post_obj = {}
        when 'unknown'  # not logged into FB
          $('#alert-info').text("Please sign in first.").fadeIn(500).delay(1000).fadeOut(1000)

      if post_obj
        post_obj.method      = 'feed'
        post_obj.link        = 'http://socialislands.org'
        post_obj.name        = 'Social Islands'
        post_obj.description = "What's happening on each of your Social Islands? Find out."
        # ref: 'logged_in_with_graph' -> causes FB error in pop up window; perhaps we have to configure this key in Insights first?

        FB.ui post_obj, (response) ->
          if response['post_id']?
            console.log response['post_id']
            $('#alert-success').text("Post Successful").fadeIn(500).delay(1000).fadeOut(1000)


########################
#      Functions       #
########################

slide_in_overlays = ->
  $('.overlay.slide-in').removeClass('slide-in').addClass('slide-out')

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

#rotate = ->
#  sigInst.iterNodes (node) ->
#    tmp = node.x
#    #console.log "before", node.x, node.y
#    node.x = node.y
#    node.y = -tmp
#
#moveLeft = (idx) ->
#  console.log "move to right group #", idx
#  sigInst.iterNodes (node) ->
#    groupID = parseInt(node.attr.attributes[4].val)
#    if groupID == idx
#      node.x -= 50
#
#moveRight = (idx) ->
#  console.log "move to right group #", idx
#  sigInst.iterNodes (node) ->
#    groupID = parseInt(node.attr.attributes[4].val)
#    if groupID == idx
#      node.x += 50
#
#moveUp = (idx) ->
#  console.log "move to right group #", idx
#  sigInst.iterNodes (node) ->
#    groupID = parseInt(node.attr.attributes[4].val)
#    if groupID == idx
#      node.y -= 50
#
#moveDown = (idx) ->
#  console.log "move to right group #", idx
#  sigInst.iterNodes (node) ->
#    groupID = parseInt(node.attr.attributes[4].val)
#    if groupID == idx
#      node.y += 50
#
#
#highlightGroup = (idx) ->
#  console.log "inside highlightgroup for group #", idx
#  numNode = 0
#  sigInst.iterNodes (node) ->
#    groupID = parseInt(node.attr.attributes[4].val)
##    console.log groupID
#    if groupID == idx
#      node.color = '#FFFFFF'
#      numNode += 1
#    else
#      node.color = colorTable[groupID]
#  console.log "done highlighing, total nodes affected ", numNode
#
#deHighlightGroup = ->
#  console.log "de-highlight groups"
#  sigInst.iterNodes (node) ->
#    groupID = parseInt(node.attr.attributes[4].val)
#    node.color = colorTable[groupID]

showModalSpinner = (progress_max_secs) ->
  $('#modal-spinner').modal(backdrop: 'static', keyboard: false)
  interval_ms = progress_max_secs * 50 # max_secs * 1000 / 20 -> 20 intervals
  i = 0
  timerID = null
  incProgressBar = ->
    clearInterval(timerID) if i >= 20
    $('#modal-spinner .progress > .bar').css('width', (i * 5)+'%' )
    ++i
  timerID = setInterval(incProgressBar, interval_ms)

cancelModalSpinner = ->
  $('#modal-spinner').modal('hide')

setDefaultEdgeColorSize = ->
  sigInst._core.plotter.p.edgeColor="default"
  nodes = sigInst._core.graph.nodesIndex
  edges = sigInst._core.graph.edges
  for edge in edges
    edge.color = nodes[edge.source.id].color
    edge.size= 0.1

loadAndDrawGraph = ->
  # import GEXF file
  sigInst.parseGexf('/facebook/graph.gexf')
  setDefaultEdgeColorSize()
  window.graph_is_loaded = true

  # kill the spinner message/progress bar
  cancelModalSpinner()

  # Draw the graph :
  sigInst.draw()

updateLabels = (html) ->
  $('#button-group').append(html);

setupESHQ = ->
  eshq = new ESHQ("graph_ready_" + window.facebook_profile_id_sha1);

  eshq.onopen = (e) ->
    # callback called when the connection is made

  eshq.onmessage = (e) ->
    # called when a new message with no specific type has been received
    window.graph_ready = true
    loadAndDrawGraph() unless window.graph_is_loaded?
    updateLabels(JSON.parse(e.data).labels_html)

  eshq.onerror = (e) ->
    # callback called on errror

window.addOverlay = (sID, tIDs) ->
  if sigInst._core.graph.nodesIndex[sID]
    sourceNode = sigInst.getNodes(sID)
    sourceNode.label = ""
    sourceNode.color = "#ffffff"
    overlayNodeID++
    sigInst.addNode overlayNodeID.toString(), sourceNode
    for tID in tIDs
      if sigInst._core.graph.nodesIndex[tID]
        targetNode = sigInst.getNodes(tID)
        targetNode.label = ""
        targetNode.color = "#ffffff"
        overlayNodeID++
        sigInst.addNode overlayNodeID.toString(), targetNode
        overlayEdgeID++
        edge =
          id: overlayEdgeID
          sourceID: "1"
          targetID: overlayNodeID
          size: 0.5
          label: null
          color: "#ffffff"

        sigInst.addEdge overlayEdgeID, "1", overlayNodeID, edge
  sigInst.draw 2, 2, 2

window.removeOverlay = ->
  while overlayEdgeID > 100000000
    sigInst.dropEdge overlayEdgeID
    overlayEdgeID--
  while overlayNodeID > 0
    sigInst.dropNode overlayNodeID
    overlayNodeID--
  sigInst.draw 2, 2, 2