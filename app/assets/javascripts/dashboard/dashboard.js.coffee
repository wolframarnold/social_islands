#loadData = (collapsible_sel) ->
#  console.log 'called loadData with: '+collapsible_sel
#
#$ ->
#  $('#user-rows.collapse').on 'show', ->
#    console.log 'show callback fired'
#    collapsible = $(this).data['target']
#    loadData(collapsible) unless $(collapsible)