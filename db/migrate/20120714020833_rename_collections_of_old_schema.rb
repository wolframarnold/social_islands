class RenameCollectionsOfOldSchema < Mongoid::Migration

  COLLECTIONS_TO_RENAME = %w( status_engagements
                              photo_engagements
                              facebook_profiles
                              users
                              api_clients )

  def self.up
    COLLECTIONS_TO_RENAME.each do |coll|
      Mongoid.database.rename_collection coll, "#{coll}-pre-2012-07-15"
    end
  end

  def self.down
    COLLECTIONS_TO_RENAME.each do |coll|
      Mongoid.database.rename_collection "#{coll}-pre-2012-07-15", coll
    end
  end
end