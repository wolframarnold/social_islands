class RenameCollectionsOfOldSchema < Mongoid::Migration

  COLLECTIONS_TO_RENAME = %w( status_engagements
                              photo_engagements
                              facebook_profiles
                              users
                              api_clients )

  def self.up
    COLLECTIONS_TO_RENAME.each do |coll|
      Mongoid.database.rename_collection coll, "#{coll}_pre_2012_07_15"
    end
  end

  def self.down
    COLLECTIONS_TO_RENAME.each do |coll|
      Mongoid.database.rename_collection "#{coll}_pre_2012_07_15", coll
    end
  end
end