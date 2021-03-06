class AlterCategoryTopicsAddUniqueIndex < ActiveRecord::Migration
  def change
    add_index :category_topics,
              [:topic_id, :category_id, :category_type],
              unique: true,
              name: 'index_category_topics_to_assure_uniqueness'
  end
end
