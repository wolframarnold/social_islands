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

  ndx = crossfilter(window.photo_engagement_data)
  console.log ndx
  engagement_by_type = ndx.dimension( (d) -> d.dd)
  dc.barChart('#photo-engagements-chart2').dimension(engagement_by_type)
