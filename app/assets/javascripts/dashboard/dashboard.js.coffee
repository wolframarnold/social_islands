#loadData = (collapsible_sel) ->
#  console.log 'called loadData with: '+collapsible_sel
#
#$ ->
#  $('#user-rows.collapse').on 'show', ->
#    console.log 'show callback fired'
#    collapsible = $(this).data['target']
#    loadData(collapsible) unless $(collapsible)

$ ->
  photo_eng_chart = d3.select('#photo-engagements-chart')
                      .append('svg').attr('class','chart')
                      .attr('width', 400)
                      .attr('height', 20 * window.photo_engagement_data.length)

  x = d3.scale.linear()
    .domain([0, d3.max(window.photo_engagement_data)])
    .range([0 ,400])

  photo_eng_chart.selectAll('rect')
                 .data(window.photo_engagement_data)
                 .enter().append('rect')
                 .attr('y', (d,i) -> i * 20)
                 .attr('width', x)
                 .attr('height', 20)

  ndx = crossfilter(window.top_friends_data)

  all = ndx.groupAll()

  by_uid                  = ndx.dimension( (d) -> d.uid)
  window.by_uid = by_uid # for debugging; can type 'by_uid' in browser console and interact w/ object
  by_inbound_score        = ndx.dimension( (d) -> d.inbound_score)
  by_mutual_friends_count = ndx.dimension( (d) -> d.mutual_friends_count)

  # each "group" represents a filter to apply to the data set. See https://github.com/square/crossfilter/wiki/API-Reference for details
  # our "by_uid_group" filters the records for just one user
  by_uid_group = by_uid.group()  # no grouping needed the UID is already the group identifier
  window.by_uid_group = by_uid_group
  console.log by_uid_group.size() # should be top friend count in data set (relevant_top_friends method in Ruby)-- number of records/disctinct values in group

  # See http://nickqizhu.github.com/dc.js/, Bubble Chart example
  dc.bubbleChart('#top-friends-chart')
    .width(600)
    .height(300)
    .dimension(by_uid)
    .group(by_uid_group)
    .keyRetriever( (d) -> d.mutual_friends_count)
    .valueRetriever( (d) -> d.inbound_score)
    .radiusValueRetriever( -> 20)  # hard-coded radius -- we can play with this, e.g. display profile authenticity here
    .x(d3.scale.linear().domain([0,100]))
    .y(d3.scale.linear().domain([0,50]))
    .r(d3.scale.linear().domain([0,100]))
    .label( (d) -> d.uid )  # we should ship the name and image to display here, for now we display UID in the bubble
    .renderTitle(true)

  dc.renderAll()
