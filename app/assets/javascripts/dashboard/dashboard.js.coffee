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

  # each "group" represents a filter to apply to the data set. See https://github.com/square/crossfilter/wiki/API-Reference for details
  # our "by_uid_group" filters the records for just one user
  by_uid_group = by_uid.group().reduce((p,v) ->     # no grouping needed the UID is already the group identifier
    ++p.count
    p.inbound_score = v.inbound_score
    p.mutual_friends_count = v.mutual_friends_count
    p.uid = v.uid
    p

    #remove
  , (p, v)->
    --p.count
    p.inbound_score = -1
    p.mutual_friends_count = -1
    p.uid = -1
    p

    #init
  , ->
    inbound_score : 0
    mutual_friends_count : 0
    uid : 0
    )
  window.by_uid_group = by_uid_group

  by_inbound_score        = ndx.dimension( (d) -> d.inbound_score)
  window.by_inbound_score = by_inbound_score
  by_inbound_score_group = by_inbound_score.group()  # no grouping needed the UID is already the group identifier
  window.by_inbound_score_group = by_inbound_score_group
  by_mutual_friends_count = ndx.dimension( (d) -> d.mutual_friends_count)
  window.by_mutual_friends_count = by_mutual_friends_count
  by_mutual_friends_count_group = by_mutual_friends_count.group()
  window.by_mutual_friends_count_group = by_mutual_friends_count_group
  console.log by_uid_group.size() # should be top friend count in data set (relevant_top_friends method in Ruby)-- number of records/disctinct values in group

  # See http://nickqizhu.github.com/dc.js/, Bubble Chart example
  dc.bubbleChart('#top-friends-chart')
    .width(600)
    .height(300)
    .dimension(by_uid)
    .group(by_uid_group)
    .keyRetriever( (d) -> d.value.mutual_friends_count)
    .valueRetriever( (d) -> d.value.inbound_score)
    .radiusValueRetriever( -> 10)  # hard-coded radius -- we can play with this, e.g. display profile authenticity here
    .x(d3.scale.linear().domain([0,200]))
    .y(d3.scale.linear().domain([0,30]))
    .r(d3.scale.linear().domain([0,100]))
    .label( (d) -> d.value.uid )  # we should ship the name and image to display here, for now we display UID in the bubble
    .renderTitle(true)
    .filterAll

  dc.barChart("#inbound-score-histogram")
    .width(300)
    .height(250)
    .dimension(by_inbound_score)
    .group(by_inbound_score_group)
    .elasticY(true)
    .round(dc.round.floor)
    .x(d3.scale.linear().domain([0, 40]))
    .xAxis()

  dc.barChart("#mutual-friends-count-histogram")
    .width(300)
    .height(250)
    .dimension(by_mutual_friends_count)
    .group(by_mutual_friends_count_group)
    .elasticY(true)
    .round(dc.round.floor)
    .x(d3.scale.linear().domain([0, 200]))
    .xAxis()

  dc.renderAll()
