load './Projects/social_islands/lib/experiment/get_friends_feed.rb'
load './Projects/social_islands/lib/experiment/node.rb'

#name="Phillip Cardenas"
#name="Daiane Lopes da Silva"
name="Weidong Yang"

get_and_save_friends_feed(name)

$usr=User.where(name:name).first
fb=FacebookProfile.unscoped.where(user_id:$usr._id).first

friends=fb.friends
graph=fb.graph

doc=Hash.from_xml(graph)
$graph_nodes=doc["gexf"]["graph"]["nodes"]["node"]
$graph_edges=doc["gexf"]["graph"]["edges"]["edge"]



$group_list=get_group_list
$node_map=get_node_map


friends.map do |friend|
  friend["feed"].map do |feed|
    check_feed(friend["uid"].to_s, feed)
  end
end

fb.feed.map do |feed|
  check_feed(fb.uid, feed)
end
#group analysis

$group_count=Hash.new()
$node_map.each do |key, node|
  group_id=node.group
  group_id.each do |id|
    $group_count[id]=0 if $group_count[id].blank?
    $group_count[id]+=1
  end
end
pp $group_count

num_group=$group_count.count


$liked_by=Matrix.zero(num_group)
$commented_by=Matrix.zero(num_group)

$node_map.each do |key, node|
  tgtgroup=node.group[0]
  src = node.liked_by
  src.map do |srcid|
    if $node_map.has_key?(srcid)
      srcgroup = $node_map[srcid].group[0]
      puts srcgroup.to_s + "==>" + tgtgroup.to_s
      $liked_by[srcgroup, tgtgroup]+=1 #if node.uid!=$node_map[srcid].uid
    end
  end
  src = node.commented_by
  src.map do |srcid|
    if $node_map.has_key?(srcid)
      srcgroup = $node_map[srcid].group[0]
      puts srcgroup.to_s + "==>" + tgtgroup.to_s
      $commented_by[srcgroup, tgtgroup]+=1 #if node.uid!=$node_map[srcid].uid
    end
  end
end

$liked_by
$commented_by

$usr.uid
$node_map[$usr.uid].liked_by
$node_map[$usr.uid].liked_to

$group_count.each_with_index do |cnt, idx|
  puts cnt[1].to_s+", "+idx.to_s+",   "+ ($liked_by[idx,idx]*1.0/cnt[1]).to_s
end
