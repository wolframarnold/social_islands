class SchemaRefactorFriendsAreFirstClassRecords < Mongoid::Migration

  def self.up
    # Changes:
    # Friends are not first class FacebookProfile records
    #   It's possible to have more than one record per UID; each request with
    #   a new app_id will produce new records to be written
    #   Records are only unique by UID *and* app_id, so as to not co-mingle
    #   data from different access tokens and permissions, as the raw data level.
    # Edges are recorded in FacebookFriendship collection, based on UID
    # The graph has been moved to its own collection, FacebookGraph with embedded
    #   labels.
    # FacebookProfile uses a last_fetched_at flag (should be set from created_at)
    #   to determine whether to run fetch
  end

  def self.down
  end
end