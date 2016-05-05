class AddSubmissionContextCodeToFolders < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :folders, :submission_context_code, :string
    add_index :folders, [:submission_context_code, :parent_folder_id], unique: true, algorithm: :concurrently
  end
end