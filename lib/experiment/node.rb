require 'matrix'

class Matrix
  def []=(i,j,x)
    @rows[i][j]=x
  end
end

class Node
  attr_accessor :uid, :name, :group, :friends, :liked_by, :liked_to, :commented_by, :commented_to, :message_to, :message_from, :checkin_others, :co_checkin_with
  def initialize
    @group=[]
    @friends=[]
    @checkin_others = []
    @co_checkin_with=[]
    @liked_by=[]        #like, comment in status, checkin
    @liked_to=[]
    @commented_by=[]
    @commented_to=[]
    @message_to=[]
    @message_from=[]
  end
  def add_friend(friend_id)
    @friends.insert(-1, friend_id) if !(@friends.include?(friend_id))
  end
  def add_checkin_others(tgt)
    tgt.each do |t|
      @checkin_others.insert(-1, t) if ! (@checkin_others.include?(t))
    end
  end
  def add_co_checkin_with(tgt)
    tgt.each do |t|
      @co_checkin_with.insert(-1, t) if ! (@co_checkin_with.include?(t))
    end
  end

  def folks_like_comment(para, folks)
    folks.each do |folk|
      id=folk["id"]
      para.insert(-1, id) if !(para.include?(id))
    end
  end

  def add_photo_commented_to(folks)
    folks.each do |folk|
      id=folk["from"]["id"]
      @commented_to.insert(-1, id) if !(@commented_to.include?(id))
    end
  end

  def add_liked_by(folks)
    folks_like_comment(@liked_by, folks)
  end

  def add_commented_by(folks)
    folks_like_comment(@commented_by, folks)
  end

  def add_liked_to(folk)
    @liked_to.insert(-1, folk) if !(@liked_to.include?(folk))
  end

  def add_commented_to(folk)
    @commented_to.insert(-1, folk) if !(@commented_to.include?(folk))
  end

  def add_message_to(folks)
    folks.each do |folk|
      @message_to.insert(-1, folk) if !(@message_to.include?(folk))
    end
  end

  def add_message_from(folk)
    @message_from.insert(-1, folk) if !(@message_from.include?(folk))
  end

end



#establish group list from graph
def get_group_list
  group_id=0
  group_list=Hash.new()  #{color, group_id}
  $graph_nodes.each do |graph_node|
    color=graph_node["color"]
    if (!group_list.has_key?(color))
      group_list[color]=group_id
      group_id+=1
    end
  end
  return group_list
end

#create list of nodes (friends) from graph
def get_node_map
  node_map=Hash.new()
  $graph_nodes.each do |graph_node|
    node=Node.new()
    node.uid=graph_node["id"]
    node.name=graph_node["label"]

    group_id=$group_list[graph_node["color"]]
    node.group.insert(-1, group_id) if !node.group.include?(group_id)
    node_map[node.uid]= node
  end
  #populate friends(edge) list for each node
  $graph_edges.each do |graph_edge|
    node_map[graph_edge["source"]].add_friend(graph_edge["target"])
    node_map[graph_edge["target"]].add_friend(graph_edge["source"])
  end
  return node_map
end

def add_liked_commented_by(uid, feed)
  if $node_map.has_key?(uid)
    if feed["likes"].present?
      $node_map[uid].add_liked_by(feed["likes"]["data"]) if feed["likes"]["data"].present?
    end
    if feed["comments"].present? && feed["comments"]["data"].present?
      folks=feed["comments"]["data"].collect {|d| d["from"]}
      $node_map[uid].add_commented_by(folks)
    end
  end

  if feed["likes"].present?
    feed["likes"]["data"].each do |folk|
      $node_map[folk["id"]].add_liked_to(uid) if $node_map[folk["id"]].present?
    end
  end

  if feed["comments"].present? && feed["comments"]["data"].present?
    feed["comments"]["data"].each do |comment|
      id=comment["from"]["id"]
      $node_map[id].add_commented_to(uid) if $node_map[id].present?
    end
  end
end

#now processing feeds

def process_checkin(uid, feed)
  add_liked_commented_by(uid, feed)
  if feed["to"].present?
    src=feed["from"]["id"]
    tgt=feed["to"]["data"].map {|t| t["id"]}.compact
    $node_map[src].add_checkin_others(tgt) if $node_map.has_key?(src)
    tgt.each do |t|
      $node_map[t].add_co_checkin_with(tgt-[t]) if $node_map.has_key?(t)
    end
  end
end

def process_status(uid, feed)
  add_liked_commented_by(uid, feed)
  if feed["to"].present?
    src=feed["from"]["id"]
    tgt=feed["to"]["data"].collect {|d| d["id"]}
    $node_map[src].add_message_to(tgt) if $node_map.has_key?(src)
    tgt.each {|t| $node_map[t].add_message_from(src) if $node_map.has_key?(t)}
  elsif feed["story"].present?
    if !(feed["story"].include?("friend"))  #ignor new friend messages
      if feed["story_tags"].present?
        src=feed["from"]["id"]
        tgt=feed["story_tags"].collect {|t| t[1][0]["id"]}
        $node_map[src].add_message_to(tgt) if $node_map.has_key?(src)
        tgt.each {|t| $node_map[t].add_message_from(src) if $node_map.has_key?(t)}
      end
    end
  else
    puts "a status update, ignore for now==> " + feed["message"]
  end
end

def process_photos(uid, feed)
  add_liked_commented_by(uid, feed)
end

def check_feed(uid, feed)
  puts feed["type"]
  case feed["type"]
    when "checkin"
      process_checkin(uid, feed)
    when "photo"
      process_photos(uid, feed)
    when "status"
      process_status(uid, feed)
    when "link"
      #puts "it's a link"
    when "question"
    when "offer"
    when "video"
      #puts "it's a video"
    when "swf"   #twitter
    else
      puts "no type match"
      pp feed
  end
end

