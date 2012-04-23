class Label
  include MongoMapper::EmbeddedDocument

  key :name, String
  key :group_index, Integer
  key :color, Hash
end